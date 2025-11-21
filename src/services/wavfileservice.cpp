#include "wavfileservice.h"
#include "../helpers/wavFile.h"
#include <QDebug>
#include <QDir>
#include <QCoreApplication>

WavFileService::WavFileService(QObject *parent) : QObject(parent)
{

}

uint16_t sampleFormatToBitsPerSample(QAudioFormat::SampleFormat sampleFormat)
{
    switch (sampleFormat) {
    case QAudioFormat::UInt8:
        return 8;
    case QAudioFormat::Int16:
        return 16;
    case QAudioFormat::Int32:
        return 32;
    case QAudioFormat::Float:
        return 32;
    default:
        return 0;
    }
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

    WaveHeader *waveHeader = makeWaveHeader(buffer.size());
    FormatChunk *formatChunk = makeFormatChunk(
        format.channelCount(),
        format.sampleRate(),
        sampleFormatToBitsPerSample(format.sampleFormat())
    );
    DataChunk *dataChunk = makeDataChunk(buffer.size(), (char*)buffer.data());

    WaveFile *waveFile = makeWaveFile(
        waveHeader,
        formatChunk,
        dataChunk,
        nullptr,
        nullptr,
        0,
        nullptr,
        0
    );

    saveWaveFile(waveFile, absoluteFilePath.toStdString().c_str());
    waveCloseFile(waveFile);

    qDebug() << "Saved to:" << absoluteFilePath;
    return relativeFilePath;
}