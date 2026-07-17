#include "settings.h"

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QSettings>
#include <QStandardPaths>

#include "logger.h"

AppSettings
Settings::getDefaultSettings()
{
    return AppSettings();
}

QString
Settings::getAppDataDir()
{
#ifdef Q_OS_ANDROID
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
#else
    return QCoreApplication::applicationDirPath();
#endif
}

QString
Settings::getSettingsFilePath()
{
#ifdef Q_OS_ANDROID
    QString path = getAppDataDir() + "/settings.ini";
    // Ensure the directory exists — QSettings will create the file on first write
    QDir().mkpath(QFileInfo(path).absolutePath());
    return path;
#else
    return getAppDataDir() + "/settings.ini";
#endif
}

AppSettings
Settings::loadSettings()
{
    AppSettings settings;
    QString filePath = getSettingsFilePath();

    // Use absolute path for QSettings
    QFileInfo fileInfo(filePath);
    QString absolutePath = fileInfo.absoluteFilePath();

    QSettings qsettings(absolutePath, QSettings::IniFormat);
    LOG_INFO() << "Loading settings from:" << absolutePath;

    qsettings.beginGroup("General");
    settings.language = qsettings.value("language", "ru").toString().toStdString();
    settings.languageTitle = qsettings.value("languageTitle", "Русский").toString().toStdString();
    settings.theme = qsettings.value("theme", "light").toString().toStdString();
    settings.fontSizeMultiplier = qsettings.value("fontSizeMultiplier", 1.0).toDouble();
    settings.primaryColor = qsettings.value("primaryColor", "blue").toString().toStdString();
    settings.showNavigationMenu = qsettings.value("showNavigationMenu", false).toBool();
    settings.autoStopRecording = qsettings.value("autoStopRecording", true).toBool();
    settings.autoCalibrate = qsettings.value("autoCalibrate", true).toBool();
    settings.vadCalibrationDurationMs = qsettings.value("vadCalibrationDurationMs", 2000).toInt();
    settings.autoStopSilenceDuration = qsettings.value("autoStopSilenceDuration", 2000).toInt();
    settings.vadMethod = qsettings.value("vadMethod", 0).toInt();
    settings.vadThreshold = qsettings.value("vadThreshold", 10000.0).toDouble();
    settings.autoCorrThreshold = qsettings.value("autoCorrThreshold", 0.3).toDouble();
    settings.autoCorrThresholdK = qsettings.value("autoCorrThresholdK", 1.0).toDouble();
    settings.autoCorrMinF0 = qsettings.value("autoCorrMinF0", 80.0).toDouble();
    settings.autoCorrMaxF0 = qsettings.value("autoCorrMaxF0", 200.0).toDouble();
    settings.minimumRecordLengthPercent = qsettings.value("minimumRecordLengthPercent", 1.0).toDouble();
    settings.showVadA = qsettings.value("showVadA", false).toBool();
    settings.showVadU = qsettings.value("showVadU", false).toBool();
    settings.showVadV = qsettings.value("showVadV", false).toBool();
    settings.showVadCorr = qsettings.value("showVadCorr", false).toBool();
    settings.playSignalBeforeRecording = qsettings.value("playSignalBeforeRecording", true).toBool();
    settings.playSignalAfterRecording = qsettings.value("playSignalAfterRecording", true).toBool();
    settings.guidedModeEnabled = qsettings.value("guidedModeEnabled", true).toBool();
    settings.guidedListenTimeoutMs = qsettings.value("guidedListenTimeoutMs", 4000).toInt();
    settings.guidedPrePlayListenDelayMs = qsettings.value("guidedPrePlayListenDelayMs", 150).toInt();
    qsettings.endGroup();

    qsettings.beginGroup("Pitch");
    settings.algorithm = qsettings.value("algorithm", "SWIPE").toString().toStdString();
    settings.frameShift = qsettings.value("frameShift", 80.0).toDouble();
    settings.sampleRate = qsettings.value("sampleRate", 16000.0).toDouble();
    settings.minF0 = qsettings.value("minF0", 20.0).toDouble();
    settings.maxF0 = qsettings.value("maxF0", 600.0).toDouble();
    settings.voicingThreshold = qsettings.value("voicingThreshold", 0.3).toDouble();
    settings.pitchNormalization = qsettings.value("pitchNormalization", "max").toString().toStdString();
    settings.pitchInterpolationType = qsettings.value("pitchInterpolationType", "Linear")
                                          .toString()
                                          .toStdString();
    settings.pitchSmoothing = qsettings.value("pitchSmoothing", "None").toString().toStdString();
    settings.pitchSmoothingWindowSize = qsettings.value("pitchSmoothingWindowSize", 5).toInt();
    settings.pitchGaussianSmoothingSigma = qsettings.value("pitchGaussianSmoothingSigma", 2.0).toDouble();

    settings.pitchSplineSmoothingPenalty = qsettings.value("pitchSplineSmoothingPenalty", 10.0).toDouble();
    qsettings.endGroup();

    qsettings.beginGroup("UMP");
    settings.showUMP = qsettings.value("showUMP", true).toBool();
    settings.umpSmoothing = qsettings.value("umpSmoothing", "None").toString().toStdString();
    settings.umpSmoothingWindowSize = qsettings.value("umpSmoothingWindowSize", 5).toInt();
    settings.umpGaussianSmoothingSigma = qsettings.value("umpGaussianSmoothingSigma", 1.0).toDouble();
    settings.umpSplineSmoothingPenalty = qsettings.value("umpSplineSmoothingPenalty", 1.0).toDouble();
    qsettings.endGroup();

    // Amplitude settings
    qsettings.beginGroup("Amplitude");
    settings.amplitudeWindow = qsettings.value("window", 1024).toInt();
    settings.amplitudeShift = qsettings.value("shift", 512).toInt();
    settings.amplitudeSmoothing = qsettings.value("amplitudeSmoothing", "Median").toString().toStdString();
    settings.amplitudeSmoothingWindowSize = qsettings.value("amplitudeSmoothingWindowSize", 16).toInt();
    settings.amplitudeGaussianSmoothingSigma = qsettings.value("amplitudeGaussianSmoothingSigma", 1.0).toDouble();
    settings.showAmplitude = qsettings.value("showAmplitude", true).toBool();
    settings.showAmplitudeDerivative = qsettings.value("showAmplitudeDerivative", true).toBool();
    settings.showF0 = qsettings.value("showF0", true).toBool();
    settings.showLogPitch = qsettings.value("showLogPitch", true).toBool();
    settings.showProcessedPitch = qsettings.value("showProcessedPitch", true).toBool();
    settings.useOnlyN = qsettings.value("useOnlyN", true).toBool();
    qsettings.endGroup();

    qsettings.beginGroup("Spectrum");
    settings.specFftLength = qsettings.value("specFftLength", 2048).toInt();
    settings.specF0Refinement = qsettings.value("specF0Refinement", false).toBool();
    settings.specUseLogScale = qsettings.value("specUseLogScale", true).toBool();
    settings.specColorScheme = qsettings.value("specColorScheme", "Viridis").toString().toStdString();
    settings.showSpectrum = qsettings.value("showSpectrum", false).toBool();
    settings.showCepstrum = qsettings.value("showCepstrum", false).toBool();
    settings.cepstrNumOrder = qsettings.value("cepstrNumOrder", 25).toInt();
    qsettings.endGroup();

    qsettings.beginGroup("DP");
    settings.showDtwAlignment = qsettings.value("showDtwAlignment", true).toBool();
    settings.dpUsePitch = qsettings.value("dpUsePitch", true).toBool();
    settings.dpPitchCoef = qsettings.value("dpPitchCoef", 1.0).toDouble();
    settings.dpUsePitchDerivative = qsettings.value("dpUsePitchDerivative", true).toBool();
    settings.dpPitchDerivativeCoef = qsettings.value("dpPitchDerivativeCoef", 1.0).toDouble();
    settings.dpUsePitchLog = qsettings.value("dpUsePitchLog", true).toBool();
    settings.dpPitchLogCoef = qsettings.value("dpPitchLogCoef", 1.0).toDouble();
    settings.dpUsePitchLogAsMask = qsettings.value("dpUsePitchLogAsMask", true).toBool();
    settings.pitchLogSmoothingWindowSize = qsettings.value("pitchLogSmoothingWindowSize", 32).toInt();
    settings.pitchLogSmoothingMovingAverageSize = qsettings.value("pitchLogSmoothingMovingAverageSize", 64).toInt();
    settings.transformPitchLogToBinary = qsettings.value("transformPitchLogToBinary", false).toBool();
    settings.transformPitchLogThreshold = qsettings.value("transformPitchLogThreshold", 0.1).toDouble();
    settings.dpUseAmplitude = qsettings.value("dpUseAmplitude", true).toBool();
    settings.dpAmplitudeCoef = qsettings.value("dpAmplitudeCoef", 1.0).toDouble();
    settings.dpUseAmplitudeDerivative = qsettings.value("dpUseAmplitudeDerivative", true).toBool();
    settings.dpAmplitudeDerivativeCoef = qsettings.value("dpAmplitudeDerivativeCoef", 1.0).toDouble();
    settings.dpUseSpectrum = qsettings.value("dpUseSpectrum", true).toBool();
    settings.dpSpectrumCoef = qsettings.value("dpSpectrumCoef", 1.0).toDouble();
    settings.dpUseCepstrum = qsettings.value("dpUseCepstrum", true).toBool();
    settings.dpCepstrumCoef = qsettings.value("dpCepstrumCoef", 1.0).toDouble();
    settings.dpMatchCoef = qsettings.value("dpMatchCoef", 1.0).toDouble();
    settings.dpInsertionCoef = qsettings.value("dpInsertionCoef", 1.0).toDouble();
    settings.dpDeletionCoef = qsettings.value("dpDeletionCoef", 1.0).toDouble();
    settings.dpUseFixedStartEndDP = qsettings.value("dpUseFixedStartEndDP", false).toBool();
    settings.dtwDistanceLimit = qsettings.value("dtwDistanceLimit", 100.0).toDouble();
    qsettings.endGroup();

    return settings;
}

