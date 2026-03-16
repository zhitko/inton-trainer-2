#include "audioapi.h"
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

#include <cmath>

#include <QAudioOutput>
#include <QMediaPlayer>

AudioApi::AudioApi(QObject* parent)
    : QObject(parent)
{
    m_audioDevice = QMediaDevices::defaultAudioInput();
    m_format.setSampleRate(8000);
    m_format.setChannelCount(1);
    m_format.setSampleFormat(QAudioFormat::Int16);
    m_wavFileService = std::make_unique<WavFileService>(
        QCoreApplication::applicationDirPath().toStdString());

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

qreal AudioApi::audioLevel() const
{
    qreal result = m_audioLevel;
    return result;
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

    // Load settings for auto-stop recording
    AppSettings settings = Settings::loadSettings();
    m_autoStopEnabled = settings.autoStopRecording;
    m_silenceDurationMs = settings.autoStopSilenceDuration;
    
    // Reset VAD parameters
    m_thresholdCalculated = false;
    m_silenceThreshold = 0.0;  // Initial threshold to detect voice start
    m_noiseFloor = 0.0;        // Will be calibrated during initial frames
    m_peakLevel = 0.0;         // Will track peak audio level during recording
    m_calibrationCounter = 0;
    m_calibrationSum = 0.0;

    m_buffer.clear();
    m_preBuffer.clear();
    setAudioLevel(0.0);

    // Reset silence tracking for auto-stop
    m_silenceStartTime = 0;
    m_silenceBufferSize = 0;
    m_voiceDetected = false;

    m_audioSource = std::make_unique<QAudioSource>(m_audioDevice, m_format, this);
    QIODevice* io = m_audioSource->start();

    connect(io, &QIODevice::readyRead, this, [this, io, durationSeconds]() {
        const qint64 len = m_audioSource->bytesAvailable();
        QByteArray data = io->read(len);

        qint64 numSamples = data.size() / (m_format.bytesPerSample());
        qint64 sumValue = 0;
        if (numSamples > 0) {
            const auto samples = reinterpret_cast<const qint16*>(data.constData());
            for (qint64 i = 0; i < numSamples; ++i) {
                sumValue += std::abs(samples[i]);
            }
        }
        double avgValue = (numSamples > 0) ? (double)sumValue / numSamples : 0.0;
        double level = avgValue / 4000.0;
        setAudioLevel(level > 1.0 ? 1.0 : level);

        // Auto-stop recording logic using improved VAD (Voice Activity Detection)
        // This implementation uses:
        // 1. Initial calibration period to establish noise floor
        // 2. Adaptive thresholds that adjust to changing noise conditions
        // 3. More robust voice detection with configurable ratios
        // 4. Improved silence detection with better parameters
        if (m_autoStopEnabled) {
            // Calculate pre-buffer max size: 500ms of audio
            const int preBufferMaxBytes = (m_format.sampleRate() * m_format.bytesPerSample() * PRE_BUFFER_MS) / 1000;
            // Calculate post-buffer size: 500ms of audio (bytes to keep after silence starts)
            const int postBufferBytes = (m_format.sampleRate() * m_format.bytesPerSample() * PRE_BUFFER_MS) / 1000;

            // Step 1: Calibrate noise floor during initial frames
            if (m_calibrationCounter < CALIBRATION_FRAMES) {
                m_calibrationSum += avgValue;
                m_calibrationCounter++;
                
                // Once we have enough samples, calculate the noise floor
                if (m_calibrationCounter == CALIBRATION_FRAMES) {
                    m_noiseFloor = m_calibrationSum / CALIBRATION_FRAMES;
                    // Set initial silence threshold based on noise floor
                    m_silenceThreshold = m_noiseFloor * 1.2; // 20% above noise floor
                    LOG_DEBUG() << "AutoStop: Calibrated noise floor=" << m_noiseFloor
                                << ", initial silence threshold=" << m_silenceThreshold;
                }
                
                // Keep rolling pre-buffer during calibration
                m_preBuffer.append(data);
                if (m_preBuffer.size() > preBufferMaxBytes) {
                    m_preBuffer.remove(0, m_preBuffer.size() - preBufferMaxBytes);
                }
            }
            // Step 2: Voice activity detection after calibration
            else if (!m_voiceDetected) {
                // Adaptively adjust threshold based on current audio level
                // This helps with changing background noise conditions
                if (avgValue > m_noiseFloor && avgValue < m_silenceThreshold * VOICE_LEVEL_RATIO) {
                    // Slowly adapt to changing background noise
                    m_noiseFloor = m_noiseFloor * 0.95 + avgValue * 0.05;
                    m_silenceThreshold = m_noiseFloor * 1.2;
                }
                
                // Voice detection: level significantly above threshold
                if (avgValue >= m_silenceThreshold * VOICE_LEVEL_RATIO) {
                    LOG_DEBUG() << "AutoStop: Voice detected avgValue=" << avgValue
                                << ", threshold=" << m_silenceThreshold
                                << ", ratio=" << (avgValue / m_silenceThreshold);
                    
                    // Voice detected - prepend pre-buffer (500ms before voice) to main buffer
                    m_buffer = m_preBuffer + data;
                    m_preBuffer.clear();
                    m_voiceDetected = true;
                    m_thresholdCalculated = true;
                    // Initialize peak level with current level
                    m_peakLevel = avgValue;
                    LOG_DEBUG() << "AutoStop: Voice detected, prepended" << m_preBuffer.size() << "bytes of pre-buffer";
                } else {
                    // Still in pre-voice phase, maintain rolling pre-buffer
                    m_preBuffer.append(data);
                    if (m_preBuffer.size() > preBufferMaxBytes) {
                        m_preBuffer.remove(0, m_preBuffer.size() - preBufferMaxBytes);
                    }
                }
            }
            // Step 3: Silence detection after voice was detected
            else if (m_voiceDetected) {
                m_buffer.append(data);
                
                // Adaptive silence detection threshold
                double silenceDetectionThreshold = m_silenceThreshold * SILENCE_LEVEL_RATIO;
                
                // Update peak level if current level is higher
                if (avgValue > m_peakLevel) {
                    m_peakLevel = avgValue;
                }
                
                // Calculate both absolute and relative silence thresholds
                double absoluteThreshold = silenceDetectionThreshold;
                double relativeThreshold = m_peakLevel * RELATIVE_SILENCE_RATIO;
                
                LOG_DEBUG() << "AutoStop: Processing voice avgValue=" << avgValue
                            << ", abs threshold=" << absoluteThreshold
                            << ", rel threshold=" << relativeThreshold
                            << ", peak=" << m_peakLevel;
                
                // Detect silence if level drops below either threshold
                if (avgValue <= absoluteThreshold ||
                    (m_peakLevel > 0 && avgValue <= relativeThreshold)) {
                    // Silence detected (back to near-ambient level)
                    if (m_silenceStartTime == 0) {
                        // Start tracking silence
                        m_silenceStartTime = QDateTime::currentMSecsSinceEpoch();
                        // Track the buffer size at the start of silence
                        m_silenceBufferSize = m_buffer.size();
                        LOG_DEBUG() << "AutoStop: Potential silence started, monitoring...";
                    } else {
                        // Check if silence duration exceeded threshold
                        qint64 silenceDuration = QDateTime::currentMSecsSinceEpoch() - m_silenceStartTime;
                        if (silenceDuration >= m_silenceDurationMs) {
                            LOG_DEBUG() << "AutoStop: Silence detected for" << silenceDuration
                                        << "ms, stopping recording (level=" << avgValue
                                        << ", peak=" << m_peakLevel
                                        << ", ratio=" << (avgValue / m_peakLevel) << ")";
                            
                            // Keep post-buffer after voice ends, remove the rest of silence
                            if (m_silenceBufferSize > 0 && m_buffer.size() > m_silenceBufferSize + postBufferBytes) {
                                int silenceBytesToRemove = m_buffer.size() - m_silenceBufferSize - postBufferBytes;
                                m_buffer.remove(m_silenceBufferSize + postBufferBytes, silenceBytesToRemove);
                                LOG_DEBUG() << "AutoStop: Removed" << silenceBytesToRemove
                                            << "bytes of silence, kept" << postBufferBytes << "bytes post-buffer";
                            }
                            stopRecording();
                            return;
                        }
                    }
                } else {
                    // Voice/level is back above threshold, reset silence tracking
                    if (m_silenceStartTime != 0) {
                        LOG_DEBUG() << "AutoStop: Voice resumed, resetting silence tracking";
                        m_silenceStartTime = 0;
                        m_silenceBufferSize = 0;
                    }
                    
                    // Adapt noise floor and threshold based on ongoing audio
                    // This helps with changing speech characteristics during recording
                    if (avgValue < m_silenceThreshold * VOICE_LEVEL_RATIO * 1.5) {
                        // Slowly adapt threshold for better silence detection
                        m_silenceThreshold = m_silenceThreshold * 0.98 + (avgValue * 0.02);
                    }
                }
            }
        } else {
            // Auto-stop disabled, append all data
            m_buffer.append(data);
        }

        if (durationSeconds > 0) {
            const int maxBufferSize = m_format.sampleRate() * m_format.bytesPerSample() * durationSeconds;
            if (m_buffer.size() > maxBufferSize) {
                m_buffer = m_buffer.right(maxBufferSize);
            }
        }
    });

    m_isRecording = true;
    emit isRecordingChanged();

    LOG_DEBUG() << "Finish: startRecording - Recording started";
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
    emit isRecordingChanged();

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
