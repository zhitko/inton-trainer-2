#ifndef UMPSERVICE_H
#define UMPSERVICE_H

#include <vector>
#include "wavfileservice.h"

class UMPService
{
public:
    static std::vector<double> getUMP(
        const std::vector<double>& pitch,
        const std::vector<CuePointData>& cuePoints,
        int pLength,
        int nLength,
        int tLength,
        int waveDataSize
    );
};

#endif // UMPSERVICE_H
