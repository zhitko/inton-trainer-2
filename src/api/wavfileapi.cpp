#include "wavfileapi.h"
#include "helpers/logger.h"
#include "helpers/settings.h"
#include "src/services/amplitudeservice.h"
#include "src/services/cdtwservice.h"
#include "src/services/dpservice.h"
#include "src/services/helpers/vectorutils.h"
#include "src/services/pitchservice.h"
#include "src/services/specservice.h"
#include "src/services/umpservice.h"
#include "src/services/wavfileservice.h"
#include <QDebug>
#include <QPointF>
#include <limits>

QVariantList WavFileApi::getSpecDP(const QVariantList& patternSpectrum,
    const QVariantList& signalSpectrum,
    const QVariantList& pitch,
    const int targetLength)
{
    LOG_DEBUG() << "Start: getSpecDP - pattern.size=" << patternSpectrum.size()
                << ", signal.size=" << signalSpectrum.size()
                << ", pitch.size=" << pitch.size();

    QVariantList pathDataList;

    if (patternSpectrum.isEmpty()) {
        LOG_WARNING() << "Pattern spectrum is empty";
        return pathDataList;
    }

    if (signalSpectrum.isEmpty()) {
        LOG_WARNING() << "Signal spectrum is empty";
        return pathDataList;
    }

    if (pitch.isEmpty()) {
        LOG_WARNING() << "Pitch data is empty";
        return pathDataList;
    }

    // Convert patternSpectrum QVariantList -> std::vector<std::vector<double>>
    std::vector<std::vector<double>> patternSpec;
    patternSpec.reserve(patternSpectrum.size());
    for (const auto& frameVar : patternSpectrum) {
        QVariantList frameQ = frameVar.toList();
        std::vector<double> frameVec;
        frameVec.reserve(frameQ.size());
        for (const auto& val : frameQ) {
            frameVec.push_back(val.toDouble());
        }
        patternSpec.push_back(frameVec);
    }

    // Convert signalSpectrum QVariantList -> std::vector<std::vector<double>>
    std::vector<std::vector<double>> signalSpec;
    signalSpec.reserve(signalSpectrum.size());
    for (const auto& frameVar : signalSpectrum) {
        QVariantList frameQ = frameVar.toList();
        std::vector<double> frameVec;
        frameVec.reserve(frameQ.size());
        for (const auto& val : frameQ) {
            frameVec.push_back(val.toDouble());
        }
        signalSpec.push_back(frameVec);
    }

    // Convert pitch QVariantList to std::vector<double>
    std::vector<double> pitchVec;
    pitchVec.reserve(pitch.size());
    for (const auto& val : pitch) {
        if (val.canConvert<QPointF>()) {
            pitchVec.push_back(val.toPointF().y());
        } else {
            pitchVec.push_back(val.toDouble());
        }
    }
    // Create DPService and compute signal path
    std::vector<std::vector<std::vector<double>>> patternData = { patternSpec };
    std::vector<std::vector<std::vector<double>>> signalData = { signalSpec };
    DPService dpService(patternData, signalData);
    dpService.compute();
    std::vector<double> pitchTransformed = dpService.applyPathToVector(
        pitchVec, targetLength); // Apply DP path to pitch vector

    for (size_t i = 0; i < pitchTransformed.size(); ++i) {
        pathDataList.append(QPointF(i, pitchTransformed[i]));
    }

    LOG_DEBUG() << "Finish: getSpecDP - path points=" << pathDataList.size();
    return pathDataList;
}

