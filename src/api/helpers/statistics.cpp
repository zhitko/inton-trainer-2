#include "statistics.h"

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <algorithm>
#include <functional>
#include <numeric>

#include "logger.h"
#include "settings.h"

// Helper function to normalize path separators to forward slashes
static std::string normalizePath(const std::string& path) {
    std::string normalized;
    for (char c : path) {
        if (c == '\\') {
            normalized += '/';
        } else {
            normalized += c;
        }
    }
    return normalized;
}

// Static member initialization
UserStatistics Statistics::cachedStatistics;
bool Statistics::statisticsLoaded = false;

QString
Statistics::getStatisticsFilePath()
{
#ifdef Q_OS_ANDROID
    QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/statistics.json";
    QDir().mkpath(QFileInfo(path).absolutePath());
    return path;
#else
    QString path = QCoreApplication::applicationDirPath() + "/statistics.json";
    return path;
#endif
}

static QJsonObject itemToJson(const std::shared_ptr<StatisticsItem>& item)
{
    QJsonObject obj;
    obj["type"] = item->type == StatisticsItem::File ? "file" : "folder";
    obj["name"] = QString::fromStdString(item->name);
    obj["avg_result"] = item->avgResult;
    obj["best_result"] = item->bestResult;

    if (item->type == StatisticsItem::Folder) {
        obj["completeness"] = item->completeness;
        obj["total_files"] = item->totalFiles;
        obj["processed_files"] = item->processedFiles;
        QJsonArray itemsArray;
        for (const auto& child : item->items) {
            itemsArray.append(itemToJson(child));
        }
        obj["items"] = itemsArray;
    } else {
        QJsonArray resultsArray;
        for (double result : item->results) {
            resultsArray.append(result);
        }
        obj["results"] = resultsArray;
    }

    return obj;
}

static std::shared_ptr<StatisticsItem> jsonToItem(const QJsonObject& obj)
{
    QString typeStr = obj["type"].toString();
    StatisticsItem::Type type = typeStr == "file" ? StatisticsItem::File : StatisticsItem::Folder;
    auto item = std::make_shared<StatisticsItem>(type, obj["name"].toString().toStdString());
    item->avgResult = obj["avg_result"].toDouble();
    item->bestResult = obj["best_result"].toDouble();

    if (type == StatisticsItem::Folder) {
        item->completeness = obj["completeness"].toDouble();
        item->totalFiles = obj["total_files"].toInt();
        item->processedFiles = obj["processed_files"].toInt();
        QJsonArray itemsArray = obj["items"].toArray();
        for (const QJsonValue& val : itemsArray) {
            item->items.push_back(jsonToItem(val.toObject()));
        }
    } else {
        QJsonArray resultsArray = obj["results"].toArray();
        for (const QJsonValue& val : resultsArray) {
            item->results.push_back(val.toDouble());
        }
    }

    return item;
}

