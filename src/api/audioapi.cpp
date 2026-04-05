#include "audioapi.h"
#include <QPointF>
#include "helpers/logger.h"
#include "helpers/settings.h"
#include <QBuffer>
#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QIODevice>
#include <QMediaDevices>
#include <QStandardPaths>
#include <QUrl>

#include <algorithm>
#include <cmath>
#include <memory>

#include <QAudioOutput>
#include <QEventLoop>
#include <QMediaPlayer>
#include <QTimer>

AudioApi::AudioApi(QObject* parent)
    : QObject(parent)
{
    m_audioDevice = QMediaDevices::defaultAudioInput();
    m_format.setSampleRate(8000);
    m_format.setChannelCount(1);
    m_format.setSampleFormat(QAudioFormat::Int16);
    m_wavFileService = std::unique_ptr<WavFileService>(new WavFileService(
        QCoreApplication::applicationDirPath().toStdString()));

    m_vadService = std::unique_ptr<VADEnergyService>(new VADEnergyService(this));

    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_player->setAudioOutput(m_audioOutput);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this,
        [this](QMediaPlayer::PlaybackState state) {
            bool isPlaying = (state == QMediaPlayer::PlayingState);
            if (m_isPlaying != isPlaying) {
                m_isPlaying = isPlaying;
                emit isPlayingChanged();
            }
        });
}

bool AudioApi::isRecording() const
{
    LOG_DEBUG() << "Start: isRecording";
    bool result = m_isRecording;
    LOG_DEBUG() << "Finish: isRecording - result=" << result;
    return result;
}

bool AudioApi::isPlaying() const
{
    LOG_DEBUG() << "Start: isPlaying";
    bool result = m_isPlaying;
    LOG_DEBUG() << "Finish: isPlaying - result=" << result;
    return result;
}

bool AudioApi::isVoiceDetected() const
{
    return m_voiceDetected;
}

qreal AudioApi::audioLevel() const
{
    qreal result = m_audioLevel;
    return result;
}

QVariantList AudioApi::getVadA() const
{
    QVariantList list;
    const auto& savedA = m_vadService->getSavedA();
    for (int i = 0; i < static_cast<int>(savedA.size()); ++i)
        list.append(QPointF(i, savedA[i]));
    return list;
}

QVariantList AudioApi::getVadU() const
{
    QVariantList list;
    const auto& savedU = m_vadService->getSavedU();
    for (int i = 0; i < static_cast<int>(savedU.size()); ++i)
        list.append(QPointF(i, savedU[i]));
    return list;
}

QVariantList AudioApi::getVadV() const
{
    QVariantList list;
    const auto& savedV = m_vadService->getSavedV();
    for (int i = 0; i < static_cast<int>(savedV.size()); ++i)
        list.append(QPointF(i, savedV[i]));
    return list;
}

void AudioApi::play(const QString& filePath)
{
    LOG_DEBUG() << "Start: play - filePath=" << filePath;
    if (!m_player) {
        LOG_CRITICAL() << "QMediaPlayer is not initialized";
        return;
    }
    QString fullPath = QDir(QCoreApplication::applicationDirPath()).filePath(filePath);
    m_player->setSource(QUrl::fromLocalFile(fullPath));
    m_player->play();
    LOG_DEBUG() << "Finish: play";
}

void AudioApi::stopPlayback()
{
    LOG_DEBUG() << "Start: stopPlayback";
    if (m_player) {
        m_player->stop();
    }
    LOG_DEBUG() << "Finish: stopPlayback";
}

void AudioApi::setAudioLevel(qreal level)
{
    if (qFuzzyCompare(m_audioLevel, level)) {
        return;
    }
    m_audioLevel = level;
    emit isAudioLevelChanged();
}

