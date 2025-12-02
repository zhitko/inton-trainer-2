#ifndef QMLLOGGER_H
#define QMLLOGGER_H

#include <QObject>
#include <QString>
#include <QQmlEngine>

class QmlLogger : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static QmlLogger* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine) {
        Q_UNUSED(qmlEngine)
        Q_UNUSED(jsEngine)
        return new QmlLogger();
    }

    explicit QmlLogger(QObject *parent = nullptr) : QObject(parent) {}

public slots:
    Q_INVOKABLE void debug(const QString& message, const QString& file, int line, const QString& function);
    Q_INVOKABLE void info(const QString& message, const QString& file, int line, const QString& function);
    Q_INVOKABLE void warning(const QString& message, const QString& file, int line, const QString& function);
    Q_INVOKABLE void critical(const QString& message, const QString& file, int line, const QString& function);
};

#endif // QMLLOGGER_H
