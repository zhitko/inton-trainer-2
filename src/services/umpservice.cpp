#include "umpservice.h"
#include "helpers/vectorutils.h"
#include <cmath>
#include <algorithm>
#include <iostream>

std::vector<double> UMPService::getUMP(
    const std::vector<double>& pitch,
    const std::vector<CuePointData>& cuePoints,
    int length,
    int waveDataSize
)
{
    std::cout << "[UMPService::getUMP] Starting..." << std::endl;
    std::cout << "  Pitch size: " << pitch.size() << std::endl;
    std::cout << "  Cue points count: " << cuePoints.size() << std::endl;
    std::cout << "  Target segment length: " << length << std::endl;
    std::cout << "  Wave data size: " << waveDataSize << std::endl;
    
    std::vector<double> result;

    const int pitchSize = pitch.size();
    
    if (pitch.empty() || cuePoints.empty() || length <= 0 || pitchSize <= 0) {
        std::cout << "  Early return due to invalid input" << std::endl;
        return result;
    }

    int cuePointIndex = 0;
    for (const auto& cuePoint : cuePoints) {
        std::cout << "  Processing cue point " << cuePointIndex << " (ID " << cuePoint.id << ", label: " << cuePoint.label << ")" << std::endl;
        std::cout << "    Position: " << cuePoint.position << ", Length: " << cuePoint.length << std::endl;
        
        // Calculate start and end frame indices
        // cuePoint.position is in waveDataSize
        // cuePoint.length is in waveDataSize
        
        int startFrame = static_cast<int>(std::floor(pitchSize * cuePoint.position / waveDataSize));
        int endFrame = static_cast<int>(std::floor(pitchSize * (cuePoint.position + cuePoint.length) / waveDataSize));
        
        std::cout << "    Calculated startFrame: " << startFrame << ", endFrame: " << endFrame << std::endl;
        
        // Clamp indices to pitch vector bounds
        startFrame = std::max(0, std::min(startFrame, pitchSize));
        endFrame = std::max(0, std::min(endFrame, pitchSize));
        
        std::cout << "    Clamped startFrame: " << startFrame << ", endFrame: " << endFrame << std::endl;
        
        // If startFrame >= endFrame, we have no data for this segment.
        // We still need to produce 'length' samples to maintain the structure.
        if (startFrame >= endFrame) {
            std::cout << "    No data for this segment, filling with zeros" << std::endl;
            for (int i = 0; i < length; ++i) {
                result.push_back(0.0);
            }
            cuePointIndex++;
            continue;
        }

        // Extract segment
        std::vector<double> segment;
        if (startFrame < endFrame) {
            segment.assign(pitch.begin() + startFrame, pitch.begin() + endFrame);
        }

        std::cout << "    Segment size: " << segment.size() << " frames" << std::endl;

        std::vector<double> interpolatedSegment = VectorUtils::linearInterpolation(segment, length);
        result.insert(result.end(), interpolatedSegment.begin(), interpolatedSegment.end());
        
        cuePointIndex++;
    }

    std::cout << "[UMPService::getUMP] Finished. Result size: " << result.size() << std::endl;
    return result;
}
