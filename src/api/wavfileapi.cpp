#include "wavfileapi.h"
#include "src/services/wavfileservice.h"
#include "src/services/pitchservice.h"
#include "src/services/umpservice.h"
#include "src/services/helpers/vectorutils.h"
#include <QDebug>
#include <QPointF>
#include <limits>

WavFileApi::WavFileApi(QObject *parent) : QObject(parent)
{
}

WaveFile* WavFileApi::openWavFile(const QString& filePath)
{
    std::string stdPath = filePath.toStdString();
    return waveOpenFile(stdPath);
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
        cuePoint["label"] = QString::fromStdString(cp.label);
        
        if (cp.length > 0) {
             cuePoint["length"] = cp.length;
        }

        qDebug() << "Cue Point" 
                 << ": ID=" << cp.id
                 << "Label=" << cuePoint["label"].toString()
                 << "Position=" << cp.position
                 << "Length=" << cp.length;

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
    std::vector<double> normalizedSamples = VectorUtils::normalizeByMinMax(0.0, 1.0, samples);
    
    for (size_t i = 0; i < normalizedSamples.size(); ++i) {
        waveData.append(QPointF(i, normalizedSamples[i]));
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
                                  const QString& outputFormat,
                                  const QString& normalizationMode)
{
    qDebug() << "getPitch called with normalization:" << normalizationMode;
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
    
    // Normalize pitch data using VectorUtils based on mode
    if (!pitch.empty()) {
        std::vector<double> normalizedPitch;
        
        if (normalizationMode == "max") {
            normalizedPitch = VectorUtils::normalizeByMax(1.0, pitch);
        } else if (normalizationMode == "min_max") {
            normalizedPitch = VectorUtils::normalizeByMinMax(0.0, 1.0, pitch);
        } else if (normalizationMode == "mean") {
            normalizedPitch = VectorUtils::normalizeByMean(pitch);
        } else if (normalizationMode == "mean_deviation") {
            normalizedPitch = VectorUtils::normalizeByMeanDeviation(pitch);
        } else {
            // Default to by max if unknown
            qDebug() << "Unknown normalization mode:" << normalizationMode << ", defaulting to max";
            normalizedPitch = VectorUtils::normalizeByMax(1.0, pitch);
        }
        
        for (size_t i = 0; i < normalizedPitch.size(); ++i) {
            pitchData.append(QPointF(i, normalizedPitch[i]));
        }
    }
    
    qDebug() << "getPitch finished with" << pitch.size() << "frames";
    return pitchData;
}

QVariantMap WavFileApi::getUMP(const QVariantList& pitch,
                               const QVariantList& cuePoints,
                               int length,
                               int waveDataSize)
{
    qDebug() << "getUMP called";
    qDebug() << "  Input pitch size:" << pitch.size();
    qDebug() << "  Input cuePoints count:" << cuePoints.size();
    qDebug() << "  Target segment length:" << length;
    qDebug() << "  Wave data size:" << waveDataSize;
    
    QVariantMap result;

    // Convert pitch QVariantList to std::vector<double>
    std::vector<double> pitchVec;
    pitchVec.reserve(pitch.size());
    for (const auto& val : pitch) {
        if (val.canConvert<QPointF>()) {
            pitchVec.push_back(val.toPointF().y());
        } else {
             // Fallback if it's just a list of numbers
             pitchVec.push_back(val.toDouble());
        }
    }
    qDebug() << "  Converted pitch vector size:" << pitchVec.size();

    // Convert cuePoints QVariantList to std::vector<CuePointData>
    std::vector<CuePointData> cuePointsVec;
    cuePointsVec.reserve(cuePoints.size());
    for (const auto& val : cuePoints) {
        QVariantMap cpMap = val.toMap();
        CuePointData cp;
        cp.id = cpMap["id"].toUInt();
        cp.position = cpMap["position"].toUInt();
        cp.length = cpMap["length"].toUInt();
        cp.label = cpMap["label"].toString().toStdString();
        cuePointsVec.push_back(cp);
        
        qDebug() << "  Cue point" << cp.id << ":" 
                 << "position=" << cp.position 
                 << "length=" << cp.length 
                 << "label=" << QString::fromStdString(cp.label);
    }

    // Call UMPService
    qDebug() << "  Calling UMPService::getUMP...";
    std::vector<double> umpVec = UMPService::getUMP(pitchVec, cuePointsVec, length, waveDataSize);
    qDebug() << "  UMP result size:" << umpVec.size();

    // Convert result back to QVariantList (as QPointF for graph)
    QVariantList umpData;
    for (size_t i = 0; i < umpVec.size(); ++i) {
        umpData.append(QPointF(i, umpVec[i]));
    }
    result["ump"] = umpData;
    qDebug() << "  UMP data points created:" << umpData.size();

    // Create modified cue points
    QVariantList modifiedCuePoints;
    for (size_t i = 0; i < cuePointsVec.size(); ++i) {
        QVariantMap cpMap;
        cpMap["id"] = cuePointsVec[i].id;
        cpMap["label"] = QString::fromStdString(cuePointsVec[i].label);
        cpMap["position"] = static_cast<uint>(i * length);
        cpMap["length"] = static_cast<uint>(length);
        modifiedCuePoints.append(cpMap);
        
        qDebug() << "  Modified cue point" << cpMap["id"].toUInt() << ":" 
                 << "position=" << cpMap["position"].toUInt() 
                 << "length=" << cpMap["length"].toUInt();
    }
    result["cuePoints"] = modifiedCuePoints;

    qDebug() << "getUMP finished";
    return result;
}

