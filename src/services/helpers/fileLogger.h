#ifndef FILE_LOGGER_H
#define FILE_LOGGER_H

#include <string>
#include <fstream>
#include <mutex>
#include <memory>

class FileLogger {
public:
    // Get the singleton instance
    static FileLogger& getInstance() {
        static FileLogger instance;
        return instance;
    }

    // Delete copy constructor and assignment operator
    FileLogger(const FileLogger&) = delete;
    FileLogger& operator=(const FileLogger&) = delete;

    // Write a log message to the file
    void writeLog(const std::string& message) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_logFile.is_open()) {
            m_logFile << message << std::endl;
            m_logFile.flush(); // Ensure immediate write to disk
        }
    }

    // Initialize/reinitialize the logger (clears the log file)
    void initialize() {
        std::lock_guard<std::mutex> lock(m_mutex);
        
        // Close existing file if open
        if (m_logFile.is_open()) {
            m_logFile.close();
        }
        
        // Open file in truncate mode to clear it
        m_logFile.open("application.log", std::ios::out | std::ios::trunc);
    }

    ~FileLogger() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_logFile.is_open()) {
            m_logFile.close();
        }
    }

private:
    FileLogger() {
        // Open log file in truncate mode (clears existing content)
        m_logFile.open("application.log", std::ios::out | std::ios::trunc);
    }

    std::ofstream m_logFile;
    std::mutex m_mutex;
};

#endif // FILE_LOGGER_H
