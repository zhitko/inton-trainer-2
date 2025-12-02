#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFontDatabase>

// APIS
#include "audioapi.h"
#include "fileapi.h"
#include "wavfileapi.h"
#include "src/api/settingsapi.h"

// Logging
#include "src/services/helpers/fileLogger.h"

int main(int argc, char *argv[])
{
    // Initialize file logger (clears the log file)
    FileLogger::getInstance().initialize();
    
    QGuiApplication app(argc, argv);

    qmlRegisterType<AudioApi>("by.intontrainer.audio", 1, 0, "AudioApi");
    qmlRegisterType<FileApi>("by.intontrainer.file", 1, 0, "FileApi");
    qmlRegisterType<WavFileApi>("by.intontrainer.wavfile", 1, 0, "WavFileApi");
    qmlRegisterType<SettingsApi>("by.intontrainer.settings", 1, 0, "SettingsApi");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("inton-trainer-2", "Main");

    return app.exec();
}