QVariantMap WavFileApi::getDP(const QVariantList& patternAmplitude,
    const QVariantList& patternAmplitudeDerivative,
    const QVariantList& patternPitch,
    const QVariantList& patternPitchLog,
    const QVariantList& patternPitchDerivative,
    const QVariantList& patternSpectrum,
    const QVariantList& patternCepstrum,
    const QVariantList& signalAmplitude,
    const QVariantList& signalAmplitudeDerivative,
    const QVariantList& signalPitch,
    const QVariantList& signalPitchLog,
    const QVariantList& signalPitchDerivative,
    const QVariantList& signalSpectrum,
    const QVariantList& signalCepstrum,
    const QVariantList& pitchToTransform,
    const QVariantList& cuePointsToTransform)
{
    LOG_DEBUG() << "Start: getDP - pattern data size=" << patternAmplitude.size();

    QVariantMap result;

    if (patternAmplitude.isEmpty() || signalAmplitude.isEmpty() || pitchToTransform.isEmpty()) {
        LOG_WARNING() << "Input data is empty in getDP";
        return result;
    }

    auto parse1D = [](const QVariantList& list) {
        std::vector<std::vector<double>> res;
        res.reserve(list.size());
        for (const auto& val : list) {
            if (val.canConvert<QPointF>())
                res.push_back({ val.toPointF().y() });
            else
                res.push_back({ val.toDouble() });
        }
        return res;
    };

    auto parse2D = [](const QVariantList& list) {
        std::vector<std::vector<double>> res;
        res.reserve(list.size());
        for (const auto& frameVar : list) {
            QVariantList frameQ = frameVar.toList();
            std::vector<double> frameVec;
            frameVec.reserve(frameQ.size());
            for (const auto& val : frameQ) {
                frameVec.push_back(val.toDouble());
            }
            res.push_back(frameVec);
        }
        return res;
    };

    AppSettings settings = Settings::loadSettings();
    std::vector<std::vector<std::vector<double>>> patternData;
    std::vector<std::vector<std::vector<double>>> signalData;
    std::vector<double> weights;

    if (settings.dpUsePitch && !patternPitch.isEmpty()) {
        patternData.push_back(parse1D(patternPitch));
        signalData.push_back(parse1D(signalPitch));
        weights.push_back(settings.dpPitchCoef);
    }
    if (settings.dpUsePitchLog && !patternPitchLog.isEmpty()) {
        patternData.push_back(parse1D(patternPitchLog));
        signalData.push_back(parse1D(signalPitchLog));
        weights.push_back(settings.dpPitchLogCoef);
    }
    if (settings.dpUsePitchDerivative && !patternPitchDerivative.isEmpty()) {
        patternData.push_back(parse1D(patternPitchDerivative));
        signalData.push_back(parse1D(signalPitchDerivative));
        weights.push_back(settings.dpPitchDerivativeCoef);
    }
    if (settings.dpUseSpectrum && !patternSpectrum.isEmpty()) {
        patternData.push_back(parse2D(patternSpectrum));
        signalData.push_back(parse2D(signalSpectrum));
        weights.push_back(settings.dpSpectrumCoef);
    }
    if (settings.dpUseCepstrum && !patternCepstrum.isEmpty()) {
        patternData.push_back(parse2D(patternCepstrum));
        signalData.push_back(parse2D(signalCepstrum));
        weights.push_back(settings.dpCepstrumCoef);
    }
    if (settings.dpUseAmplitude && !patternAmplitude.isEmpty()) {
        patternData.push_back(parse1D(patternAmplitude));
        signalData.push_back(parse1D(signalAmplitude));
        weights.push_back(settings.dpAmplitudeCoef);
    }
    if (settings.dpUseAmplitudeDerivative && !patternAmplitudeDerivative.isEmpty()) {
        patternData.push_back(parse1D(patternAmplitudeDerivative));
        signalData.push_back(parse1D(signalAmplitudeDerivative));
        weights.push_back(settings.dpAmplitudeDerivativeCoef);
    }

    std::vector<double> pitchVec;
    pitchVec.reserve(pitchToTransform.size());
    for (const auto& val : pitchToTransform) {
        if (val.canConvert<QPointF>()) {
            pitchVec.push_back(val.toPointF().y());
        } else {
            pitchVec.push_back(val.toDouble());
        }
    }

    std::vector<CuePointData> cuePointsVec;
    cuePointsVec.reserve(cuePointsToTransform.size());
    for (const auto& val : cuePointsToTransform) {
        QVariantMap cpMap = val.toMap();
        CuePointData cp;
        cp.id = cpMap["id"].toUInt();
        cp.position = cpMap["position"].toUInt();
        cp.length = cpMap["length"].toUInt();
        cp.label = cpMap["label"].toString().toStdString();
        cp.type = static_cast<CuePointType>(cpMap["type"].toInt());
        cuePointsVec.push_back(cp);
    }

    CDTWService cdtwService(patternData, signalData, weights,
        settings.dpMatchCoef, settings.dpInsertionCoef, settings.dpDeletionCoef);
    cdtwService.compute();

    std::vector<double> pitchTransformed = cdtwService.applyPathToVector(pitchVec, patternPitch.size());
    std::vector<CuePointData> cuePointsTransformed = cdtwService.applyPathToCuePoints(cuePointsVec);

    QVariantList pathDataList;
    for (size_t i = 0; i < pitchTransformed.size(); ++i) {
        pathDataList.append(QPointF(i, pitchTransformed[i]));
    }
    result["pitch"] = pathDataList;

    QVariantList modifiedCuePoints;
    for (const auto& cp : cuePointsTransformed) {
        QVariantMap cpMap;
        cpMap["id"] = cp.id;
        cpMap["label"] = QString::fromStdString(cp.label);
        cpMap["position"] = cp.position;
        cpMap["length"] = cp.length;
        modifiedCuePoints.append(cpMap);
    }
    result["cuePoints"] = modifiedCuePoints;

    result["minFinalCost"] = cdtwService.getMinFinalCost();

    QVariantList streamDistancesList;
    const std::vector<double> streamDistances = cdtwService.getSignalStreamDistances();
    streamDistancesList.reserve(static_cast<int>(streamDistances.size()));
    for (size_t i = 0; i < streamDistances.size(); ++i) {
        streamDistancesList.append(QPointF(i, streamDistances[i]));
    }
    result["signalStreamDistances"] = streamDistancesList;

    LOG_DEBUG() << "Finish: getDP - pitch size=" << pathDataList.size()
                << ", cuePoints size=" << modifiedCuePoints.size()
                << ", minFinalCost=" << cdtwService.getMinFinalCost()
                << ", signalStreamDistances size=" << streamDistancesList.size();
    return result;
}

