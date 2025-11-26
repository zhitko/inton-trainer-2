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

struct WaveFile;

class WavFileService
{
public:
    explicit WavFileService(const std::string &rootPath);

    std::string writeWaveFile(const std::string &fileName, const std::vector<char> &buffer, const AudioFormat &format);

    static std::vector<double> readWaveData(WaveFile *waveFile);

private:
    std::string m_rootPath;
};

#endif // WAVFILESERVICE_H
