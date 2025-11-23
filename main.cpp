#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFontDatabase>

// APIS
#include "audioapi.h"
#include "fileapi.h"
#include "wavfileapi.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<AudioApi>("by.intontrainer.audio", 1, 0, "AudioApi");
    qmlRegisterType<FileApi>("by.intontrainer.file", 1, 0, "FileApi");
    qmlRegisterType<WavFileApi>("by.intontrainer.wavfile", 1, 0, "WavFileApi");

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
