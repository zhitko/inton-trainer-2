#include "settingsapi.h"
#include <QDebug>
#include <QCoreApplication>
#include <QQmlEngine>

SettingsApi::SettingsApi(QObject *parent) : QObject(parent)
{
    load();
}

QString SettingsApi::language() const
{
    return QString::fromStdString(m_settings.language);
}

void SettingsApi::setLanguage(const QString &language)
{
    if (m_settings.language != language.toStdString()) {
        m_settings.language = language.toStdString();
        save();
        updateTranslator();
        emit languageChanged();
    }
}

QString SettingsApi::theme() const
{
    return QString::fromStdString(m_settings.theme);
}

void SettingsApi::setTheme(const QString &theme)
{
    if (m_settings.theme != theme.toStdString()) {
        m_settings.theme = theme.toStdString();
        save();
        emit themeChanged();
    }
}

QString SettingsApi::algorithm() const
{
    return QString::fromStdString(m_settings.algorithm);
}

void SettingsApi::setAlgorithm(const QString &algorithm)
{
    if (m_settings.algorithm != algorithm.toStdString()) {
        m_settings.algorithm = algorithm.toStdString();
        save();
        emit algorithmChanged();
    }
}

double SettingsApi::frameShift() const
{
    return m_settings.frameShift;
}

void SettingsApi::setFrameShift(double frameShift)
{
    if (qAbs(m_settings.frameShift - frameShift) > 0.0001) {
        m_settings.frameShift = frameShift;
        save();
        emit frameShiftChanged();
    }
}

double SettingsApi::sampleRate() const
{
    return m_settings.sampleRate;
}

void SettingsApi::setSampleRate(double sampleRate)
{
    if (qAbs(m_settings.sampleRate - sampleRate) > 0.0001) {
        m_settings.sampleRate = sampleRate;
        save();
        emit sampleRateChanged();
    }
}

double SettingsApi::minF0() const
{
    return m_settings.minF0;
}

void SettingsApi::setMinF0(double minF0)
{
    if (qAbs(m_settings.minF0 - minF0) > 0.0001) {
        m_settings.minF0 = minF0;
        save();
        emit minF0Changed();
    }
}

double SettingsApi::maxF0() const
{
    return m_settings.maxF0;
}

void SettingsApi::setMaxF0(double maxF0)
{
    if (qAbs(m_settings.maxF0 - maxF0) > 0.0001) {
        m_settings.maxF0 = maxF0;
        save();
        emit maxF0Changed();
    }
}

double SettingsApi::voicingThreshold() const
{
    return m_settings.voicingThreshold;
}

void SettingsApi::setVoicingThreshold(double voicingThreshold)
{
    if (qAbs(m_settings.voicingThreshold - voicingThreshold) > 0.0001) {
        m_settings.voicingThreshold = voicingThreshold;
        save();
        emit voicingThresholdChanged();
    }
}

void SettingsApi::load()
{
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
}

void SettingsApi::save()
{
    Settings::saveSettings(m_settings);
}

void SettingsApi::updateTranslator()
{
    QCoreApplication::removeTranslator(&m_translator);
    QString lang = QString::fromStdString(m_settings.language);
    if (m_translator.load("inton-trainer-2_" + lang, QCoreApplication::applicationDirPath())) {
        QCoreApplication::installTranslator(&m_translator);
        QQmlEngine *engine = qmlEngine(this);
        if (engine) {
            engine->retranslate();
        }
    } else {
        qDebug() << "Failed to load translation for" << lang;
    }
}
