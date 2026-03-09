#include "settingsapi.h"
#include "helpers/logger.h"
#include <QCoreApplication>
#include <QDebug>
#include <QQmlEngine>

SettingsApi::SettingsApi(QObject* parent)
    : QObject(parent)
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

void SettingsApi::setLanguage(const QString& language)
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

QString SettingsApi::languageTitle() const
{
    LOG_DEBUG() << "Start: languageTitle";
    QString result = QString::fromStdString(m_settings.languageTitle);
    LOG_DEBUG() << "Finish: languageTitle - result=" << result;
    return result;
}

void SettingsApi::setLanguageTitle(const QString& languageTitle)
{
    LOG_DEBUG() << "Start: setLanguageTitle - languageTitle=" << languageTitle;
    if (m_settings.languageTitle != languageTitle.toStdString()) {
        m_settings.languageTitle = languageTitle.toStdString();
        save();
        emit languageTitleChanged();
    }
    LOG_DEBUG() << "Finish: setLanguageTitle";
}

QString SettingsApi::theme() const
{
    LOG_DEBUG() << "Start: theme";
    QString result = QString::fromStdString(m_settings.theme);
    LOG_DEBUG() << "Finish: theme - result=" << result;
    return result;
}

void SettingsApi::setTheme(const QString& theme)
{
    LOG_DEBUG() << "Start: setTheme - theme=" << theme;
    if (m_settings.theme != theme.toStdString()) {
        m_settings.theme = theme.toStdString();
        save();
        emit themeChanged();
    }
    LOG_DEBUG() << "Finish: setTheme";
}

QString SettingsApi::primaryColor() const
{
    LOG_DEBUG() << "Start: primaryColor";
    QString result = QString::fromStdString(m_settings.primaryColor);
    LOG_DEBUG() << "Finish: primaryColor - result=" << result;
    return result;
}

void SettingsApi::setPrimaryColor(const QString& primaryColor)
{
    LOG_DEBUG() << "Start: setPrimaryColor - primaryColor=" << primaryColor;
    if (m_settings.primaryColor != primaryColor.toStdString()) {
        m_settings.primaryColor = primaryColor.toStdString();
        save();
        emit primaryColorChanged();
    }
    LOG_DEBUG() << "Finish: setPrimaryColor";
}

bool SettingsApi::showNavigationMenu() const
{
    LOG_DEBUG() << "Start: showNavigationMenu";
    bool result = m_settings.showNavigationMenu;
    LOG_DEBUG() << "Finish: showNavigationMenu - result=" << result;
    return result;
}

void SettingsApi::setShowNavigationMenu(bool showNavigationMenu)
{
    LOG_DEBUG() << "Start: setShowNavigationMenu - showNavigationMenu=" << showNavigationMenu;
    if (m_settings.showNavigationMenu != showNavigationMenu) {
        m_settings.showNavigationMenu = showNavigationMenu;
        save();
        emit showNavigationMenuChanged();
    }
    LOG_DEBUG() << "Finish: setShowNavigationMenu";
}

QString SettingsApi::algorithm() const
{
    LOG_DEBUG() << "Start: algorithm";
    QString result = QString::fromStdString(m_settings.algorithm);
    LOG_DEBUG() << "Finish: algorithm - result=" << result;
    return result;
}

void SettingsApi::setAlgorithm(const QString& algorithm)
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
    LOG_DEBUG() << "Start: setVoicingThreshold - voicingThreshold="
                << voicingThreshold;
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