WavFileApi::WavFileApi(QObject* parent)
    : QObject(parent)
{
}

QVariantList WavFileApi::getPitchDerivative(
    WaveFile* waveFile, const QString& algorithm, double frameShift,
    double sampleRate, double minF0, double maxF0,
    double voicingThreshold, const QString& outputFormat,
    bool normalized)
{
    LOG_DEBUG() << "Start: getPitchDerivative - algorithm=" << algorithm
                << ", frameShift=" << frameShift << ", sampleRate=" << sampleRate
                << ", minF0=" << minF0 << ", maxF0=" << maxF0
                << ", voicingThreshold=" << voicingThreshold
                << ", outputFormat=" << outputFormat
                << ", normalized=" << normalized;

    QVariantList result;

    if (!waveFile) {
        LOG_WARNING() << "WaveFile is null";
        return result;
    }

    std::vector<double> samples = WavFileService::readWaveData(waveFile);
    if (samples.empty()) {
        LOG_WARNING() << "No wave data found";
        return result;
    }

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
    } else {
        LOG_WARNING() << "Unknown algorithm:" << algorithm;
        return result;
    }

    PitchOutputFormat format;
    if (outputFormat == "PITCH") {
        format = PitchOutputFormat::PITCH;
    } else if (outputFormat == "F0") {
        format = PitchOutputFormat::F0;
    } else if (outputFormat == "LOG_F0") {
        format = PitchOutputFormat::LOG_F0;
    } else {
        LOG_WARNING() << "Unknown output format:" << outputFormat;
        return result;
    }

    PitchService pitchService;
    std::vector<double> derivative = pitchService.getPitchDerivative(
        samples, algo, frameShift, sampleRate, minF0, maxF0,
        voicingThreshold, format);

    if (normalized && !derivative.empty()) {
        derivative = VectorUtils::normalizeFromTo(0.0, 1.0, derivative);
    }

    for (size_t i = 0; i < derivative.size(); ++i) {
        result.append(QPointF(i, derivative[i]));
    }

    LOG_DEBUG() << "Finish: getPitchDerivative - size=" << result.size();
    return result;
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

        LOG_DEBUG() << "Cue Point" << ": ID=" << cp.id
                    << "Label=" << cuePoint["label"].toString()
                    << "Position=" << cp.position << "Length=" << cp.length
                    << "Type=" << static_cast<int>(cp.type);

        cuePoints.append(cuePoint);
    }

    LOG_DEBUG() << "Finish: getCuePoints - count=" << cuePoints.size();
    return cuePoints;
}

