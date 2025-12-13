#include "wavfileapi.h"
#include "helpers/logger.h"
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
    LOG_DEBUG() << "Start: openWavFile - filePath=" << filePath;
    std::string stdPath = filePath.toStdString();
    WaveFile* result = waveOpenFile(stdPath);
    LOG_DEBUG() << "Finish: openWavFile - success=" << (result != nullptr);
    return result;
}

QVariantList WavFileApi::getCuePoints(WaveFile* waveFile)
{
    LOG_DEBUG() << "Start: getCuePoints";
    QVariantList cuePoints;
    
    std::vector<CuePointData> points = WavFileService::readCuePoints(waveFile);
    LOG_INFO() << "Found" << points.size() << "cue points";

    for (const auto& cp : points) {
        QVariantMap cuePoint;
        cuePoint["id"] = cp.id;
        cuePoint["position"] = cp.position;
        cuePoint["label"] = QString::fromStdString(cp.label);
        cuePoint["type"] = static_cast<int>(cp.type);
        
        if (cp.length > 0) {
             cuePoint["length"] = cp.length;
        }

        LOG_DEBUG() << "Cue Point" 
                 << ": ID=" << cp.id
                 << "Label=" << cuePoint["label"].toString()
                 << "Position=" << cp.position
                 << "Length=" << cp.length
                 << "Type=" << static_cast<int>(cp.type);

        cuePoints.append(cuePoint);
    }

    LOG_DEBUG() << "Finish: getCuePoints - count=" << cuePoints.size();
    return cuePoints;
}

