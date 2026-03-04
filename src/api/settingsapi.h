#ifndef SETTINGSAPI_H
#define SETTINGSAPI_H

#include "src/api/helpers/settings.h"
#include <QObject>
#include <QTranslator>

/**
 * SettingsApi class provides methods for managing application settings such as
 * language, theme, pitch extraction parameters, spectrum analysis parameters,
 * and amplitude analysis parameters. It allows for loading and saving settings to
 * a file, as well as emitting signals when settings are changed to update the UI
 * accordingly. The class also handles the translation of the application based on
 * the selected language.
 */
class SettingsApi : public QObject {
    Q_OBJECT
    Q_PROPERTY(
        QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString algorithm READ algorithm WRITE setAlgorithm NOTIFY
            algorithmChanged)
    Q_PROPERTY(double frameShift READ frameShift WRITE setFrameShift NOTIFY
            frameShiftChanged)
    Q_PROPERTY(double sampleRate READ sampleRate WRITE setSampleRate NOTIFY
            sampleRateChanged)
    Q_PROPERTY(double minF0 READ minF0 WRITE setMinF0 NOTIFY minF0Changed)
    Q_PROPERTY(double maxF0 READ maxF0 WRITE setMaxF0 NOTIFY maxF0Changed)
    Q_PROPERTY(double voicingThreshold READ voicingThreshold WRITE
            setVoicingThreshold NOTIFY voicingThresholdChanged)
    Q_PROPERTY(QString pitchNormalization READ pitchNormalization WRITE
            setPitchNormalization NOTIFY pitchNormalizationChanged)
    Q_PROPERTY(
        PitchInterpolationType pitchInterpolationType READ pitchInterpolationType
            WRITE setPitchInterpolationType NOTIFY pitchInterpolationTypeChanged)
    Q_PROPERTY(PitchSmoothingType pitchSmoothing READ pitchSmoothing WRITE
            setPitchSmoothing NOTIFY pitchSmoothingChanged)
    Q_PROPERTY(
        int pitchSmoothingWindowSize READ pitchSmoothingWindowSize WRITE
            setPitchSmoothingWindowSize NOTIFY pitchSmoothingWindowSizeChanged)
    Q_PROPERTY(double pitchGaussianSmoothingSigma READ pitchGaussianSmoothingSigma
            WRITE setPitchGaussianSmoothingSigma NOTIFY
                pitchGaussianSmoothingSigmaChanged)

    Q_PROPERTY(double pitchSplineSmoothingPenalty READ pitchSplineSmoothingPenalty
            WRITE setPitchSplineSmoothingPenalty NOTIFY
                pitchSplineSmoothingPenaltyChanged)

    Q_PROPERTY(int specFftLength READ specFftLength WRITE setSpecFftLength NOTIFY
            specFftLengthChanged)
    Q_PROPERTY(bool specF0Refinement READ specF0Refinement WRITE
            setSpecF0Refinement NOTIFY specF0RefinementChanged)
    Q_PROPERTY(bool specUseLogScale READ specUseLogScale WRITE setSpecUseLogScale
            NOTIFY specUseLogScaleChanged)
    Q_PROPERTY(SpecColorScheme specColorScheme READ specColorScheme WRITE
            setSpecColorScheme NOTIFY specColorSchemeChanged)
    Q_PROPERTY(bool showSpectrum READ showSpectrum WRITE setShowSpectrum NOTIFY
            showSpectrumChanged)
    Q_PROPERTY(bool showCepstrum READ showCepstrum WRITE setShowCepstrum NOTIFY
            showCepstrumChanged)

    Q_PROPERTY(int amplitudeWindow READ amplitudeWindow WRITE setAmplitudeWindow
            NOTIFY amplitudeWindowChanged)
    Q_PROPERTY(int amplitudeShift READ amplitudeShift WRITE setAmplitudeShift
            NOTIFY amplitudeShiftChanged)
    Q_PROPERTY(AmplitudeSmoothingType amplitudeSmoothing READ amplitudeSmoothing
            WRITE setAmplitudeSmoothing NOTIFY amplitudeSmoothingChanged)
    Q_PROPERTY(int amplitudeSmoothingWindowSize READ amplitudeSmoothingWindowSize
            WRITE setAmplitudeSmoothingWindowSize NOTIFY
                amplitudeSmoothingWindowSizeChanged)
    Q_PROPERTY(double amplitudeGaussianSmoothingSigma READ
            amplitudeGaussianSmoothingSigma WRITE
                setAmplitudeGaussianSmoothingSigma NOTIFY
                    amplitudeGaussianSmoothingSigmaChanged)
    Q_PROPERTY(bool showAmplitude READ showAmplitude WRITE setShowAmplitude NOTIFY
            showAmplitudeChanged)
    Q_PROPERTY(
        bool showAmplitudeDerivative READ showAmplitudeDerivative WRITE
            setShowAmplitudeDerivative NOTIFY showAmplitudeDerivativeChanged)
    Q_PROPERTY(bool showF0 READ showF0 WRITE setShowF0 NOTIFY showF0Changed)
    Q_PROPERTY(bool showLogPitch READ showLogPitch WRITE setShowLogPitch NOTIFY
            showLogPitchChanged)
    Q_PROPERTY(bool showProcessedPitch READ showProcessedPitch WRITE
            setShowProcessedPitch NOTIFY showProcessedPitchChanged)