QVariantList WavFileApi::getWaveData(WaveFile* waveFile, bool normalized)
{
    LOG_DEBUG() << "Start: getWaveData - normalized=" << normalized;
    QVariantList waveData;

    std::vector<double> samples = WavFileService::readWaveData(waveFile);
    std::vector<double> outSamples = normalized ? VectorUtils::normalizeFromTo(0.0, 1.0, samples) : samples;

    for (size_t i = 0; i < outSamples.size(); ++i) {
        waveData.append(QPointF(i, outSamples[i]));
    }

    LOG_DEBUG() << "Finish: getWaveData - size=" << waveData.size();
    return waveData;
}

QVariantList WavFileApi::getAmplitude(WaveFile* waveFile, int window, int shift,
    const QString& amplitudeSmoothing,
    int amplitudeSmoothingWindowSize,
    double amplitudeGaussianSmoothingSigma,
    bool normalized)
{
    LOG_DEBUG() << "Start: getAmplitude - window=" << window
                << ", shift=" << shift << ", smoothing=" << amplitudeSmoothing
                << ", smoothingWindow=" << amplitudeSmoothingWindowSize
                << ", sigma=" << amplitudeGaussianSmoothingSigma
                << ", normalized=" << normalized;
    QVariantList result;

    if (!waveFile) {
        LOG_WARNING() << "getAmplitude called with null WaveFile";
        return result;
    }

    std::vector<double> samples = WavFileService::readWaveData(waveFile);
    if (samples.empty()) {
        LOG_WARNING() << "getAmplitude - no wave data";
        return result;
    }

    AmplitudeService ampService;
    std::vector<double> amps = ampService.getAmplitude(samples, window, shift);

    // Apply smoothing
    if (!amps.empty() && amplitudeSmoothing != "None") {
        std::string smoothType = amplitudeSmoothing.toStdString();
        double param1 = static_cast<double>(amplitudeSmoothingWindowSize);
        double param2 = 0.0;

        if (smoothType == "Gaussian") {
            param2 = amplitudeGaussianSmoothingSigma;
        }

        amps = VectorUtils::smooth(smoothType, amps, param1, param2);
    }

    if (normalized) {
        amps = VectorUtils::normalizeFromTo(0.0, 1.0, amps);
    }
    for (size_t i = 0; i < amps.size(); ++i) {
        result.append(QPointF(i, amps[i]));
    }

    LOG_DEBUG() << "Finish: getAmplitude - size=" << result.size();
    return result;
}

QVariantList WavFileApi::getAmplitudeDerivative(
    WaveFile* waveFile, int window, int shift,
    const QString& amplitudeSmoothing, int amplitudeSmoothingWindowSize,
    double amplitudeGaussianSmoothingSigma, bool normalized)
{
    LOG_DEBUG() << "Start: getAmplitudeDerivative - window=" << window
                << ", shift=" << shift << ", smoothing=" << amplitudeSmoothing
                << ", smoothingWindow=" << amplitudeSmoothingWindowSize
                << ", sigma=" << amplitudeGaussianSmoothingSigma
                << ", normalized=" << normalized;
    QVariantList result;

    if (!waveFile) {
        LOG_WARNING() << "getAmplitudeDerivative called with null WaveFile";
        return result;
    }

    std::vector<double> samples = WavFileService::readWaveData(waveFile);
    if (samples.empty()) {
        LOG_WARNING() << "getAmplitudeDerivative - no wave data";
        return result;
    }

    AmplitudeService ampService;
    std::vector<double> deriv = ampService.getAmplitudeDerivative(samples, window, shift);

    // Apply smoothing
    if (!deriv.empty() && amplitudeSmoothing != "None") {
        std::string smoothType = amplitudeSmoothing.toStdString();
        double param1 = static_cast<double>(amplitudeSmoothingWindowSize);
        double param2 = 0.0;

        if (smoothType == "Gaussian") {
            param2 = amplitudeGaussianSmoothingSigma;
        }

        deriv = VectorUtils::smooth(smoothType, deriv, param1, param2);
    }

    if (normalized) {
        deriv = VectorUtils::normalizeFromTo(0.0, 1.0, deriv);
    }
    for (size_t i = 0; i < deriv.size(); ++i) {
        result.append(QPointF(i, deriv[i]));
    }

    LOG_DEBUG() << "Finish: getAmplitudeDerivative - size=" << result.size();
    return result;
}

