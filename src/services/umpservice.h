#ifndef UMPSERVICE_H
#define UMPSERVICE_H

#include <vector>
#include <string>
#include "wavfileservice.h"

struct UMPResult {
    std::vector<double> ump;
    std::vector<CuePointData> processedCuePoints;
};

class UMPService
{
public:
    static UMPResult getUMP(
        const std::string& interpolationType,
        const std::vector<double>& pitch,
        const std::vector<CuePointData>& cuePoints,
        int pLength,
        int nLength,
        int tLength,
        int waveDataSize
    );
};

#endif // UMPSERVICE_H