UserStatistics
Statistics::loadStatistics()
{
    UserStatistics statistics;
    QString filePath = getStatisticsFilePath();

    QFileInfo fileInfo(filePath);
    QString absolutePath = fileInfo.absoluteFilePath();

    QFile file(absolutePath);
    if (!file.open(QIODevice::ReadOnly)) {
        LOG_INFO() << "Statistics file not found, initializing from disk";

        QString appDir = Settings::getAppDataDir();
        QString patternsDir = appDir + "/data/patterns";

        if (QDir(patternsDir).exists()) {
            LOG_INFO() << "Initializing statistics from patterns directory:" << patternsDir;

            // Clear current statistics
            cachedStatistics.items.clear();

            QDirIterator it(patternsDir, QStringList() << "*.wav", QDir::Files, QDirIterator::Subdirectories);
            while (it.hasNext()) {
                QString fullPath = it.next();
                QString relPath = QDir(appDir).relativeFilePath(fullPath);
                findOrCreateItem(relPath.toStdString(), true);
            }

            // Recursive function to update completeness and stats for all folders
            std::function<void(const std::shared_ptr<StatisticsItem>&, const std::string&)> updateAllFolderStats =
                [&](const std::shared_ptr<StatisticsItem>& item, const std::string& currentPath) {
                    if (item->type == StatisticsItem::Folder) {
                        std::string itemPath = currentPath.empty() ? item->name : currentPath + "/" + item->name;
                        for (auto& child : item->items) {
                            updateAllFolderStats(child, itemPath);
                        }
                        // Use calculateCompleteness to populate totalFiles and processedFiles
                        // We pass the full disk path to ensure it correctly identifies the folder for counting
                        QString folderDiskPath = QDir(appDir).absoluteFilePath(QString::fromStdString(itemPath));
                        item->completeness = calculateCompleteness(item, folderDiskPath.toStdString());
                        item->avgResult = calculateAverage(item);
                    }
                };

            for (auto& item : cachedStatistics.items) {
                updateAllFolderStats(item, "");
            }

            saveStatistics(cachedStatistics);
            return cachedStatistics;
        }

        return statistics;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        LOG_WARNING() << "Invalid statistics JSON format";
        return statistics;
    }

    QJsonObject root = doc.object();
    QJsonArray itemsArray = root["items"].toArray();

    for (const QJsonValue& val : itemsArray) {
        statistics.items.push_back(jsonToItem(val.toObject()));
    }

    // Load history entries at root level
    if (root.contains("history")) {
        QJsonArray historyArray = root["history"].toArray();
        for (const QJsonValue& val : historyArray) {
            QJsonObject historyObj = val.toObject();
            // Normalize paths to use forward slashes for cross-platform consistency
            std::string normalizedUserPath = normalizePath(historyObj["userRecordPath"].toString().toStdString());
            std::string normalizedPatternPath = normalizePath(historyObj["patternPath"].toString().toStdString());
            HistoryEntry entry(
                normalizedUserPath,
                normalizedPatternPath,
                historyObj["result"].toDouble()
            );
            entry.date = historyObj["date"].toString().toStdString();
            statistics.history.push_back(entry);
        }
    }

    LOG_INFO() << "Loaded statistics from:" << absolutePath;
    return statistics;
}

void Statistics::saveStatistics(const UserStatistics& statistics)
{
    QString filePath = getStatisticsFilePath();

    QFileInfo fileInfo(filePath);
    QString absolutePath = fileInfo.absoluteFilePath();

    QJsonObject root;
    QJsonArray itemsArray;

    for (const auto& item : statistics.items) {
        itemsArray.append(itemToJson(item));
    }

    root["items"] = itemsArray;

    // Save history entries at root level
    QJsonArray historyArray;
    for (const auto& entry : statistics.history) {
        QJsonObject historyObj;
        historyObj["userRecordPath"] = QString::fromStdString(entry.userRecordPath);
        historyObj["patternPath"] = QString::fromStdString(entry.patternPath);
        historyObj["result"] = entry.result;
        historyObj["date"] = QString::fromStdString(entry.date);
        historyArray.append(historyObj);
    }
    root["history"] = historyArray;

    QJsonDocument doc(root);
    QFile file(absolutePath);

    if (!file.open(QIODevice::WriteOnly)) {
        LOG_WARNING() << "Failed to open statistics file for writing:" << absolutePath;
        return;
    }

    file.write(doc.toJson());
    file.close();

    LOG_INFO() << "Saved statistics to:" << absolutePath;
}

void Statistics::reloadStatistics()
{
    cachedStatistics = UserStatistics();
    statisticsLoaded = false;
    LOG_INFO() << "Statistics cache cleared, will reload on next access";
}

