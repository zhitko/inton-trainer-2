#include "statisticsapi.h"
#include "helpers/settings.h"

#include <QCoreApplication>
#include <QFileInfo>

StatisticsApi::StatisticsApi(QObject* parent)
    : QObject(parent)
{
}

static QString removeApplicationPath(const QString& filePath)
{
    QString appPath = Settings::getAppDataDir();
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

double StatisticsApi::getBestResultForFile(const QString& filePath)
{
    QString relativePath = removeApplicationPath(filePath);
    return Statistics::getBestResultForFile(relativePath.toStdString());
}

QVariantList StatisticsApi::getResultsForFile(const QString& filePath)
{
    QString relativePath = removeApplicationPath(filePath);
    const std::vector<double> results = Statistics::getResultsForFile(relativePath.toStdString());

    QVariantList out;
    for (double value : results) {
        out.push_back(value);
    }

    return out;
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

void StatisticsApi::registerHistoryEntry(const QString& userRecordPath, const QString& patternPath, double result)
{
    QString relativeUserPath = removeApplicationPath(userRecordPath);
    QString relativePatternPath = removeApplicationPath(patternPath);
    Statistics::registerHistoryEntry(relativeUserPath.toStdString(), relativePatternPath.toStdString(), result);
    emit statisticsUpdated();
}

QVariantList StatisticsApi::getAllHistory()
{
    std::vector<HistoryEntry> history = Statistics::getAllHistory();
    QVariantList out;

    for (const auto& entry : history) {
        QVariantMap map;
        map["userRecordPath"] = QString::fromStdString(entry.userRecordPath);
        map["patternPath"] = QString::fromStdString(entry.patternPath);
        map["result"] = entry.result;
        map["date"] = QString::fromStdString(entry.date);
        out.push_back(map);
    }

    return out;
}

void StatisticsApi::clearAllStatistics()
{
    Statistics::clearAllStatistics();
    emit statisticsUpdated();
}

void StatisticsApi::removeHistoryEntry(const QString& userRecordPath)
{
    QString relativePath = removeApplicationPath(userRecordPath);
    Statistics::removeHistoryEntry(relativePath.toStdString());
    emit statisticsUpdated();
}