void SettingsApi::setPitchNormalization(const QString& pitchNormalization)
{
    LOG_DEBUG() << "Start: setPitchNormalization - pitchNormalization="
                << pitchNormalization;
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
    emit languageTitleChanged();
    emit themeChanged();
    emit primaryColorChanged();
    emit showNavigationMenuChanged();
    emit algorithmChanged();
    emit frameShiftChanged();
    emit sampleRateChanged();
    emit minF0Changed();
    emit maxF0Changed();
    emit voicingThresholdChanged();
    emit pitchNormalizationChanged();
    emit pitchInterpolationTypeChanged();
    emit pitchSmoothingChanged();
    emit pitchSmoothingWindowSizeChanged();
    emit pitchGaussianSmoothingSigmaChanged();

    emit amplitudeWindowChanged();
    emit amplitudeShiftChanged();
    emit amplitudeSmoothingChanged();
    emit amplitudeSmoothingWindowSizeChanged();
    emit amplitudeGaussianSmoothingSigmaChanged();
    emit showAmplitudeChanged();
    emit showAmplitudeDerivativeChanged();
    emit showLogPitchChanged();

    emit pitchSplineSmoothingPenaltyChanged();
    emit specFftLengthChanged();
    emit specF0RefinementChanged();
    emit specUseLogScaleChanged();
    emit specColorSchemeChanged();
    emit cepstrNumOrderChanged();
    emit dpUsePitchChanged();
    emit dpPitchCoefChanged();
    emit dpUsePitchDerivativeChanged();
    emit dpPitchDerivativeCoefChanged();
    emit dpUsePitchLogChanged();
    emit dpPitchLogCoefChanged();
    emit dpUseAmplitudeChanged();
    emit dpAmplitudeCoefChanged();
    emit dpUseAmplitudeDerivativeChanged();
    emit dpAmplitudeDerivativeCoefChanged();
    emit dpUseSpectrumChanged();
    emit dpSpectrumCoefChanged();
    emit dpUseCepstrumChanged();
    emit dpCepstrumCoefChanged();
    LOG_DEBUG() << "Finish: load";
}

int SettingsApi::cepstrNumOrder() const
{
    LOG_DEBUG() << "Start: cepstrNumOrder";
    int result = m_settings.cepstrNumOrder;
    LOG_DEBUG() << "Finish: cepstrNumOrder - result=" << result;
    return result;
}

void SettingsApi::setCepstrNumOrder(int cepstrNumOrder)
{
    LOG_DEBUG() << "Start: setCepstrNumOrder - cepstrNumOrder=" << cepstrNumOrder;
    if (m_settings.cepstrNumOrder != cepstrNumOrder) {
        m_settings.cepstrNumOrder = cepstrNumOrder;
        save();
        emit cepstrNumOrderChanged();
    }
    LOG_DEBUG() << "Finish: setCepstrNumOrder";
}

void SettingsApi::save()
{
    LOG_DEBUG() << "Start: save";
    Settings::saveSettings(m_settings);
    LOG_DEBUG() << "Finish: save";
}

SettingsApi::PitchInterpolationType
SettingsApi::pitchInterpolationType() const
{
    LOG_DEBUG() << "Start: pitchInterpolationType";
    PitchInterpolationType result = PitchInterpolationType::Linear;
    std::string type = m_settings.pitchInterpolationType;
    if (type == "None")
        result = PitchInterpolationType::None;
    else if (type == "Linear")
        result = PitchInterpolationType::Linear;
    else if (type == "Cubic")
        result = PitchInterpolationType::Cubic;
    else if (type == "Akima")
        result = PitchInterpolationType::Akima;
    else if (type == "Monotone")
        result = PitchInterpolationType::Monotone;
    LOG_DEBUG() << "Finish: pitchInterpolationType - result="
                << static_cast<int>(result);
    return result;
}

void SettingsApi::setPitchInterpolationType(
    PitchInterpolationType pitchInterpolationType)
{
    LOG_DEBUG() << "Start: setPitchInterpolationType - pitchInterpolationType="
                << static_cast<int>(pitchInterpolationType);
    std::string type = "Linear";
    switch (pitchInterpolationType) {
    case PitchInterpolationType::None:
        type = "None";
        break;
    case PitchInterpolationType::Linear:
        type = "Linear";
        break;
    case PitchInterpolationType::Cubic:
        type = "Cubic";
        break;
    case PitchInterpolationType::Akima:
        type = "Akima";
        break;
    case PitchInterpolationType::Monotone:
        type = "Monotone";
        break;
    }

    if (m_settings.pitchInterpolationType != type) {
        m_settings.pitchInterpolationType = type;
        save();
        emit pitchInterpolationTypeChanged();
    }
    LOG_DEBUG() << "Finish: setPitchInterpolationType";
}