std::shared_ptr<StatisticsItem> Statistics::findOrCreateItem(const std::string& path, bool create)
{
    // Split path into components
    std::vector<std::string> components;
    std::string current;
    for (char c : path) {
        if (c == '/' || c == '\\') {
            if (!current.empty()) {
                components.push_back(current);
                current.clear();
            }
        } else {
            current += c;
        }
    }
    if (!current.empty()) {
        components.push_back(current);
    }

    if (components.empty()) {
        return nullptr;
    }

    // Navigate/create hierarchy
    std::vector<std::shared_ptr<StatisticsItem>>* currentLevel = &cachedStatistics.items;

    for (size_t i = 0; i < components.size(); ++i) {
        const std::string& component = components[i];
        bool isLast = (i == components.size() - 1);

        // Find existing item
        auto it = std::find_if(currentLevel->begin(), currentLevel->end(),
            [&component](const std::shared_ptr<StatisticsItem>& item) {
                return item->name == component;
            });

        if (it != currentLevel->end()) {
            if (isLast) {
                return *it;
            }
            currentLevel = &(*it)->items;
        } else if (create) {
            // Create new item
            StatisticsItem::Type type = isLast ? StatisticsItem::File : StatisticsItem::Folder;
            auto newItem = std::make_shared<StatisticsItem>(type, component);
            currentLevel->push_back(newItem);

            if (isLast) {
                return newItem;
            }
            currentLevel = &newItem->items;
        } else {
            return nullptr;
        }
    }

    return nullptr;
}

double Statistics::calculateCompleteness(const std::shared_ptr<StatisticsItem>& item, const std::string& folderPath)
{
    if (!item || item->type != StatisticsItem::Folder) {
        return 0.0;
    }

    if (item->items.empty()) {
        return 0.0;
    }

    // Count files with results
    int filesWithResults = 0;

    std::function<void(const std::shared_ptr<StatisticsItem>&)> countFilesWithResults =
        [&](const std::shared_ptr<StatisticsItem>& i) {
            if (i->type == StatisticsItem::File) {
                if (!i->results.empty()) {
                    filesWithResults++;
                }
            } else {
                for (const auto& child : i->items) {
                    countFilesWithResults(child);
                }
            }
        };

    for (const auto& child : item->items) {
        countFilesWithResults(child);
    }

    // Get total files from file system if folderPath is provided
    int totalFiles = 0;
    if (!folderPath.empty()) {
        // Count all .wav files in the folder recursively
        std::function<void(const QString&)> countWavFiles =
            [&](const QString& path) {
                QDir dir(path);
                QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
                for (const QFileInfo& entry : entries) {
                    if (entry.isFile() && entry.suffix().toLower() == "wav") {
                        totalFiles++;
                    } else if (entry.isDir()) {
                        countWavFiles(entry.absoluteFilePath());
                    }
                }
            };

        countWavFiles(QString::fromStdString(folderPath));
    } else {
        // Fallback: count files from statistics tree
        std::function<void(const std::shared_ptr<StatisticsItem>&)> countAllFiles =
            [&](const std::shared_ptr<StatisticsItem>& i) {
                if (i->type == StatisticsItem::File) {
                    totalFiles++;
                } else {
                    for (const auto& child : i->items) {
                        countAllFiles(child);
                    }
                }
            };

        for (const auto& child : item->items) {
            countAllFiles(child);
        }
    }

    item->processedFiles = filesWithResults;
    item->totalFiles = totalFiles;

    if (totalFiles == 0) {
        return 0.0;
    }

    return static_cast<double>(filesWithResults) / totalFiles * 100.0;
}

