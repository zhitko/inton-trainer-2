#ifndef WAVFILEAPI_H
#define WAVFILEAPI_H

#include <QObject>
#include <QVariant>
#include "src/helpers/wavFile.h"

struct WaveFile;

class WavFileApi : public QObject
{
    Q_OBJECT
public:
    explicit WavFileApi(QObject *parent = nullptr);

public slots:
    Q_INVOKABLE WaveFile* openWavFile(const QString& filePath);
    Q_INVOKABLE QVariantList getCuePoints(WaveFile* waveFile);
};

#endif // WAVFILEAPI_H
