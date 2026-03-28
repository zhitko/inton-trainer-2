#include "cdtwservice.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

#include "helpers/logger.h"
#include "helpers/vectorutils.h"

CDTWService::CDTWService(
    std::vector<std::vector<std::vector<double>>> templateData,
    std::vector<std::vector<std::vector<double>>> signalData,
    std::vector<double> streamWeights,
    double matchCoef,
    double insertionCoef,
    double deletionCoef)
    : templateData(templateData)
    , signalData(signalData)
    , streamWeights(streamWeights)
    , matchCoef(matchCoef)
    , insertionCoef(insertionCoef)
    , deletionCoef(deletionCoef)
    , bestStartIndex(-1)
    , bestEndIndex(-1)
    , minFinalCost(std::numeric_limits<double>::infinity())
{
    normalizeData();
}

CDTWService::~CDTWService() { }

void CDTWService::normalizeData()
{
    if (!templateData.empty()) {
        size_t targetLength = templateData[0].size();
        for (size_t k = 1; k < templateData.size(); ++k) {
            if (templateData[k].size() != targetLength) {
                size_t originalLength = templateData[k].size();
                templateData[k] = scaleStream(templateData[k], targetLength);
                LOG_DEBUG() << "Scaled stream template " << k << " from " << originalLength << " to " << targetLength << " frames";
            }
        }
    }

    if (!signalData.empty()) {
        size_t targetLength = signalData[0].size();
        for (size_t k = 1; k < signalData.size(); ++k) {
            if (signalData[k].size() != targetLength) {
                size_t originalLength = signalData[k].size();
                signalData[k] = scaleStream(signalData[k], targetLength);
                LOG_DEBUG() << "Scaled stream signal " << k << " from " << originalLength << " to " << targetLength << " frames";
            }
        }
    }
}

std::vector<std::vector<double>>
CDTWService::scaleStream(const std::vector<std::vector<double>>& stream,
    size_t targetLength)
{
    if (stream.empty() || targetLength == 0) {
        return stream;
    }

    size_t dim = stream[0].size(); // number of values per frame
    size_t srcLength = stream.size();

    // For each dimension, extract values across all source frames, resample
    // along the frame axis to targetLength, then reconstruct frame-major output.
    std::vector<std::vector<double>> result(targetLength, std::vector<double>(dim, 0.0));

    for (size_t d = 0; d < dim; ++d) {
        std::vector<double> column(srcLength);
        for (size_t i = 0; i < srcLength; ++i) {
            column[i] = (d < stream[i].size()) ? stream[i][d] : 0.0;
        }
        std::vector<double> resampled = VectorUtils::linearInterpolation(column, static_cast<int>(targetLength));
        for (size_t i = 0; i < targetLength; ++i) {
            result[i][d] = resampled[i];
        }
    }

    return result;
}

double CDTWService::calculateDistance(int templateIndex, int signalIndex)
{
    double totalDistance = 0.0;
    int count = 0;

    size_t minStreams = std::min(templateData.size(), signalData.size());
    for (size_t k = 0; k < minStreams; ++k) {
        if (templateIndex < static_cast<int>(templateData[k].size()) && signalIndex < static_cast<int>(signalData[k].size())) {
            const std::vector<double>& templateValue = templateData[k][templateIndex];
            const std::vector<double>& signalValue = signalData[k][signalIndex];

            double dist = calculateDistance(templateValue, signalValue);
            double weight = (k < streamWeights.size()) ? streamWeights[k] : 1.0;
            totalDistance += dist * weight;
            count++;
        }
    }

    return (count > 0) ? (totalDistance / count) : 0.0;
}

double CDTWService::calculateDistance(const std::vector<double>& vec1,
    const std::vector<double>& vec2)
{
    if (vec1.empty() || vec2.empty()) {
        return 0.0;
    }

    size_t maxDim = std::max(vec1.size(), vec2.size());
    size_t minDim = std::min(vec1.size(), vec2.size());

    // Accumulate in long double to reduce risk of intermediate overflow
    // when vectors are large or contain large values
    long double distance = 0.0L;

    // Calculate squared distance for common dimensions
    for (size_t i = 0; i < minDim; ++i) {
        long double diff = static_cast<long double>(vec1[i]) - static_cast<long double>(vec2[i]);
        distance += diff * diff;
    }

    // Add penalty for mismatched dimensions (if any)
    for (size_t i = minDim; i < maxDim; ++i) {
        long double val = static_cast<long double>((i < vec1.size()) ? vec1[i] : vec2[i]);
        distance += val * val;
    }

    // Normalize by sqrt(maxDim) so distance is independent of vector length
    // and stays in a bounded range regardless of dimensionality
    double normalizationCoeff = 1.0 / std::sqrt(static_cast<double>(maxDim));
    double result = static_cast<double>(std::sqrt(distance)) * normalizationCoeff;

    return result;
}

