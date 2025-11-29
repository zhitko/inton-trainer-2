#include "vectorutils.h"
#include <algorithm>
#include <cmath>
#include <limits>

std::vector<double> VectorUtils::normalizeByMinMax(double from, double to, const std::vector<double>& data) {
    if (data.empty()) {
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

    return result;
}

std::vector<double> VectorUtils::normalizeByMax(double to, const std::vector<double>& data) {
    if (data.empty()) {
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

    return result;
}

std::vector<double> VectorUtils::normalizeByMean(const std::vector<double>& data) {
    if (data.empty()) {
        return {};
    }

    double sum = 0.0;
    for (double val : data) {
        sum += val;
    }
    double mean = sum / data.size();

    std::vector<double> result;
    result.reserve(data.size());

    for (double val : data) {
        result.push_back(val - mean);
    }

    return result;
}

std::vector<double> VectorUtils::normalizeByMeanDeviation(const std::vector<double>& data) {
    if (data.empty()) {
        return {};
    }

    double sum = 0.0;
    for (double val : data) {
        sum += val;
    }
    double mean = sum / data.size();

    double deviationSum = 0.0;
    for (double val : data) {
        deviationSum += std::abs(val - mean);
    }
    double deviation = deviationSum / data.size();

    if (std::abs(deviation) < std::numeric_limits<double>::epsilon()) {
        // Deviation is 0 (all values are the same), return 0s
        return std::vector<double>(data.size(), 0.0);
    }

    std::vector<double> result;
    result.reserve(data.size());

    for (double val : data) {
        result.push_back((val - mean) / deviation);
    }

    return result;
}