QVariantList WavFileApi::getPitch(
    WaveFile* waveFile, const QString& algorithm, double frameShift,
    double sampleRate, double minF0, double maxF0, double voicingThreshold,
    const QString& outputFormat, const QString& normalizationMode,
    const QString& pitchInterpolationType, const QString& pitchSmoothing,
    int pitchSmoothingWindowSize, double pitchGaussianSmoothingSigma,
    double pitchSplineSmoothingPenalty, bool normalized, bool useOnlyN)
{
    LOG_DEBUG() << "Start: getPitch - algorithm=" << algorithm
                << ", frameShift=" << frameShift << ", sampleRate=" << sampleRate
                << ", minF0=" << minF0 << ", maxF0=" << maxF0
                << ", voicingThreshold=" << voicingThreshold
                << ", outputFormat=" << outputFormat
                << ", normalizationMode=" << normalizationMode
                << ", interpolation=" << pitchInterpolationType
                << ", smoothing=" << pitchSmoothing
                << ", smoothingWindow=" << pitchSmoothingWindowSize
                << ", sigma=" << pitchGaussianSmoothingSigma
                << ", penalty=" << pitchSplineSmoothingPenalty
                << ", normalized=" << normalized
                << ", useOnlyN=" << useOnlyN;
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
    std::vector<double> pitch = pitchService.getPitch(samples, algo, frameShift, sampleRate, minF0, maxF0,
        voicingThreshold, format);

    if (!pitch.empty()) {
        pitch = VectorUtils::interpolate(pitchInterpolationType.toStdString(),
            pitch, pitch.size());
    }

    // Keep only NUCLEUS frames based on cue points (before smoothing)
    if (useOnlyN) {
        std::vector<CuePointData> allCuePoints = WavFileService::readCuePoints(waveFile);
        std::vector<CuePointData> nucleusCuePoints;
        for (const CuePointData& cp : allCuePoints) {
            if (cp.type == CuePointType::NUCLEUS) {
                nucleusCuePoints.push_back(cp);
            }
        }
        if (!nucleusCuePoints.empty()) {
            pitch = pitchService.keepCuePointSectors(pitch, nucleusCuePoints, frameShift, sampleRate);
        }
    }

    // Apply smoothing
    if (!pitch.empty() && pitchSmoothing != "None") {
        std::string smoothType = pitchSmoothing.toStdString();
        // Default parameters for smoothing
        double param1 = static_cast<double>(pitchSmoothingWindowSize); // Window size
        double param2 = 0.0; // Sigma or poly order

        if (smoothType == "Gaussian") {
            param2 = pitchGaussianSmoothingSigma; // Sigma
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
            LOG_WARNING() << "Unknown normalization mode:" << normalizationMode
                          << ", defaulting to max";
            normalizedPitch = pitch;
        }

        if (normalized) {
            normalizedPitch = VectorUtils::normalizeFromTo(0.0, 1.0, normalizedPitch);
        }

        for (size_t i = 0; i < normalizedPitch.size(); ++i) {
            pitchData.append(QPointF(i, normalizedPitch[i]));
        }
    }

    LOG_DEBUG() << "Finish: getPitch - size=" << pitchData.size();
    return pitchData;
}

