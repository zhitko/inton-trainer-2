#include "vectorutils.h"
#include <algorithm>
#include <cmath>
#include <limits>

std::vector<double> VectorUtils::normalizeFromTo(double from, double to, const std::vector<double>& data) {
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

std::vector<double> VectorUtils::normalizeTo(double to, const std::vector<double>& data) {
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
