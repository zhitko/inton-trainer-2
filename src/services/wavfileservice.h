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

struct CuePointData {
    uint32_t id;
    uint32_t position;
    uint32_t chunkStart;
    uint32_t blockStart;
    uint32_t frameOffset;
    uint32_t sampleLength;
    std::string label;
    std::string purposeID;
    uint16_t country;
    uint16_t language;
    uint16_t dialect;
    uint16_t codePage;
    std::string text;
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
