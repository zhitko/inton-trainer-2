#include <QGuiApplication>
#include <QQmlApplicationEngine>

// APIS
#include "audioapi.h"
#include "fileapi.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<AudioAPI>("by.intontrainer.audio", 1, 0, "AudioAPI");
    qmlRegisterType<FileApi>("by.intontrainer.file", 1, 0, "FileApi");

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
