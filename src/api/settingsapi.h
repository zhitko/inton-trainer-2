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
    Q_PROPERTY(
        QString languageTitle READ languageTitle WRITE setLanguageTitle NOTIFY languageTitleChanged)
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(double fontSizeMultiplier READ fontSizeMultiplier WRITE setFontSizeMultiplier NOTIFY fontSizeMultiplierChanged)
    Q_PROPERTY(QString primaryColor READ primaryColor WRITE setPrimaryColor NOTIFY primaryColorChanged)
    Q_PROPERTY(bool showNavigationMenu READ showNavigationMenu WRITE setShowNavigationMenu NOTIFY showNavigationMenuChanged)
    Q_PROPERTY(bool showVadA READ showVadA WRITE setShowVadA NOTIFY showVadAChanged)
    Q_PROPERTY(bool showVadU READ showVadU WRITE setShowVadU NOTIFY showVadUChanged)
    Q_PROPERTY(bool showVadV READ showVadV WRITE setShowVadV NOTIFY showVadVChanged)
    Q_PROPERTY(bool showVadCorr READ showVadCorr WRITE setShowVadCorr NOTIFY showVadCorrChanged)
    Q_PROPERTY(bool autoStopRecording READ autoStopRecording WRITE setAutoStopRecording NOTIFY autoStopRecordingChanged)
    Q_PROPERTY(bool autoCalibrate READ autoCalibrate WRITE setAutoCalibrate NOTIFY autoCalibrateChanged)
    Q_PROPERTY(int vadCalibrationDurationMs READ vadCalibrationDurationMs WRITE setVadCalibrationDurationMs NOTIFY vadCalibrationDurationMsChanged)
    Q_PROPERTY(int autoStopSilenceDuration READ autoStopSilenceDuration WRITE setAutoStopSilenceDuration NOTIFY autoStopSilenceDurationChanged)
    Q_PROPERTY(double minimumRecordLengthPercent READ minimumRecordLengthPercent WRITE setMinimumRecordLengthPercent NOTIFY minimumRecordLengthPercentChanged)
    Q_PROPERTY(int vadMethod READ vadMethod WRITE setVadMethod NOTIFY vadMethodChanged)
    Q_PROPERTY(double vadThreshold READ vadThreshold WRITE setVadThreshold NOTIFY vadThresholdChanged)
    Q_PROPERTY(double autoCorrThreshold READ autoCorrThreshold WRITE setAutoCorrThreshold NOTIFY autoCorrThresholdChanged)
    Q_PROPERTY(double autoCorrThresholdK READ autoCorrThresholdK WRITE setAutoCorrThresholdK NOTIFY autoCorrThresholdKChanged)
    Q_PROPERTY(double autoCorrMinF0 READ autoCorrMinF0 WRITE setAutoCorrMinF0 NOTIFY autoCorrMinF0Changed)
    Q_PROPERTY(double autoCorrMaxF0 READ autoCorrMaxF0 WRITE setAutoCorrMaxF0 NOTIFY autoCorrMaxF0Changed)
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

    Q_PROPERTY(bool showUMP READ showUMP WRITE setShowUMP NOTIFY showUMPChanged)
    Q_PROPERTY(UmpSmoothingType umpSmoothing READ umpSmoothing WRITE
            setUmpSmoothing NOTIFY umpSmoothingChanged)
    Q_PROPERTY(int umpSmoothingWindowSize READ umpSmoothingWindowSize WRITE
            setUmpSmoothingWindowSize NOTIFY umpSmoothingWindowSizeChanged)
    Q_PROPERTY(double umpGaussianSmoothingSigma READ umpGaussianSmoothingSigma
            WRITE setUmpGaussianSmoothingSigma NOTIFY
                umpGaussianSmoothingSigmaChanged)
    Q_PROPERTY(double umpSplineSmoothingPenalty READ umpSplineSmoothingPenalty
            WRITE setUmpSplineSmoothingPenalty NOTIFY
                umpSplineSmoothingPenaltyChanged)

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
    Q_PROPERTY(bool useOnlyN READ useOnlyN WRITE setUseOnlyN NOTIFY useOnlyNChanged)

    Q_PROPERTY(int cepstrNumOrder READ cepstrNumOrder WRITE setCepstrNumOrder
            NOTIFY cepstrNumOrderChanged)

    Q_PROPERTY(bool showDtwAlignment READ showDtwAlignment WRITE setShowDtwAlignment NOTIFY showDtwAlignmentChanged)
    Q_PROPERTY(bool dpUsePitch READ dpUsePitch WRITE setDpUsePitch NOTIFY dpUsePitchChanged)
    Q_PROPERTY(double dpPitchCoef READ dpPitchCoef WRITE setDpPitchCoef NOTIFY dpPitchCoefChanged)
    Q_PROPERTY(bool dpUsePitchDerivative READ dpUsePitchDerivative WRITE setDpUsePitchDerivative NOTIFY dpUsePitchDerivativeChanged)
    Q_PROPERTY(double dpPitchDerivativeCoef READ dpPitchDerivativeCoef WRITE setDpPitchDerivativeCoef NOTIFY dpPitchDerivativeCoefChanged)
    Q_PROPERTY(bool dpUsePitchLog READ dpUsePitchLog WRITE setDpUsePitchLog NOTIFY dpUsePitchLogChanged)
    Q_PROPERTY(double dpPitchLogCoef READ dpPitchLogCoef WRITE setDpPitchLogCoef NOTIFY dpPitchLogCoefChanged)
    Q_PROPERTY(bool dpUsePitchLogAsMask READ dpUsePitchLogAsMask WRITE setDpUsePitchLogAsMask NOTIFY dpUsePitchLogAsMaskChanged)
    Q_PROPERTY(int pitchLogSmoothingWindowSize READ pitchLogSmoothingWindowSize WRITE setPitchLogSmoothingWindowSize NOTIFY pitchLogSmoothingWindowSizeChanged)
    Q_PROPERTY(int pitchLogSmoothingMovingAverageSize READ pitchLogSmoothingMovingAverageSize WRITE setPitchLogSmoothingMovingAverageSize NOTIFY pitchLogSmoothingMovingAverageSizeChanged)
    Q_PROPERTY(bool transformPitchLogToBinary READ transformPitchLogToBinary WRITE setTransformPitchLogToBinary NOTIFY transformPitchLogToBinaryChanged)
    Q_PROPERTY(double transformPitchLogThreshold READ transformPitchLogThreshold WRITE setTransformPitchLogThreshold NOTIFY transformPitchLogThresholdChanged)
    Q_PROPERTY(bool dpUseAmplitude READ dpUseAmplitude WRITE setDpUseAmplitude NOTIFY dpUseAmplitudeChanged)
    Q_PROPERTY(double dpAmplitudeCoef READ dpAmplitudeCoef WRITE setDpAmplitudeCoef NOTIFY dpAmplitudeCoefChanged)
    Q_PROPERTY(bool dpUseAmplitudeDerivative READ dpUseAmplitudeDerivative WRITE setDpUseAmplitudeDerivative NOTIFY dpUseAmplitudeDerivativeChanged)
    Q_PROPERTY(double dpAmplitudeDerivativeCoef READ dpAmplitudeDerivativeCoef WRITE setDpAmplitudeDerivativeCoef NOTIFY dpAmplitudeDerivativeCoefChanged)
    Q_PROPERTY(bool dpUseSpectrum READ dpUseSpectrum WRITE setDpUseSpectrum NOTIFY dpUseSpectrumChanged)
    Q_PROPERTY(double dpSpectrumCoef READ dpSpectrumCoef WRITE setDpSpectrumCoef NOTIFY dpSpectrumCoefChanged)
    Q_PROPERTY(bool dpUseCepstrum READ dpUseCepstrum WRITE setDpUseCepstrum NOTIFY dpUseCepstrumChanged)
    Q_PROPERTY(double dpCepstrumCoef READ dpCepstrumCoef WRITE setDpCepstrumCoef NOTIFY dpCepstrumCoefChanged)
    Q_PROPERTY(double dpMatchCoef READ dpMatchCoef WRITE setDpMatchCoef NOTIFY dpMatchCoefChanged)
    Q_PROPERTY(double dpInsertionCoef READ dpInsertionCoef WRITE setDpInsertionCoef NOTIFY dpInsertionCoefChanged)
    Q_PROPERTY(double dpDeletionCoef READ dpDeletionCoef WRITE setDpDeletionCoef NOTIFY dpDeletionCoefChanged)
    Q_PROPERTY(bool dpUseFixedStartEndDP READ dpUseFixedStartEndDP WRITE setDpUseFixedStartEndDP NOTIFY dpUseFixedStartEndDPChanged)
    Q_PROPERTY(double dtwDistanceLimit READ dtwDistanceLimit WRITE setDtwDistanceLimit NOTIFY dtwDistanceLimitChanged)

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

    enum class UmpSmoothingType {
        None,
        MovingAverage,
        Median,
        Gaussian,
        Spline
    };
    Q_ENUM(UmpSmoothingType)
    explicit SettingsApi(QObject* parent = nullptr);

    QString language() const;
    void setLanguage(const QString& language);

    QString languageTitle() const;
    void setLanguageTitle(const QString& languageTitle);

    QString theme() const;
    void setTheme(const QString& theme);

    double fontSizeMultiplier() const;
    void setFontSizeMultiplier(double fontSizeMultiplier);

    QString primaryColor() const;
    void setPrimaryColor(const QString& primaryColor);

    bool showNavigationMenu() const;
    void setShowNavigationMenu(bool showNavigationMenu);

    bool showVadA() const;
    void setShowVadA(bool show);
    bool showVadU() const;
    void setShowVadU(bool show);
    bool showVadV() const;
    void setShowVadV(bool show);
    bool showVadCorr() const;
    void setShowVadCorr(bool show);

    bool autoStopRecording() const;
    void setAutoStopRecording(bool autoStopRecording);

    bool autoCalibrate() const;
    void setAutoCalibrate(bool autoCalibrate);

    int vadCalibrationDurationMs() const;
    void setVadCalibrationDurationMs(int vadCalibrationDurationMs);

    int autoStopSilenceDuration() const;
    void setAutoStopSilenceDuration(int autoStopSilenceDuration);

    double minimumRecordLengthPercent() const;
    void setMinimumRecordLengthPercent(double minimumRecordLengthPercent);
    
    int vadMethod() const;
    void setVadMethod(int method);

    double vadThreshold() const;
    void setVadThreshold(double vadThreshold);

    double autoCorrThreshold() const;
    void setAutoCorrThreshold(double threshold);

    double autoCorrThresholdK() const;
    void setAutoCorrThresholdK(double thresholdK);

    double autoCorrMinF0() const;
    void setAutoCorrMinF0(double minF0);

    double autoCorrMaxF0() const;
    void setAutoCorrMaxF0(double maxF0);

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

    UmpSmoothingType umpSmoothing() const;
    void setUmpSmoothing(UmpSmoothingType umpSmoothing);
    int umpSmoothingWindowSize() const;
    void setUmpSmoothingWindowSize(int umpSmoothingWindowSize);
    double umpGaussianSmoothingSigma() const;
    void setUmpGaussianSmoothingSigma(double umpGaussianSmoothingSigma);
    double umpSplineSmoothingPenalty() const;
    void setUmpSplineSmoothingPenalty(double umpSplineSmoothingPenalty);

    bool showUMP() const;
    void setShowUMP(bool showUMP);

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
    bool useOnlyN() const;

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
    void setUseOnlyN(bool useOnlyN);

    void setCepstrNumOrder(int cepstrNumOrder);

    bool showDtwAlignment() const;
    void setShowDtwAlignment(bool showDtwAlignment);

    bool dpUsePitch() const;
    void setDpUsePitch(bool dpUsePitch);
    double dpPitchCoef() const;
    void setDpPitchCoef(double dpPitchCoef);
    bool dpUsePitchDerivative() const;
    void setDpUsePitchDerivative(bool dpUsePitchDerivative);
    double dpPitchDerivativeCoef() const;
    void setDpPitchDerivativeCoef(double dpPitchDerivativeCoef);
    bool dpUsePitchLog() const;
    void setDpUsePitchLog(bool dpUsePitchLog);
    double dpPitchLogCoef() const;
    void setDpPitchLogCoef(double dpPitchLogCoef);
    bool dpUsePitchLogAsMask() const;
    void setDpUsePitchLogAsMask(bool dpUsePitchLogAsMask);
    int pitchLogSmoothingWindowSize() const;
    void setPitchLogSmoothingWindowSize(int pitchLogSmoothingWindowSize);
    int pitchLogSmoothingMovingAverageSize() const;
    void setPitchLogSmoothingMovingAverageSize(int pitchLogSmoothingMovingAverageSize);
    bool transformPitchLogToBinary() const;
    void setTransformPitchLogToBinary(bool transformPitchLogToBinary);
    double transformPitchLogThreshold() const;
    void setTransformPitchLogThreshold(double transformPitchLogThreshold);
    bool dpUseAmplitude() const;
    void setDpUseAmplitude(bool dpUseAmplitude);
    double dpAmplitudeCoef() const;
    void setDpAmplitudeCoef(double dpAmplitudeCoef);
    bool dpUseAmplitudeDerivative() const;
    void setDpUseAmplitudeDerivative(bool dpUseAmplitudeDerivative);
    double dpAmplitudeDerivativeCoef() const;
    void setDpAmplitudeDerivativeCoef(double dpAmplitudeDerivativeCoef);
    bool dpUseSpectrum() const;
    void setDpUseSpectrum(bool dpUseSpectrum);
    double dpSpectrumCoef() const;
    void setDpSpectrumCoef(double dpSpectrumCoef);
    bool dpUseCepstrum() const;
    void setDpUseCepstrum(bool dpUseCepstrum);
    double dpCepstrumCoef() const;
    void setDpCepstrumCoef(double dpCepstrumCoef);
    double dpMatchCoef() const;
    void setDpMatchCoef(double dpMatchCoef);
    double dpInsertionCoef() const;
    void setDpInsertionCoef(double dpInsertionCoef);
    double dpDeletionCoef() const;
    void setDpDeletionCoef(double dpDeletionCoef);
    bool dpUseFixedStartEndDP() const;
    void setDpUseFixedStartEndDP(bool dpUseFixedStartEndDP);
    double dtwDistanceLimit() const;
    void setDtwDistanceLimit(double dtwDistanceLimit);

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

    /**
     * Clears all user statistics data by deleting the statistics file.
     * This removes all training results and resets the statistics to an empty state.
     * The statistics file will be deleted from disk.
     */
    Q_INVOKABLE void clearUserStatistics();

