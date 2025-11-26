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
    if (!waveFile || !waveFile->cueChunk) {
        qDebug() << "WaveFile or CueChunk is null";
        return cuePoints;
    }

    uint32_t cuePointsCount = littleEndianBytesToUInt32(waveFile->cueChunk->cuePointsCount);
    qDebug() << "Found" << cuePointsCount << "cue points";
    for (uint32_t i = 0; i < cuePointsCount; ++i) {
        QVariantMap cuePoint;
        CuePoint *cp = &waveFile->cueChunk->cuePoints[i];
        uint32_t cuePointID = littleEndianBytesToUInt32(cp->cuePointID);
        cuePoint["id"] = cuePointID;
        cuePoint["position"] = littleEndianBytesToUInt32(cp->playOrderPosition);
        cuePoint["chunkStart"] = littleEndianBytesToUInt32(cp->chunkStart);
        cuePoint["blockStart"] = littleEndianBytesToUInt32(cp->blockStart);
        cuePoint["frameOffset"] = littleEndianBytesToUInt32(cp->frameOffset);

        // Find associated label
        QString label = "";
        bool ltxtFound = false;
        if (waveFile->listCount > 0) {
            for (uint32_t j = 0; j < waveFile->listCount; ++j) {
                ListChunk *listChunk = &waveFile->listChunks[j];
                if (label.isEmpty()) {
                    for (uint32_t k = 0; k < listChunk->lablCount; ++k) {
                        LablChunk *lablChunk = &listChunk->lablChunks[k];
                        if (littleEndianBytesToUInt32(lablChunk->cuePointID) == cuePointID) {
                            label = QString(lablChunk->text);
                            break;
                        }
                    }
                }

                if (!ltxtFound) {
                    for (uint32_t k = 0; k < listChunk->ltxtCount; ++k) {
                        LtxtChunk *ltxtChunk = &listChunk->ltxtChunks[k];
                        if (littleEndianBytesToUInt32(ltxtChunk->cuePointID) == cuePointID) {
                            cuePoint["sampleLength"] = littleEndianBytesToUInt32(ltxtChunk->sampleLength);
                            cuePoint["purposeID"] = QString(QByteArray(ltxtChunk->purposeID, 4));
                            cuePoint["country"] = littleEndianBytesToUInt16(ltxtChunk->country);
                            cuePoint["language"] = littleEndianBytesToUInt16(ltxtChunk->language);
                            cuePoint["dialect"] = littleEndianBytesToUInt16(ltxtChunk->dialect);
                            cuePoint["codePage"] = littleEndianBytesToUInt16(ltxtChunk->codePage);
                            cuePoint["text"] = QString(ltxtChunk->text);
                            ltxtFound = true;
                            break;
                        }
                    }
                }

                if (!label.isEmpty() && ltxtFound) {
                    break;
                }
            }
        }
        cuePoint["label"] = label;
        qDebug() << "Cue Point" << i 
                 << ": ID=" << cuePointID 
                 << "Label=" << label 
                 << "Position=" << cuePoint["position"].toUInt()
                 << "Sample Length=" << cuePoint["sampleLength"].toUInt();

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
