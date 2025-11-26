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

class WavFileService
{
public:
    explicit WavFileService(const std::string &rootPath);

    std::string writeWaveFile(const std::string &fileName, const std::vector<char> &buffer, const AudioFormat &format);

private:
    std::string m_rootPath;
};

#endif // WAVFILESERVICE_H
