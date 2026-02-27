#ifndef WAVFILEAPI_H
#define WAVFILEAPI_H

#include <QObject>
#include <QVariant>
#include "src/services/helpers/wavFile.h"

struct WaveFile;

class WavFileApi : public QObject
{
    Q_OBJECT
public:
    explicit WavFileApi(QObject *parent = nullptr);

public slots:
    Q_INVOKABLE WaveFile* openWavFile(const QString& filePath);
    Q_INVOKABLE QVariantList getCuePoints(WaveFile* waveFile);
    Q_INVOKABLE QVariantList getWaveData(WaveFile* waveFile,
                                          bool normalized = true);
    Q_INVOKABLE QVariantList getPitch(WaveFile* waveFile,
                                      const QString& algorithm,
                                      double frameShift,
                                      double sampleRate,
                                      double minF0,
                                      double maxF0,
                                      double voicingThreshold,
                                      const QString& outputFormat,
                                      const QString& normalizationMode,
                                      const QString& pitchInterpolationType,
                                      const QString& pitchSmoothing = "None",
                                      int pitchSmoothingWindowSize = 5,
                                      double pitchGaussianSmoothingSigma = 2.0,
                                      double pitchSplineSmoothingPenalty = 10.0,
                                      bool normalized = true);

    Q_INVOKABLE QVariantMap getUMP(const QVariantList& pitch,
                                   const QVariantList& cuePoints,
                                   int pLength,
                                   int nLength,
                                   int tLength,
                                   int waveDataSize,
                                   const QString& pitchInterpolationType,
                                   bool normalized = true);

    Q_INVOKABLE QVariantList getSpec(WaveFile* waveFile,
                                     int fftLength,
                                     int frameShift,
                                     double sampleRate,
                                     const QString& algorithm = "DIO",
                                     double minF0 = 71.0,
                                     double maxF0 = 800.0,
                                     double voicingThreshold = 0.9,
                                     bool f0Refinement = false,
                                     bool normalized = false);

    Q_INVOKABLE QVariantList getCepstr(WaveFile* waveFile,
                                       int fftLength,
                                       int frameShift,
                                       double sampleRate,
                                       int numOrder,
                                       const QString& algorithm = "DIO",
                                       double minF0 = 71.0,
                                       double maxF0 = 800.0,
                                       double voicingThreshold = 0.9,
                                       bool f0Refinement = false,
                                       bool normalized = false);

    Q_INVOKABLE QVariantList getSpecDP(const QVariantList& patternSpectrum,
                                       const QVariantList& signalSpectrum,
                                       const QVariantList& pitch,
                                       const int targetLength);

    Q_INVOKABLE QVariantList getDP(const QVariantList& patternAmplitude,
                                   const QVariantList& patternAmplitudeDerivative,
                                   const QVariantList& patternPitch,
                                   const QVariantList& patternCepstrum,
                                   const QVariantList& signalAmplitude,
                                   const QVariantList& signalAmplitudeDerivative,
                                   const QVariantList& signalPitch,
                                   const QVariantList& signalCepstrum,
                                   const QVariantList& pitchToTransform,
                                   const int targetLength);

    Q_INVOKABLE QVariantList getAmplitude(WaveFile* waveFile,
                                         int window,
                                         int shift,
                                         bool normalized = true);

    Q_INVOKABLE QVariantList getAmplitudeDerivative(WaveFile* waveFile,
                                                    int window,
                                                    int shift,
                                                    bool normalized = true);
};

#endif // WAVFILEAPI_H