SettingsApi::PitchSmoothingType SettingsApi::pitchSmoothing() const
{
    LOG_DEBUG() << "Start: pitchSmoothing";
    PitchSmoothingType result = PitchSmoothingType::None;
    std::string type = m_settings.pitchSmoothing;

    if (type == "None")
        result = PitchSmoothingType::None;
    else if (type == "MovingAverage")
        result = PitchSmoothingType::MovingAverage;
    else if (type == "Median")
        result = PitchSmoothingType::Median;
    else if (type == "Gaussian")
        result = PitchSmoothingType::Gaussian;

    else if (type == "Spline")
        result = PitchSmoothingType::Spline;

    LOG_DEBUG() << "Finish: pitchSmoothing - result=" << static_cast<int>(result);
    return result;
}

void SettingsApi::setPitchSmoothing(PitchSmoothingType pitchSmoothing)
{
    LOG_DEBUG() << "Start: setPitchSmoothing - pitchSmoothing="
                << static_cast<int>(pitchSmoothing);
    std::string type = "None";
    switch (pitchSmoothing) {
    case PitchSmoothingType::None:
        type = "None";
        break;
    case PitchSmoothingType::MovingAverage:
        type = "MovingAverage";
        break;
    case PitchSmoothingType::Median:
        type = "Median";
        break;
    case PitchSmoothingType::Gaussian:
        type = "Gaussian";
        break;

    case PitchSmoothingType::Spline:
        type = "Spline";
        break;
    }

    if (m_settings.pitchSmoothing != type) {
        m_settings.pitchSmoothing = type;
        save();
        emit pitchSmoothingChanged();
    }
    LOG_DEBUG() << "Finish: setPitchSmoothing";
}

int SettingsApi::pitchSmoothingWindowSize() const
{
    LOG_DEBUG() << "Start: pitchSmoothingWindowSize";
    int result = m_settings.pitchSmoothingWindowSize;
    LOG_DEBUG() << "Finish: pitchSmoothingWindowSize - result=" << result;
    return result;
}

void SettingsApi::setPitchSmoothingWindowSize(int pitchSmoothingWindowSize)
{
    LOG_DEBUG()
        << "Start: setPitchSmoothingWindowSize - pitchSmoothingWindowSize="
        << pitchSmoothingWindowSize;
    if (m_settings.pitchSmoothingWindowSize != pitchSmoothingWindowSize) {
        m_settings.pitchSmoothingWindowSize = pitchSmoothingWindowSize;
        save();
        emit pitchSmoothingWindowSizeChanged();
    }
    LOG_DEBUG() << "Finish: setPitchSmoothingWindowSize";
}

double SettingsApi::pitchGaussianSmoothingSigma() const
{
    LOG_DEBUG() << "Start: pitchGaussianSmoothingSigma";
    double result = m_settings.pitchGaussianSmoothingSigma;
    LOG_DEBUG() << "Finish: pitchGaussianSmoothingSigma - result=" << result;
    return result;
}

int SettingsApi::amplitudeWindow() const
{
    LOG_DEBUG() << "Start: amplitudeWindow";
    int result = m_settings.amplitudeWindow;
    LOG_DEBUG() << "Finish: amplitudeWindow - result=" << result;
    return result;
}

int SettingsApi::amplitudeShift() const
{
    LOG_DEBUG() << "Start: amplitudeShift";
    int result = m_settings.amplitudeShift;
    LOG_DEBUG() << "Finish: amplitudeShift - result=" << result;
    return result;
}

SettingsApi::AmplitudeSmoothingType SettingsApi::amplitudeSmoothing() const
{
    LOG_DEBUG() << "Start: amplitudeSmoothing";
    AmplitudeSmoothingType result = AmplitudeSmoothingType::None;
    std::string type = m_settings.amplitudeSmoothing;

    if (type == "None")
        result = AmplitudeSmoothingType::None;
    else if (type == "MovingAverage")
        result = AmplitudeSmoothingType::MovingAverage;
    else if (type == "Median")
        result = AmplitudeSmoothingType::Median;
    else if (type == "Gaussian")
        result = AmplitudeSmoothingType::Gaussian;

    LOG_DEBUG() << "Finish: amplitudeSmoothing - result="
                << static_cast<int>(result);
    return result;
}

