#include "wavfileservice.h"
#include "helpers/wavFile.h"
#include <iostream>
#include <filesystem>
#include <algorithm>

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

std::vector<double> WavFileService::readWaveData(WaveFile *waveFile)
{
    std::vector<double> samples;
    if (!waveFile || !waveFile->dataChunk) {
        std::cerr << "WaveFile or DataChunk is null" << std::endl;
        return samples;
    }

    void *data = waveFile->dataChunk->waveformData;
    uint32_t dataSize = littleEndianBytesToUInt32(waveFile->dataChunk->chunkDataSize);
    uint16_t bitDepth = littleEndianBytesToUInt16(waveFile->formatChunk->significantBitsPerSample);

    samples = waveformDataToVector(data, dataSize, bitDepth);
    return samples;
}

std::vector<CuePointData> WavFileService::readCuePoints(WaveFile *waveFile)
{
    std::cout << "readCuePoints called" << std::endl;
    std::vector<CuePointData> cuePoints;
    if (!waveFile || !waveFile->cueChunk) {
        std::cout << "WaveFile or CueChunk is null" << std::endl;
        return cuePoints;
    }

    uint32_t cuePointsCount = littleEndianBytesToUInt32(waveFile->cueChunk->cuePointsCount);
    std::cout << "Found " << cuePointsCount << " cue points" << std::endl;

    for (uint32_t i = 0; i < cuePointsCount; ++i) {
        CuePointData cuePoint;
        CuePoint *cp = &waveFile->cueChunk->cuePoints[i];
        
        cuePoint.id = littleEndianBytesToUInt32(cp->cuePointID);
        cuePoint.position = littleEndianBytesToUInt32(cp->playOrderPosition);
        
        // Initialize optional fields
        cuePoint.length = 0;

        // Find associated label
        std::string label = "";
        bool ltxtFound = false;
        if (waveFile->listCount > 0) {
            for (uint32_t j = 0; j < waveFile->listCount; ++j) {
                ListChunk *listChunk = &waveFile->listChunks[j];
                if (label.empty()) {
                    for (uint32_t k = 0; k < listChunk->lablCount; ++k) {
                        LablChunk *lablChunk = &listChunk->lablChunks[k];
                        if (littleEndianBytesToUInt32(lablChunk->cuePointID) == cuePoint.id) {
                            if (lablChunk->text) {
                                label = std::string(lablChunk->text);
                            }
                            break;
                        }
                    }
                }

                if (!ltxtFound) {
                    for (uint32_t k = 0; k < listChunk->ltxtCount; ++k) {
                        LtxtChunk *ltxtChunk = &listChunk->ltxtChunks[k];
                        if (littleEndianBytesToUInt32(ltxtChunk->cuePointID) == cuePoint.id) {
                            cuePoint.length = littleEndianBytesToUInt32(ltxtChunk->sampleLength);
                            ltxtFound = true;
                            break;
                        }
                    }
                }

                if (!label.empty() && ltxtFound) {
                    break;
                }
            }
        }
        cuePoint.label = label;
        
        std::cout << "Cue Point " << i 
                  << ": ID=" << cuePoint.id 
                  << " Label=" << cuePoint.label 
                  << " Position=" << cuePoint.position
                  << " Length=" << cuePoint.length << std::endl;

        cuePoints.push_back(cuePoint);
    }

    std::sort(cuePoints.begin(), cuePoints.end(), [](const CuePointData& a, const CuePointData& b) {
        return a.position < b.position;
    });

    return cuePoints;
}