#ifndef SETTINGSAPI_H
#define SETTINGSAPI_H

#include <QObject>
#include "src/api/helpers/settings.h"
#include <QTranslator>

class SettingsApi : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString algorithm READ algorithm WRITE setAlgorithm NOTIFY algorithmChanged)
    Q_PROPERTY(double frameShift READ frameShift WRITE setFrameShift NOTIFY frameShiftChanged)
    Q_PROPERTY(double sampleRate READ sampleRate WRITE setSampleRate NOTIFY sampleRateChanged)
    Q_PROPERTY(double minF0 READ minF0 WRITE setMinF0 NOTIFY minF0Changed)
    Q_PROPERTY(double maxF0 READ maxF0 WRITE setMaxF0 NOTIFY maxF0Changed)
    Q_PROPERTY(double voicingThreshold READ voicingThreshold WRITE setVoicingThreshold NOTIFY voicingThresholdChanged)
    Q_PROPERTY(QString pitchNormalization READ pitchNormalization WRITE setPitchNormalization NOTIFY pitchNormalizationChanged)
    Q_PROPERTY(PitchInterpolationType pitchInterpolationType READ pitchInterpolationType WRITE setPitchInterpolationType NOTIFY pitchInterpolationTypeChanged)
    Q_PROPERTY(PitchSmoothingType pitchSmoothing READ pitchSmoothing WRITE setPitchSmoothing NOTIFY pitchSmoothingChanged)
    Q_PROPERTY(int pitchSmoothingWindowSize READ pitchSmoothingWindowSize WRITE setPitchSmoothingWindowSize NOTIFY pitchSmoothingWindowSizeChanged)
    Q_PROPERTY(double pitchGaussianSmoothingSigma READ pitchGaussianSmoothingSigma WRITE setPitchGaussianSmoothingSigma NOTIFY pitchGaussianSmoothingSigmaChanged)

    Q_PROPERTY(double pitchSplineSmoothingPenalty READ pitchSplineSmoothingPenalty WRITE setPitchSplineSmoothingPenalty NOTIFY pitchSplineSmoothingPenaltyChanged)

public:
    enum class PitchInterpolationType {
        None,
        Linear,
        Cubic,
        Akima,
        Monotone
    };
    Q_ENUM(PitchInterpolationType)
    
    enum class PitchSmoothingType {
        None,
        MovingAverage,
        Median,
        Gaussian,
        Spline
    };
    Q_ENUM(PitchSmoothingType)
    explicit SettingsApi(QObject *parent = nullptr);

    QString language() const;
    void setLanguage(const QString &language);

    QString theme() const;
    void setTheme(const QString &theme);

    QString algorithm() const;
    void setAlgorithm(const QString &algorithm);

    double frameShift() const;
    void setFrameShift(double frameShift);

    double sampleRate() const;
    void setSampleRate(double sampleRate);

    double minF0() const;
    void setMinF0(double minF0);

    double maxF0() const;
    void setMaxF0(double maxF0);

    double voicingThreshold() const;
    void setVoicingThreshold(double voicingThreshold);

    QString pitchNormalization() const;
    void setPitchNormalization(const QString &pitchNormalization);

    PitchInterpolationType pitchInterpolationType() const;
    void setPitchInterpolationType(PitchInterpolationType pitchInterpolationType);

    PitchSmoothingType pitchSmoothing() const;
    void setPitchSmoothing(PitchSmoothingType pitchSmoothing);

    int pitchSmoothingWindowSize() const;
    void setPitchSmoothingWindowSize(int pitchSmoothingWindowSize);

    double pitchGaussianSmoothingSigma() const;
    void setPitchGaussianSmoothingSigma(double pitchGaussianSmoothingSigma);



    double pitchSplineSmoothingPenalty() const;
    void setPitchSplineSmoothingPenalty(double pitchSplineSmoothingPenalty);

    Q_INVOKABLE void load();
    Q_INVOKABLE void save();

signals:
    void languageChanged();
    void themeChanged();
    void algorithmChanged();
    void frameShiftChanged();
    void sampleRateChanged();
    void minF0Changed();
    void maxF0Changed();
    void voicingThresholdChanged();
    void pitchNormalizationChanged();
    void pitchInterpolationTypeChanged();
    void pitchSmoothingChanged();
    void pitchSmoothingWindowSizeChanged();
    void pitchGaussianSmoothingSigmaChanged();

    void pitchSplineSmoothingPenaltyChanged();

private:
    AppSettings m_settings;
    QTranslator m_translator;

    void updateTranslator();
};

#endif // SETTINGSAPI_H
