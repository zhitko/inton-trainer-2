#include "wavfileservice.h"
#include "../helpers/wavFile.h"
#include <iostream>
#include <filesystem>

namespace fs = std::filesystem;

WavFileService::WavFileService(const std::string &rootPath) : m_rootPath(rootPath)
{
}

std::string WavFileService::writeWaveFile(const std::string &fileName, const std::vector<char> &buffer, const AudioFormat &format)
{
    fs::path appDir(m_rootPath);
    fs::path recordsDir = appDir / "data" / "records";

    if (!fs::exists(recordsDir)) {
        fs::create_directories(recordsDir);
    }

    fs::path relativePath = fs::path("data") / "records" / (fileName + ".wav");
    fs::path absoluteFilePath = appDir / relativePath;

    WaveHeader *waveHeader = makeWaveHeader(buffer.size());
    FormatChunk *formatChunk = makeFormatChunk(
        format.channelCount,
        format.sampleRate,
        format.bitsPerSample
    );
    
    // Cast constness away because makeDataChunk expects char* but likely doesn't modify it (it copies).
    DataChunk *dataChunk = makeDataChunk(buffer.size(), const_cast<char*>(buffer.data()));

    WaveFile *waveFile = makeWaveFile(
        waveHeader,
        formatChunk,
        dataChunk,
        nullptr,
        nullptr,
        0,
        nullptr,
        0
    );

    saveWaveFile(waveFile, absoluteFilePath.string());
    waveCloseFile(waveFile);

    std::cout << "Saved to:" << absoluteFilePath.string() << std::endl;
    return relativePath.string();
}