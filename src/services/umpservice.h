#ifndef UMPSERVICE_H
#define UMPSERVICE_H

#include <vector>
#include <string>
#include "wavfileservice.h"

struct UMPResult {
    std::vector<double> ump;
    std::vector<CuePointData> processedCuePoints;
};

struct UMPComparison {
    double referenceRange;  // 0-100: percentage of full range covered by reference UMP
    double userRange;       // 0-100: percentage of full range covered by user UMP
    double rangeSimilarity; // 0-100: how similar the ranges are
    double shapeSimilarity; // 0-100: Pearson correlation between the two profiles
};

class UMPService
{
public:
    /**
     * @brief Calculates the Unified Melodic Profile (UMP) based on pitch data and cue points.
     * 
     * @param interpolationType The type of interpolation method to use for UMP calculation
     *                          (e.g., "linear", "cubic", etc.)
     * @param pitch A vector of pitch values that form the basis for UMP generation.
     * @param cuePoints A vector of cue points containing structural markers or control points
     *                  for the UMP calculation.
     * @param pLength The length or number of pitch samples to process.
     * @param nLength The length parameter for normalization or note-related processing.
     * @param tLength The length of the time window or temporal segment for analysis.
     * @param waveDataSize The total size of the waveform data being processed.
     * 
     * @return UMPResult A result object containing the calculated UMP data and status information.
     * 
     * @details This static method performs melodic profile analysis using the provided pitch
     *          data and cue points, applying the specified interpolation technique to generate
     *          a unified representation of the melodic contour.
     */
    static UMPResult getUMP(
        const std::string& interpolationType,
        const std::vector<double>& pitch,
        const std::vector<CuePointData>& cuePoints,
        int pLength,
        int nLength,
        int tLength,
        int waveDataSize
    );

    /**
     * @brief Compares two UMP portraits and calculates similarity metrics.
     * 
     * @param referenceUmp The reference UMP vector to compare against.
     * @param userUmp The user UMP vector to compare.
     * @param fullMin The minimum value of the full range for normalization.
     * @param fullMax The maximum value of the full range for normalization.
     * 
     * @return UMPComparison A result object containing:
     *         - referenceRange: Percentage of full range covered by reference UMP (0-100)
     *         - userRange: Percentage of full range covered by user UMP (0-100)
     *         - rangeSimilarity: How well the ranges match (0-100)
     *         - shapeSimilarity: Pearson correlation between profiles (0-100)
     * 
     * @details This static method performs profile comparison using correlation analysis
     *          and range normalization. Both UMP vectors must have the same length.
     * 
     * @note Returns zero values for all fields if input vectors have mismatched lengths
     *       or if either vector is empty.
     */
    static UMPComparison compareUMP(
        const std::vector<double>& referenceUmp,
        const std::vector<double>& userUmp,
        double fullMin,
        double fullMax
    );
};

#endif // UMPSERVICE_H
