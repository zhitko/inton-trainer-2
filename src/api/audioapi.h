#ifndef AUDIOAPI_H
#define AUDIOAPI_H

#include <QObject>
#include <QAudioSource>
#include <QAudioFormat>
#include <QMediaDevices>
#include "src/services/wavfileservice.h"
#include "src/services/helpers/wavFile.h"
#include <memory>

#include <QMediaPlayer>

class WavFileService;
struct WaveFile;

class AudioApi : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isRecording READ isRecording NOTIFY isRecordingChanged)
    Q_PROPERTY(qreal audioLevel READ audioLevel NOTIFY isAudioLevelChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY isPlayingChanged)

public:
    explicit AudioApi(QObject *parent = nullptr);

    bool isRecording() const;
    qreal audioLevel() const;
    bool isPlaying() const;

public slots:
    Q_INVOKABLE void startRecording(int durationSeconds = -1);
    Q_INVOKABLE void stopRecording();
    Q_INVOKABLE QString saveWavFile(QString fileName = "");
    Q_INVOKABLE void play(const QString& filePath);
    Q_INVOKABLE void stopPlayback();

signals:
    void isRecordingChanged();
    void isAudioLevelChanged();
    void isPlayingChanged();

private:
    void setAudioLevel(qreal level = 0.0);

    QAudioDevice m_audioDevice;
    QAudioSource *m_audioSource = nullptr;
    QAudioFormat m_format;
    QByteArray m_buffer;
    bool m_isRecording = false;
    qreal m_audioLevel = 0.0;
    std::unique_ptr<WavFileService> m_wavFileService;
    QMediaPlayer *m_player = nullptr;
    bool m_isPlaying = false;
};

#endif // AUDIOAPI_H
