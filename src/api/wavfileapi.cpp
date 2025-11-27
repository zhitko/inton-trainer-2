#include "wavfileapi.h"
#include "src/services/wavfileservice.h"
#include "src/services/pitchservice.h"
#include <QDebug>
#include <QPointF>
#include <limits>

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

QVariantList WavFileApi::getPitch(WaveFile* waveFile,
                                  const QString& algorithm,
                                  double frameShift,
                                  double sampleRate,
                                  double minF0,
                                  double maxF0,
                                  double voicingThreshold,
                                  const QString& outputFormat)
{
    qDebug() << "getPitch called";
    QVariantList pitchData;
    
    if (!waveFile) {
        qDebug() << "WaveFile is null";
        return pitchData;
    }
    
    // Get wave data
    std::vector<double> samples = WavFileService::readWaveData(waveFile);
    if (samples.empty()) {
        qDebug() << "No wave data found";
        return pitchData;
    }
    
    // Map algorithm string to enum
    PitchAlgorithm algo;
    if (algorithm == "RAPT") {
        algo = PitchAlgorithm::RAPT;
    } else if (algorithm == "SWIPE") {
        algo = PitchAlgorithm::SWIPE;
    } else if (algorithm == "REAPER") {
        algo = PitchAlgorithm::REAPER;
    } else if (algorithm == "DIO") {
        algo = PitchAlgorithm::DIO;
    } else if (algorithm == "Harvest") {
        algo = PitchAlgorithm::Harvest;
    } else if (algorithm == "NumAlgorithm") {
        algo = PitchAlgorithm::NumAlgorithm;
    } else {
        qDebug() << "Unknown algorithm:" << algorithm;
        return pitchData;
    }
    
    // Map output format string to enum
    PitchOutputFormat format;
    if (outputFormat == "PITCH") {
        format = PitchOutputFormat::PITCH;
    } else if (outputFormat == "F0") {
        format = PitchOutputFormat::F0;
    } else if (outputFormat == "LOG_F0") {
        format = PitchOutputFormat::LOG_F0;
    } else {
        qDebug() << "Unknown output format:" << outputFormat;
        return pitchData;
    }
    
    // Create PitchService and extract pitch
    PitchService pitchService;
    std::vector<double> pitch = pitchService.getPitch(
        samples,
        algo,
        frameShift,
        sampleRate,
        minF0,
        maxF0,
        voicingThreshold,
        format
    );
    
    // Normalize pitch data to 0-1 range
    if (!pitch.empty()) {
        // Find min and max values (excluding zeros for unvoiced frames)
        double minVal = std::numeric_limits<double>::max();
        double maxVal = std::numeric_limits<double>::lowest();
        
        for (double value : pitch) {
            if (value > 0.0) {  // Only consider voiced frames
                if (value < minVal) minVal = value;
                if (value > maxVal) maxVal = value;
            }
        }
        
        // Normalize if we have valid range
        if (minVal < maxVal) {
            for (size_t i = 0; i < pitch.size(); ++i) {
                double normalizedValue;
                if (pitch[i] > 0.0) {
                    // Normalize voiced frames to 0-1 range
                    normalizedValue = (pitch[i] - minVal) / (maxVal - minVal);
                } else {
                    // Keep unvoiced frames at 0
                    normalizedValue = 0.0;
                }
                pitchData.append(QPointF(i, normalizedValue));
            }
        } else {
            // All values are the same or all unvoiced, keep as-is
            for (size_t i = 0; i < pitch.size(); ++i) {
                pitchData.append(QPointF(i, pitch[i]));
            }
        }
    }
    
    qDebug() << "getPitch finished with" << pitch.size() << "frames";
    return pitchData;
}