signals:
    void settingsChanged();
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
    void useOnlyNChanged();
    void languageChanged();
    void languageTitleChanged();
    void themeChanged();
    void fontSizeMultiplierChanged();
    void primaryColorChanged();
    void showNavigationMenuChanged();
    void showVadAChanged();
    void showVadUChanged();
    void showVadVChanged();
    void showVadCorrChanged();
    void autoStopRecordingChanged();
    void autoCalibrateChanged();
    void vadCalibrationDurationMsChanged();
    void autoStopSilenceDurationChanged();
    void minimumRecordLengthPercentChanged();
    void vadMethodChanged();
    void vadThresholdChanged();
    void autoCorrThresholdChanged();
    void autoCorrThresholdKChanged();
    void autoCorrMinF0Changed();
    void autoCorrMaxF0Changed();
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

    void umpSmoothingChanged();
    void umpSmoothingWindowSizeChanged();
    void umpGaussianSmoothingSigmaChanged();
    void umpSplineSmoothingPenaltyChanged();
    void showUMPChanged();

    void specFftLengthChanged();
    void specF0RefinementChanged();
    void specUseLogScaleChanged();
    void specColorSchemeChanged();
    void showSpectrumChanged();
    void showCepstrumChanged();
    void cepstrNumOrderChanged();

    void showDtwAlignmentChanged();
    void dpUsePitchChanged();
    void dpPitchCoefChanged();
    void dpUsePitchDerivativeChanged();
    void dpPitchDerivativeCoefChanged();
    void dpUsePitchLogChanged();
    void dpPitchLogCoefChanged();
    void dpUsePitchLogAsMaskChanged();
    void pitchLogSmoothingWindowSizeChanged();
    void pitchLogSmoothingMovingAverageSizeChanged();
    void transformPitchLogToBinaryChanged();
    void transformPitchLogThresholdChanged();
    void dpUseAmplitudeChanged();
    void dpAmplitudeCoefChanged();
    void dpUseAmplitudeDerivativeChanged();
    void dpAmplitudeDerivativeCoefChanged();
    void dpUseSpectrumChanged();
    void dpSpectrumCoefChanged();
    void dpUseCepstrumChanged();
    void dpCepstrumCoefChanged();
    void dpMatchCoefChanged();
    void dpInsertionCoefChanged();
    void dpDeletionCoefChanged();
    void dpUseFixedStartEndDPChanged();
    void dtwDistanceLimitChanged();

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
