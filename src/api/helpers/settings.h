#ifndef SETTINGS_H
#define SETTINGS_H

#include <QString>
#include <string>

/*
 * AppSettings struct holds all the configurable settings for the application.
 * This includes settings for pitch extraction, spectrum analysis, amplitude
 * analysis, and general UI preferences. The Settings class provides static
 * methods to load and save these settings to a file, as well as to get default
 * settings.
 *
 * The settings are designed to be easily extendable in the future as new
 * features are added to the application.
 */
struct AppSettings {
    // == General settings ==
    // Language options: "en", "ru", etc.
    std::string language = "ru";
    // Language title for display (e.g., "American English", "Русский")
    std::string languageTitle = "Русский";
    std::string theme = "light";

    // Primary color options: "blue", "green", "purple", "orange", "red"
    std::string primaryColor = "blue";
    // Show navigation menu in the UI
    bool showNavigationMenu = false;
    // Auto stop recording when silence is detected
    bool autoStopRecording = true;
    // Duration of silence in ms before auto-stop triggers
    int autoStopSilenceDuration = 2000;
    // VAD settings
    int vadMethod = 0; // 0: energy, 1: autocorr, 2: hybrid
    double vadThreshold = 10000.0;
    double autoCorrThreshold = 0.3;
    double autoCorrMinF0 = 80.0;
    double autoCorrMaxF0 = 300.0;
    // Show VAD internal curves in the UI
    bool showVadA = false;
    bool showVadU = false;
    bool showVadV = false;
    bool showVadCorr = false;

    // == Pitch extraction settings ==
    // Show F0 contour in the UI
    bool showF0 = true;
    // Show log F0 contour in the UI
    bool showLogPitch = true;
    // Show processed pitch contour in the UI (after smoothing and interpolation)
    bool showProcessedPitch = true;
    // Use only N frames from cue points (for pitch extraction)
    bool useOnlyN = true;
    // Algorithm options: "RAPT", "SWIPE", "REAPER", "DIO", "Harvest",
    // "NumAlgorithm"
    std::string algorithm = "RAPT";
    // Frame shift in milliseconds
    double frameShift = 32.0;
    // Sample rate for pitch extraction
    double sampleRate = 8000.0;
    // Minimum and maximum F0 for pitch extraction
    double minF0 = 80.0;
    // Maximum F0 for pitch extraction
    double maxF0 = 500.0;
    // Voicing threshold for pitch extraction
    double voicingThreshold = 0;
    // Normalization mode options: "max", "min_max", "mean", "mean_deviation"
    std::string pitchNormalization = "min_max";
    // Interpolation type options: "None", "Linear", "Cubic", "Akima", "Monotone"
    std::string pitchInterpolationType = "Linear";
    // Smoothing type options: "None", "MovingAverage", "Median", "Gaussian",
    // "Spline"
    std::string pitchSmoothing = "Median";
    // Smoothing window size for moving average, median, and Gaussian smoothing
    int pitchSmoothingWindowSize = 16;
    // Sigma for Gaussian smoothing
    double pitchGaussianSmoothingSigma = 1.0;
    // Penalty for spline smoothing (higher values result in smoother curves)
    double pitchSplineSmoothingPenalty = 1.0;

    // == Spectrum analysis settings ==
    // Show spectrum in the UI
    bool showSpectrum = false;
    // Show cepstrum in the UI
    bool showCepstrum = false;
    // FFT length for spectrum analysis
    int specFftLength = 1024;
    // Hop length for spectrum analysis
    bool specF0Refinement = true;
    // Logarithmic scale for spectrum display
    bool specUseLogScale = true;
    // Color scheme for spectrum display (e.g., "Viridis", "Plasma", "Hot",
    // "Cool")
    std::string specColorScheme = "Viridis";
    // Cepstrum
    int cepstrNumOrder = 25;

    // == Amplitude analysis settings ==
    // Show amplitude in the UI
    bool showAmplitude = true;
    // Show amplitude derivative in the UI
    bool showAmplitudeDerivative = true;
    // Window size for amplitude analysis
    int amplitudeWindow = 1024;
    // Shift for amplitude analysis
    int amplitudeShift = 512;
    // Smoothing type options: "None", "MovingAverage", "Median", "Gaussian",
    // "Spline"
    std::string amplitudeSmoothing = "Median";
    // Smoothing window size for moving average, median, and Gaussian smoothing
    int amplitudeSmoothingWindowSize = 16;
    // Sigma for Gaussian smoothing
    double amplitudeGaussianSmoothingSigma = 1.0;

    // == UMP settings ==
    // Show UMP graph in the UI
    bool showUMP = true;
    // Smoothing type options: "None", "MovingAverage", "Median", "Gaussian", "Spline"
    std::string umpSmoothing = "None";
    // Smoothing window size for moving average, median, and Gaussian smoothing
    int umpSmoothingWindowSize = 5;
    // Sigma for Gaussian smoothing
    double umpGaussianSmoothingSigma = 1.0;
    // Penalty for spline smoothing
    double umpSplineSmoothingPenalty = 1.0;

    // == DP settings ==
    bool showDtwAlignment = true;
    bool dpUsePitch = true;
    double dpPitchCoef = 1.0;
    bool dpUsePitchDerivative = true;
    double dpPitchDerivativeCoef = 1.0;
    bool dpUsePitchLog = true;
    double dpPitchLogCoef = 1.0;
    bool dpUsePitchLogAsMask = true;

    // == Pitch Log processing settings ==
    int pitchLogSmoothingWindowSize = 32;
    int pitchLogSmoothingMovingAverageSize = 64;
    bool transformPitchLogToBinary = false;
    double transformPitchLogThreshold = 0.1;

    bool dpUseAmplitude = true;
    double dpAmplitudeCoef = 1.0;
    bool dpUseAmplitudeDerivative = true;
    double dpAmplitudeDerivativeCoef = 1.0;
    bool dpUseSpectrum = true;
    double dpSpectrumCoef = 1.0;
    bool dpUseCepstrum = true;
    double dpCepstrumCoef = 1.0;

    // == DP editing coefficients ==
    double dpMatchCoef = 1.0;
    double dpInsertionCoef = 1.0;
    double dpDeletionCoef = 1.0;
    // When true, DTW is constrained to fixed start/end (full template vs full signal).
    bool dpUseFixedStartEndDP = false;
};

/*
 * The Settings class provides static methods to load and save the application
 * settings to a file, as well as to get default settings. The settings are
 * stored in a JSON file in the user's home directory.
 */
class Settings {
public:
    /**
     * Loads the application settings from a JSON file. If the file does not exist
     * or is invalid, it returns the default settings.
     *
     * @return An AppSettings object containing the loaded settings or default
     * settings if loading fails.
     */
    static AppSettings loadSettings();

    /**
     * Saves the given application settings to a JSON file in the user's home
     * directory. If the file cannot be written, it should handle the error
     * gracefully (e.g., by logging an error message).
     *
     * @param settings An AppSettings object containing the settings to be saved.
     */
    static void saveSettings(const AppSettings& settings);

    /**
     * Returns an AppSettings object initialized with default values. This can be
     * used as a fallback when loading settings fails or when the application is
     * run for the first time.
     *
     * @return An AppSettings object containing the default settings.
     */
    static AppSettings getDefaultSettings();

private:
    /**
     * Returns the file path for the settings JSON file. This is typically located
     * in the user's home directory under a hidden folder for the application.
     *
     * @return A QString containing the full file path to the settings JSON file.
     */
    static QString getSettingsFilePath();
};

#endif // SETTINGS_H
