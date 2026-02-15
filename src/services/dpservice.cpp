#include "dpservice.h"

#include <vector>
#include <cmath>
#include <algorithm>


DPService::DPService(
    std::vector<std::vector<double>> templateData,
    std::vector<std::vector<double>> signalData
) : templateData(templateData), signalData(signalData) {
    // Constructor implementation (if needed)
}

DPService::~DPService() {
    // Destructor implementation (if needed)
}

void DPService::compute() {
    // Example implementation of the compute function
    if (templateData.empty() || signalData.empty()) {
        return; // Handle empty data case
    }

    // Compute distance matrix for the first sequences as an example
    computeDistanceMatrix();

    // Compute integral time distance matrix for the first sequences as an example
    computeIntegralTimeDistanceMatrix();

    // Find singal start and end positions
    int signalStartPos = findPositionForSignalStart();
    int signalEndPos = findPositionForSignalEnd();

    // Perform backtracking to find the optimal path
    optimalPath = performBacktracking(signalStartPos, signalEndPos);

    return;
}

void DPService::computeDistanceMatrix() {
    // Example implementation of distance matrix computation
    int templateLength = templateData[0].size();
    int signalLength = signalData[0].size();
    distanceMatrix.resize(templateLength, std::vector<double>(signalLength, 0.0));

    for (int i = 0; i < templateLength; ++i) {
        for (int j = 0; j < signalLength; ++j) {
            distanceMatrix[i][j] = calculateDistance(templateData[i], signalData[j]);
        }
    }
}

double DPService::calculateDistance(
    const std::vector<double>& templateValue,
    const std::vector<double>& signalValue
) {
    // Example implementation of distance calculation (Euclidean distance)
    double sum = 0.0;
    for (size_t k = 0; k < templateValue.size(); ++k) {
        double diff = templateValue[k] - signalValue[k];
        sum += diff * diff;
    }
    return std::sqrt(sum);
}

void DPService::computeIntegralTimeDistanceMatrix() {
    // Example implementation of integral time distance matrix computation
    int templateLength = templateData[0].size();
    int signalLength = signalData[0].size();
    integralTimeDistanceMatrix.resize(templateLength, std::vector<double>(signalLength, 0.0));

    for (int i = 0; i < templateLength; ++i) {
        for (int j = 0; j < signalLength; ++j) {
            if (i == 0) {
                integralTimeDistanceMatrix[i][j] = distanceMatrix[i][j];
            } else if (j == 0) {
                integralTimeDistanceMatrix[i][j] = integralTimeDistanceMatrix[i - 1][j] + distanceMatrix[i][j];
            } else {
                double minTime = std::min({
                    integralTimeDistanceMatrix[i - 1][j] + distanceMatrix[i][j], // Insertion
                    integralTimeDistanceMatrix[i][j - 1] + distanceMatrix[i][j], // Deletion
                    integralTimeDistanceMatrix[i - 1][j - 1] + distanceMatrix[i][j] // Match
                });
                integralTimeDistanceMatrix[i][j] = minTime;
            }
        }
    }
}

int DPService::findPositionForSignalStart() {
    // implementation to find minimum position for signal start
    int minPos = 0;
    double minValue = integralTimeDistanceMatrix[0][0];
    for (size_t j = 1; j < integralTimeDistanceMatrix[0].size(); ++j) {
        if (integralTimeDistanceMatrix[0][j] < minValue) {
            minValue = integralTimeDistanceMatrix[0][j];
            minPos = j;
        }
    }
    return minPos;
}

int DPService::findPositionForSignalEnd() {
    // implementation to find minimum position for signal end
    int minPos = 0;
    double minValue = integralTimeDistanceMatrix.back()[0];
    for (size_t j = 1; j < integralTimeDistanceMatrix.back().size(); ++j) {
        if (integralTimeDistanceMatrix.back()[j] < minValue) {
            minValue = integralTimeDistanceMatrix.back()[j];
            minPos = j;
        }
    }
    return minPos;
}

std::vector<int> DPService::performBacktracking(int signalStartPos, int signalEndPos) {
    // Example implementation of backtracking to find the optimal path
    std::vector<int> path;
    int i = templateData[0].size() - 1; // Start from the end of the template
    int j = signalEndPos; // Start from the end position of the signal
    path.push_back(j);

    while (i >= 0 && j >= 0) {
        if (i > 0 && j > 0 && integralTimeDistanceMatrix[i][j] == integralTimeDistanceMatrix[i - 1][j - 1] + distanceMatrix[i][j]) {
            --i; // Move diagonally (match)
            --j;
            path.push_back(j); // Add signal position to path
        } else if (i > 0 && integralTimeDistanceMatrix[i][j] == integralTimeDistanceMatrix[i - 1][j] + distanceMatrix[i][j]) {
            --i; // Move up (insertion)
            path.push_back(j); // Add signal position to path
        } else {
            --j; // Move left (deletion)
        }
    }

    std::reverse(path.begin(), path.end()); // Reverse to get the correct order
    return path;
}

std::vector<double> DPService::applyPathToVector(const std::vector<double>& input, const int targetLength) {
    // Implementation of applying the computed DP path to a given vector
    std::vector<double> transformed(targetLength, 0.0);
    double scalingFactor = static_cast<double>(input.size()) / targetLength; // Scaling factor based on input size and target length
    for (size_t i = 0; i < targetLength; ++i) {
        size_t inputIndex = static_cast<size_t>(i * scalingFactor);
        if (inputIndex < input.size()) {
            transformed[i] = input[inputIndex];
        } else {
            transformed[i] = input.back(); // Use last value if index exceeds input size
        }
    }
    return transformed;
}
