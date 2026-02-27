#ifndef SETTINGS_H
#define SETTINGS_H

#include <QString>
#include <string>

struct AppSettings {
    // General
    std::string language = "ru";
    std::string theme = "light";

    // Pitch
    std::string algorithm = "RAPT";
    double frameShift = 32.0;
    double sampleRate = 8000.0;
    double minF0 = 80.0;
    double maxF0 = 500.0;
    double voicingThreshold = 0;
    std::string pitchNormalization = "min_max";
    std::string pitchInterpolationType = "Linear";
    std::string pitchSmoothing = "Median";
    int pitchSmoothingWindowSize = 16;
    double pitchGaussianSmoothingSigma = 1.0;

    double pitchSplineSmoothingPenalty = 1.0;

    // Spectrum
    int specFftLength = 1024;
    bool specF0Refinement = true;
    bool specUseLogScale = true;
    std::string specColorScheme = "Viridis";
    bool showSpectrum = false;
    bool showCepstrum = false;

    // Amplitude analysis
    int amplitudeWindow = 1024;
    int amplitudeShift = 512;
    bool showAmplitude = true;
    bool showAmplitudeDerivative = true;

    // Pitch display
    bool showF0 = true;
    bool showLogPitch = true;
    bool showProcessedPitch = true;

    // Cepstrum
    int cepstrNumOrder = 25;
};

class Settings {
public:
    static AppSettings loadSettings();
    static void saveSettings(const AppSettings& settings);
    static AppSettings getDefaultSettings();

private:
    static QString getSettingsFilePath();
};

#endif // SETTINGS_H
