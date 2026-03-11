#ifndef STATISTICSAPI_H
#define STATISTICSAPI_H

#include "src/api/helpers/statistics.h"
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

/**
 * StatisticsApi class provides QML-accessible methods for managing user training
 * statistics. It allows registering training results, retrieving average results
 * for files and folders, and getting overall user statistics. The class emits
 * signals when statistics are updated to notify the UI.
 */
class StatisticsApi : public QObject {
    Q_OBJECT

public:
    explicit StatisticsApi(QObject* parent = nullptr);

    /**
     * Registers a new training result for a specific file.
     * Emits resultRegistered signal after successful registration.
     *
     * @param filePath The path to the training file.
     * @param result The training result (score) as a double.
     */
    Q_INVOKABLE void registerResult(const QString& filePath, double result);

    /**
     * Gets the average result for a specific file.
     *
     * @param filePath The path to the training file.
     * @return The average result for the file, or 0.0 if no results exist.
     */
    Q_INVOKABLE double getAvgResultForFile(const QString& filePath);

    /**
     * Gets the best result for a specific file.
     *
     * @param filePath The path to the training file.
     * @return The best result for the file, or 0.0 if no results exist.
     */
    Q_INVOKABLE double getBestResultForFile(const QString& filePath);

    /**
     * Gets recent raw results for a specific file (oldest to newest).
     *
     * @param filePath The path to the training file.
     * @return A QVariantList of double values.
     */
    Q_INVOKABLE QVariantList getResultsForFile(const QString& filePath);

    /**
     * Gets the average result and completeness for all files in a specific folder.
     *
     * @param folderPath The path to the folder.
     * @return A QVariantMap containing "avgResult" and "completeness" values.
     */
    Q_INVOKABLE QVariantMap getAvgResultForFolder(const QString& folderPath);

    /**
     * Gets overall user statistics (average of all results).
     *
     * @return A QVariantMap containing overall statistics with keys like "avgResult", "totalResults", "filesCount".
     */
    Q_INVOKABLE QVariantMap getOverallStatistics();

    /**
     * Reloads statistics from disk, clearing the cache.
     * This should be called when UI components become visible to ensure fresh data.
     */
    Q_INVOKABLE void reloadStatistics();

signals:
    /**
     * Emitted when a new result is successfully registered.
     *
     * @param filePath The path to the training file.
     * @param result The registered result.
     */
    void resultRegistered(const QString& filePath, double result);

    /**
     * Emitted when statistics are updated.
     */
    void statisticsUpdated();
};

#endif // STATISTICSAPI_H