double Statistics::calculateAverage(const std::shared_ptr<StatisticsItem>& item)
{
    if (!item) {
        return 0.0;
    }

    if (item->type == StatisticsItem::File) {
        if (item->results.empty()) {
            return 0.0;
        }
        double sum = std::accumulate(item->results.begin(), item->results.end(), 0.0);
        return sum / item->results.size();
    } else {
        // For folders, calculate average of all nested results
        std::vector<double> allResults;
        std::function<void(const std::shared_ptr<StatisticsItem>&)> collectResults =
            [&](const std::shared_ptr<StatisticsItem>& i) {
                if (i->type == StatisticsItem::File) {
                    allResults.insert(allResults.end(), i->results.begin(), i->results.end());
                } else {
                    for (const auto& child : i->items) {
                        collectResults(child);
                    }
                }
            };

        for (const auto& child : item->items) {
            collectResults(child);
        }

        if (allResults.empty()) {
            return 0.0;
        }
        double sum = std::accumulate(allResults.begin(), allResults.end(), 0.0);
        return sum / allResults.size();
    }
}

double Statistics::calculateAverageBest(const std::shared_ptr<StatisticsItem>& item)
{
    if (!item) {
        return 0.0;
    }

    if (item->type == StatisticsItem::File) {
        return item->bestResult;
    } else {
        // For folders, calculate average of bestResult of all nested files
        std::vector<double> allBestResults;
        std::function<void(const std::shared_ptr<StatisticsItem>&)> collectBestResults =
            [&](const std::shared_ptr<StatisticsItem>& i) {
                if (i->type == StatisticsItem::File) {
                    if (i->bestResult > 0.0) {
                        allBestResults.push_back(i->bestResult);
                    }
                } else {
                    for (const auto& child : i->items) {
                        collectBestResults(child);
                    }
                }
            };

        for (const auto& child : item->items) {
            collectBestResults(child);
        }

        if (allBestResults.empty()) {
            return 0.0;
        }
        double sum = std::accumulate(allBestResults.begin(), allBestResults.end(), 0.0);
        return sum / allBestResults.size();
    }
}

void Statistics::registerResult(const std::string& filePath, double result)
{
    // Load current statistics if not already loaded
    if (!statisticsLoaded) {
        cachedStatistics = loadStatistics();
        statisticsLoaded = true;
    }

    // Find or create the file item
    auto fileItem = findOrCreateItem(filePath, true);
    if (!fileItem) {
        LOG_WARNING() << "Failed to create statistics item for:" << QString::fromStdString(filePath);
        return;
    }

    // Add result and keep only last 5
    fileItem->results.push_back(result);
    if (fileItem->results.size() > 5) {
        fileItem->results.erase(fileItem->results.begin());
    }
    fileItem->avgResult = calculateAverage(fileItem);
    fileItem->bestResult = std::max(fileItem->bestResult, result);

    // Update parent folder averages and completeness
    std::string path = filePath;
    while (true) {
        size_t lastSep = path.find_last_of("/\\");
        if (lastSep == std::string::npos) {
            break;
        }
        path = path.substr(0, lastSep);
        auto folderItem = findOrCreateItem(path, false);
        if (folderItem) {
            folderItem->avgResult = calculateAverage(folderItem);
            folderItem->completeness = calculateCompleteness(folderItem, path);
        }
    }

    // Save updated statistics
    saveStatistics(cachedStatistics);

    LOG_INFO() << "Registered result for file:" << QString::fromStdString(filePath)
               << "Result:" << result;
}

double Statistics::getAvgResultForFile(const std::string& filePath)
{
    // Load current statistics if not already loaded
    if (!statisticsLoaded) {
        cachedStatistics = loadStatistics();
        statisticsLoaded = true;
    }

    auto fileItem = findOrCreateItem(filePath, false);
    if (!fileItem) {
        return 0.0;
    }

    return fileItem->avgResult;
}

double Statistics::getBestResultForFile(const std::string& filePath)
{
    // Load current statistics if not already loaded
    if (!statisticsLoaded) {
        cachedStatistics = loadStatistics();
        statisticsLoaded = true;
    }

    auto fileItem = findOrCreateItem(filePath, false);
    if (!fileItem) {
        return 0.0;
    }

    if (fileItem->bestResult == 0.0 && !fileItem->results.empty()) {
        fileItem->bestResult = *std::max_element(fileItem->results.begin(), fileItem->results.end());
    }

    return fileItem->bestResult;
}

