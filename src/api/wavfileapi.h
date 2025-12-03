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
    Q_INVOKABLE QVariantList getWaveData(WaveFile* waveFile);
    Q_INVOKABLE QVariantList getPitch(WaveFile* waveFile,
                                      const QString& algorithm,
                                      double frameShift,
                                      double sampleRate,
                                      double minF0,
                                      double maxF0,
                                      double voicingThreshold,
                                      const QString& outputFormat,
                                      const QString& normalizationMode);

    Q_INVOKABLE QVariantMap getUMP(const QVariantList& pitch,
                                   const QVariantList& cuePoints,
                                   int pLength,
                                   int nLength,
                                   int tLength,
                                   int waveDataSize);
};

#endif // WAVFILEAPI_H
