#include "wavfileservice.h"
#include <QDebug>
#include <QDir>
#include <QCoreApplication>

WavFileService::WavFileService(QObject *parent) : QObject(parent)
{

}

void WavFileService::writeWavHeader(QIODevice *device, const QAudioFormat &format, qint64 dataSize)
{
    device->write("RIFF");
    device->write(QByteArray(4, 0)); // Placeholder for file size
    device->write("WAVE");
    device->write("fmt ");
    device->write(QByteArray::fromHex("10000000")); // 16
    device->write(QByteArray::fromHex("0100"));   // 1
    quint16 channelCount = format.channelCount();
    device->write(reinterpret_cast<const char *>(&channelCount), 2);
    quint32 sampleRate = format.sampleRate();
    device->write(reinterpret_cast<const char *>(&sampleRate), 4);
    qint32 byteRate = format.sampleRate() * format.channelCount() * format.bytesPerSample();
    device->write(reinterpret_cast<const char *>(&byteRate), 4);
    qint16 blockAlign = format.channelCount() * format.bytesPerSample();
    device->write(reinterpret_cast<const char *>(&blockAlign), 2);

    QAudioFormat::SampleFormat sampleFormat = format.sampleFormat();
    quint16 sampleSize = 0;
    switch (sampleFormat) {
        case QAudioFormat::UInt8:
            sampleSize = 8;
            break;
        case QAudioFormat::Int16:
            sampleSize = 16;
            break;
        case QAudioFormat::Int32:
        case QAudioFormat::Float:
            sampleSize = 32;
            break;
        default:
            qWarning() << "Unknown sample format";
            break;
    }
    device->write(reinterpret_cast<const char *>(&sampleSize), 2);
    device->write("data");
    device->write(reinterpret_cast<const char *>(&dataSize), 4);

    qint64 fileSize = dataSize + 44 - 8;
    device->seek(4);
    device->write(reinterpret_cast<const char *>(&fileSize), 4);
    device->seek(44);
}

QString WavFileService::writeWaveFile(const QString &fileName, const QByteArray &buffer, const QAudioFormat &format)
{
    QDir appDir(QCoreApplication::applicationDirPath());
    QString recordsPath = "data/records";
    if (!appDir.exists(recordsPath)) {
        appDir.mkpath(recordsPath);
    }

    QString relativeFilePath = recordsPath + "/" + fileName + ".wav";
    QString absoluteFilePath = appDir.filePath(relativeFilePath);

    QFile file(absoluteFilePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "Could not open file for writing:" << absoluteFilePath;
        return "";
    }

    writeWavHeader(&file, format, buffer.size());
    file.write(buffer);
    file.close();

    qDebug() << "Saved to:" << absoluteFilePath;
    return relativeFilePath;
}