void AudioApi::startRecording(int durationSeconds)
{
    LOG_DEBUG() << "Start: startRecording - durationSeconds=" << durationSeconds;
    if (m_isRecording) {
        LOG_DEBUG() << "Finish: startRecording - Already recording";
        return;
    }

    AppSettings settings = Settings::loadSettings();
    m_autoStopEnabled = settings.autoStopRecording;
    m_silenceDurationMs = settings.autoStopSilenceDuration;
    
    m_firstSpeechFrame = -1;
    m_lastSpeechFrame = -1;
    m_silenceFramesCount = 0;

    // Initialize VAD service
    m_vadService->reset();
    if (settings.vadThreshold > 0) {
        m_vadService->setThreshold(settings.vadThreshold);
    } else {
        m_vadService->setThreshold(0.0);
    }

    if (m_voiceDetected) {
        m_voiceDetected = false;
        emit isVoiceDetectedChanged();
    }

    m_buffer.clear();
    m_bufferOffsetBytes = 0;
    setAudioLevel(0.0);

    m_audioSource = std::unique_ptr<QAudioSource>(new QAudioSource(m_audioDevice, m_format, this));
    QIODevice* io = m_audioSource->start();

    connect(io, &QIODevice::readyRead, this, [this, io, durationSeconds]() {
        const qint64 len = m_audioSource->bytesAvailable();
        QByteArray data = io->read(len);
        m_buffer.append(data);

        qint64 numSamples = data.size() / (m_format.bytesPerSample());
        qint64 sumValue = 0;
        if (numSamples > 0) {
            const auto samples = reinterpret_cast<const qint16*>(data.constData());
            for (qint64 i = 0; i < numSamples; ++i) {
                sumValue += std::abs(static_cast<int>(samples[i]));
            }
            // Calculate VAD metrics using service
            std::vector<double> newVValues = m_vadService->processAudioSamples(samples, numSamples);
            
            // Process new V values for auto-stop if enabled
            if (m_autoStopEnabled) {
                int validV = m_vadService->getValidVIndex();
                int firstFrameIdx = validV - static_cast<int>(newVValues.size());
                for (size_t i = 0; i < newVValues.size(); ++i) {
                    processVadFrame(firstFrameIdx + i, newVValues[i]);
                }
            }
        }
        double avgValue = (numSamples > 0) ? (double)sumValue / numSamples : 0.0;
        double level = avgValue / 4000.0;
        setAudioLevel(level > 1.0 ? 1.0 : level);

        if (durationSeconds > 0) {
            const int maxBufferSize = m_format.sampleRate() * m_format.bytesPerSample() * durationSeconds;
            if (m_buffer.size() > maxBufferSize) {
                int removeBytes = m_buffer.size() - maxBufferSize;
                m_buffer = m_buffer.right(maxBufferSize);
                m_bufferOffsetBytes += removeBytes;
            }
        }
    });

    m_isRecording = true;
    emit isRecordingChanged();

    LOG_DEBUG() << "Finish: startRecording - Recording started";
}

void AudioApi::processVadFrame(int frameIndex, double V_n)
{
    if (m_vadService->addCalibrationFrame(V_n)) {
        // Calibration just completed
        double threshold = m_vadService->getThreshold();
        LOG_DEBUG() << "AutoStop: Calibrated threshold Pe=" << threshold;
    }

    bool isSpeech = m_vadService->isSpeech(V_n);

    if (isSpeech) {
        if (!m_voiceDetected) {
            m_voiceDetected = true;
            emit isVoiceDetectedChanged();
            m_firstSpeechFrame = frameIndex;
            LOG_DEBUG() << "AutoStop: Voice detected at frame " << frameIndex << ", V=" << V_n;
        }
        m_lastSpeechFrame = frameIndex;
        m_silenceFramesCount = 0;
    } else if (m_voiceDetected) {
        m_silenceFramesCount++;
        // 1 frame corresponds to a 64-sample advance (8ms at 8kHz).
        int silenceDuration = (m_silenceFramesCount * 64 * 1000) / m_format.sampleRate();
        
        if (silenceDuration >= m_silenceDurationMs) {
            LOG_DEBUG() << "AutoStop: Silence limit reached. Stopping.";
            stopRecording();
        }
    }
}

void AudioApi::calibrateVad()
{
    LOG_DEBUG() << "Start: calibrateVad";
    if (m_isRecording) {
        LOG_DEBUG() << "Finish: calibrateVad - Already recording, skipping";
        return;
    }

    // Create a temporary VAD service for calibration
    auto calibrationService = std::make_unique<VADEnergyService>(nullptr);
    calibrationService->prepareForCalibration();

    QAudioFormat fmt = m_format;
    auto source = std::unique_ptr<QAudioSource>(new QAudioSource(m_audioDevice, fmt, this));
    QIODevice* io = source->start();
    if (!io) {
        LOG_DEBUG() << "Finish: calibrateVad - Failed to open audio device";
        emit calibrationFinished(50000.0);
        return;
    }

    // Record for 2 seconds synchronously using a local event loop
    QTimer stopTimer;
    stopTimer.setSingleShot(true);
    stopTimer.setInterval(2000);

    QEventLoop loop;
    connect(&stopTimer, &QTimer::timeout, &loop, &QEventLoop::quit);

    connect(io, &QIODevice::readyRead, this, [this, io, calibrationService = calibrationService.get(), fmt]() {
        QByteArray data = io->readAll();
        qint64 numSamples = data.size() / fmt.bytesPerSample();
        if (numSamples > 0) {
            const auto samples = reinterpret_cast<const qint16*>(data.constData());
            // Process audio samples through calibration service
            calibrationService->processAudioSamples(samples, numSamples);
        }
    });

    stopTimer.start();
    loop.exec();

    source->stop();

    // Get all V values and calculate threshold
    std::vector<double> vValues = calibrationService->getAndClearRecentVValues();
    double threshold = VADEnergyService::calculateThresholdFromValues(vValues);
    
    LOG_DEBUG() << "Calibration done: threshold=" << threshold
                << " (from" << vValues.size() << "frames)";
    emit calibrationFinished(threshold);
    LOG_DEBUG() << "Finish: calibrateVad";
}