void SettingsApi::setAmplitudeSmoothing(
    AmplitudeSmoothingType amplitudeSmoothing)
{
    LOG_DEBUG() << "Start: setAmplitudeSmoothing - amplitudeSmoothing="
                << static_cast<int>(amplitudeSmoothing);
    std::string type = "None";
    switch (amplitudeSmoothing) {
    case AmplitudeSmoothingType::None:
        type = "None";
        break;
    case AmplitudeSmoothingType::MovingAverage:
        type = "MovingAverage";
        break;
    case AmplitudeSmoothingType::Median:
        type = "Median";
        break;
    case AmplitudeSmoothingType::Gaussian:
        type = "Gaussian";
        break;
    }

    if (m_settings.amplitudeSmoothing != type) {
        m_settings.amplitudeSmoothing = type;
        save();
        emit amplitudeSmoothingChanged();
    }
    LOG_DEBUG() << "Finish: setAmplitudeSmoothing";
}

int SettingsApi::amplitudeSmoothingWindowSize() const
{
    LOG_DEBUG() << "Start: amplitudeSmoothingWindowSize";
    int result = m_settings.amplitudeSmoothingWindowSize;
    LOG_DEBUG() << "Finish: amplitudeSmoothingWindowSize - result=" << result;
    return result;
}

void SettingsApi::setAmplitudeSmoothingWindowSize(
    int amplitudeSmoothingWindowSize)
{
    LOG_DEBUG() << "Start: setAmplitudeSmoothingWindowSize - "
                   "amplitudeSmoothingWindowSize="
                << amplitudeSmoothingWindowSize;
    if (m_settings.amplitudeSmoothingWindowSize != amplitudeSmoothingWindowSize) {
        m_settings.amplitudeSmoothingWindowSize = amplitudeSmoothingWindowSize;
        save();
        emit amplitudeSmoothingWindowSizeChanged();
    }
    LOG_DEBUG() << "Finish: setAmplitudeSmoothingWindowSize";
}

double SettingsApi::amplitudeGaussianSmoothingSigma() const
{
    LOG_DEBUG() << "Start: amplitudeGaussianSmoothingSigma";
    double result = m_settings.amplitudeGaussianSmoothingSigma;
    LOG_DEBUG() << "Finish: amplitudeGaussianSmoothingSigma - result=" << result;
    return result;
}

void SettingsApi::setAmplitudeGaussianSmoothingSigma(
    double amplitudeGaussianSmoothingSigma)
{
    LOG_DEBUG() << "Start: setAmplitudeGaussianSmoothingSigma - "
                   "amplitudeGaussianSmoothingSigma="
                << amplitudeGaussianSmoothingSigma;
    if (qAbs(m_settings.amplitudeGaussianSmoothingSigma - amplitudeGaussianSmoothingSigma) > 0.0001) {
        m_settings.amplitudeGaussianSmoothingSigma = amplitudeGaussianSmoothingSigma;
        save();
        emit amplitudeGaussianSmoothingSigmaChanged();
    }
    LOG_DEBUG() << "Finish: setAmplitudeGaussianSmoothingSigma";
}

bool SettingsApi::showAmplitude() const
{
    LOG_DEBUG() << "Start: showAmplitude";
    bool result = m_settings.showAmplitude;
    LOG_DEBUG() << "Finish: showAmplitude - result=" << result;
    return result;
}

bool SettingsApi::showAmplitudeDerivative() const
{
    LOG_DEBUG() << "Start: showAmplitudeDerivative";
    bool result = m_settings.showAmplitudeDerivative;
    LOG_DEBUG() << "Finish: showAmplitudeDerivative - result=" << result;
    return result;
}