QVariantMap WavFileApi::getUMP(const QVariantList& pitch,
    const QVariantList& cuePoints, int pLength,
    int nLength, int tLength, int waveDataSize,
    const QString& pitchInterpolationType,
    const QString& umpSmoothing,
    int umpSmoothingWindowSize,
    double umpGaussianSmoothingSigma,
    double umpSplineSmoothingPenalty,
    bool normalized)
{
    LOG_DEBUG() << "Start: getUMP - pitch.size=" << pitch.size()
                << ", cuePoints.size=" << cuePoints.size()
                << ", pLength=" << pLength << ", nLength=" << nLength
                << ", tLength=" << tLength << ", waveDataSize=" << waveDataSize
                << ", interpolation=" << pitchInterpolationType
                << ", umpSmoothing=" << umpSmoothing
                << ", normalized=" << normalized;

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

        LOG_DEBUG() << "  Cue point" << cp.id << ":" << "position=" << cp.position
                    << "length=" << cp.length
                    << "label=" << QString::fromStdString(cp.label);
    }

    // Call UMPService
    LOG_DEBUG() << "  Calling UMPService::getUMP...";
    UMPResult umpResult = UMPService::getUMP(pitchInterpolationType.toStdString(), pitchVec,
        cuePointsVec, pLength, nLength, tLength, waveDataSize,
        umpSmoothing.toStdString(), umpSmoothingWindowSize,
        umpGaussianSmoothingSigma, umpSplineSmoothingPenalty);
    LOG_DEBUG() << "  UMP result size:" << umpResult.ump.size();

    // Convert result back to QVariantList (as QPointF for graph)
    std::vector<double> umpVec = umpResult.ump;
    if (normalized) {
        umpVec = VectorUtils::normalizeFromTo(0.0, 1.0, umpVec);
    }
    QVariantList umpData;
    for (size_t i = 0; i < umpVec.size(); ++i) {
        umpData.append(QPointF(i, umpVec[i]));
    }
    result["ump"] = umpData;
    LOG_DEBUG() << "  UMP data points created:" << umpData.size();

    // Create modified cue points from processedCuePoints returned by UMPService
    QVariantList modifiedCuePoints;
    QVariantList scaledCuePoints;
    int position = 0;
    for (size_t i = 0; i < umpResult.processedCuePoints.size(); ++i) {
        const CuePointData& cp = umpResult.processedCuePoints[i];
        int length = nLength;
        if (cp.type == CuePointType::PRE_NUCLEUS) {
            length = pLength;
        } else if (cp.type == CuePointType::POST_NUCLEUS) {
            length = tLength;
        }

        QVariantMap cpMap;
        cpMap["id"] = cp.id;
        cpMap["label"] = QString::fromStdString(cp.label);
        cpMap["position"] = static_cast<uint>(position);
        cpMap["length"] = static_cast<uint>(length);
        modifiedCuePoints.append(cpMap);
        position += length;
        LOG_DEBUG() << "  Modified cue point" << cpMap["id"].toUInt() << ":"
                    << "position=" << cpMap["position"].toUInt()
                    << "length=" << cpMap["length"].toUInt();

        // Also create scaled cue points for the original wave data
        QVariantMap scaledCpMap;
        scaledCpMap["id"] = cp.id;
        scaledCpMap["label"] = QString::fromStdString(cp.label);
        scaledCpMap["position"] = cp.position;
        scaledCpMap["length"] = cp.length;
        scaledCuePoints.append(scaledCpMap);
        LOG_DEBUG() << "  Scaled cue point" << scaledCpMap["id"].toUInt() << ":"
                    << "position=" << scaledCpMap["position"].toUInt()
                    << "length=" << scaledCpMap["length"].toUInt();
    }
    result["cuePoints"] = modifiedCuePoints;

    result["waveCuePoints"] = scaledCuePoints;

    LOG_DEBUG() << "Finish: getUMP - result.keys=" << result.keys();
    return result;
}

QVariantList WavFileApi::getSpec(WaveFile* waveFile, int fftLength,
    int frameShift, double sampleRate,
    const QString& algorithm, double minF0,
    double maxF0, double voicingThreshold,
    bool f0Refinement, bool normalized)
{
    LOG_DEBUG() << "Start: getSpec - fftLength=" << fftLength
                << ", frameShift=" << frameShift << ", sampleRate=" << sampleRate
                << ", algorithm=" << algorithm << ", minF0=" << minF0
                << ", maxF0=" << maxF0
                << ", voicingThreshold=" << voicingThreshold
                << ", f0Refinement=" << f0Refinement
                << ", normalized=" << normalized;

    QVariantList specData;

    if (!waveFile) {
        LOG_WARNING() << "WaveFile is null";
        return specData;
    }

    // Get wave data
    std::vector<double> samples = WavFileService::readWaveData(waveFile);
    if (samples.empty()) {
        LOG_WARNING() << "No wave data found";
        return specData;
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
    } else {
        LOG_WARNING() << "Unknown algorithm:" << algorithm << ", defaulting to DIO";
        algo = PitchAlgorithm::DIO;
    }

    // Extract F0 using PitchService
    PitchService pitchService;
    std::vector<double> f0Vec = pitchService.getPitch(
        samples, algo, static_cast<double>(frameShift), sampleRate, minF0, maxF0,
        voicingThreshold,
        PitchOutputFormat::F0 // We need F0 in Hz for spectrum extraction
    );

    if (f0Vec.empty()) {
        LOG_WARNING() << "F0 extraction failed";
        return specData;
    }

    LOG_DEBUG() << "Extracted F0 vector size:" << f0Vec.size();

    // Create SpecService and extract spectrum
    SpecService specService;
    std::vector<std::vector<double>> spectrum = specService.getSpec(
        samples, f0Vec, fftLength, frameShift, sampleRate, f0Refinement);

    if (spectrum.empty()) {
        LOG_WARNING() << "Spectrum extraction returned empty result";
        return specData;
    }

    std::vector<std::vector<double>> outSpec = spectrum;
    if (normalized) {
        outSpec = VectorUtils::normalizeFromTo2D(0.0, 1.0, spectrum);
    }

    // Convert 2D spectrum vector to QVariantList
    // Each frame becomes a QVariantList of spectral values
    for (size_t frameIdx = 0; frameIdx < outSpec.size(); ++frameIdx) {
        const std::vector<double>& frame = outSpec[frameIdx];
        QVariantList specFrame;
        for (size_t binIdx = 0; binIdx < frame.size(); ++binIdx) {
            specFrame.append(frame[binIdx]);
        }
        specData.append(QVariant::fromValue(specFrame));
    }

    LOG_DEBUG() << "Finish: getSpec - frames=" << specData.size();
    if (!outSpec.empty()) {
        LOG_DEBUG() << "First frame bins=" << outSpec[0].size();
    }

    return specData;
}