QVariantList WavFileApi::getWaveData(WaveFile* waveFile)
{
    LOG_DEBUG() << "Start: getWaveData";
    QVariantList waveData;
    
    std::vector<double> samples = WavFileService::readWaveData(waveFile);
    std::vector<double> normalizedSamples = VectorUtils::normalizeFromTo(0.0, 1.0, samples);
    
    for (size_t i = 0; i < normalizedSamples.size(); ++i) {
        waveData.append(QPointF(i, normalizedSamples[i]));
    }
    
    LOG_DEBUG() << "Finish: getWaveData - size=" << waveData.size();
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
                                  const QString& normalizationMode,
                                  const QString& pitchInterpolationType,
                                  const QString& pitchSmoothing,
                                  int pitchSmoothingWindowSize,
                                  double pitchGaussianSmoothingSigma,
                                  int pitchSavitzkyGolaySmoothingPolynomialOrder,
                                  double pitchSplineSmoothingPenalty)
{
    LOG_DEBUG() << "Start: getPitch - algorithm=" << algorithm << ", frameShift=" << frameShift << ", sampleRate=" << sampleRate << ", minF0=" << minF0 << ", maxF0=" << maxF0 << ", voicingThreshold=" << voicingThreshold << ", outputFormat=" << outputFormat << ", normalizationMode=" << normalizationMode << ", interpolation=" << pitchInterpolationType << ", smoothing=" << pitchSmoothing << ", smoothingWindow=" << pitchSmoothingWindowSize << ", sigma=" << pitchGaussianSmoothingSigma << ", polyOrder=" << pitchSavitzkyGolaySmoothingPolynomialOrder << ", penalty=" << pitchSplineSmoothingPenalty;
    QVariantList pitchData;
    
    if (!waveFile) {
        LOG_WARNING() << "WaveFile is null";
        return pitchData;
    }
    
    // Get wave data
    std::vector<double> samples = WavFileService::readWaveData(waveFile);
    if (samples.empty()) {
        LOG_WARNING() << "No wave data found";
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
        LOG_WARNING() << "Unknown algorithm:" << algorithm;
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
        LOG_WARNING() << "Unknown output format:" << outputFormat;
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
    
    if (!pitch.empty()) {
        pitch = VectorUtils::interpolate(pitchInterpolationType.toStdString(), pitch, pitch.size());
    }
    
    // Apply smoothing
    if (!pitch.empty() && pitchSmoothing != "None") {
        std::string smoothType = pitchSmoothing.toStdString();
        // Default parameters for smoothing
        double param1 = static_cast<double>(pitchSmoothingWindowSize); // Window size
        double param2 = 0.0; // Sigma or poly order
        
        if (smoothType == "Gaussian") {
            param2 = pitchGaussianSmoothingSigma; // Sigma
        } else if (smoothType == "SavitzkyGolay") {
            param2 = static_cast<double>(pitchSavitzkyGolaySmoothingPolynomialOrder); // Polynomial order
        } else if (smoothType == "Spline") {
            param1 = pitchSplineSmoothingPenalty; // Penalty (rho)
        }
        
        pitch = VectorUtils::smooth(smoothType, pitch, param1, param2);
    }
    
    // Normalize pitch data using VectorUtils based on mode
    if (!pitch.empty()) {
        std::vector<double> normalizedPitch;
        
        if (normalizationMode == "max") {
            normalizedPitch = pitch;
        } else if (normalizationMode == "min_max") {
            normalizedPitch = VectorUtils::normalizeByMinMax(pitch);
        } else if (normalizationMode == "mean") {
            normalizedPitch = VectorUtils::normalizeByMean(pitch);
        } else if (normalizationMode == "mean_deviation") {
            normalizedPitch = VectorUtils::normalizeByMeanDeviation(pitch);
        } else {
            // Default to by max if unknown
            LOG_WARNING() << "Unknown normalization mode:" << normalizationMode << ", defaulting to max";
            normalizedPitch = pitch;
        }
        
        for (size_t i = 0; i < normalizedPitch.size(); ++i) {
            pitchData.append(QPointF(i, normalizedPitch[i]));
        }
    }
    
    LOG_DEBUG() << "Finish: getPitch - size=" << pitchData.size();
    return pitchData;
}

QVariantMap WavFileApi::getUMP(const QVariantList& pitch,
                               const QVariantList& cuePoints,
                               int pLength,
                               int nLength,
                               int tLength,
                               int waveDataSize,
                               const QString& pitchInterpolationType)
{
    LOG_DEBUG() << "Start: getUMP - pitch.size=" << pitch.size() << ", cuePoints.size=" << cuePoints.size() << ", pLength=" << pLength << ", nLength=" << nLength << ", tLength=" << tLength << ", waveDataSize=" << waveDataSize << ", interpolation=" << pitchInterpolationType;
    
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
    LOG_DEBUG() << "  Converted pitch vector size:" << pitchVec.size();

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
        cp.type = static_cast<CuePointType>(cpMap["type"].toInt());
        cuePointsVec.push_back(cp);
        
        LOG_DEBUG() << "  Cue point" << cp.id << ":" 
                 << "position=" << cp.position 
                 << "length=" << cp.length 
                 << "label=" << QString::fromStdString(cp.label);
    }

    // Call UMPService
    LOG_DEBUG() << "  Calling UMPService::getUMP...";
    std::vector<double> umpVec = UMPService::getUMP(pitchInterpolationType.toStdString(), pitchVec, cuePointsVec, pLength, nLength, tLength, waveDataSize);
    LOG_DEBUG() << "  UMP result size:" << umpVec.size();

    // Convert result back to QVariantList (as QPointF for graph)
    QVariantList umpData;
    for (size_t i = 0; i < umpVec.size(); ++i) {
        umpData.append(QPointF(i, umpVec[i]));
    }
    result["ump"] = umpData;
    LOG_DEBUG() << "  UMP data points created:" << umpData.size();

    // Create modified cue points
    QVariantList modifiedCuePoints;
    int position = 0;
    for (size_t i = 0; i < cuePointsVec.size(); ++i) {
        int length = nLength;
        if (cuePointsVec[i].type == CuePointType::PRE_NUCLEUS) {
            length = pLength;
        } else if (cuePointsVec[i].type == CuePointType::POST_NUCLEUS) {
            length = tLength;
        }
        
        QVariantMap cpMap;
        cpMap["id"] = cuePointsVec[i].id;
        cpMap["label"] = QString::fromStdString(cuePointsVec[i].label);
        cpMap["position"] = static_cast<uint>(position);
        cpMap["length"] = static_cast<uint>(length);
        modifiedCuePoints.append(cpMap);
        position += length;
        LOG_DEBUG() << "  Modified cue point" << cpMap["id"].toUInt() << ":" 
                 << "position=" << cpMap["position"].toUInt() 
                 << "length=" << cpMap["length"].toUInt();
    }
    result["cuePoints"] = modifiedCuePoints;

    LOG_DEBUG() << "Finish: getUMP - result.keys=" << result.keys();
    return result;
}