void Settings::saveSettings(const AppSettings& settings)
{
    QString filePath = getSettingsFilePath();

    // Use absolute path for QSettings
    QFileInfo fileInfo(filePath);
    QString absolutePath = fileInfo.absoluteFilePath();

    QSettings qsettings(absolutePath, QSettings::IniFormat);
    LOG_INFO() << "Saving settings to:" << absolutePath;

    qsettings.beginGroup("General");
    qsettings.setValue("language", QString::fromStdString(settings.language));
    qsettings.setValue("languageTitle", QString::fromStdString(settings.languageTitle));
    qsettings.setValue("theme", QString::fromStdString(settings.theme));
    qsettings.setValue("fontSizeMultiplier", settings.fontSizeMultiplier);
    qsettings.setValue("primaryColor", QString::fromStdString(settings.primaryColor));
    qsettings.setValue("showNavigationMenu", settings.showNavigationMenu);
    qsettings.setValue("autoStopRecording", settings.autoStopRecording);
    qsettings.setValue("autoCalibrate", settings.autoCalibrate);
    qsettings.setValue("vadCalibrationDurationMs", settings.vadCalibrationDurationMs);
    qsettings.setValue("autoStopSilenceDuration", settings.autoStopSilenceDuration);
    qsettings.setValue("vadMethod", settings.vadMethod);
    qsettings.setValue("vadThreshold", settings.vadThreshold);
    qsettings.setValue("autoCorrThreshold", settings.autoCorrThreshold);
    qsettings.setValue("autoCorrThresholdK", settings.autoCorrThresholdK);
    qsettings.setValue("autoCorrMinF0", settings.autoCorrMinF0);
    qsettings.setValue("autoCorrMaxF0", settings.autoCorrMaxF0);
    qsettings.setValue("minimumRecordLengthPercent", settings.minimumRecordLengthPercent);
    qsettings.setValue("showVadA", settings.showVadA);
    qsettings.setValue("showVadU", settings.showVadU);
    qsettings.setValue("showVadV", settings.showVadV);
    qsettings.setValue("showVadCorr", settings.showVadCorr);
    qsettings.setValue("playSignalBeforeRecording", settings.playSignalBeforeRecording);
    qsettings.setValue("playSignalAfterRecording", settings.playSignalAfterRecording);
    qsettings.setValue("guidedModeEnabled", settings.guidedModeEnabled);
    qsettings.setValue("guidedListenTimeoutMs", settings.guidedListenTimeoutMs);
    qsettings.setValue("guidedPrePlayListenDelayMs", settings.guidedPrePlayListenDelayMs);
    qsettings.endGroup();

    qsettings.beginGroup("Pitch");
    qsettings.setValue("algorithm", QString::fromStdString(settings.algorithm));
    qsettings.setValue("frameShift", settings.frameShift);
    qsettings.setValue("sampleRate", settings.sampleRate);
    qsettings.setValue("minF0", settings.minF0);
    qsettings.setValue("maxF0", settings.maxF0);
    qsettings.setValue("voicingThreshold", settings.voicingThreshold);
    qsettings.setValue("pitchNormalization",
        QString::fromStdString(settings.pitchNormalization));
    qsettings.setValue("pitchInterpolationType",
        QString::fromStdString(settings.pitchInterpolationType));
    qsettings.setValue("pitchSmoothing",
        QString::fromStdString(settings.pitchSmoothing));
    qsettings.setValue("pitchSmoothingWindowSize",
        settings.pitchSmoothingWindowSize);
    qsettings.setValue("pitchGaussianSmoothingSigma",
        settings.pitchGaussianSmoothingSigma);

    qsettings.setValue("pitchSplineSmoothingPenalty",
        settings.pitchSplineSmoothingPenalty);
    qsettings.endGroup();

    qsettings.beginGroup("UMP");
    qsettings.setValue("showUMP", settings.showUMP);
    qsettings.setValue("umpSmoothing",
        QString::fromStdString(settings.umpSmoothing));
    qsettings.setValue("umpSmoothingWindowSize", settings.umpSmoothingWindowSize);
    qsettings.setValue("umpGaussianSmoothingSigma", settings.umpGaussianSmoothingSigma);
    qsettings.setValue("umpSplineSmoothingPenalty", settings.umpSplineSmoothingPenalty);
    qsettings.endGroup();

    // Amplitude settings
    qsettings.beginGroup("Amplitude");
    qsettings.setValue("window", settings.amplitudeWindow);
    qsettings.setValue("shift", settings.amplitudeShift);
    qsettings.setValue("amplitudeSmoothing",
        QString::fromStdString(settings.amplitudeSmoothing));
    qsettings.setValue("amplitudeSmoothingWindowSize",
        settings.amplitudeSmoothingWindowSize);
    qsettings.setValue("amplitudeGaussianSmoothingSigma",
        settings.amplitudeGaussianSmoothingSigma);
    qsettings.setValue("showAmplitude", settings.showAmplitude);
    qsettings.setValue("showAmplitudeDerivative",
        settings.showAmplitudeDerivative);
    qsettings.setValue("showF0", settings.showF0);
    qsettings.setValue("showLogPitch", settings.showLogPitch);
    qsettings.setValue("showProcessedPitch", settings.showProcessedPitch);
    qsettings.setValue("useOnlyN", settings.useOnlyN);
    qsettings.endGroup();

    qsettings.beginGroup("Spectrum");
    qsettings.setValue("specFftLength", settings.specFftLength);
    qsettings.setValue("specF0Refinement", settings.specF0Refinement);
    qsettings.setValue("specUseLogScale", settings.specUseLogScale);
    qsettings.setValue("specColorScheme",
        QString::fromStdString(settings.specColorScheme));
    qsettings.setValue("showSpectrum", settings.showSpectrum);
    qsettings.setValue("showCepstrum", settings.showCepstrum);
    qsettings.setValue("cepstrNumOrder", settings.cepstrNumOrder);
    qsettings.endGroup();

    qsettings.beginGroup("DP");
    qsettings.setValue("showDtwAlignment", settings.showDtwAlignment);
    qsettings.setValue("dpUsePitch", settings.dpUsePitch);
    qsettings.setValue("dpPitchCoef", settings.dpPitchCoef);
    qsettings.setValue("dpUsePitchDerivative", settings.dpUsePitchDerivative);
    qsettings.setValue("dpPitchDerivativeCoef", settings.dpPitchDerivativeCoef);
    qsettings.setValue("dpUsePitchLog", settings.dpUsePitchLog);
    qsettings.setValue("dpPitchLogCoef", settings.dpPitchLogCoef);
    qsettings.setValue("dpUsePitchLogAsMask", settings.dpUsePitchLogAsMask);
    qsettings.setValue("pitchLogSmoothingWindowSize", settings.pitchLogSmoothingWindowSize);
    qsettings.setValue("pitchLogSmoothingMovingAverageSize", settings.pitchLogSmoothingMovingAverageSize);
    qsettings.setValue("transformPitchLogToBinary", settings.transformPitchLogToBinary);
    qsettings.setValue("transformPitchLogThreshold", settings.transformPitchLogThreshold);
    qsettings.setValue("dpUseAmplitude", settings.dpUseAmplitude);
    qsettings.setValue("dpAmplitudeCoef", settings.dpAmplitudeCoef);
    qsettings.setValue("dpUseAmplitudeDerivative", settings.dpUseAmplitudeDerivative);
    qsettings.setValue("dpAmplitudeDerivativeCoef", settings.dpAmplitudeDerivativeCoef);
    qsettings.setValue("dpUseSpectrum", settings.dpUseSpectrum);
    qsettings.setValue("dpSpectrumCoef", settings.dpSpectrumCoef);
    qsettings.setValue("dpUseCepstrum", settings.dpUseCepstrum);
    qsettings.setValue("dpCepstrumCoef", settings.dpCepstrumCoef);
    qsettings.setValue("dpMatchCoef", settings.dpMatchCoef);
    qsettings.setValue("dpInsertionCoef", settings.dpInsertionCoef);
    qsettings.setValue("dpDeletionCoef", settings.dpDeletionCoef);
    qsettings.setValue("dpUseFixedStartEndDP", settings.dpUseFixedStartEndDP);
    qsettings.setValue("dtwDistanceLimit", settings.dtwDistanceLimit);
    qsettings.endGroup();

    qsettings.sync();

    LOG_DEBUG() << "QSettings status:" << qsettings.status();
    if (qsettings.status() != QSettings::NoError) {
        LOG_WARNING() << "Failed to save settings. Status:" << qsettings.status();
    }
}
