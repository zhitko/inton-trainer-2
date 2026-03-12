#ifndef STATISTICS_H
#define STATISTICS_H

#include <QString>
#include <algorithm>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

/*
 * StatisticsItem represents a single item in the statistics hierarchy.
 * Can be either a file or a folder with nested items.
 */
struct StatisticsItem {
    enum Type { File,
        Folder };

    Type type;
    std::string name;
    double avgResult = 0.0;
    double bestResult = 0.0;
    double completeness = 0.0; // For folders: completion percentage
    int totalFiles = 0; // For folders: total number of files
    int processedFiles = 0; // For folders: number of files with results
    std::vector<double> results; // For files: individual results
    std::vector<std::shared_ptr<StatisticsItem>> items; // For folders: nested items

    StatisticsItem(Type t, const std::string& n)
        : type(t)
        , name(n)
    {
    }
};

/*
 * UserStatistics struct holds all user training statistics in a hierarchical structure.
 */
struct UserStatistics {
    std::vector<std::shared_ptr<StatisticsItem>> items;
};

/*
 * The Statistics class provides static methods to load and save user statistics
 * to a JSON file, as well as to manage and query statistics data. The statistics are
 * stored in a JSON file in the user's home directory (statistics.json).
 */
class Statistics {
public:
    /**
     * Loads the user statistics from a JSON file. If the file does not exist
     * or is invalid, it returns empty statistics.
     *
     * @return A UserStatistics object containing the loaded statistics.
     */
    static UserStatistics loadStatistics();

    /**
     * Saves the given user statistics to a JSON file in the user's home directory.
     * If the file cannot be written, it should handle the error gracefully.
     *
     * @param statistics A UserStatistics object containing the statistics to be saved.
     */
    static void saveStatistics(const UserStatistics& statistics);

    /**
     * Reloads statistics from disk, clearing the cache.
     * This should be called when UI components become visible to ensure fresh data.
     */
    static void reloadStatistics();

    /**
     * Registers a new training result for a specific file.
     *
     * @param filePath The path to the training file.
     * @param result The training result (score) as a double.
     */
    static void registerResult(const std::string& filePath, double result);

    /**
     * Gets the average result for a specific file.
     *
     * @param filePath The path to the training file.
     * @return The average result for the file, or 0.0 if no results exist.
     */
    static double getAvgResultForFile(const std::string& filePath);

    /**
     * Gets the best result (maximum score) for a specific file.
     *
     * @param filePath The path to the training file.
     * @return The best result for the file, or 0.0 if no results exist.
     */
    static double getBestResultForFile(const std::string& filePath);

    /**
     * Gets raw recent results for a specific file in chronological order.
     *
     * @param filePath The path to the training file.
     * @return A vector of recent results (oldest -> newest), empty if none.
     */
    static std::vector<double> getResultsForFile(const std::string& filePath);

    /**
     * Gets the average result, average best result, and completeness for all files in a specific folder.
     *
     * @param folderPath The path to the folder.
     * @return A map containing "avgResult", "avgBestResult", "completeness", "totalFiles", "processedFiles" values.
     */
    static std::map<std::string, double> getAvgResultForFolder(const std::string& folderPath);

    /**
     * Gets overall user statistics (average of all results and overall completeness).
     *
     * @return A map containing overall statistics with keys like "avgResult", "totalResults", "filesCount", "completeness".
     */
    static std::map<std::string, double> getOverallStatistics();

private:
    /**
     * Returns the file path for the statistics JSON file. This is typically located
     * in the user's home directory under a hidden folder for the application.
     *
     * @return A QString containing the full file path to the statistics JSON file.
     */
    static QString getStatisticsFilePath();

    /**
     * Finds or creates an item in the hierarchy based on the path.
     *
     * @param path The file or folder path.
     * @param create If true, creates missing items in the hierarchy.
     * @return Pointer to the found or created item, or nullptr if not found and create is false.
     */
    static std::shared_ptr<StatisticsItem> findOrCreateItem(const std::string& path, bool create = false);

    /**
     * Calculates the average result for an item and all its children.
     *
     * @param item The item to calculate average for.
     * @return The average result.
     */
    static double calculateAverage(const std::shared_ptr<StatisticsItem>& item);

    /**
     * Calculates the average of the best results for an item and all its children.
     *
     * @param item The item to calculate average best for.
     * @return The average of best results.
     */
    static double calculateAverageBest(const std::shared_ptr<StatisticsItem>& item);

    /**
     * Calculates the completeness for a folder (percentage of files with results).
     * For subfolders, returns the average completeness of child folders.
     *
     * @param item The folder item to calculate completeness for.
     * @param folderPath The file system path to the folder for counting total files.
     * @return The completeness value (0.0 to 1.0).
     */
    static double calculateCompleteness(const std::shared_ptr<StatisticsItem>& item, const std::string& folderPath = "");

    /**
     * In-memory cache of statistics to avoid repeated file I/O.
     */
    static UserStatistics cachedStatistics;
    static bool statisticsLoaded;
};

#endif // STATISTICS_H
