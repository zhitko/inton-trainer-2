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

std::vector<double> AudioApi::calculateVadMetrics(const qint16* samples, qint64 numSamples)
{
    std::vector<double> newVValues;
    
    // Add samples to buffer
    for (qint64 i = 0; i < numSamples; ++i) {
        m_sampleBuf.push_back(samples[i]);
    }

    // Calculate A (Amplitude) from 128-sample frames with 64-sample hop
    while (static_cast<int>(m_sampleBuf.size()) >= 128) {
        long long sumAmp = 0;
        for (int i = 0; i < 128; ++i) {
            sumAmp += std::abs(static_cast<int>(m_sampleBuf[i]));
        }
        m_A.push_back(static_cast<double>(sumAmp) / 128.0);
        m_sampleBuf.erase(m_sampleBuf.begin(), m_sampleBuf.begin() + 64);
    }

    // Ensure vectors are large enough
    if (m_U.size() < m_A.size()) m_U.resize(m_A.size(), 0.0);
    if (m_H.size() < m_A.size()) m_H.resize(m_A.size(), 0.0);
    if (m_V.size() < m_A.size()) m_V.resize(m_A.size(), 0.0);

    // Calculate U(n) and H(n) incrementally
    for (; m_valid_U + K_FRAMES - 1 < static_cast<int>(m_A.size()); ++m_valid_U) {
        int i = m_valid_U;
        if (i - K_FRAMES + 1 < 0) continue;

        double sum_A = 0.0;
        for (int j = i - K_FRAMES + 1; j < i + K_FRAMES; ++j) {
            sum_A += m_A[j];
        }
        m_U[i] = sum_A / (2 * K_FRAMES - 1);
        m_H[i] = std::abs(m_A[i] - m_U[i]);
    }

    // Calculate V(n) incrementally
    for (; m_valid_V + K_FRAMES - 1 < m_valid_U; ++m_valid_V) {
        int i = m_valid_V;
        if (i - K_FRAMES + 1 < 0) continue;

        double sum_H = 0.0;
        for (int j = i - K_FRAMES + 1; j < i + K_FRAMES; ++j) {
            sum_H += m_H[j];
        }
        m_V[i] = sum_H / (2 * K_FRAMES - 1);
        newVValues.push_back(m_V[i]);
    }

    return newVValues;
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
    for (int i = 0; i < static_cast<int>(m_savedA.size()); ++i)
        list.append(QPointF(i, m_savedA[i]));
    return list;
}

QVariantList AudioApi::getVadU() const
{
    QVariantList list;
    for (int i = 0; i < static_cast<int>(m_savedU.size()); ++i)
        list.append(QPointF(i, m_savedU[i]));
    return list;
}

