#include "settings.h"
#include "logger.h"
#include <QSettings>
#include <QFileInfo>
#include <QCoreApplication>
#include <QDebug>

AppSettings Settings::getDefaultSettings() {
    return AppSettings();
}

QString Settings::getSettingsFilePath() {
    QString path = QCoreApplication::applicationDirPath() + "/settings.ini";
    return path;
}

AppSettings Settings::loadSettings() {
    AppSettings settings;
    QString filePath = getSettingsFilePath();
    
    // Use absolute path for QSettings
    QFileInfo fileInfo(filePath);
    QString absolutePath = fileInfo.absoluteFilePath();
    
    QSettings qsettings(absolutePath, QSettings::IniFormat);
    LOG_INFO() << "Loading settings from:" << absolutePath;

    qsettings.beginGroup("General");
    settings.language = qsettings.value("language", "ru").toString().toStdString();
    settings.theme = qsettings.value("theme", "light").toString().toStdString();
    qsettings.endGroup();

    qsettings.beginGroup("Pitch");
    settings.algorithm = qsettings.value("algorithm", "SWIPE").toString().toStdString();
    settings.frameShift = qsettings.value("frameShift", 80.0).toDouble();
    settings.sampleRate = qsettings.value("sampleRate", 16000.0).toDouble();
    settings.minF0 = qsettings.value("minF0", 20.0).toDouble();
    settings.maxF0 = qsettings.value("maxF0", 600.0).toDouble();
    settings.voicingThreshold = qsettings.value("voicingThreshold", 0.3).toDouble();
    settings.pitchNormalization = qsettings.value("pitchNormalization", "max").toString().toStdString();
    settings.pitchInterpolationType = qsettings.value("pitchInterpolationType", "Linear").toString().toStdString();
    settings.pitchSmoothing = qsettings.value("pitchSmoothing", "None").toString().toStdString();
    settings.pitchSmoothingWindowSize = qsettings.value("pitchSmoothingWindowSize", 5).toInt();
    settings.pitchGaussianSmoothingSigma = qsettings.value("pitchGaussianSmoothingSigma", 2.0).toDouble();

    settings.pitchSplineSmoothingPenalty = qsettings.value("pitchSplineSmoothingPenalty", 10.0).toDouble();
    qsettings.endGroup();

    return settings;
}

void Settings::saveSettings(const AppSettings& settings) {
    QString filePath = getSettingsFilePath();
    
    // Use absolute path for QSettings
    QFileInfo fileInfo(filePath);
    QString absolutePath = fileInfo.absoluteFilePath();
    
    QSettings qsettings(absolutePath, QSettings::IniFormat);
    LOG_INFO() << "Saving settings to:" << absolutePath;

    qsettings.beginGroup("General");
    qsettings.setValue("language", QString::fromStdString(settings.language));
    qsettings.setValue("theme", QString::fromStdString(settings.theme));
    qsettings.endGroup();

    qsettings.beginGroup("Pitch");
    qsettings.setValue("algorithm", QString::fromStdString(settings.algorithm));
    qsettings.setValue("frameShift", settings.frameShift);
    qsettings.setValue("sampleRate", settings.sampleRate);
    qsettings.setValue("minF0", settings.minF0);
    qsettings.setValue("maxF0", settings.maxF0);
    qsettings.setValue("voicingThreshold", settings.voicingThreshold);
    qsettings.setValue("pitchNormalization", QString::fromStdString(settings.pitchNormalization));
    qsettings.setValue("pitchInterpolationType", QString::fromStdString(settings.pitchInterpolationType));
    qsettings.setValue("pitchSmoothing", QString::fromStdString(settings.pitchSmoothing));
    qsettings.setValue("pitchSmoothingWindowSize", settings.pitchSmoothingWindowSize);
    qsettings.setValue("pitchGaussianSmoothingSigma", settings.pitchGaussianSmoothingSigma);

    qsettings.setValue("pitchSplineSmoothingPenalty", settings.pitchSplineSmoothingPenalty);
    qsettings.endGroup();
    
    qsettings.sync();
    
    LOG_DEBUG() << "QSettings status:" << qsettings.status();
    if (qsettings.status() != QSettings::NoError) {
        LOG_WARNING() << "Failed to save settings. Status:" << qsettings.status();
    }
}