QVariantList WavFileApi::getCepstr(WaveFile* waveFile, int fftLength,
    int frameShift, double sampleRate,
    int numOrder, const QString& algorithm,
    double minF0, double maxF0,
    double voicingThreshold, bool f0Refinement,
    bool normalized)
{
    LOG_DEBUG() << "Start: getCepstr - fftLength=" << fftLength
                << ", frameShift=" << frameShift << ", sampleRate=" << sampleRate
                << ", numOrder=" << numOrder << ", algorithm=" << algorithm
                << ", minF0=" << minF0 << ", maxF0=" << maxF0
                << ", voicingThreshold=" << voicingThreshold
                << ", f0Refinement=" << f0Refinement
                << ", normalized=" << normalized;

    QVariantList cepstrData;

    if (!waveFile) {
        LOG_WARNING() << "WaveFile is null";
        return cepstrData;
    }

    // Get wave data
    std::vector<double> samples = WavFileService::readWaveData(waveFile);
    if (samples.empty()) {
        LOG_WARNING() << "No wave data found";
        return cepstrData;
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
    } else {
        LOG_WARNING() << "Unknown algorithm:" << algorithm << ", defaulting to DIO";
        algo = PitchAlgorithm::DIO;
    }

    // Extract F0 using PitchService
    PitchService pitchService;
    std::vector<double> f0Vec = pitchService.getPitch(
        samples, algo, static_cast<double>(frameShift), sampleRate, minF0, maxF0,
        voicingThreshold,
        PitchOutputFormat::F0 // We need F0 in Hz for spectrum/cepstrum extraction
    );

    if (f0Vec.empty()) {
        LOG_WARNING() << "F0 extraction failed";
        return cepstrData;
    }

    LOG_DEBUG() << "Extracted F0 vector size:" << f0Vec.size();

    // Create SpecService and extract cepstrum
    SpecService specService;
    std::vector<std::vector<double>> cepstrum = specService.getCepstr(samples, f0Vec, fftLength, frameShift, sampleRate,
        numOrder, f0Refinement);

    if (cepstrum.empty()) {
        LOG_WARNING() << "Cepstrum extraction returned empty result";
        return cepstrData;
    }

    std::vector<std::vector<double>> outCepstrum = cepstrum;
    if (normalized) {
        outCepstrum = VectorUtils::normalizeFromTo2D(0.0, 1.0, cepstrum);
    }

    for (size_t frameIdx = 0; frameIdx < outCepstrum.size(); ++frameIdx) {
        const std::vector<double>& frame = outCepstrum[frameIdx];
        QVariantList frameData;
        for (size_t coeffIdx = 0; coeffIdx < frame.size(); ++coeffIdx) {
            frameData.append(frame[coeffIdx]);
        }
        cepstrData.append(QVariant::fromValue(frameData));
    }

    LOG_DEBUG() << "Finish: getCepstr - frames=" << cepstrData.size();
    if (!cepstrum.empty()) {
        LOG_DEBUG() << "First frame coefficients=" << cepstrum[0].size();
    }

    return cepstrData;
}
