#include "umpservice.h"
#include "helpers/vectorutils.h"
#include <cmath>
#include <algorithm>
#include <iostream>
#include <sstream>
#include "helpers/logger.h"

UMPResult UMPService::getUMP(
    const std::string& interpolationType,
    const std::vector<double>& pitch,
    const std::vector<CuePointData>& cuePoints,
    int pLength,
    int nLength,
    int tLength,
    int waveDataSize
)
{
    LOG_DEBUG() << "Start: getUMP - pitch.size=" << pitch.size()
                << ", cuePoints.size=" << cuePoints.size()
                << ", pLength=" << pLength
                << ", nLength=" << nLength
                << ", tLength=" << tLength
                << ", waveDataSize=" << waveDataSize;
    
    std::vector<double> result;

    const int pitchSize = pitch.size();
    
    if (pitch.empty() || cuePoints.empty() || pLength <= 0 || nLength <= 0 || tLength <= 0 || pitchSize <= 0) {
        LOG_WARNING() << "  Early return due to invalid input";
        UMPResult emptyOut;
        return emptyOut;
    }

    // -----------------------
    // If we have single PRE_NUCLEUS or POST_NUCLEUS between two NUCLEUS, 
    // we should split it to PRE_NUCLEUS + POST_NUCLEUS with the same position and length as the original one.

    std::vector<CuePointData> processedCuePoints;
    processedCuePoints.push_back(cuePoints[0]);

    for (int i = 1; i < cuePoints.size() - 1; ++i) {
        const CuePointData& cuePoint = cuePoints[i];
        if (cuePoint.type == CuePointType::NUCLEUS) {
            processedCuePoints.push_back(cuePoint);
        } else if (cuePoint.type == CuePointType::PRE_NUCLEUS || cuePoint.type == CuePointType::POST_NUCLEUS) {
            const CuePointData& currentCuePoint = cuePoints[i];
            const CuePointData& prevCuePoint = cuePoints[i-1];
            const CuePointData& nextCuePoint = cuePoints[i+1];

            if (prevCuePoint.type == CuePointType::NUCLEUS && nextCuePoint.type == CuePointType::NUCLEUS) {
                // Split the current cue point into PRE_NUCLEUS and POST_NUCLEUS
                CuePointData preCuePoint = currentCuePoint;
                preCuePoint.type = CuePointType::PRE_NUCLEUS;
                preCuePoint.length = currentCuePoint.length / 2;

                LOG_DEBUG() << "  Splitting cue point ID " << currentCuePoint.id << " into PRE_NUCLEUS and POST_NUCLEUS";
                LOG_DEBUG() << "    Original: position=" << currentCuePoint.position << ", length=" << currentCuePoint.length;
                LOG_DEBUG() << "    PRE_NUCLEUS: position=" << preCuePoint.position << ", length=" << preCuePoint.length;

                CuePointData postCuePoint = currentCuePoint;
                postCuePoint.type = CuePointType::POST_NUCLEUS;
                postCuePoint.position += currentCuePoint.length / 2;
                postCuePoint.length = currentCuePoint.length / 2;

                LOG_DEBUG() << "    POST_NUCLEUS: position=" << postCuePoint.position << ", length=" << postCuePoint.length;

                processedCuePoints.push_back(preCuePoint);
                processedCuePoints.push_back(postCuePoint);
            } else {
                processedCuePoints.push_back(cuePoint);
            }
        } else {
            LOG_WARNING() << "  Unknown cue point type for ID " << cuePoint.id << ", label: " << cuePoint.label;
        }
    }
    processedCuePoints.push_back(cuePoints.back());
    // -----------------------

    int cuePointIndex = 0;
    for (const auto& cuePoint : processedCuePoints) {
        LOG_DEBUG() << "  Processing cue point " << cuePointIndex << " (ID " << cuePoint.id << ", label: " << cuePoint.label << ")";
        LOG_DEBUG() << "    Position: " << cuePoint.position << ", Length: " << cuePoint.length;

        int length = nLength;
        if (cuePoint.type == CuePointType::PRE_NUCLEUS) {
            length = pLength;
        } else if (cuePoint.type == CuePointType::POST_NUCLEUS) {
            length = tLength;
        }
        
        // Calculate start and end frame indices
        // cuePoint.position is in waveDataSize
        // cuePoint.length is in waveDataSize
        
        int startFrame = static_cast<int>(std::floor(pitchSize * cuePoint.position / waveDataSize));
        int endFrame = static_cast<int>(std::floor(pitchSize * (cuePoint.position + cuePoint.length) / waveDataSize));
        
        LOG_DEBUG() << "    Calculated startFrame: " << startFrame << ", endFrame: " << endFrame;
        
        // Clamp indices to pitch vector bounds
        startFrame = std::max(0, std::min(startFrame, pitchSize));
        endFrame = std::max(0, std::min(endFrame, pitchSize));
        
        LOG_DEBUG() << "    Clamped startFrame: " << startFrame << ", endFrame: " << endFrame;
        
        // If startFrame >= endFrame, we have no data for this segment.
        // We still need to produce 'length' samples to maintain the structure.
        if (startFrame >= endFrame) {
            LOG_DEBUG() << "    No data for this segment, filling with zeros";
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

        LOG_DEBUG() << "    Segment size: " << segment.size() << " frames";

        std::vector<double> interpolatedSegment = VectorUtils::interpolate(interpolationType, segment, length);
        result.insert(result.end(), interpolatedSegment.begin(), interpolatedSegment.end());
        
        cuePointIndex++;
    }

    LOG_DEBUG() << "Finish: getUMP - result.size=" << result.size();
    UMPResult out;
    out.ump = std::move(result);
    out.processedCuePoints = std::move(processedCuePoints);
    return out;
}