QVariantList AudioApi::getVadV() const
{
    QVariantList list;
    for (int i = 0; i < static_cast<int>(m_savedV.size()); ++i)
        list.append(QPointF(i, m_savedV[i]));
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
    
    m_valid_U = 0;
    m_valid_V = 0;
    m_calibrationCounter = 0;
    m_calibrationFrames.clear();
    // Use saved threshold from settings if available; otherwise will calibrate at runtime
    m_Pe = settings.vadThreshold > 0 ? settings.vadThreshold : 0.0;
    // If we have a preset threshold, skip the in-recording calibration phase
    if (m_Pe > 0) {
        m_calibrationCounter = CALIBRATION_FRAMES;
    }
    if (m_voiceDetected) {
        m_voiceDetected = false;
        emit isVoiceDetectedChanged();
    }
    
    m_sampleBuf.clear();
    m_A.clear();
    m_U.clear();
    m_H.clear();
    m_V.clear();

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
            // Calculate VAD metrics using helper function
            std::vector<double> newVValues = calculateVadMetrics(samples, numSamples);
            
            // Process new V values for auto-stop if enabled
            if (m_autoStopEnabled) {
                int firstFrameIdx = m_valid_V - static_cast<int>(newVValues.size());
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
    if (m_calibrationCounter < CALIBRATION_FRAMES) {
        m_calibrationFrames.push_back(V_n);
        m_calibrationCounter++;
        if (m_calibrationCounter == CALIBRATION_FRAMES) {
            // Use 95th percentile to ignore occasional noise spikes during calibration
            m_Pe = percentileValue(m_calibrationFrames, 0.95) * 3.0;
            LOG_DEBUG() << "AutoStop: Calibrated threshold Pe=" << m_Pe
                        << " (95th percentile of" << CALIBRATION_FRAMES << "frames)";
        }
        return;
    }

    bool isSpeech = (V_n > m_Pe);

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

double AudioApi::percentileValue(std::vector<double> values, double percentile)
{
    if (values.empty()) return 0.0;
    // We need a sorted copy, and 'values' is already a copy since it's passed by value
    std::sort(values.begin(), values.end());
    int idx = static_cast<int>(std::ceil(percentile * values.size())) - 1;
    if (idx < 0) idx = 0;
    if (idx >= static_cast<int>(values.size())) idx = static_cast<int>(values.size()) - 1;
    return values[idx];
}

void AudioApi::calibrateVad()
{
    LOG_DEBUG() << "Start: calibrateVad";
    if (m_isRecording) {
        LOG_DEBUG() << "Finish: calibrateVad - Already recording, skipping";
        return;
    }

    // Save current VAD state
    auto savedSampleBuf = m_sampleBuf;
    auto savedA = m_A;
    auto savedU = m_U;
    auto savedH = m_H;
    auto savedV = m_V;
    int savedValidU = m_valid_U;
    int savedValidV = m_valid_V;

    // Clear VAD state for calibration
    m_sampleBuf.clear();
    m_A.clear();
    m_U.clear();
    m_H.clear();
    m_V.clear();
    m_valid_U = 0;
    m_valid_V = 0;

    std::vector<double> allV;
    
    QAudioFormat fmt = m_format;
    auto source = std::unique_ptr<QAudioSource>(new QAudioSource(m_audioDevice, fmt, this));
    QIODevice* io = source->start();
    if (!io) {
        LOG_DEBUG() << "Finish: calibrateVad - Failed to open audio device";
        // Restore state
        m_sampleBuf = savedSampleBuf;
        m_A = savedA;
        m_U = savedU;
        m_H = savedH;
        m_V = savedV;
        m_valid_U = savedValidU;
        m_valid_V = savedValidV;
        emit calibrationFinished(50000.0);
        return;
    }

    // Record for 2 seconds synchronously using a local event loop
    QTimer stopTimer;
    stopTimer.setSingleShot(true);
    stopTimer.setInterval(2000);

    QEventLoop loop;
    connect(&stopTimer, &QTimer::timeout, &loop, &QEventLoop::quit);

    connect(io, &QIODevice::readyRead, this, [this, io, &allV, fmt]() {
        QByteArray data = io->readAll();
        qint64 numSamples = data.size() / fmt.bytesPerSample();
        if (numSamples > 0) {
            const auto samples = reinterpret_cast<const qint16*>(data.constData());
            // Use helper function to calculate VAD metrics
            std::vector<double> newVValues = calculateVadMetrics(samples, numSamples);
            // Collect all V values for threshold calculation
            allV.insert(allV.end(), newVValues.begin(), newVValues.end());
        }
    });

    stopTimer.start();
    loop.exec();

    source->stop();

    // Restore original state
    m_sampleBuf = savedSampleBuf;
    m_A = savedA;
    m_U = savedU;
    m_H = savedH;
    m_V = savedV;
    m_valid_U = savedValidU;
    m_valid_V = savedValidV;

    // Use 95th percentile × 3 as threshold — robust against noise spikes
    double threshold = allV.empty() ? 50000.0 : percentileValue(allV, 0.95) * 3.0;
    LOG_DEBUG() << "Calibration done: threshold=" << threshold
                << " (95th percentile of" << allV.size() << "frames)";
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

    m_savedA = m_A;
    m_savedU = m_U;
    m_savedV = m_V;

    // Crop m_savedA, m_savedU, m_savedV to synchronize with m_buffer
    if (m_autoStopEnabled && m_voiceDetected && m_firstSpeechFrame >= 0 && m_lastSpeechFrame >= 0) {
        int pre_samples = (PRE_BUFFER_MS * m_format.sampleRate()) / 1000;
        int post_samples = (PRE_BUFFER_MS * m_format.sampleRate()) / 1000;
        
        int start_frame = (m_firstSpeechFrame * 64 - pre_samples) / 64;
        if (start_frame < 0) start_frame = 0;
        
        int end_frame = (m_lastSpeechFrame * 64 + 128 + post_samples) / 64;
        
        if (start_frame < static_cast<int>(m_savedA.size())) {
            int count = end_frame - start_frame;
            if (start_frame + count > static_cast<int>(m_savedA.size()))
                count = m_savedA.size() - start_frame;
            
            if (count > 0) {
                m_savedA = std::vector<double>(m_savedA.begin() + start_frame, m_savedA.begin() + start_frame + count);
                if (start_frame < static_cast<int>(m_savedU.size())) {
                   int u_count = std::min<int>(count, m_savedU.size() - start_frame);
                   m_savedU = std::vector<double>(m_savedU.begin() + start_frame, m_savedU.begin() + start_frame + u_count);
                }
                if (start_frame < static_cast<int>(m_savedV.size())) {
                   int v_count = std::min<int>(count, m_savedV.size() - start_frame);
                   m_savedV = std::vector<double>(m_savedV.begin() + start_frame, m_savedV.begin() + start_frame + v_count);
                }
            }
        }
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
