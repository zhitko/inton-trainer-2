#include "statisticsapi.h"

#include <QCoreApplication>
#include <QFileInfo>

StatisticsApi::StatisticsApi(QObject* parent)
    : QObject(parent)
{
}

static QString removeApplicationPath(const QString& filePath)
{
    QString appPath = QCoreApplication::applicationDirPath();
    QString normalizedPath = filePath;
    
    // Remove application path prefix if present
    if (normalizedPath.startsWith(appPath)) {
        normalizedPath = normalizedPath.mid(appPath.length());
        // Remove leading slash if present
        if (normalizedPath.startsWith(QLatin1Char('/'))) {
            normalizedPath = normalizedPath.mid(1);
        }
    }
    
    return normalizedPath;
}

void StatisticsApi::registerResult(const QString& filePath, double result)
{
    QString relativePath = removeApplicationPath(filePath);
    Statistics::registerResult(relativePath.toStdString(), result);
    emit resultRegistered(filePath, result);
    emit statisticsUpdated();
}

double StatisticsApi::getAvgResultForFile(const QString& filePath)
{
    QString relativePath = removeApplicationPath(filePath);
    return Statistics::getAvgResultForFile(relativePath.toStdString());
}

QVariantMap StatisticsApi::getAvgResultForFolder(const QString& folderPath)
{
    QString relativePath = removeApplicationPath(folderPath);
    std::map<std::string, double> stats = Statistics::getAvgResultForFolder(relativePath.toStdString());
    QVariantMap result;
    
    for (const auto& pair : stats) {
        result[QString::fromStdString(pair.first)] = pair.second;
    }
    
    return result;
}

QVariantMap StatisticsApi::getOverallStatistics()
{
    std::map<std::string, double> stats = Statistics::getOverallStatistics();
    QVariantMap result;
    
    for (const auto& pair : stats) {
        result[QString::fromStdString(pair.first)] = pair.second;
    }
    
    return result;
}

void StatisticsApi::reloadStatistics()
{
    Statistics::reloadStatistics();
    emit statisticsUpdated();
}
