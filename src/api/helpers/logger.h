#ifndef API_LOGGER_H
#define API_LOGGER_H

#include <QDebug>
#include <QDateTime>
#include <QString>
#include <QFileInfo>
#include "../services/helpers/fileLogger.h"

class QtLogger {
public:
    enum class Level {
        DEBUG,
        INFO,
        WARNING,
        CRITICAL
    };

    static QString formatPrefix(const QString& file, int line, const QString& function) {
        // Get current timestamp with milliseconds
        QDateTime now = QDateTime::currentDateTime();
        QString timestamp = now.toString("yyyy-MM-dd hh:mm:ss.zzz");
        
        // Extract filename from full path
        QFileInfo fileInfo(file);
        QString filename = fileInfo.fileName();
        
        // Format: "timestamp filename:line:function"
        return QString("%1 %2:%3 [%4]").arg(timestamp).arg(filename).arg(line).arg(function);
    }

    static QtMsgType levelToMsgType(Level level) {
        switch (level) {
            case Level::DEBUG: return QtDebugMsg;
            case Level::INFO: return QtInfoMsg;
            case Level::WARNING: return QtWarningMsg;
            case Level::CRITICAL: return QtCriticalMsg;
        }
        return QtDebugMsg;
    }
};

// QtLogStream helper class for stream-style logging with Qt
class QtLogStream {
public:
    QtLogStream(QtLogger::Level level, const QString& file, int line, const QString& function)
        : m_level(level), m_file(file), m_line(line), m_function(function) {}

    ~QtLogStream() {
        QString prefix = QtLogger::formatPrefix(m_file, m_line, m_function);
        QString fullMessage = QString("%1 %2").arg(prefix).arg(m_message);
        
        // Write to console
        switch (m_level) {
            case QtLogger::Level::DEBUG:
                qDebug().noquote() << fullMessage;
                break;
            case QtLogger::Level::INFO:
                qInfo().noquote() << fullMessage;
                break;
            case QtLogger::Level::WARNING:
                qWarning().noquote() << fullMessage;
                break;
            case QtLogger::Level::CRITICAL:
                qCritical().noquote() << fullMessage;
                break;
        }
        
        // Write to file
        FileLogger::getInstance().writeLog(fullMessage.toStdString());
    }

    template <typename T>
    QtLogStream& operator<<(const T& value) {
        if (!m_message.isEmpty()) {
            m_message += " ";
        }
        
        // Convert to QString for accumulation
        QDebug debug(&m_message);
        debug.nospace() << value;
        
        return *this;
    }

private:
    QtLogger::Level m_level;
    QString m_file;
    int m_line;
    QString m_function;
    QString m_message;
};

// Macros to make it easier to use with stream-style syntax
#define LOG_DEBUG() QtLogStream(QtLogger::Level::DEBUG, __FILE__, __LINE__, __FUNCTION__)
#define LOG_INFO() QtLogStream(QtLogger::Level::INFO, __FILE__, __LINE__, __FUNCTION__)
#define LOG_WARNING() QtLogStream(QtLogger::Level::WARNING, __FILE__, __LINE__, __FUNCTION__)
#define LOG_CRITICAL() QtLogStream(QtLogger::Level::CRITICAL, __FILE__, __LINE__, __FUNCTION__)

#endif // API_LOGGER_H
