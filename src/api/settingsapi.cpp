#include "settingsapi.h"
#include "helpers/logger.h"
#include <QDebug>
#include <QCoreApplication>
#include <QQmlEngine>

SettingsApi::SettingsApi(QObject *parent) : QObject(parent)
{
    load();
}

QString SettingsApi::language() const
{
    LOG_DEBUG() << "Start: language";
    QString result = QString::fromStdString(m_settings.language);
    LOG_DEBUG() << "Finish: language - result=" << result;
    return result;
}

void SettingsApi::setLanguage(const QString &language)
{
    LOG_DEBUG() << "Start: setLanguage - language=" << language;
    if (m_settings.language != language.toStdString()) {
        m_settings.language = language.toStdString();
        save();
        updateTranslator();
        emit languageChanged();
    }
    LOG_DEBUG() << "Finish: setLanguage";
}

QString SettingsApi::theme() const
{
    LOG_DEBUG() << "Start: theme";
    QString result = QString::fromStdString(m_settings.theme);
    LOG_DEBUG() << "Finish: theme - result=" << result;
    return result;
}

void SettingsApi::setTheme(const QString &theme)
{
    LOG_DEBUG() << "Start: setTheme - theme=" << theme;
    if (m_settings.theme != theme.toStdString()) {
        m_settings.theme = theme.toStdString();
        save();
        emit themeChanged();
    }
    LOG_DEBUG() << "Finish: setTheme";
}

QString SettingsApi::algorithm() const
{
    LOG_DEBUG() << "Start: algorithm";
    QString result = QString::fromStdString(m_settings.algorithm);
    LOG_DEBUG() << "Finish: algorithm - result=" << result;
    return result;
}

void SettingsApi::setAlgorithm(const QString &algorithm)
{
    LOG_DEBUG() << "Start: setAlgorithm - algorithm=" << algorithm;
    if (m_settings.algorithm != algorithm.toStdString()) {
        m_settings.algorithm = algorithm.toStdString();
        save();
        emit algorithmChanged();
    }
    LOG_DEBUG() << "Finish: setAlgorithm";
}

double SettingsApi::frameShift() const
{
    LOG_DEBUG() << "Start: frameShift";
    double result = m_settings.frameShift;
    LOG_DEBUG() << "Finish: frameShift - result=" << result;
    return result;
}

void SettingsApi::setFrameShift(double frameShift)
{
    LOG_DEBUG() << "Start: setFrameShift - frameShift=" << frameShift;
    if (qAbs(m_settings.frameShift - frameShift) > 0.0001) {
        m_settings.frameShift = frameShift;
        save();
        emit frameShiftChanged();
    }
    LOG_DEBUG() << "Finish: setFrameShift";
}

double SettingsApi::sampleRate() const
{
    LOG_DEBUG() << "Start: sampleRate";
    double result = m_settings.sampleRate;
    LOG_DEBUG() << "Finish: sampleRate - result=" << result;
    return result;
}

void SettingsApi::setSampleRate(double sampleRate)
{
    LOG_DEBUG() << "Start: setSampleRate - sampleRate=" << sampleRate;
    if (qAbs(m_settings.sampleRate - sampleRate) > 0.0001) {
        m_settings.sampleRate = sampleRate;
        save();
        emit sampleRateChanged();
    }
    LOG_DEBUG() << "Finish: setSampleRate";
}

double SettingsApi::minF0() const
{
    LOG_DEBUG() << "Start: minF0";
    double result = m_settings.minF0;
    LOG_DEBUG() << "Finish: minF0 - result=" << result;
    return result;
}

void SettingsApi::setMinF0(double minF0)
{
    LOG_DEBUG() << "Start: setMinF0 - minF0=" << minF0;
    if (qAbs(m_settings.minF0 - minF0) > 0.0001) {
        m_settings.minF0 = minF0;
        save();
        emit minF0Changed();
    }
    LOG_DEBUG() << "Finish: setMinF0";
}

double SettingsApi::maxF0() const
{
    LOG_DEBUG() << "Start: maxF0";
    double result = m_settings.maxF0;
    LOG_DEBUG() << "Finish: maxF0 - result=" << result;
    return result;
}

void SettingsApi::setMaxF0(double maxF0)
{
    LOG_DEBUG() << "Start: setMaxF0 - maxF0=" << maxF0;
    if (qAbs(m_settings.maxF0 - maxF0) > 0.0001) {
        m_settings.maxF0 = maxF0;
        save();
        emit maxF0Changed();
    }
    LOG_DEBUG() << "Finish: setMaxF0";
}