std::vector<double> Statistics::getResultsForFile(const std::string& filePath)
{
    // Load current statistics if not already loaded
    if (!statisticsLoaded) {
        cachedStatistics = loadStatistics();
        statisticsLoaded = true;
    }

    auto fileItem = findOrCreateItem(filePath, false);
    if (!fileItem) {
        return {};
    }

    return fileItem->results;
}

std::map<std::string, double> Statistics::getAvgResultForFolder(const std::string& folderPath)
{
    // Load current statistics if not already loaded
    if (!statisticsLoaded) {
        cachedStatistics = loadStatistics();
        statisticsLoaded = true;
    }

    std::map<std::string, double> result;
    auto folderItem = findOrCreateItem(folderPath, false);
    if (!folderItem) {
        result["avgResult"] = 0.0;
        result["avgBestResult"] = 0.0;
        result["completeness"] = 0.0;
        result["totalFiles"] = 0.0;
        result["processedFiles"] = 0.0;
        return result;
    }

    // Update stats to ensure they are fresh
    folderItem->avgResult = calculateAverage(folderItem);
    double avgBest = calculateAverageBest(folderItem);
    folderItem->completeness = calculateCompleteness(folderItem, folderPath);

    result["avgResult"] = folderItem->avgResult;
    result["avgBestResult"] = avgBest;
    result["completeness"] = folderItem->completeness;
    result["totalFiles"] = static_cast<double>(folderItem->totalFiles);
    result["processedFiles"] = static_cast<double>(folderItem->processedFiles);
    return result;
}

std::map<std::string, double> Statistics::getOverallStatistics()
{
    // Load current statistics if not already loaded
    if (!statisticsLoaded) {
        cachedStatistics = loadStatistics();
        statisticsLoaded = true;
    }

    std::map<std::string, double> stats;

    std::vector<double> allResults;
    int filesCount = 0;
    int filesWithResults = 0;
    int totalFiles = 0;
    int wellTrainedFiles = 0;

    // Collect all results recursively
    std::function<void(const std::shared_ptr<StatisticsItem>&)> collectResults =
        [&](const std::shared_ptr<StatisticsItem>& item) {
            if (item->type == StatisticsItem::File) {
                totalFiles++;
                if (!item->results.empty()) {
                    filesCount++;
                    filesWithResults++;
                    allResults.insert(allResults.end(), item->results.begin(), item->results.end());
                    if (item->bestResult >= 80.0) {
                        wellTrainedFiles++;
                    }
                }
            } else {
                for (const auto& child : item->items) {
                    collectResults(child);
                }
            }
        };

    for (const auto& item : cachedStatistics.items) {
        collectResults(item);
    }

    double sum = std::accumulate(allResults.begin(), allResults.end(), 0.0);
    double avgResult = allResults.empty() ? 0.0 : sum / allResults.size();
    double completeness = totalFiles > 0 ? static_cast<double>(filesWithResults) / totalFiles : 0.0;

    stats["avgResult"] = avgResult;
    stats["totalResults"] = static_cast<double>(allResults.size());
    stats["filesCount"] = static_cast<double>(filesCount);
    stats["processedFiles"] = static_cast<double>(filesCount);
    stats["totalFiles"] = static_cast<double>(totalFiles);
    stats["wellTrainedFiles"] = static_cast<double>(wellTrainedFiles);
    stats["completeness"] = completeness * 100.0;

    return stats;
}

