#include "vectorutils.h"
#include "logger.h"
#include <algorithm>
#include <cmath>
#include <limits>

std::vector<double> VectorUtils::normalizeFromTo(double from, double to, const std::vector<double>& data) {
    LOG_DEBUG() << "Start: normalizeFromTo - from=" << from << ", to=" << to << ", data.size=" << data.size();
    
    if (data.empty()) {
        LOG_DEBUG() << "Finish: normalizeFromTo - result.size=0 (empty input)";
        return {};
    }

    double minVal = std::numeric_limits<double>::max();
    double maxVal = std::numeric_limits<double>::lowest();

    for (double val : data) {
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
    }

    if (std::abs(maxVal - minVal) < std::numeric_limits<double>::epsilon()) {
        // All values are the same, return a vector of 'from'
        return std::vector<double>(data.size(), from);
    }

    std::vector<double> result;
    result.reserve(data.size());

    double range = maxVal - minVal;
    double targetRange = to - from;

    for (double val : data) {
        double normalized = from + ((val - minVal) / range) * targetRange;
        result.push_back(normalized);
    }

    LOG_DEBUG() << "Finish: normalizeFromTo - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::normalizeByMinMax(const std::vector<double>& data, bool skipZeros) {
    LOG_DEBUG() << "Start: normalizeByMinMax - data.size=" << data.size() << ", skipZeros=" << skipZeros;
    
    if (data.empty()) {
        LOG_DEBUG() << "Finish: normalizeByMinMax - result.size=0 (empty input)";
        return {};
    }

    double minVal = std::numeric_limits<double>::max();
    double maxVal = std::numeric_limits<double>::lowest();

    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            if (val > maxVal) maxVal = val;
            continue;
        }
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
    }

    if (std::abs(maxVal - minVal) < std::numeric_limits<double>::epsilon()) {
        // All values are the same, return a vector of 'from'
        return std::vector<double>(data.size(), 0.0);
    }

    std::vector<double> result;
    result.reserve(data.size());

    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            result.push_back(0.0);
            continue;
        }
        double normalized = val - minVal;
        result.push_back(normalized);
    }

    LOG_DEBUG() << "Finish: normalizeByMinMax - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::normalizeTo(double to, const std::vector<double>& data) {
    LOG_DEBUG() << "Start: normalizeTo - to=" << to << ", data.size=" << data.size();
    
    if (data.empty()) {
        LOG_DEBUG() << "Finish: normalizeTo - result.size=0 (empty input)";
        return {};
    }

    double maxVal = std::numeric_limits<double>::lowest();
    for (double val : data) {
        if (val > maxVal) maxVal = val;
    }

    if (std::abs(maxVal) < std::numeric_limits<double>::epsilon()) {
        // Max value is 0, cannot scale. Return 0s.
        return std::vector<double>(data.size(), 0.0);
    }

    std::vector<double> result;
    result.reserve(data.size());

    for (double val : data) {
        result.push_back((val / maxVal) * to);
    }

    LOG_DEBUG() << "Finish: normalizeTo - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::normalizeByMean(const std::vector<double>& data, bool skipZeros) {
    LOG_DEBUG() << "Start: normalizeByMean - data.size=" << data.size() << ", skipZeros=" << skipZeros;
    
    if (data.empty()) {
        LOG_DEBUG() << "Finish: normalizeByMean - result.size=0 (empty input)";
        return {};
    }

    double sum = 0.0;
    int count = 0;
    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            continue;
        }
        sum += val;
        count++;
    }
    
    // If all values are zero (or count is 0), mean is 0
    double mean = (count > 0) ? (sum / count) : 0.0;

    std::vector<double> result;
    result.reserve(data.size());

    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            result.push_back(0.0);
            continue;
        }
        result.push_back(val - mean);
    }

    LOG_DEBUG() << "Finish: normalizeByMean - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::normalizeByMeanDeviation(const std::vector<double>& data, bool skipZeros) {
    LOG_DEBUG() << "Start: normalizeByMeanDeviation - data.size=" << data.size() << ", skipZeros=" << skipZeros;
    
    if (data.empty()) {
        LOG_DEBUG() << "Finish: normalizeByMeanDeviation - result.size=0 (empty input)";
        return {};
    }

    double sum = 0.0;
    int count = 0;
    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            continue;
        }
        sum += val;
        count++;
    }
    
    // If all values are zero (or count is 0), mean is 0
    double mean = (count > 0) ? (sum / count) : 0.0;

    double deviationSum = 0.0;
    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            continue;
        }
        deviationSum += std::abs(val - mean);
    }
    
    // Calculate deviation only from non-zero values
    double deviation = (count > 0) ? (deviationSum / count) : 0.0;

    if (std::abs(deviation) < std::numeric_limits<double>::epsilon()) {
        // Deviation is 0 (all values are the same), return 0s
        return std::vector<double>(data.size(), 0.0);
    }

    std::vector<double> result;
    result.reserve(data.size());

    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            result.push_back(0.0);
            continue;
        }
        result.push_back((val - mean) / deviation);
    }

    LOG_DEBUG() << "Finish: normalizeByMeanDeviation - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::linearInterpolation(const std::vector<double>& data, int targetLength) {
    LOG_DEBUG() << "Start: linearInterpolation - data.size=" << data.size() << ", targetLength=" << targetLength;
    
    if (data.empty() || targetLength <= 0) {
        LOG_DEBUG() << "Finish: linearInterpolation - result.size=0 (invalid input)";
        return {};
    }

    if (targetLength == 1) {
        return {data[0]};
    }

    int inputSize = data.size();
    if (inputSize == 1) {
        return std::vector<double>(targetLength, data[0]);
    }

    std::vector<double> result;
    result.reserve(targetLength);

    for (int i = 0; i < targetLength; ++i) {
        double t = static_cast<double>(i) * (inputSize - 1) / (targetLength - 1);
        int idx = static_cast<int>(std::floor(t));
        double frac = t - idx;

        if (idx >= inputSize - 1) {
            // This handles the last point or precision issues
            result.push_back(data[std::min(idx, inputSize - 1)]);
        } else {
            double val = data[idx] * (1.0 - frac) + data[idx + 1] * frac;
            result.push_back(val);
        }
    }

    LOG_DEBUG() << "Finish: linearInterpolation - result.size=" << result.size();
    return result;
}