double SettingsApi::voicingThreshold() const
{
    LOG_DEBUG() << "Start: voicingThreshold";
    double result = m_settings.voicingThreshold;
    LOG_DEBUG() << "Finish: voicingThreshold - result=" << result;
    return result;
}

void SettingsApi::setVoicingThreshold(double voicingThreshold)
{
    LOG_DEBUG() << "Start: setVoicingThreshold - voicingThreshold=" << voicingThreshold;
    if (qAbs(m_settings.voicingThreshold - voicingThreshold) > 0.0001) {
        m_settings.voicingThreshold = voicingThreshold;
        save();
        emit voicingThresholdChanged();
    }
    LOG_DEBUG() << "Finish: setVoicingThreshold";
}

QString SettingsApi::pitchNormalization() const
{
    LOG_DEBUG() << "Start: pitchNormalization";
    QString result = QString::fromStdString(m_settings.pitchNormalization);
    LOG_DEBUG() << "Finish: pitchNormalization - result=" << result;
    return result;
}

void SettingsApi::setPitchNormalization(const QString &pitchNormalization)
{
    LOG_DEBUG() << "Start: setPitchNormalization - pitchNormalization=" << pitchNormalization;
    if (m_settings.pitchNormalization != pitchNormalization.toStdString()) {
        m_settings.pitchNormalization = pitchNormalization.toStdString();
        save();
        emit pitchNormalizationChanged();
    }
    LOG_DEBUG() << "Finish: setPitchNormalization";
}

void SettingsApi::load()
{
    LOG_DEBUG() << "Start: load";
    m_settings = Settings::loadSettings();
    updateTranslator();
    emit languageChanged();
    emit themeChanged();
    emit algorithmChanged();
    emit frameShiftChanged();
    emit sampleRateChanged();
    emit minF0Changed();
    emit maxF0Changed();
    emit voicingThresholdChanged();
    emit voicingThresholdChanged();
    emit pitchNormalizationChanged();
    emit pitchInterpolationTypeChanged();
    LOG_DEBUG() << "Finish: load";
}

void SettingsApi::save()
{
    LOG_DEBUG() << "Start: save";
    Settings::saveSettings(m_settings);
    LOG_DEBUG() << "Finish: save";
}

SettingsApi::PitchInterpolationType SettingsApi::pitchInterpolationType() const
{
    LOG_DEBUG() << "Start: pitchInterpolationType";
    PitchInterpolationType result = PitchInterpolationType::Linear;
    std::string type = m_settings.pitchInterpolationType;
    if (type == "None") result = PitchInterpolationType::None;
    else if (type == "Linear") result = PitchInterpolationType::Linear;
    else if (type == "Cubic") result = PitchInterpolationType::Cubic;
    else if (type == "Akima") result = PitchInterpolationType::Akima;
    else if (type == "Monotone") result = PitchInterpolationType::Monotone;
    LOG_DEBUG() << "Finish: pitchInterpolationType - result=" << static_cast<int>(result);
    return result;
}

void SettingsApi::setPitchInterpolationType(PitchInterpolationType pitchInterpolationType)
{
    LOG_DEBUG() << "Start: setPitchInterpolationType - pitchInterpolationType=" << static_cast<int>(pitchInterpolationType);
    std::string type = "Linear";
    switch (pitchInterpolationType) {
        case PitchInterpolationType::None: type = "None"; break;
        case PitchInterpolationType::Linear: type = "Linear"; break;
        case PitchInterpolationType::Cubic: type = "Cubic"; break;
        case PitchInterpolationType::Akima: type = "Akima"; break;
        case PitchInterpolationType::Monotone: type = "Monotone"; break;
    }
    
    if (m_settings.pitchInterpolationType != type) {
        m_settings.pitchInterpolationType = type;
        save();
        emit pitchInterpolationTypeChanged();
    }
    LOG_DEBUG() << "Finish: setPitchInterpolationType";
}

void SettingsApi::updateTranslator()
{
    LOG_DEBUG() << "Start: updateTranslator";
    QCoreApplication::removeTranslator(&m_translator);
    QString lang = QString::fromStdString(m_settings.language);
    if (m_translator.load("inton-trainer-2_" + lang, QCoreApplication::applicationDirPath())) {
        QCoreApplication::installTranslator(&m_translator);
        QQmlEngine *engine = qmlEngine(this);
        if (engine) {
            engine->retranslate();
        }
    } else {
        LOG_WARNING() << "Failed to load translation for" << lang;
    }
    LOG_DEBUG() << "Finish: updateTranslator";
}
