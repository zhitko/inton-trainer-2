#ifndef WAVFILESERVICE_H
#define WAVFILESERVICE_H

#include <QObject>
#include <QFile>
#include <QAudioFormat>

class WavFileService : public QObject
{
    Q_OBJECT
public:
    explicit WavFileService(QObject *parent = nullptr);

    Q_INVOKABLE void writeWavHeader(QIODevice *device, const QAudioFormat &format, qint64 dataSize);
    Q_INVOKABLE QString writeWaveFile(const QString &fileName, const QByteArray &buffer, const QAudioFormat &format);
};

#endif // WAVFILESERVICE_H
