#ifndef WAVFILESERVICE_H
#define WAVFILESERVICE_H

#include <string>
#include <vector>
#include <cstdint>

struct AudioFormat {
    int sampleRate;
    int channelCount;
    int bitsPerSample;
};


enum class CuePointType {
    PRE_NUCLEUS,
    NUCLEUS,
    POST_NUCLEUS
};

struct CuePointData {
    uint32_t id;
    uint32_t position;
    uint32_t length;
    std::string label;
    CuePointType type;
};

struct WaveFile;

class WavFileService
{
public:
    explicit WavFileService(const std::string &rootPath);

    std::string writeWaveFile(const std::string &fileName, const std::vector<char> &buffer, const AudioFormat &format);

    static std::vector<double> readWaveData(WaveFile *waveFile);
    static std::vector<CuePointData> readCuePoints(WaveFile *waveFile);

private:
    std::string m_rootPath;
};

#endif // WAVFILESERVICE_H
