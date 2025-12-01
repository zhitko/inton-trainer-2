#include "audioapi.h"
#include "helpers/logger.h"
#include <QDebug>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QMediaDevices>
#include <QUrl>
#include <QCoreApplication>
#include <QBuffer>
#include <QIODevice>

#include <cmath>

#include <QMediaPlayer>
#include <QAudioOutput>

AudioApi::AudioApi(QObject *parent) : QObject(parent)
{
    m_audioDevice = QMediaDevices::defaultAudioInput();
    m_format.setSampleRate(8000);
    m_format.setChannelCount(1);
    m_format.setSampleFormat(QAudioFormat::Int16);
    m_wavFileService = std::make_unique<WavFileService>(QCoreApplication::applicationDirPath().toStdString());

    m_player = new QMediaPlayer(this);
    QAudioOutput *audioOutput = new QAudioOutput(this);
    m_player->setAudioOutput(audioOutput);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
        bool isPlaying = (state == QMediaPlayer::PlayingState);
        if (m_isPlaying != isPlaying) {
            m_isPlaying = isPlaying;
            emit isPlayingChanged();
        }
    });
}

bool AudioApi::isRecording() const
{
    return m_isRecording;
}

bool AudioApi::isPlaying() const
{
    return m_isPlaying;
}

qreal AudioApi::audioLevel() const
{
    return m_audioLevel;
}

void AudioApi::play(const QString& filePath)
{
    LOG_DEBUG() << "AudioApi::play()" << filePath;
    QString fullPath = QDir(QCoreApplication::applicationDirPath()).filePath(filePath);
    m_player->setSource(QUrl::fromLocalFile(fullPath));
    m_player->play();
}

void AudioApi::stopPlayback()
{
    m_player->stop();
}

void AudioApi::setAudioLevel(qreal level)
{
    if (qFuzzyCompare(m_audioLevel, level))
        return;
    m_audioLevel = level;
    emit isAudioLevelChanged();
}

void AudioApi::startRecording(int durationSeconds)
{
    if (m_isRecording)
        return;

    m_buffer.clear();
    setAudioLevel(0.0);

    m_audioSource = new QAudioSource(m_audioDevice, m_format, this);
    QIODevice *io = m_audioSource->start();

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

    LOG_INFO() << "Recording started";
}

void AudioApi::stopRecording()
{
    if (!m_isRecording)
        return;

    m_audioSource->stop();
    m_audioSource->deleteLater();
    m_audioSource = nullptr;
    setAudioLevel(0.0);

    m_isRecording = false;
    emit isRecordingChanged();

    LOG_INFO() << "Recording stopped";
}

QString AudioApi::saveWavFile(QString fileName)
{
    if (fileName.isEmpty()) {
        fileName = QDateTime::currentDateTime().toString("yyyy-MM-dd_HH-mm-ss");
    }

    std::vector<char> buffer(m_buffer.begin(), m_buffer.end());
    
    int bitsPerSample = 16;
    switch (m_format.sampleFormat()) {
        case QAudioFormat::UInt8: bitsPerSample = 8; break;
        case QAudioFormat::Int16: bitsPerSample = 16; break;
        case QAudioFormat::Int32: bitsPerSample = 32; break;
        case QAudioFormat::Float: bitsPerSample = 32; break;
        default: bitsPerSample = 16;
    }

    AudioFormat format;
    format.sampleRate = m_format.sampleRate();
    format.channelCount = m_format.channelCount();
    format.bitsPerSample = bitsPerSample;

    std::string result = m_wavFileService->writeWaveFile(fileName.toStdString(), buffer, format);
    return QString::fromStdString(result);
}

    



    