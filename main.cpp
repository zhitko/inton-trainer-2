#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QStringList>
#include <QtQml>

// APIS
#include "analysisapi.h"
#include "audioapi.h"
#include "fileapi.h"
#include "settingsapi.h"
#include "statisticsapi.h"
#include "wavfileapi.h"

// Logging
#include "qmllogger.h"
#include "src/services/helpers/fileLogger.h"

int main(int argc, char* argv[])
{
    // Initialize file logger (clears the log file)
    FileLogger::getInstance().initialize();

    QGuiApplication app(argc, argv);

    // Explicitly load fonts from resources to ensure they are available on all platforms (especially Windows)
    // These paths match the structure defined in qt_add_qml_module RESOURCES
    const QStringList fontPaths = {
        QString::fromLatin1(":/qt/qml/inton-trainer-2/res/fonts/fa-brands-400.ttf"),
        QString::fromLatin1(":/qt/qml/inton-trainer-2/res/fonts/fa-regular-400.ttf"),
        QString::fromLatin1(":/qt/qml/inton-trainer-2/res/fonts/fa-solid-900.ttf")
    };

    for (const QString& path : fontPaths) {
        if (QFontDatabase::addApplicationFont(path) == -1) {
            // Fallback if prefixing is different (e.g. no /qt/qml prefix)
            QString fallbackPath = path;
            fallbackPath.replace(QLatin1String(":/qt/qml/"), QLatin1String(":/"));
            if (QFontDatabase::addApplicationFont(fallbackPath) == -1) {
                // Second fallback for direct res path
                QString secondFallback = QLatin1String(":/res/fonts/") + path.section(QLatin1Char('/'), -1);
                QFontDatabase::addApplicationFont(secondFallback);
            }
        }
    }

    qmlRegisterType<AudioApi>("by.intontrainer.audio", 1, 0, "AudioApi");
    qmlRegisterType<FileApi>("by.intontrainer.file", 1, 0, "FileApi");
    qmlRegisterType<WavFileApi>("by.intontrainer.wavfile", 1, 0, "WavFileApi");
    qmlRegisterType<AnalysisApi>("by.intontrainer.analysis", 1, 0, "AnalysisApi");
    qmlRegisterType<SettingsApi>("by.intontrainer.settings", 1, 0, "SettingsApi");
    qmlRegisterType<StatisticsApi>("by.intontrainer.statistics", 1, 0, "StatisticsApi");
    qmlRegisterSingletonType<QmlLogger>("by.intontrainer.logger", 1, 0, "QmlLogger", &QmlLogger::create);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule(QLatin1String("inton-trainer-2"), QLatin1String("Main"));

    return app.exec();
}