bool SettingsApi::showF0() const
{
    LOG_DEBUG() << "Start: showF0";
    bool result = m_settings.showF0;
    LOG_DEBUG() << "Finish: showF0 - result=" << result;
    return result;
}

bool SettingsApi::showLogPitch() const
{
    LOG_DEBUG() << "Start: showLogPitch";
    bool result = m_settings.showLogPitch;
    LOG_DEBUG() << "Finish: showLogPitch - result=" << result;
    return result;
}

bool SettingsApi::showProcessedPitch() const
{
    LOG_DEBUG() << "Start: showProcessedPitch";
    bool result = m_settings.showProcessedPitch;
    LOG_DEBUG() << "Finish: showProcessedPitch - result=" << result;
    return result;
}

void SettingsApi::setAmplitudeWindow(int amplitudeWindow)
{
    LOG_DEBUG() << "Start: setAmplitudeWindow - amplitudeWindow="
                << amplitudeWindow;
    if (m_settings.amplitudeWindow != amplitudeWindow) {
        m_settings.amplitudeWindow = amplitudeWindow;
        save();
        emit amplitudeWindowChanged();
    }
    LOG_DEBUG() << "Finish: setAmplitudeWindow";
}

void SettingsApi::setAmplitudeShift(int amplitudeShift)
{
    LOG_DEBUG() << "Start: setAmplitudeShift - amplitudeShift=" << amplitudeShift;
    if (m_settings.amplitudeShift != amplitudeShift) {
        m_settings.amplitudeShift = amplitudeShift;
        save();
        emit amplitudeShiftChanged();
    }
    LOG_DEBUG() << "Finish: setAmplitudeShift";
}

void SettingsApi::setShowAmplitude(bool showAmplitude)
{
    LOG_DEBUG() << "Start: setShowAmplitude - showAmplitude=" << showAmplitude;
    if (m_settings.showAmplitude != showAmplitude) {
        m_settings.showAmplitude = showAmplitude;
        save();
        emit showAmplitudeChanged();
    }
    LOG_DEBUG() << "Finish: setShowAmplitude";
}

void SettingsApi::setShowAmplitudeDerivative(bool showAmplitudeDerivative)
{
    LOG_DEBUG() << "Start: setShowAmplitudeDerivative - showAmplitudeDerivative="
                << showAmplitudeDerivative;
    if (m_settings.showAmplitudeDerivative != showAmplitudeDerivative) {
        m_settings.showAmplitudeDerivative = showAmplitudeDerivative;
        save();
        emit showAmplitudeDerivativeChanged();
    }
    LOG_DEBUG() << "Finish: setShowAmplitudeDerivative";
}

void SettingsApi::setShowF0(bool showF0)
{
    LOG_DEBUG() << "Start: setShowF0 - showF0=" << showF0;
    if (m_settings.showF0 != showF0) {
        m_settings.showF0 = showF0;
        save();
        emit showF0Changed();
    }
    LOG_DEBUG() << "Finish: setShowF0";
}

void SettingsApi::setShowLogPitch(bool showLogPitch)
{
    LOG_DEBUG() << "Start: setShowLogPitch - showLogPitch=" << showLogPitch;
    if (m_settings.showLogPitch != showLogPitch) {
        m_settings.showLogPitch = showLogPitch;
        save();
        emit showLogPitchChanged();
    }
    LOG_DEBUG() << "Finish: setShowLogPitch";
}

void SettingsApi::setShowProcessedPitch(bool showProcessedPitch)
{
    LOG_DEBUG() << "Start: setShowProcessedPitch - showProcessedPitch="
                << showProcessedPitch;
    if (m_settings.showProcessedPitch != showProcessedPitch) {
        m_settings.showProcessedPitch = showProcessedPitch;
        save();
        emit showProcessedPitchChanged();
    }
    LOG_DEBUG() << "Finish: setShowProcessedPitch";
}

