#ifndef DPSERVICE_H
#define DPSERVICE_H

#include <vector>

// DPService is responsible for dynamic programming related operations, 
// such as path optimization and alignment.
class DPService {
public:
    DPService(
        std::vector<std::vector<std::vector<double>>> templateData,
        std::vector<std::vector<std::vector<double>>> signalData
    );
    ~DPService();

    void compute();

    // Apply the computed DP path to a given vector (e.g., pitch vector) and return the transformed vector
    std::vector<double> applyPathToVector(const std::vector<double>& input, const int targetLength);

private:
    void normalizeData();
    std::vector<std::vector<double>> scaleStream(const std::vector<std::vector<double>>& stream, size_t targetLength);

    // Template and signal data for dynamic programming
    std::vector<std::vector<std::vector<double>>> templateData;
    std::vector<std::vector<std::vector<double>>> signalData;

    // Distance matrix for dynamic programming
    std::vector<std::vector<double>> distanceMatrix;

    // Integral time distance matrix for dynamic programming
    std::vector<std::vector<double>> integralTimeDistanceMatrix;
    
    // Optimal path found by dynamic programming
    std::vector<int> optimalPath;

protected:
    /**
     * Compute the distance matrix for dynamic programming.
     */
    void computeDistanceMatrix();

    double calculateDistance(
        const std::vector<double>& templateValue,
        const std::vector<double>& signalValue
    );

    /**
     * Compute the integral time distance matrix for dynamic programming.
     */
    void computeIntegralTimeDistanceMatrix();

    /**
     * Find position for signal start position in dynamic programming.
     * @return Minimum position index for signal start
     */
    int findPositionForSignalStart();

    /**
     * Find position for signal end position in dynamic programming.
     * @return Minimum position index for signal end
     */
    int findPositionForSignalEnd();

    /**
     * Perform backtracking to find the optimal path in dynamic programming.
     * @param signalStartPos Starting position in the signal for backtracking
     * @param signalEndPos Ending position in the signal for backtracking
     * @return Vector of indices representing the optimal path through the distance matrix
     */
    std::vector<int> performBacktracking(int signalStartPos, int signalEndPos);
};

#endif // DPSERVICE_H