void Statistics::registerHistoryEntry(const std::string& userRecordPath, const std::string& patternPath, double result)
{
    // Load current statistics if not already loaded
    if (!statisticsLoaded) {
        cachedStatistics = loadStatistics();
        statisticsLoaded = true;
    }

    // Normalize paths to use forward slashes for cross-platform consistency
    std::string normalizedUserPath = normalizePath(userRecordPath);
    std::string normalizedPatternPath = normalizePath(patternPath);

    // Create history entry with normalized paths
    HistoryEntry entry(normalizedUserPath, normalizedPatternPath, result);

    // Add history entry to root-level history
    cachedStatistics.history.push_back(entry);

    // Save updated statistics
    saveStatistics(cachedStatistics);

    LOG_INFO() << "Registered history entry for user record:" << QString::fromStdString(normalizedUserPath)
               << "Pattern:" << QString::fromStdString(normalizedPatternPath) << "Result:" << result;
}

std::vector<HistoryEntry> Statistics::getAllHistory()
{
    // Load current statistics if not already loaded
    if (!statisticsLoaded) {
        cachedStatistics = loadStatistics();
        statisticsLoaded = true;
    }

    // Return history from root level
    return cachedStatistics.history;
}

void Statistics::clearAllStatistics()
{
    // Reinitialize statistics from patterns directory instead of just clearing
    QString appDir = Settings::getAppDataDir();
    QString patternsDir = QDir(appDir).filePath("data/patterns");
    
    // Check if patterns directory exists
    if (!QDir(patternsDir).exists()) {
        LOG_WARNING() << "Patterns directory does not exist, cannot reinitialize statistics";
        cachedStatistics = UserStatistics();
        statisticsLoaded = true;
        saveStatistics(cachedStatistics);
        return;
    }
    
    LOG_INFO() << "Reinitializing statistics from patterns directory:" << patternsDir;
    
    // Clear current statistics but keep history cleared
    cachedStatistics.items.clear();
    cachedStatistics.history.clear();
    
    // Create all items from patterns directory
    QDirIterator it(patternsDir, QStringList() << "*.wav", QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        QString fullPath = it.next();
        QString relPath = QDir(appDir).relativeFilePath(fullPath);
        findOrCreateItem(relPath.toStdString(), true);
    }
    
    // Recursive function to update completeness and stats for all folders
    std::function<void(const std::shared_ptr<StatisticsItem>&, const std::string&)> updateAllFolderStats =
        [&](const std::shared_ptr<StatisticsItem>& item, const std::string& currentPath) {
            if (item->type == StatisticsItem::Folder) {
                std::string itemPath = currentPath.empty() ? item->name : currentPath + "/" + item->name;
                for (auto& child : item->items) {
                    updateAllFolderStats(child, itemPath);
                }
                // Use calculateCompleteness to populate totalFiles and processedFiles
                QString folderDiskPath = QDir(appDir).absoluteFilePath(QString::fromStdString(itemPath));
                item->completeness = calculateCompleteness(item, folderDiskPath.toStdString());
                item->avgResult = calculateAverage(item);
            }
        };
    
    for (auto& item : cachedStatistics.items) {
        updateAllFolderStats(item, "");
    }
    
    statisticsLoaded = true;
    saveStatistics(cachedStatistics);
    LOG_INFO() << "Cleared all statistics and reinitialized from patterns";
}

void Statistics::removeHistoryEntry(const std::string& userRecordPath)
{
    // Load current statistics if not already loaded
    if (!statisticsLoaded) {
        cachedStatistics = loadStatistics();
        statisticsLoaded = true;
    }

    // Normalize path for comparison
    std::string normalizedPath = normalizePath(userRecordPath);

    // Remove history entry with matching userRecordPath
    auto& history = cachedStatistics.history;
    history.erase(
        std::remove_if(history.begin(), history.end(),
            [&normalizedPath](const HistoryEntry& entry) {
                return entry.userRecordPath == normalizedPath;
            }),
        history.end()
    );

    // Save updated statistics
    saveStatistics(cachedStatistics);

    LOG_INFO() << "Removed history entry for user record:" << QString::fromStdString(userRecordPath);
}