void SettingsApi::setPitchGaussianSmoothingSigma(
    double pitchGaussianSmoothingSigma)
{
    LOG_DEBUG()
        << "Start: setPitchGaussianSmoothingSigma - pitchGaussianSmoothingSigma="
        << pitchGaussianSmoothingSigma;
    if (qAbs(m_settings.pitchGaussianSmoothingSigma - pitchGaussianSmoothingSigma) > 0.0001) {
        m_settings.pitchGaussianSmoothingSigma = pitchGaussianSmoothingSigma;
        save();
        emit pitchGaussianSmoothingSigmaChanged();
    }
    LOG_DEBUG() << "Finish: setPitchGaussianSmoothingSigma";
}

double SettingsApi::pitchSplineSmoothingPenalty() const
{
    LOG_DEBUG() << "Start: pitchSplineSmoothingPenalty";
    double result = m_settings.pitchSplineSmoothingPenalty;
    LOG_DEBUG() << "Finish: pitchSplineSmoothingPenalty - result=" << result;
    return result;
}

void SettingsApi::setPitchSplineSmoothingPenalty(
    double pitchSplineSmoothingPenalty)
{
    LOG_DEBUG()
        << "Start: setPitchSplineSmoothingPenalty - pitchSplineSmoothingPenalty="
        << pitchSplineSmoothingPenalty;
    if (m_settings.pitchSplineSmoothingPenalty != pitchSplineSmoothingPenalty) {
        m_settings.pitchSplineSmoothingPenalty = pitchSplineSmoothingPenalty;
        save();
        emit pitchSplineSmoothingPenaltyChanged();
    }
    LOG_DEBUG() << "Finish: setPitchSplineSmoothingPenalty";
}

int SettingsApi::specFftLength() const
{
    LOG_DEBUG() << "Start: specFftLength";
    int result = m_settings.specFftLength;
    LOG_DEBUG() << "Finish: specFftLength - result=" << result;
    return result;
}

void SettingsApi::setSpecFftLength(int specFftLength)
{
    LOG_DEBUG() << "Start: setSpecFftLength - specFftLength=" << specFftLength;
    if (m_settings.specFftLength != specFftLength) {
        m_settings.specFftLength = specFftLength;
        save();
        emit specFftLengthChanged();
    }
    LOG_DEBUG() << "Finish: setSpecFftLength";
}

bool SettingsApi::specF0Refinement() const
{
    LOG_DEBUG() << "Start: specF0Refinement";
    bool result = m_settings.specF0Refinement;
    LOG_DEBUG() << "Finish: specF0Refinement - result=" << result;
    return result;
}

void SettingsApi::setSpecF0Refinement(bool specF0Refinement)
{
    LOG_DEBUG() << "Start: setSpecF0Refinement - specF0Refinement="
                << specF0Refinement;
    if (m_settings.specF0Refinement != specF0Refinement) {
        m_settings.specF0Refinement = specF0Refinement;
        save();
        emit specF0RefinementChanged();
    }
    LOG_DEBUG() << "Finish: setSpecF0Refinement";
}

bool SettingsApi::specUseLogScale() const
{
    LOG_DEBUG() << "Start: specUseLogScale";
    bool result = m_settings.specUseLogScale;
    LOG_DEBUG() << "Finish: specUseLogScale - result=" << result;
    return result;
}

void SettingsApi::setSpecUseLogScale(bool specUseLogScale)
{
    LOG_DEBUG() << "Start: setSpecUseLogScale - specUseLogScale="
                << specUseLogScale;
    if (m_settings.specUseLogScale != specUseLogScale) {
        m_settings.specUseLogScale = specUseLogScale;
        save();
        emit specUseLogScaleChanged();
    }
    LOG_DEBUG() << "Finish: setSpecUseLogScale";
}

bool SettingsApi::showSpectrum() const
{
    LOG_DEBUG() << "Start: showSpectrum";
    bool result = m_settings.showSpectrum;
    LOG_DEBUG() << "Finish: showSpectrum - result=" << result;
    return result;
}

void SettingsApi::setShowSpectrum(bool showSpectrum)
{
    LOG_DEBUG() << "Start: setShowSpectrum - showSpectrum=" << showSpectrum;
    if (m_settings.showSpectrum != showSpectrum) {
        m_settings.showSpectrum = showSpectrum;
        save();
        emit showSpectrumChanged();
    }
    LOG_DEBUG() << "Finish: setShowSpectrum";
}

