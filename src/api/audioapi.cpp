#include "audioapi.h"
#include "helpers/logger.h"
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
    LOG_DEBUG() << "Start: audioLevel";
    qreal result = m_audioLevel;
    LOG_DEBUG() << "Finish: audioLevel - result=" << result;
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
    LOG_DEBUG() << "Start: setAudioLevel - level=" << level;
    if (qFuzzyCompare(m_audioLevel, level)) {
        LOG_DEBUG() << "Finish: setAudioLevel - No change";
        return;
    }
    m_audioLevel = level;
    emit isAudioLevelChanged();
    LOG_DEBUG() << "Finish: setAudioLevel";
}

void AudioApi::startRecording(int durationSeconds)
{
    LOG_DEBUG() << "Start: startRecording - durationSeconds=" << durationSeconds;
    if (m_isRecording) {
        LOG_DEBUG() << "Finish: startRecording - Already recording";
        return;
    }

    m_buffer.clear();
    setAudioLevel(0.0);

    m_audioSource = std::make_unique<QAudioSource>(m_audioDevice, m_format, this);
    QIODevice* io = m_audioSource->start();

    connect(io, &QIODevice::readyRead, this, [this, io, durationSeconds]() {
        const qint64 len = m_audioSource->bytesAvailable();
        QByteArray data = io->read(len);
        m_buffer.append(data);

        qint64 numSamples = data.size() / (m_format.bytesPerSample());
        if (numSamples > 0) {
            const auto samples = reinterpret_cast<const qint16*>(data.constData());
            qint16 maxValue = 0;
            for (qint64 i = 0; i < numSamples; ++i) {
                if (std::abs(samples[i]) > maxValue) {
                    maxValue = std::abs(samples[i]);
                }
            }
            double level = maxValue / 4000.0;
            setAudioLevel(level > 1.0 ? 1.0 : level);
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
