#include "wavfileapi.h"
#include "src/services/wavfileservice.h"
#include <QDebug>
#include <QPointF>

WavFileApi::WavFileApi(QObject *parent) : QObject(parent)
{
}

WaveFile* WavFileApi::openWavFile(const QString& filePath)
{
    QByteArray ba = filePath.toLocal8Bit();
    const char *c_filePath = ba.data();
    return waveOpenFile(c_filePath);
}

QVariantList WavFileApi::getCuePoints(WaveFile* waveFile)
{
    qDebug() << "getCuePoints called";
    QVariantList cuePoints;
    
    std::vector<CuePointData> points = WavFileService::readCuePoints(waveFile);
    qDebug() << "Found" << points.size() << "cue points";

    for (const auto& cp : points) {
        QVariantMap cuePoint;
        cuePoint["id"] = cp.id;
        cuePoint["position"] = cp.position;
        cuePoint["chunkStart"] = cp.chunkStart;
        cuePoint["blockStart"] = cp.blockStart;
        cuePoint["frameOffset"] = cp.frameOffset;
        cuePoint["label"] = QString::fromStdString(cp.label);
        
        if (cp.sampleLength > 0 || !cp.text.empty()) {
             cuePoint["sampleLength"] = cp.sampleLength;
             cuePoint["purposeID"] = QString::fromStdString(cp.purposeID);
             cuePoint["country"] = cp.country;
             cuePoint["language"] = cp.language;
             cuePoint["dialect"] = cp.dialect;
             cuePoint["codePage"] = cp.codePage;
             cuePoint["text"] = QString::fromStdString(cp.text);
        }

        qDebug() << "Cue Point" 
                 << ": ID=" << cp.id
                 << "Label=" << cuePoint["label"].toString()
                 << "Position=" << cp.position
                 << "Sample Length=" << cp.sampleLength;

        cuePoints.append(cuePoint);
    }

    qDebug() << "getCuePoints finished";
    return cuePoints;
}

QVariantList WavFileApi::getWaveData(WaveFile* waveFile)
{
    qDebug() << "getWaveData called";
    QVariantList waveData;
    
    std::vector<double> samples = WavFileService::readWaveData(waveFile);
    
    for (size_t i = 0; i < samples.size(); ++i) {
        waveData.append(QPointF(i, samples[i]));
    }
    
    qDebug() << "getWaveData finished";
    return waveData;
}