bool SettingsApi::showCepstrum() const
{
    LOG_DEBUG() << "Start: showCepstrum";
    bool result = m_settings.showCepstrum;
    LOG_DEBUG() << "Finish: showCepstrum - result=" << result;
    return result;
}

void SettingsApi::setShowCepstrum(bool showCepstrum)
{
    LOG_DEBUG() << "Start: setShowCepstrum - showCepstrum=" << showCepstrum;
    if (m_settings.showCepstrum != showCepstrum) {
        m_settings.showCepstrum = showCepstrum;
        save();
        emit showCepstrumChanged();
    }
    LOG_DEBUG() << "Finish: setShowCepstrum";
}

SettingsApi::SpecColorScheme SettingsApi::specColorScheme() const
{
    LOG_DEBUG() << "Start: specColorScheme";
    SpecColorScheme result = SpecColorScheme::Viridis;
    std::string scheme = m_settings.specColorScheme;

    if (scheme == "Viridis")
        result = SpecColorScheme::Viridis;
    else if (scheme == "Plasma")
        result = SpecColorScheme::Plasma;
    else if (scheme == "Hot")
        result = SpecColorScheme::Hot;
    else if (scheme == "Cool")
        result = SpecColorScheme::Cool;

    LOG_DEBUG() << "Finish: specColorScheme - result="
                << static_cast<int>(result);
    return result;
}

void SettingsApi::setSpecColorScheme(SpecColorScheme specColorScheme)
{
    LOG_DEBUG() << "Start: setSpecColorScheme - specColorScheme="
                << static_cast<int>(specColorScheme);
    std::string scheme = "Viridis";
    switch (specColorScheme) {
    case SpecColorScheme::Viridis:
        scheme = "Viridis";
        break;
    case SpecColorScheme::Plasma:
        scheme = "Plasma";
        break;
    case SpecColorScheme::Hot:
        scheme = "Hot";
        break;
    case SpecColorScheme::Cool:
        scheme = "Cool";
        break;
    }

    if (m_settings.specColorScheme != scheme) {
        m_settings.specColorScheme = scheme;
        save();
        emit specColorSchemeChanged();
    }
    LOG_DEBUG() << "Finish: setSpecColorScheme";
}