void CDTWService::compute()
{
    LOG_DEBUG() << "Start: CDTWService::compute";
    if (templateData.empty() || signalData.empty() || templateData[0].empty() || signalData[0].empty()) {
        LOG_WARNING() << "CDTWService::compute - Empty data provided";
        return;
    }

    int m = templateData[0].size(); // template length (pattern)
    int n = signalData[0].size(); // signal length (stream)
    LOG_DEBUG() << "CDTWService::compute - template length (m)=" << m
                << ", signal length (n)=" << n;

    // cDTW initialization
    std::vector<double> prevRow(m + 1, std::numeric_limits<double>::infinity());
    std::vector<double> currRow(m + 1, std::numeric_limits<double>::infinity());
    std::vector<int> prevStart(m + 1, -1);
    std::vector<int> currStart(m + 1, -1);

    std::vector<std::vector<int>> prevPath(m + 1);
    std::vector<std::vector<int>> currPath(m + 1);

    prevRow[0] = 0.0;

    minFinalCost = std::numeric_limits<double>::infinity();
    bestEndIndex = -1;
    bestStartIndex = -1;
    signalStreamDistances.clear();
    signalStreamDistances.reserve(n);

    for (int i = 1; i <= n; ++i) {
        currRow[0] = 0.0;
        currStart[0] = i - 1;

        for (int j = 1; j <= m; ++j) {
            double cost = calculateDistance(j - 1, i - 1);

            double match = prevRow[j - 1] * matchCoef;
            double insertion = prevRow[j] * insertionCoef;
            double deletion = currRow[j - 1] * deletionCoef;

            double minVal = match;
            int minStart = prevStart[j - 1];
            int move = 0; // 0 for match, 1 for insertion, 2 for deletion

            if (deletion < minVal) {
                minVal = deletion;
                minStart = currStart[j - 1];
                move = 2;
            }
            if (insertion < minVal) {
                minVal = insertion;
                minStart = prevStart[j];
                move = 1;
            }

            currRow[j] = cost + minVal;
            currStart[j] = minStart;

            if (move == 0) {
                currPath[j] = prevPath[j - 1];
                currPath[j].push_back(i - 1);
            } else if (move == 1) {
                currPath[j] = prevPath[j];
                if (!currPath[j].empty()) {
                    currPath[j].back() = i - 1;
                } else {
                    currPath[j].push_back(i - 1);
                }
            } else {
                currPath[j] = currPath[j - 1];
                if (!currPath[j].empty()) {
                    currPath[j].push_back(currPath[j].back());
                } else {
                    currPath[j].push_back(i - 1);
                }
            }
        }

        signalStreamDistances.push_back(currRow[m]);

        if (currRow[m] < minFinalCost) {
            minFinalCost = currRow[m];
            bestEndIndex = i - 1;
            bestStartIndex = currStart[m];
            optimalPath = currPath[m];
        }

        // Use move semantics instead of swap for better performance
        prevRow = std::move(currRow);
        prevStart = std::move(currStart);
        prevPath = std::move(currPath);

        currRow.assign(m + 1, std::numeric_limits<double>::infinity());
        currStart.assign(m + 1, -1);
        currPath.clear();
        currPath.resize(m + 1);
    }
    LOG_DEBUG() << "Finish: CDTWService::compute - bestStartIndex="
                << bestStartIndex << ", bestEndIndex=" << bestEndIndex
                << ", minFinalCost=" << minFinalCost;
}

std::vector<double>
CDTWService::applyPathToVector(const std::vector<double>& input,
    const int targetLength)
{
    LOG_DEBUG() << "Start: CDTWService::applyPathToVector - input size="
                << input.size() << ", targetLength=" << targetLength;
    if (targetLength <= 0 || optimalPath.empty() || input.empty())
        return {};

    int m = optimalPath.size();
    std::vector<double> warped(m, 0.0);
    for (int k = 0; k < m; ++k) {
        int signalIndex = optimalPath[k];
        if (signalIndex >= 0 && signalIndex < static_cast<int>(input.size())) {
            warped[k] = input[signalIndex];
        } else if (signalIndex < 0) {
            warped[k] = input.front();
        } else {
            warped[k] = input.back();
        }
    }

    std::vector<double> transformed(targetLength, 0.0);
    double scalingFactor = static_cast<double>(m) / targetLength;
    for (size_t i = 0; i < static_cast<size_t>(targetLength); ++i) {
        size_t warpedIndex = static_cast<size_t>(i * scalingFactor);
        if (warpedIndex < warped.size()) {
            transformed[i] = warped[warpedIndex];
        } else {
            transformed[i] = warped.back();
        }
    }

    LOG_DEBUG() << "Finish: CDTWService::applyPathToVector - transformed size="
                << transformed.size();
    return transformed;
}

std::vector<CuePointData>
CDTWService::applyPathToCuePoints(const std::vector<CuePointData>& cuePoints)
{
    LOG_DEBUG() << "Start: CDTWService::applyPathToCuePoints - cuePoints size="
                << cuePoints.size();
    if (optimalPath.empty() || cuePoints.empty())
        return {};

    std::vector<CuePointData> transformed;
    transformed.reserve(cuePoints.size());

    int m = optimalPath.size();

    // cuePoints are in template coordinates, map them to signal coordinates via
    // optimalPath
    for (const auto& cp : cuePoints) {
        int templateStart = static_cast<int>(cp.position);
        int templateEnd = static_cast<int>(cp.position + cp.length);

        // Clamp to valid template range [0, m)
        templateStart = std::max(0, std::min(templateStart, m - 1));
        templateEnd = std::max(0, std::min(templateEnd, m - 1));

        // Map through optimalPath to signal indices
        int signalStart = optimalPath[templateStart];
        int signalEnd = optimalPath[templateEnd];

        // Ensure proper ordering in signal space
        if (signalStart > signalEnd) {
            std::swap(signalStart, signalEnd);
        }

        CuePointData newCp = cp;
        newCp.position = static_cast<uint32_t>(signalStart);
        newCp.length = static_cast<uint32_t>(std::max(0, signalEnd - signalStart));

        LOG_DEBUG() << "  CuePoint '" << cp.label << "': template=["
                    << templateStart << ", " << templateEnd << "] -> signal=["
                    << signalStart << ", " << signalEnd << "] -> mapped=["
                    << newCp.position << ", length=" << newCp.length << "]";

        transformed.push_back(newCp);
    }

    LOG_DEBUG() << "Finish: CDTWService::applyPathToCuePoints - transformed size="
                << transformed.size();
    return transformed;
}