    Q_PROPERTY(int cepstrNumOrder READ cepstrNumOrder WRITE setCepstrNumOrder
            NOTIFY cepstrNumOrderChanged)

public:
    enum class SpecColorScheme { Viridis,
        Plasma,
        Hot,
        Cool };
    Q_ENUM(SpecColorScheme)

    enum class PitchInterpolationType { None,
        Linear,
        Cubic,
        Akima,
        Monotone };
    Q_ENUM(PitchInterpolationType)

    enum class PitchSmoothingType {
        None,
        MovingAverage,
        Median,
        Gaussian,
        Spline
    };
    Q_ENUM(PitchSmoothingType)

    enum class AmplitudeSmoothingType { None,
        MovingAverage,
        Median,
        Gaussian };
    Q_ENUM(AmplitudeSmoothingType)
    explicit SettingsApi(QObject* parent = nullptr);

    QString language() const;
    void setLanguage(const QString& language);

    QString theme() const;
    void setTheme(const QString& theme);

    QString algorithm() const;
    void setAlgorithm(const QString& algorithm);

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
    void setPitchNormalization(const QString& pitchNormalization);

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

    int specFftLength() const;
    void setSpecFftLength(int specFftLength);

    bool specF0Refinement() const;
    void setSpecF0Refinement(bool specF0Refinement);

    bool specUseLogScale() const;
    void setSpecUseLogScale(bool specUseLogScale);

    SpecColorScheme specColorScheme() const;
    void setSpecColorScheme(SpecColorScheme specColorScheme);

    bool showSpectrum() const;
    void setShowSpectrum(bool showSpectrum);

    bool showCepstrum() const;
    void setShowCepstrum(bool showCepstrum);

    int cepstrNumOrder() const;

    int amplitudeWindow() const;
    int amplitudeShift() const;
    AmplitudeSmoothingType amplitudeSmoothing() const;
    int amplitudeSmoothingWindowSize() const;
    double amplitudeGaussianSmoothingSigma() const;
    bool showAmplitude() const;
    bool showAmplitudeDerivative() const;
    bool showF0() const;
    bool showLogPitch() const;
    bool showProcessedPitch() const;

    void setAmplitudeWindow(int amplitudeWindow);
    void setAmplitudeShift(int amplitudeShift);
    void setAmplitudeSmoothing(AmplitudeSmoothingType amplitudeSmoothing);
    void setAmplitudeSmoothingWindowSize(int amplitudeSmoothingWindowSize);
    void
    setAmplitudeGaussianSmoothingSigma(double amplitudeGaussianSmoothingSigma);
    void setShowAmplitude(bool showAmplitude);
    void setShowAmplitudeDerivative(bool showAmplitudeDerivative);
    void setShowF0(bool showF0);
    void setShowLogPitch(bool showLogPitch);
    void setShowProcessedPitch(bool showProcessedPitch);

    void setCepstrNumOrder(int cepstrNumOrder);

    /**
     * Loads the settings from a file and updates the internal state of the
     * SettingsApi object. This method should be called when the application
     * starts to initialize the settings based on previously saved values.
     */
    Q_INVOKABLE void load();
    /**
     * Saves the current settings to a file. This method should be called
     * whenever a setting is changed to ensure that the new values are persisted
     * for future sessions. The settings are typically saved in a JSON format in
     * the user's home directory.
     */
    Q_INVOKABLE void save();

signals:
    void amplitudeWindowChanged();
    void amplitudeShiftChanged();
    void amplitudeSmoothingChanged();
    void amplitudeSmoothingWindowSizeChanged();
    void amplitudeGaussianSmoothingSigmaChanged();
    void showAmplitudeChanged();
    void showAmplitudeDerivativeChanged();
    void showF0Changed();
    void showLogPitchChanged();
    void showProcessedPitchChanged();
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

    void specFftLengthChanged();
    void specF0RefinementChanged();
    void specUseLogScaleChanged();
    void specColorSchemeChanged();
    void showSpectrumChanged();
    void showCepstrumChanged();
    void cepstrNumOrderChanged();

private:
    AppSettings m_settings;
    QTranslator m_translator;

    /**
     * Updates the application's translator based on the current language setting.
     * This method is called internally whenever the language setting is changed to
     * ensure that the UI is updated with the appropriate translations. The method loads
     * the corresponding translation file based on the selected language and applies it
     * to the application, allowing for dynamic language switching without restarting
     */
    void updateTranslator();
};

#endif // SETTINGSAPI_H
