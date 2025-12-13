#ifndef SETTINGS_H
#define SETTINGS_H

#include <QString>
#include <string>

struct AppSettings {
    // General
    std::string language = "ru";
    std::string theme = "light";

    // Pitch
    std::string algorithm = "SWIPE";
    double frameShift = 1.0;
    double sampleRate = 16000.0;
    double minF0 = 50.0;
    double maxF0 = 600.0;
    double voicingThreshold = 0.2;
    std::string pitchNormalization = "max";
    std::string pitchInterpolationType = "Linear";
    std::string pitchSmoothing = "None";
    int pitchSmoothingWindowSize = 10;
    double pitchGaussianSmoothingSigma = 1.0;
    int pitchSavitzkyGolaySmoothingPolynomialOrder = 5;
    double pitchSplineSmoothingPenalty = 1.0;
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