void AudioApi::stopRecording()
{
    LOG_DEBUG() << "Start: stopRecording";
    if (!m_isRecording) {
        LOG_DEBUG() << "Finish: stopRecording - Not recording";
        return;
    }

    if (m_audioSource) {
        m_audioSource->stop();
    }
    m_audioSource.reset();
    setAudioLevel(0.0);

    m_isRecording = false;

    // Crop m_buffer to keep only relevant speech + pre/post buffers
    if (m_autoStopEnabled && m_voiceDetected && m_firstSpeechFrame >= 0 && m_lastSpeechFrame >= 0) {
        int pre_samples = (PRE_BUFFER_MS * m_format.sampleRate()) / 1000;
        int post_samples = (PRE_BUFFER_MS * m_format.sampleRate()) / 1000;
        
        int start_sample = m_firstSpeechFrame * 64 - pre_samples;
        if (start_sample < 0) start_sample = 0;
        
        int end_sample = m_lastSpeechFrame * 64 + 128 + post_samples;
        
        int start_byte_absolute = start_sample * m_format.bytesPerSample();
        int end_byte_absolute = end_sample * m_format.bytesPerSample();
        
        int start_byte = start_byte_absolute - m_bufferOffsetBytes;
        if (start_byte < 0) start_byte = 0;
        
        int end_byte = end_byte_absolute - m_bufferOffsetBytes;
        if (end_byte > m_buffer.size()) end_byte = m_buffer.size();
        
        int length = end_byte - start_byte;
        if (length > 0 && start_byte >= 0 && start_byte + length <= m_buffer.size()) {
            m_buffer = m_buffer.mid(start_byte, length);
            LOG_DEBUG() << "AutoStop: Cropped buffer to length " << length << " bytes";
        }
    }

    emit isRecordingChanged();

    // Save current VAD metrics
    m_vadService->updateSavedMetrics();

    // Crop saved metrics to synchronize with m_buffer
    if (m_autoStopEnabled && m_voiceDetected && m_firstSpeechFrame >= 0 && m_lastSpeechFrame >= 0) {
        int pre_samples = (PRE_BUFFER_MS * m_format.sampleRate()) / 1000;
        int post_samples = (PRE_BUFFER_MS * m_format.sampleRate()) / 1000;
        
        int start_frame = (m_firstSpeechFrame * 64 - pre_samples) / 64;
        if (start_frame < 0) start_frame = 0;
        
        int end_frame = (m_lastSpeechFrame * 64 + 128 + post_samples) / 64;
        
        m_vadService->cropSavedMetrics(start_frame, end_frame);
    }

    if (m_voiceDetected) {
        m_voiceDetected = false;
        emit isVoiceDetectedChanged();
    }

    LOG_DEBUG() << "Finish: stopRecording - Recording stopped";
}

QString AudioApi::saveWavFile(QString fileName)
{
    LOG_DEBUG() << "Start: saveWavFile - fileName=" << fileName;
    if (fileName.isEmpty()) {
        fileName = QDateTime::currentDateTime().toString("yyyy-MM-dd_HH-mm-ss");
    }

    std::vector<char> buffer(m_buffer.begin(), m_buffer.end());

    int bitsPerSample = 16;
    switch (m_format.sampleFormat()) {
    case QAudioFormat::UInt8:
        bitsPerSample = 8;
        break;
    case QAudioFormat::Int16:
        bitsPerSample = 16;
        break;
    case QAudioFormat::Int32:
        bitsPerSample = 32;
        break;
    case QAudioFormat::Float:
        bitsPerSample = 32;
        break;
    default:
        bitsPerSample = 16;
    }

    AudioFormat format;
    format.sampleRate = m_format.sampleRate();
    format.channelCount = m_format.channelCount();
    format.bitsPerSample = bitsPerSample;

    std::string result = m_wavFileService->writeWaveFile(fileName.toStdString(), buffer, format);
    QString qResult = QString::fromStdString(result);
    LOG_DEBUG() << "Finish: saveWavFile - result=" << qResult;
    return qResult;
}