bool SettingsApi::dpUsePitch() const { return m_settings.dpUsePitch; }
void SettingsApi::setDpUsePitch(bool val)
{
    if (m_settings.dpUsePitch != val) {
        m_settings.dpUsePitch = val;
        save();
        emit dpUsePitchChanged();
    }
}
double SettingsApi::dpPitchCoef() const { return m_settings.dpPitchCoef; }
void SettingsApi::setDpPitchCoef(double val)
{
    if (qAbs(m_settings.dpPitchCoef - val) > 0.0001) {
        m_settings.dpPitchCoef = val;
        save();
        emit dpPitchCoefChanged();
    }
}
bool SettingsApi::dpUsePitchDerivative() const { return m_settings.dpUsePitchDerivative; }
void SettingsApi::setDpUsePitchDerivative(bool val)
{
    if (m_settings.dpUsePitchDerivative != val) {
        m_settings.dpUsePitchDerivative = val;
        save();
        emit dpUsePitchDerivativeChanged();
    }
}
double SettingsApi::dpPitchDerivativeCoef() const { return m_settings.dpPitchDerivativeCoef; }
void SettingsApi::setDpPitchDerivativeCoef(double val)
{
    if (qAbs(m_settings.dpPitchDerivativeCoef - val) > 0.0001) {
        m_settings.dpPitchDerivativeCoef = val;
        save();
        emit dpPitchDerivativeCoefChanged();
    }
}
bool SettingsApi::dpUsePitchLog() const { return m_settings.dpUsePitchLog; }
void SettingsApi::setDpUsePitchLog(bool val)
{
    if (m_settings.dpUsePitchLog != val) {
        m_settings.dpUsePitchLog = val;
        save();
        emit dpUsePitchLogChanged();
    }
}
double SettingsApi::dpPitchLogCoef() const { return m_settings.dpPitchLogCoef; }
void SettingsApi::setDpPitchLogCoef(double val)
{
    if (qAbs(m_settings.dpPitchLogCoef - val) > 0.0001) {
        m_settings.dpPitchLogCoef = val;
        save();
        emit dpPitchLogCoefChanged();
    }
}
bool SettingsApi::dpUseAmplitude() const { return m_settings.dpUseAmplitude; }
void SettingsApi::setDpUseAmplitude(bool val)
{
    if (m_settings.dpUseAmplitude != val) {
        m_settings.dpUseAmplitude = val;
        save();
        emit dpUseAmplitudeChanged();
    }
}
double SettingsApi::dpAmplitudeCoef() const { return m_settings.dpAmplitudeCoef; }
void SettingsApi::setDpAmplitudeCoef(double val)
{
    if (qAbs(m_settings.dpAmplitudeCoef - val) > 0.0001) {
        m_settings.dpAmplitudeCoef = val;
        save();
        emit dpAmplitudeCoefChanged();
    }
}
bool SettingsApi::dpUseAmplitudeDerivative() const { return m_settings.dpUseAmplitudeDerivative; }
void SettingsApi::setDpUseAmplitudeDerivative(bool val)
{
    if (m_settings.dpUseAmplitudeDerivative != val) {
        m_settings.dpUseAmplitudeDerivative = val;
        save();
        emit dpUseAmplitudeDerivativeChanged();
    }
}
double SettingsApi::dpAmplitudeDerivativeCoef() const { return m_settings.dpAmplitudeDerivativeCoef; }
void SettingsApi::setDpAmplitudeDerivativeCoef(double val)
{
    if (qAbs(m_settings.dpAmplitudeDerivativeCoef - val) > 0.0001) {
        m_settings.dpAmplitudeDerivativeCoef = val;
        save();
        emit dpAmplitudeDerivativeCoefChanged();
    }
}
bool SettingsApi::dpUseSpectrum() const { return m_settings.dpUseSpectrum; }
void SettingsApi::setDpUseSpectrum(bool val)
{
    if (m_settings.dpUseSpectrum != val) {
        m_settings.dpUseSpectrum = val;
        save();
        emit dpUseSpectrumChanged();
    }
}
double SettingsApi::dpSpectrumCoef() const { return m_settings.dpSpectrumCoef; }
void SettingsApi::setDpSpectrumCoef(double val)
{
    if (qAbs(m_settings.dpSpectrumCoef - val) > 0.0001) {
        m_settings.dpSpectrumCoef = val;
        save();
        emit dpSpectrumCoefChanged();
    }
}
bool SettingsApi::dpUseCepstrum() const { return m_settings.dpUseCepstrum; }
void SettingsApi::setDpUseCepstrum(bool val)
{
    if (m_settings.dpUseCepstrum != val) {
        m_settings.dpUseCepstrum = val;
        save();
        emit dpUseCepstrumChanged();
    }
}
double SettingsApi::dpCepstrumCoef() const { return m_settings.dpCepstrumCoef; }
void SettingsApi::setDpCepstrumCoef(double val)
{
    if (qAbs(m_settings.dpCepstrumCoef - val) > 0.0001) {
        m_settings.dpCepstrumCoef = val;
        save();
        emit dpCepstrumCoefChanged();
    }
}

void SettingsApi::updateTranslator()
{
    LOG_DEBUG() << "Start: updateTranslator";
    QCoreApplication::removeTranslator(&m_translator);
    QString lang = QString::fromStdString(m_settings.language);
    if (m_translator.load("inton-trainer-2_" + lang,
            QCoreApplication::applicationDirPath())) {
        QCoreApplication::installTranslator(&m_translator);
        QQmlEngine* engine = qmlEngine(this);
        if (engine) {
            engine->retranslate();
        }
    } else {
        LOG_WARNING() << "Failed to load translation for" << lang;
    }
    LOG_DEBUG() << "Finish: updateTranslator";
}
