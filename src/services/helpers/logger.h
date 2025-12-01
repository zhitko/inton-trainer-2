#ifndef LOGGER_H
#define LOGGER_H

#include <string>
#include <iostream>
#include <sstream>
#include <chrono>
#include <iomanip>
#include <filesystem>

class Logger {
public:
    enum class Level {
        DEBUG,
        INFO,
        WARNING,
        CRITICAL
    };

    static void log(Level level, const std::string& file, int line, const std::string& message) {
        auto now = std::chrono::system_clock::now();
        auto in_time_t = std::chrono::system_clock::to_time_t(now);
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;

        std::string levelStr;
        switch (level) {
            case Level::DEBUG: levelStr = "DEBUG"; break;
            case Level::INFO: levelStr = "INFO"; break;
            case Level::WARNING: levelStr = "WARNING"; break;
            case Level::CRITICAL: levelStr = "CRITICAL"; break;
        }
        
        // Extract filename from path
        std::filesystem::path filePath(file);
        std::string filename = filePath.filename().string();

        std::cout << std::put_time(std::localtime(&in_time_t), "%Y-%m-%d %H:%M:%S")
                  << "." << std::setfill('0') << std::setw(3) << ms.count() << " "
                  << filename << ":" << line << " "
                  << message << std::endl;
    }
};

// LogStream helper class for stream-style logging
class LogStream {
public:
    LogStream(Logger::Level level, const std::string& file, int line)
        : m_level(level), m_file(file), m_line(line) {}

    ~LogStream() {
        Logger::log(m_level, m_file, m_line, m_stream.str());
    }

    template <typename T>
    LogStream& operator<<(const T& value) {
        m_stream << value;
        return *this;
    }

private:
    Logger::Level m_level;
    std::string m_file;
    int m_line;
    std::ostringstream m_stream;
};

// Macros to make it easier to use with stream-style syntax
#define LOG_DEBUG() LogStream(Logger::Level::DEBUG, __FILE__, __LINE__)
#define LOG_INFO() LogStream(Logger::Level::INFO, __FILE__, __LINE__)
#define LOG_WARNING() LogStream(Logger::Level::WARNING, __FILE__, __LINE__)
#define LOG_CRITICAL() LogStream(Logger::Level::CRITICAL, __FILE__, __LINE__)

#endif // LOGGER_H
