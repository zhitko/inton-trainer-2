#ifndef CDTWSERVICE_H
#define CDTWSERVICE_H

#include <vector>
#include "wavfileservice.h"

// CDTWService is responsible for continuous dynamic time warping related operations.
class CDTWService {
public:
    CDTWService(
        std::vector<std::vector<std::vector<double>>> templateData,
        std::vector<std::vector<std::vector<double>>> signalData
    );
    ~CDTWService();

    void compute();

    // Apply the computed DP path to a given vector (e.g., pitch vector) and return the transformed vector
    std::vector<double> applyPathToVector(const std::vector<double>& input, const int targetLength);

    // Apply the computed DP path to cue points
    std::vector<CuePointData> applyPathToCuePoints(const std::vector<CuePointData>& cuePoints);

    int getBestStartIndex() const { return bestStartIndex; }
    int getBestEndIndex() const { return bestEndIndex; }
    double getMinFinalCost() const { return minFinalCost; }

private:
    void normalizeData();
    std::vector<std::vector<double>> scaleStream(const std::vector<std::vector<double>>& stream, size_t targetLength);

    // Template and signal data
    std::vector<std::vector<std::vector<double>>> templateData;
    std::vector<std::vector<std::vector<double>>> signalData;

    int bestStartIndex;
    int bestEndIndex;
    double minFinalCost;
    std::vector<int> optimalPath;

protected:
    double calculateDistance(
        int templateIndex,
        int signalIndex
    );
};

#endif // CDTWSERVICE_H
