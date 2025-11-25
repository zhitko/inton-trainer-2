#include "wavFile.h"

#include <iostream>

#include <string.h>
#include <limits.h>
#include <cfloat>

#ifdef _WIN32
#include <windows.h>
#include <string>
#include <codecvt>
#include <locale>
#endif




#define INT32 littleEndianBytesToUInt32
#define INT16 littleEndianBytesToUInt16

#define INT3_MAX   8388607
#define INT3_MIN   (-8388608)
#define UINT3_MAX  16777215

uint32_t to_odd(uint32_t value)
{
    if (value % 2 == 1)
    {
        value += 1;
    }
    return value;
}

WaveFile * initWaveFile()
{
    WaveFile * waveFile = new WaveFile();

    waveFile->file = nullptr;
    waveFile->formatChunk = nullptr;
    waveFile->waveHeader = nullptr;
    waveFile->dataChunk = nullptr;
    waveFile->cueChunk = nullptr;
    waveFile->filePath = nullptr;
    waveFile->listChunks = nullptr;
    waveFile->listCount = 0;

    return waveFile;
}

WaveFile * processFile(WaveFile * waveFile);

WaveFile * waveOpenHFile(int handle)
{
    WaveFile * waveFile = initWaveFile();
    if(waveFile == nullptr)
    {
        std::cout << "[waveOpenHFile] Memory Allocation Error: Could not allocate memory for Wave File" << std::endl;
        return nullptr;
    }

    waveFile->filePath = nullptr;

    waveFile->file = fdopen(handle, "rb");
    if(waveFile->file == nullptr)
    {
        std::cout << "[waveOpenHFile] Could not open input file " << waveFile->filePath << std::endl;
        waveCloseFile(waveFile);
        return nullptr;
    }
    return processFile(waveFile);
}

WaveFile * waveOpenFile(const std::string& path)
{
    WaveFile * waveFile = initWaveFile();
    if(waveFile == nullptr)
    {
        std::cout << "[waveOpenFile] Memory Allocation Error: Could not allocate memory for Wave File" << std::endl;
        return nullptr;
    }

    waveFile->filePath = (char *)calloc(path.length()+1, sizeof(char));
    strncpy(waveFile->filePath, path.c_str(), path.length());

#ifdef _WIN32
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    std::wstring wide_path = converter.from_bytes(path);
    waveFile->file = _wfopen(wide_path.c_str(), L"rb");
#else
    waveFile->file = fopen(path.c_str(), "rb");
#endif

    if(waveFile->file == nullptr)
    {
        std::cout << "[waveOpenFile] Could not open input file " << waveFile->filePath << std::endl;
        waveCloseFile(waveFile);
        return nullptr;
    }

    waveFile = processFile(waveFile);

    if (waveFile != nullptr && waveFile->file != nullptr)
    {
        fclose(waveFile->file);
        waveFile->file = nullptr;
    }

    return waveFile;
}
WaveFile * processFile(WaveFile * waveFile)
{
    ChunkLocation formatChunkExtraBytes = {0,0};
    ChunkLocation dataChunkLocation = {0,0};
    ChunkLocation otherChunkLocation = {0,0};

    waveFile->waveHeader = (WaveHeader *) malloc(sizeof(WaveHeader));
    if(waveFile->waveHeader == nullptr)
    {
        std::cout << "[processFile] Memory Allocation Error: Could not allocate memory for Wave File Header" << std::endl;
        waveCloseFile(waveFile);
        return nullptr;
    }
    fread(waveFile->waveHeader, sizeof(WaveHeader), 1, waveFile->file);
    if (ferror(waveFile->file) != 0)
    {
        std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
        waveCloseFile(waveFile);
        return nullptr;
    }

    if (strncmp(&(waveFile->waveHeader->chunkID[0]), "RIFF", 4) != 0)
    {
        std::cout << "[processFile] Input file is not a RIFF file" << std::endl;
        waveCloseFile(waveFile);
        return nullptr;
    }

    if (strncmp(&(waveFile->waveHeader->riffType[0]), "WAVE", 4) != 0)
    {
        std::cout << "[processFile] Input file is not a WAVE file" << std::endl;
        waveCloseFile(waveFile);
        return nullptr;
    }

    uint32_t remainingFileSize = littleEndianBytesToUInt32(waveFile->waveHeader->dataSize);
    int size = remainingFileSize - sizeof(waveFile->waveHeader->riffType); // dataSize does not counf the chunkID or the dataSize, so remove the riffType size to get the length of the rest of the file.

    if (size <= 0)
    {
        std::cout << "[processFile] Input file is an empty WAVE file" << std::endl;
        waveCloseFile(waveFile);
        return nullptr;
    }

    waveFile->listCount = 0;
    waveFile->listChunks = nullptr;

    while (1)
    {
        char nextChunkID[4];

        fread(&nextChunkID[0], sizeof(nextChunkID), 1, waveFile->file);
        if (feof(waveFile->file))
        {
            break;
        }

        if (ferror(waveFile->file) != 0)
        {
            std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
            waveCloseFile(waveFile);
            return nullptr;
        }

        if (strncmp(&nextChunkID[0], "fmt ", 4) == 0)
        {
            std::cout << "[processFile] Found FMT chunk" << std::endl;
            waveFile->formatChunk = (FormatChunk *)malloc(sizeof(FormatChunk));
            if (waveFile->formatChunk == NULL)
            {
                std::cout << "[processFile] Memory Allocation Error: Could not allocate memory for Wave File Format Chunk" << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            fseek(waveFile->file, -4, SEEK_CUR);
            fread(waveFile->formatChunk, sizeof(FormatChunk), 1, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            if (littleEndianBytesToUInt16(waveFile->formatChunk->compressionCode) != (uint16_t)1)
            {
                std::cout << "[processFile] Compressed audio formats are not supported" << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            // Note: For compressed audio data there may be extra bytes appended to the format chunk,
            // but as we are only handling uncompressed data we shouldn't encounter them

            // There may or may not be extra data at the end of the fomat chunk.  For uncompressed audio there should be no need, but some files may still have it.
            // if formatChunk.chunkDataSize > 16 (16 = the number of bytes for the format chunk, not counting the 4 byte ID and the chunkDataSize itself) there is extra data
            uint32_t extraFormatBytesCount = littleEndianBytesToUInt32(waveFile->formatChunk->chunkDataSize) - 16;
            if (extraFormatBytesCount > 0)
            {
                formatChunkExtraBytes.startOffset = ftell(waveFile->file);
                formatChunkExtraBytes.size = extraFormatBytesCount;
                fseek(waveFile->file, extraFormatBytesCount, SEEK_CUR);
                if (extraFormatBytesCount % 2 != 0)
                {
                    fseek(waveFile->file, 1, SEEK_CUR);
                }
            }
        }

        else if (strncmp(&nextChunkID[0], "data", 4) == 0)
        {
            std::cout << "[processFile] Found DATA chunk" << std::endl;

            waveFile->dataChunk = (DataChunk *)malloc(sizeof(DataChunk));
            if (waveFile->dataChunk == nullptr)
            {
                std::cout << "[processFile] Memory Allocation Error: Could not allocate memory for Wave File Data Chunk" << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            waveFile->dataChunk->chunkID[0] = 'd';
            waveFile->dataChunk->chunkID[1] = 'a';
            waveFile->dataChunk->chunkID[2] = 't';
            waveFile->dataChunk->chunkID[3] = 'a';

            dataChunkLocation.startOffset = ftell(waveFile->file) - sizeof(nextChunkID);

            // The next 4 bytes are the chunk data size - the size of the sample data
            char sampleDataSizeBytes[4];
            fread(sampleDataSizeBytes, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            uint32_t sampleDataSize = littleEndianBytesToUInt32(sampleDataSizeBytes);

            dataChunkLocation.size = sizeof(nextChunkID) + sizeof(sampleDataSizeBytes) + sampleDataSize;

            uint32ToLittleEndianBytes(sampleDataSize, waveFile->dataChunk->chunkDataSize);

            // TODO: check if no errors in allocate and read data
            waveFile->dataChunk->waveformData = (char *) malloc(sampleDataSize);
            fread(waveFile->dataChunk->waveformData, sampleDataSize, 1, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            // Skip to the end of the chunk.  Chunks must be aligned to 2 byte boundaries, but any padding at the end of a chunk is not included in the chunkDataSize
            if (sampleDataSize % 2 != 0)
            {
                fseek(waveFile->file, 1, SEEK_CUR);
            }
        }

        else if (strncmp(&nextChunkID[0], "cue ", 4) == 0)
        {
            std::cout << "[processFile] Found CUE chunk" << std::endl;

            char cueChunkDataSizeBytes[4];
            fread(cueChunkDataSizeBytes, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            uint32_t cueChunkDataSize = littleEndianBytesToUInt32(cueChunkDataSizeBytes);

            char cuePointsCountBytes[4];
            fread(cuePointsCountBytes, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            uint32_t cuePointsCount = littleEndianBytesToUInt32(cuePointsCountBytes);

            // Read in the existing cue points into CuePoint Structs
            CuePoint *existingCuePoints = (CuePoint *)malloc(sizeof(CuePoint) * cuePointsCount);
            for (uint32_t cuePointIndex = 0; cuePointIndex < cuePointsCount; cuePointIndex++)
            {
                CuePoint * cue_point = &existingCuePoints[cuePointIndex];
                std::cout << "[processFile] Found CUE POINT " << cuePointIndex << std::endl;
                fread(cue_point, sizeof(CuePoint), 1, waveFile->file);
                if (ferror(waveFile->file) != 0)
                {
                    std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                    waveCloseFile(waveFile);
                    free(existingCuePoints);
                    return nullptr;
                }
                std::cout << "[processFile] Read CUE POINT cuePointID " << INT32(cue_point->cuePointID) << std::endl;
                std::cout << "[processFile] Read CUE POINT playOrderPosition " << INT32(cue_point->playOrderPosition) << std::endl;
                std::cout << "[processFile] Read CUE POINT dataChunkID " << cue_point->dataChunkID[0] << cue_point->dataChunkID[1] << cue_point->dataChunkID[2] << cue_point->dataChunkID[3] << std::endl;
                std::cout << "[processFile] Read CUE POINT chunkStart " << INT32(cue_point->chunkStart) << std::endl;
                std::cout << "[processFile] Read CUE POINT blockStart " << INT32(cue_point->blockStart) << std::endl;
                std::cout << "[processFile] Read CUE POINT frameOffset " << INT32(cue_point->frameOffset) << std::endl;
            }

            // Populate the existingCueChunk struct
            waveFile->cueChunk = (CueChunk *) malloc(sizeof(CueChunk));
            if (waveFile->dataChunk == nullptr)
            {
                std::cout << "[processFile] Memory Allocation Error: Could not allocate memory for Wave File Cue Chunk" << std::endl;
                waveCloseFile(waveFile);
                free(existingCuePoints);
                return nullptr;
            }
            waveFile->cueChunk->chunkID[0] = 'c';
            waveFile->cueChunk->chunkID[1] = 'u';
            waveFile->cueChunk->chunkID[2] = 'e';
            waveFile->cueChunk->chunkID[3] = ' ';
            uint32ToLittleEndianBytes(cueChunkDataSize, waveFile->cueChunk->chunkDataSize);
            uint32ToLittleEndianBytes(cuePointsCount, waveFile->cueChunk->cuePointsCount);
            waveFile->cueChunk->cuePoints = existingCuePoints;

            std::cout << "[processFile] Read CUE chunkID " << waveFile->cueChunk->chunkID[0] << waveFile->cueChunk->chunkID[1] << waveFile->cueChunk->chunkID[2] << waveFile->cueChunk->chunkID[3] << std::endl;
            std::cout << "[processFile] Read CUE chunkDataSize " << INT32(waveFile->cueChunk->chunkDataSize) << std::endl;
            std::cout << "[processFile] Read CUE cuePointsCount " << INT32(waveFile->cueChunk->cuePointsCount) << std::endl;
        }
        else if (strncmp(&nextChunkID[0], "LIST", 4) == 0)
        {
            std::cout << "[processFile] Found LIST chunk" << std::endl;
            // We found an existing List Chunk
            waveFile->listChunks = (ListChunk*)realloc(waveFile->listChunks, sizeof(ListChunk)*(waveFile->listCount+1));

            ListChunk * listChunk = &waveFile->listChunks[waveFile->listCount];

            waveFile->listCount++;

            if (waveFile->dataChunk == nullptr)
            {
                std::cout << "[processFile] Memory Allocation Error: Could not allocate memory for Wave File Cue Chunk" << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            listChunk->chunkID[0] = 'L';
            listChunk->chunkID[1] = 'I';
            listChunk->chunkID[2] = 'S';
            listChunk->chunkID[3] = 'T';

            listChunk->lablChunks = nullptr;
            listChunk->ltxtChunks = nullptr;
            listChunk->lablCount = 0;
            listChunk->ltxtCount = 0;

            char listChunkDataSizeBytes[4];
            fread(listChunkDataSizeBytes, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            uint32_t listChunkDataSize = littleEndianBytesToUInt32(listChunkDataSizeBytes);
            uint32ToLittleEndianBytes(listChunkDataSize, listChunk->chunkDataSize);

            fread(listChunk->typeID, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            std::cout << "[processFile] Read LIST chunkID " << listChunk->chunkID[0] << listChunk->chunkID[1] << listChunk->chunkID[2] << listChunk->chunkID[3] << std::endl;
            std::cout << "[processFile] Read LIST chunkDataSize " << INT32(listChunk->chunkDataSize) << std::endl;
            std::cout << "[processFile] Read LIST typeID " << listChunk->typeID[0] << listChunk->typeID[1] << listChunk->typeID[2] << listChunk->typeID[3] << std::endl;
        }
        else if (strncmp(&nextChunkID[0], "ltxt", 4) == 0)
        {
            std::cout << "[processFile] Found LTXT chunk" << std::endl;
            ListChunk * listChunk = &(waveFile->listChunks[waveFile->listCount-1]);
            std::cout << "[processFile] listCount " << waveFile->listCount << std::endl;

            // We found an existing LTXT chunk in LIST chunk
            listChunk->ltxtChunks = (LtxtChunk *)realloc(listChunk->ltxtChunks, sizeof(LtxtChunk)*(listChunk->ltxtCount+1));

            LtxtChunk * ltxtChunk = &(listChunk->ltxtChunks[listChunk->ltxtCount]);

            listChunk->ltxtCount++;

            if (ltxtChunk == nullptr)
            {
                std::cout << "[processFile] Memory Allocation Error: Could not allocate memory for Wave File LABL chunk" << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            ltxtChunk->chunkID[0] = 'l';
            ltxtChunk->chunkID[1] = 't';
            ltxtChunk->chunkID[2] = 'x';
            ltxtChunk->chunkID[3] = 't';

            char ltxtChunkDataSizeBytes[4];
            fread(ltxtChunkDataSizeBytes, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            uint32_t ltxtChunkDataSize = littleEndianBytesToUInt32(ltxtChunkDataSizeBytes);
            uint32ToLittleEndianBytes(ltxtChunkDataSize, ltxtChunk->chunkDataSize);

            fread(ltxtChunk->cuePointID, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            fread(ltxtChunk->sampleLength, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            fread(ltxtChunk->purposeID, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            fread(ltxtChunk->country, sizeof(char), 2, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            fread(ltxtChunk->language, sizeof(char), 2, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            fread(ltxtChunk->dialect, sizeof(char), 2, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            fread(ltxtChunk->codePage, sizeof(char), 2, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            std::cout << "[processFile] LTXT dataSize " << ltxtChunkDataSize << std::endl;

            ltxtChunkDataSize = to_odd(ltxtChunkDataSize);

            if(ltxtChunkDataSize > 20) {
                ltxtChunk->text = (char *) malloc(ltxtChunkDataSize-20);
                fread(ltxtChunk->text, ltxtChunkDataSize-20, 1, waveFile->file);

                std::cout << "[processFile] LTXT text " << ltxtChunk->text << std::endl;
            } else {
                ltxtChunk->text = nullptr;

                std::cout << "[processFile] LTXT text <skip>" << std::endl;
            }
            std::cout << "[processFile] Read LTXT chunkID " << ltxtChunk->chunkID[0] << ltxtChunk->chunkID[1] << ltxtChunk->chunkID[2] << ltxtChunk->chunkID[3] << std::endl;
            std::cout << "[processFile] Read LTXT chunkDataSize " << INT32(ltxtChunk->chunkDataSize) << std::endl;
            std::cout << "[processFile] Read LTXT cuePointID " << INT32(ltxtChunk->cuePointID) << std::endl;
            std::cout << "[processFile] Read LTXT sampleLength " << INT32(ltxtChunk->sampleLength) << std::endl;
            std::cout << "[processFile] Read LTXT purposeID " << ltxtChunk->purposeID[0] << ltxtChunk->purposeID[1] << ltxtChunk->purposeID[2] << ltxtChunk->purposeID[3] << std::endl;
            std::cout << "[processFile] Read LTXT country " << INT16(ltxtChunk->country) << std::endl;
            std::cout << "[processFile] Read LTXT language " << INT16(ltxtChunk->language) << std::endl;
            std::cout << "[processFile] Read LTXT dialect " << INT16(ltxtChunk->dialect) << std::endl;
            std::cout << "[processFile] Read LTXT codePage " << INT16(ltxtChunk->codePage) << std::endl;
        }
        else if (strncmp(&nextChunkID[0], "labl", 4) == 0)
        {
            std::cout << "[processFile] Found LABL chunk" << std::endl;
            ListChunk * listChunk = &waveFile->listChunks[waveFile->listCount-1];

            // We found an existing LABL chunk in LIST chunk
            listChunk->lablChunks = (LablChunk *)realloc(listChunk->lablChunks, sizeof(LablChunk)*(listChunk->lablCount+1));

            LablChunk * lablChunk = &listChunk->lablChunks[listChunk->lablCount];

            listChunk->lablCount++;

            if (lablChunk == nullptr)
            {
                std::cout << "[processFile] Memory Allocation Error: Could not allocate memory for Wave File LABL chunk" << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            lablChunk->chunkID[0] = 'l';
            lablChunk->chunkID[1] = 'a';
            lablChunk->chunkID[2] = 'b';
            lablChunk->chunkID[3] = 'l';

            char lablChunkDataSizeBytes[4];
            fread(lablChunkDataSizeBytes, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            uint32_t lablChunkDataSize = littleEndianBytesToUInt32(lablChunkDataSizeBytes);
            uint32ToLittleEndianBytes(lablChunkDataSize, lablChunk->chunkDataSize);

            fread(lablChunk->cuePointID, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }

            std::cout << "[processFile] LABL dataSize " << lablChunkDataSize << std::endl;

            lablChunkDataSize = to_odd(lablChunkDataSize);

            if (lablChunkDataSize > 4)
            {
                lablChunk->text = (char *) malloc(lablChunkDataSize - 4);
                fread(lablChunk->text, sizeof(char), lablChunkDataSize - 4, waveFile->file);

                std::cout << "[processFile] LABL text " << lablChunk->text << std::endl;
            } else {
                lablChunk->text = nullptr;

                std::cout << "[processFile] LABL text <skip>" << std::endl;
            }
            std::cout << "[processFile] Read LABL chunkID " << lablChunk->chunkID[0] << lablChunk->chunkID[1] << lablChunk->chunkID[2] << lablChunk->chunkID[3] << std::endl;
            std::cout << "[processFile] Read LABL chunkDataSize " << INT32(lablChunk->chunkDataSize) << std::endl;
            std::cout << "[processFile] Read LABL cuePointID " << INT32(lablChunk->cuePointID) << std::endl;
        }
        else
        {
            std::cout << "[processFile] Found unsuppoted chunk " << nextChunkID << std::endl;
            // We have found a chunk type that we are not going to work with.
            // ISFTL
            // IENGL
            // ICRDL
            otherChunkLocation.startOffset = ftell(waveFile->file) - sizeof(nextChunkID);

            char chunkDataSizeBytes[4] = {0};
            fread(chunkDataSizeBytes, sizeof(char), 4, waveFile->file);
            if (ferror(waveFile->file) != 0)
            {
                std::cout << "[processFile] Error reading input file " << waveFile->filePath << std::endl;
                waveCloseFile(waveFile);
                return nullptr;
            }
            uint32_t chunkDataSize = littleEndianBytesToUInt32(chunkDataSizeBytes);

            otherChunkLocation.size = sizeof(nextChunkID) + sizeof(chunkDataSizeBytes) + chunkDataSize;

            // Skip over the chunk's data, and any padding byte
            fseek(waveFile->file, chunkDataSize, SEEK_CUR);
            if (chunkDataSize % 2 != 0)
            {
                fseek(waveFile->file, 1, SEEK_CUR);
            }
        }
    }

    return waveFile;
}

void waveCloseFile(WaveFile *waveFile)
{
    // TODO: free allocated memory in stucts
    if(waveFile == nullptr) return;
    if(waveFile->file != nullptr)
    {
        fclose(waveFile->file);
        waveFile->file = nullptr;
    }
    if(waveFile->formatChunk != nullptr) free(waveFile->formatChunk);
    if(waveFile->waveHeader != nullptr) free(waveFile->waveHeader);
    if(waveFile->dataChunk != nullptr)
    {
        if (waveFile->dataChunk->isWaveformDataOwned == 1)
        {
            free(waveFile->dataChunk->waveformData);
        }
        free(waveFile->dataChunk);
    }
    if(waveFile->cueChunk != nullptr) free(waveFile->cueChunk);
    if(waveFile->listChunks != nullptr)
    {
        free(waveFile->listChunks);
    }
    if(waveFile->filePath != nullptr) free(waveFile->filePath);
    free(waveFile);
}

WaveFile * waveCloneFile(WaveFile *waveFile)
{
    WaveFile *clone = initWaveFile();

    clone->waveHeader = makeWaveHeader(
        INT32(waveFile->waveHeader->dataSize)
    );

    clone->formatChunk = makeFormatChunk(
        INT16(waveFile->formatChunk->numberOfChannels),
        INT32(waveFile->formatChunk->sampleRate),
        INT16(waveFile->formatChunk->significantBitsPerSample)
    );

    char * data = (char*) malloc(INT32(waveFile->dataChunk->chunkDataSize));
    memcpy(data, waveFile->dataChunk->waveformData, INT32(waveFile->dataChunk->chunkDataSize));
    clone->dataChunk = makeDataChunk(
        INT32(waveFile->dataChunk->chunkDataSize),
        data
    );

    CuePoint * cuePoints = (CuePoint *) malloc(sizeof(CuePoint) * INT32(waveFile->cueChunk->cuePointsCount));
    for (int i=0; i<INT32(waveFile->cueChunk->cuePointsCount); i++)
    {
        cuePoints[i] = *makeCuePoint(
            INT32(waveFile->cueChunk->cuePoints[i].cuePointID),
            INT32(waveFile->cueChunk->cuePoints[i].playOrderPosition),
            INT32(waveFile->cueChunk->cuePoints[i].chunkStart),
            INT32(waveFile->cueChunk->cuePoints[i].blockStart),
            INT32(waveFile->cueChunk->cuePoints[i].frameOffset)
        );
    }
    clone->cueChunk = makeCueChunk(
        INT32(waveFile->cueChunk->cuePointsCount),
        cuePoints
    );

    LtxtChunk * ltxtChunks = (LtxtChunk *) malloc(sizeof(LtxtChunk) * INT32(waveFile->cueChunk->cuePointsCount));
    LablChunk * lablChunks = (LablChunk *) malloc(sizeof(LablChunk) * INT32(waveFile->cueChunk->cuePointsCount));
    for (int i=0; i<INT32(waveFile->cueChunk->cuePointsCount); i++)
    {
        ltxtChunks[i] = *makeLtxtChunk(
            INT32(waveFile->listChunks[0].ltxtChunks[i].cuePointID),
            INT32(waveFile->listChunks[0].ltxtChunks[i].sampleLength),
            INT16(waveFile->listChunks[0].ltxtChunks[i].country),
            INT16(waveFile->listChunks[0].ltxtChunks[i].language),
            INT16(waveFile->listChunks[0].ltxtChunks[i].dialect),
            INT16(waveFile->listChunks[0].ltxtChunks[i].codePage),
            waveFile->listChunks[0].ltxtChunks[i].text
        );
        lablChunks[i] = *makeLablChunk(
            INT32(waveFile->listChunks[0].lablChunks[i].cuePointID),
            waveFile->listChunks[0].lablChunks[i].text
        );
    }
    clone->listCount = 1;
    clone->listChunks = makeListChunk(
        INT32(waveFile->cueChunk->cuePointsCount),
        ltxtChunks,
        INT32(waveFile->cueChunk->cuePointsCount),
        lablChunks
    );

    return clone;
}

WaveHeader * makeWaveHeader(uint32_t dataSize)
{
    WaveHeader * header = (WaveHeader *) malloc(sizeof(WaveHeader));
    uint32ToLittleEndianBytes(dataSize, header->dataSize);
    header->chunkID[0] = 'R';
    header->chunkID[1] = 'I';
    header->chunkID[2] = 'F';
    header->chunkID[3] = 'F';
    header->riffType[0] = 'W';
    header->riffType[1] = 'A';
    header->riffType[2] = 'V';
    header->riffType[3] = 'E';
    return header;
}

FormatChunk * makeFormatChunk(
        uint16_t numberOfChannels,
        uint32_t sampleRate,
        uint16_t significantBitsPerSample
) {
    FormatChunk * format = (FormatChunk *) malloc(sizeof(FormatChunk));
    format->chunkID[0] = 'f';
    format->chunkID[1] = 'm';
    format->chunkID[2] = 't';
    format->chunkID[3] = ' ';
    // Unsigned 4-byte little endian int: Byte count for the remainder of the chunk: 16 + extraFormatbytes.
    uint32ToLittleEndianBytes(16, format->chunkDataSize);
    // Unsigned 2-byte little endian int
    uint16ToLittleEndianBytes(1, format->compressionCode);
    // Unsigned 2-byte little endian int
    uint16ToLittleEndianBytes(numberOfChannels, format->numberOfChannels);
    // Unsigned 4-byte little endian int
    uint32ToLittleEndianBytes(sampleRate, format->sampleRate);
    // Unsigned 2-byte little endian int: The number of bytes per sample slice. This value is not affected by the
    // number of channels and can be calculated with the formula: blockAlign = significantBitsPerSample / 8 * numberOfChannels
    uint16_t blockAlign = significantBitsPerSample / 8 * numberOfChannels;
    uint16ToLittleEndianBytes(blockAlign, format->blockAlign);
    // Unsigned 4-byte little endian int: This value indicates how many bytes of wave data must be streamed to a
    // D/A converter per second in order to play the wave file. This information is useful when determining if data
    // can be streamed from the source fast enough to keep up with playback. = SampleRate * BlockAlign.
    uint32ToLittleEndianBytes(sampleRate * blockAlign, format->averageBytesPerSecond);
    // Unsigned 2-byte little endian int
    uint16ToLittleEndianBytes(significantBitsPerSample, format->significantBitsPerSample);
    return format;
}

DataChunk * makeDataChunk(
        uint32_t waveformDataSize,
        char *waveformData
) {
    DataChunk * data = (DataChunk *) malloc(sizeof(DataChunk));
    data->chunkID[0] = 'd';
    data->chunkID[1] = 'a';
    data->chunkID[2] = 't';
    data->chunkID[3] = 'a';
    uint32ToLittleEndianBytes(waveformDataSize, data->chunkDataSize);
    data->waveformData = (char *)malloc(waveformDataSize);
    memcpy(data->waveformData, waveformData, waveformDataSize);
    data->isWaveformDataOwned = 1;
    return data;
}

CueChunk * makeCueChunk(
        uint32_t cuePointsCount,
        CuePoint *cuePoints
) {
    CueChunk * chunk = (CueChunk *) malloc(sizeof(CueChunk));
    chunk->chunkID[0] = 'c';
    chunk->chunkID[1] = 'u';
    chunk->chunkID[2] = 'e';
    chunk->chunkID[3] = ' ';
    uint32_t chunkDataSize = 4 + 24 * cuePointsCount;
    uint32ToLittleEndianBytes(chunkDataSize, chunk->chunkDataSize);
    uint32ToLittleEndianBytes(cuePointsCount, chunk->cuePointsCount);
    chunk->cuePoints = cuePoints;
    return chunk;
}

CuePoint * makeCuePoint(
        uint32_t cuePointID,
        uint32_t playOrderPosition,
        uint32_t chunkStart,
        uint32_t blockStart,
        uint32_t frameOffset
) {
    CuePoint * chunk = (CuePoint *) malloc(sizeof(CuePoint));
    uint32ToLittleEndianBytes(cuePointID, chunk->cuePointID);
    uint32ToLittleEndianBytes(playOrderPosition, chunk->playOrderPosition);
    chunk->dataChunkID[0] = 'd';
    chunk->dataChunkID[1] = 'a';
    chunk->dataChunkID[2] = 't';
    chunk->dataChunkID[3] = 'a';
    uint32ToLittleEndianBytes(chunkStart, chunk->chunkStart);
    uint32ToLittleEndianBytes(blockStart, chunk->blockStart);
    uint32ToLittleEndianBytes(frameOffset, chunk->frameOffset);
    return chunk;
}

ListChunk * makeListChunk(
        uint32_t ltxtCount,
        LtxtChunk *ltxtChunks,
        uint32_t lablCount,
        LablChunk *lablChunks
) {
    ListChunk * chunk = (ListChunk *) malloc(sizeof(ListChunk));

    chunk->ltxtCount = 0;
    chunk->ltxtChunks = nullptr;
    chunk->lablCount = 0;
    chunk->lablChunks = nullptr;

    chunk->chunkID[0] = 'L';
    chunk->chunkID[1] = 'I';
    chunk->chunkID[2] = 'S';
    chunk->chunkID[3] = 'T';

    chunk->typeID[0] = 'a';
    chunk->typeID[1] = 'd';
    chunk->typeID[2] = 't';
    chunk->typeID[3] = 'l';

    uint32_t chunkDataSize = 4;

    if (ltxtCount > 0)
    {
        for (int i=0; i<ltxtCount; i++)
        {
            chunkDataSize += 8 + littleEndianBytesToUInt32(ltxtChunks[i].chunkDataSize);
        }
        uint32ToLittleEndianBytes(chunkDataSize, chunk->chunkDataSize);
        chunk->ltxtCount = ltxtCount;
        chunk->ltxtChunks = ltxtChunks;
    }

    if (lablCount > 0)
    {
        for (int i=0; i<lablCount; i++)
        {
            chunkDataSize += 8 + littleEndianBytesToUInt32(lablChunks[i].chunkDataSize);
        }
        uint32ToLittleEndianBytes(chunkDataSize, chunk->chunkDataSize);
        chunk->lablCount = lablCount;
        chunk->lablChunks = lablChunks;
    }

    return chunk;
}

LtxtChunk * makeLtxtChunk(
        uint32_t cuePointID,
        uint32_t sampleLength,
        uint16_t country,
        uint16_t language,
        uint16_t dialect,
        uint16_t codePage,
        char *text
) {
    LtxtChunk * chunk = (LtxtChunk *) malloc(sizeof(LtxtChunk));
    chunk->chunkID[0] = 'l';
    chunk->chunkID[1] = 't';
    chunk->chunkID[2] = 'x';
    chunk->chunkID[3] = 't';
    chunk->purposeID[0] = 'r';
    chunk->purposeID[1] = 'g';
    chunk->purposeID[2] = 'n';
    chunk->purposeID[3] = ' ';
    uint32ToLittleEndianBytes(cuePointID, chunk->cuePointID);
    uint32ToLittleEndianBytes(sampleLength, chunk->sampleLength);
    if (country != 0) uint16ToLittleEndianBytes(country, chunk->country);
    else uint16ToLittleEndianBytes(0, chunk->country);
    if (language != 0) uint16ToLittleEndianBytes(language, chunk->language);
    else uint16ToLittleEndianBytes(0, chunk->language);
    if (dialect != 0) uint16ToLittleEndianBytes(dialect, chunk->dialect);
    else uint16ToLittleEndianBytes(0, chunk->dialect);
    if (codePage != 0) uint16ToLittleEndianBytes(codePage, chunk->codePage);
    else uint16ToLittleEndianBytes(0, chunk->codePage);
    uint32_t chunkDataSize = 20;
    if (text)
    {
        int text_size = to_odd((unsigned)strlen(text)+1);
        chunk->text = (char*) malloc(sizeof(char)*text_size);
        chunk->text[text_size-1] = 0;
        chunk->text[text_size-2] = 0;
        strcpy(chunk->text, text);

        chunkDataSize += sizeof(char) * text_size;
    } else {
        chunk->text = nullptr;
    }
    uint32ToLittleEndianBytes(chunkDataSize, chunk->chunkDataSize);
    return chunk;
}

LablChunk * makeLablChunk(
        uint32_t cuePointID,
        char *text
) {
    LablChunk * chunk = (LablChunk *) malloc(sizeof(LablChunk));
    chunk->chunkID[0] = 'l';
    chunk->chunkID[1] = 'a';
    chunk->chunkID[2] = 'b';
    chunk->chunkID[3] = 'l';
    uint32_t chunkDataSize = 4;
    uint32ToLittleEndianBytes(cuePointID, chunk->cuePointID);
    if (text)
    {
        int text_size = to_odd((unsigned)strlen(text)+1);
        chunk->text = (char*) malloc(sizeof(char)*text_size);
        chunk->text[text_size-1] = 0;
        chunk->text[text_size-2] = 0;
        strcpy(chunk->text, text);

        chunkDataSize += sizeof(char) * text_size;
    } else {
        chunk->text = nullptr;
    }
    uint32ToLittleEndianBytes(chunkDataSize, chunk->chunkDataSize);
    return chunk;
}

WaveFile * makeWaveFile(
        WaveHeader *waveHeader,
        FormatChunk *formatChunk,
        DataChunk *dataChunk,
        CueChunk *cueChunk,
        LtxtChunk *ltxtChunks,
        uint32_t ltxtChunksCount,
        LablChunk *lablChunks,
        uint32_t lablChunksCount
) {
    WaveFile *wave = initWaveFile();

    wave->file = nullptr;
    wave->waveHeader = waveHeader;
    wave->formatChunk = formatChunk;
    wave->dataChunk = dataChunk;
    wave->cueChunk = cueChunk;
    wave->listCount = 1;
    wave->listChunks = makeListChunk(ltxtChunksCount, ltxtChunks, lablChunksCount, lablChunks);

    uint32_t fileSize = 4;
    if(formatChunk != nullptr)
        fileSize += 8 + INT32(formatChunk->chunkDataSize);
    if(dataChunk != nullptr)
        fileSize += 8 + INT32(dataChunk->chunkDataSize);
    if(cueChunk != nullptr)
        fileSize += 8 + INT32(cueChunk->chunkDataSize);
    if(wave->listChunks != nullptr)
        fileSize += 8 + INT32(wave->listChunks->chunkDataSize);
    uint32ToLittleEndianBytes(fileSize, waveHeader->dataSize);

    return wave;
}

WaveFile * makeWaveFileFromRawData(
        char *waveformData,
        uint32_t waveformDataSize,
        uint16_t numberOfChannels,
        uint32_t sampleRate,
        uint16_t significantBitsPerSample,
        uint32_t pointsCount,
        uint32_t *pointsOffset,
        uint32_t *pointsLenght,
        char **pointsLabels
) {
    WaveHeader *headerChunk = makeWaveHeader(0);
    FormatChunk *formatChunk = makeFormatChunk(numberOfChannels, sampleRate, significantBitsPerSample);
    DataChunk *dataChunk = makeDataChunk(waveformDataSize, waveformData);
    dataChunk->isWaveformDataOwned = 0;

    CueChunk *cueChunk = nullptr;
    LtxtChunk *ltxtChunks = nullptr;
    uint32_t ltxtChunksCount = 0;
    LablChunk *lablChunks = nullptr;
    uint32_t lablChunksCount = 0;

    if (pointsCount > 0)
    {
        ltxtChunksCount = pointsCount;
        lablChunksCount = pointsCount;
        CuePoint * cuePoints = (CuePoint *) malloc(sizeof(CuePoint) * pointsCount);
        ltxtChunks = (LtxtChunk *) malloc(sizeof(LtxtChunk) * pointsCount);
        lablChunks = (LablChunk *) malloc(sizeof(LablChunk) * pointsCount);

        for (uint32_t i=0; i<pointsCount; i++)
        {
            uint32_t pintId = i + 1;
            CuePoint * cuePoint = makeCuePoint(
                        pintId,
                        pointsOffset[i],
                        0,
                        0,
                        pointsOffset[i]
            );
            cuePoints[i] = *cuePoint;
            free(cuePoint);

            LtxtChunk * ltxtChunk = makeLtxtChunk(
                        pintId,
                        pointsLenght[i],
                        0,
                        0,
                        0,
                        0,
                        nullptr
            );
            ltxtChunks[i] = *ltxtChunk;
            free(ltxtChunk);

            LablChunk * lablChunk = makeLablChunk(
                        pintId,
                        pointsLabels[i]
            );
            lablChunks[i] = *lablChunk;
            free(lablChunk);
        }

        cueChunk = makeCueChunk(pointsCount, cuePoints);
    }

    return makeWaveFile(
                headerChunk,
                formatChunk,
                dataChunk,
                cueChunk,
                ltxtChunks,
                ltxtChunksCount,
                lablChunks,
                lablChunksCount
    );
}

void saveWaveFile(WaveFile *waveFile, const std::string &filePath)
{
    if (!filePath.empty())
    {
        waveFile->filePath = (char *)malloc(1 + filePath.length());
        strcpy(waveFile->filePath, filePath.c_str());
    }
    if (waveFile->file == nullptr)
    {
#ifdef _WIN32
        std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
        std::wstring wide_path = converter.from_bytes(filePath);
        waveFile->file = _wfopen(wide_path.c_str(), L"wb");
#else
        waveFile->file = fopen(filePath.c_str(), "wb");
#endif
    }
    if (waveFile->file == nullptr)
    {
        std::cerr << "[saveWaveFile] Could not open output file " << filePath << std::endl;
        return;
    }
    if (waveFile->waveHeader != nullptr)
    {
        std::cout << "[saveWaveFile] Write HEADER chunk" << std::endl;
        if (fwrite(waveFile->waveHeader, sizeof(WaveHeader), 1, waveFile->file) < 1)
        {
            std::cerr << "[saveWaveFile] Error writing header to output file" << std::endl;
            return;
        }
    }
    if (waveFile->formatChunk != nullptr)
    {
        std::cout << "[saveWaveFile] Write FMT chunk" << std::endl;
        if (fwrite(waveFile->formatChunk, sizeof(FormatChunk), 1, waveFile->file) < 1)
        {
            std::cerr << "[saveWaveFile] Error writing format chunk to output file" << std::endl;
            return;
        }
    }
    if (waveFile->dataChunk != nullptr)
    {
        std::cout << "[saveWaveFile] Write DATA chunk" << std::endl;
        uint32_t dataChunkSize = littleEndianBytesToUInt32(waveFile->dataChunk->chunkDataSize);
        if (fwrite(waveFile->dataChunk->chunkID, sizeof(char), 4, waveFile->file) < 1)
        {
            std::cerr << "[saveWaveFile] Error writing data chunk (chunkID) to output file" << std::endl;
            return;
        }
        if (fwrite(waveFile->dataChunk->chunkDataSize, sizeof(char), 4, waveFile->file) < 1)
        {
            std::cerr << "[saveWaveFile] Error writing data chunk (chunkDataSize) to output file" << std::endl;
            return;
        }
        if (fwrite(waveFile->dataChunk->waveformData, dataChunkSize, 1, waveFile->file) < 1)
        {
            std::cerr << "[saveWaveFile] Size data chunk (waveformData) " << dataChunkSize << std::endl;
            std::cerr << "[saveWaveFile] Error writing data chunk (waveformData) to output file" << std::endl;
            return;
        }
        if (dataChunkSize % 2 != 0)
        {
            if (fwrite("\0", sizeof(char), 1, waveFile->file) < 1)
            {
                std::cerr << "[saveWaveFile] Error writing padding character to output file" << std::endl;
                return;

            }
        }
    }
    if  (waveFile->cueChunk != nullptr)
    {
        std::cout << "[saveWaveFile] Write CUE chunk" << std::endl;
        CueChunk * cue_chunk = waveFile->cueChunk;

        std::cout << "[saveWaveFile] Write CUE chunkID " << cue_chunk->chunkID[0] << cue_chunk->chunkID[1] << cue_chunk->chunkID[2] << cue_chunk->chunkID[3] << std::endl;
        if (fwrite(cue_chunk->chunkID, sizeof(char), 4, waveFile->file) < 1)
        {
            std::cerr << "[saveWaveFile] Error writing cue chunk (chunkID) to output file" << std::endl;
            return;
        }

        std::cout << "[saveWaveFile] Write CUE chunkDataSize " << INT32(cue_chunk->chunkDataSize) << std::endl;
        if (fwrite(cue_chunk->chunkDataSize, sizeof(char), 4, waveFile->file) < 1)
        {
            std::cerr << "[saveWaveFile] Error writing cue chunk (chunkDataSize) to output file" << std::endl;
            return;
        }

        std::cout << "[saveWaveFile] Write CUE cuePointsCount " << INT32(cue_chunk->cuePointsCount) << std::endl;
        if (fwrite(cue_chunk->cuePointsCount, sizeof(char), 4, waveFile->file) < 1)
        {
            std::cerr << "[saveWaveFile] Error writing cue chunk (cuePointsCount) to output file" << std::endl;
            return;
        }

        uint32_t cuePointsCount = littleEndianBytesToUInt32(cue_chunk->cuePointsCount);
        for (uint32_t i=0; i<cuePointsCount; i++)
        {
            std::cout << "[saveWaveFile] Write CUE POINT " << i << std::endl;
            CuePoint * cue_point = &cue_chunk->cuePoints[i];

            std::cout << "[saveWaveFile] Write CUE POINT cuePointID " << INT32(cue_point->cuePointID) << std::endl;
            if (fwrite(cue_point->cuePointID, sizeof(char), 4, waveFile->file) < 1)
            {
                std::cerr << "[saveWaveFile] Error writing cue point (cuePointID) to output file" << std::endl;
                return;
            }

            std::cout << "[saveWaveFile] Write CUE POINT playOrderPosition " << INT32(cue_point->playOrderPosition) << std::endl;
            if (fwrite(cue_point->playOrderPosition, sizeof(char), 4, waveFile->file) < 1)
            {
                std::cerr << "[saveWaveFile] Error writing cue point (playOrderPosition) to output file" << std::endl;
                return;
            }

            std::cout << "[saveWaveFile] Write CUE POINT dataChunkID " << cue_point->dataChunkID[0] << cue_point->dataChunkID[1] << cue_point->dataChunkID[2] << cue_point->dataChunkID[3] << std::endl;
            if (fwrite(cue_point->dataChunkID, sizeof(char), 4, waveFile->file) < 1)
            {
                std::cerr << "[saveWaveFile] Error writing cue point (dataChunkID) to output file" << std::endl;
                return;
            }

            std::cout << "[saveWaveFile] Write CUE POINT chunkStart " << INT32(cue_point->chunkStart) << std::endl;
            if (fwrite(cue_point->chunkStart, sizeof(char), 4, waveFile->file) < 1)
            {
                std::cerr << "[saveWaveFile] Error writing cue point (chunkStart) to output file" << std::endl;
                return;
            }

            std::cout << "[saveWaveFile] Write CUE POINT blockStart " << INT32(cue_point->blockStart) << std::endl;
            if (fwrite(cue_point->blockStart, sizeof(char), 4, waveFile->file) < 1)
            {
                std::cerr << "[saveWaveFile] Error writing cue point (blockStart) to output file" << std::endl;
                return;
            }

            std::cout << "[saveWaveFile] Write CUE POINT frameOffset " << INT32(cue_point->frameOffset) << std::endl;
            if (fwrite(cue_point->frameOffset, sizeof(char), 4, waveFile->file) < 1)
            {
                std::cerr << "[saveWaveFile] Error writing cue point (frameOffset) to output file" << std::endl;
                return;
            }
        }
    }
    if  (waveFile->listChunks != nullptr)
    {
        std::cout << "[saveWaveFile] Write LIST chunk" << std::endl;
        for (int listChunkIndex=0; listChunkIndex<waveFile->listCount; listChunkIndex++)
        {
            ListChunk * list_chunk = &waveFile->listChunks[listChunkIndex];

            if (list_chunk->lablCount == 0 && list_chunk->ltxtCount == 0) continue;

            std::cout << "[saveWaveFile] Write LIST chunkID " << list_chunk->chunkID[0] << list_chunk->chunkID[1] << list_chunk->chunkID[2] << list_chunk->chunkID[3] << std::endl;
            if (fwrite(list_chunk->chunkID, sizeof(char), 4, waveFile->file) < 1)
            {
                std::cerr << "[saveWaveFile] Error writing list chunk (chunkID) to output file" << std::endl;
                return;
            }

            std::cout << "[saveWaveFile] Write LIST chunkDataSize " << INT32(list_chunk->chunkDataSize) << std::endl;
            if (fwrite(list_chunk->chunkDataSize, sizeof(char), 4, waveFile->file) < 1)
            {
                std::cerr << "[saveWaveFile] Error writing list chunk (chunkDataSize) to output file" << std::endl;
                return;
            }

            std::cout << "[saveWaveFile] Write LIST typeID " << list_chunk->typeID[0] << list_chunk->typeID[1] << list_chunk->typeID[2] << list_chunk->typeID[3] << std::endl;
            if (fwrite(list_chunk->typeID, sizeof(char), 4, waveFile->file) < 1)
            {
                std::cerr << "[saveWaveFile] Error writing list chunk (typeID) to output file" << std::endl;
                return;
            }

            for( int i=0; i<list_chunk->ltxtCount; i++)
            {
                std::cout << "[saveWaveFile] Write LTXT chunk " << i << std::endl;
                LtxtChunk * ltxt_chank = &list_chunk->ltxtChunks[i];

                std::cout << "[saveWaveFile] Write LTXT chunkID " << ltxt_chank->chunkID[0] << ltxt_chank->chunkID[1] << ltxt_chank->chunkID[2] << ltxt_chank->chunkID[3] << std::endl;
                if (fwrite(ltxt_chank->chunkID, sizeof(char), 4, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LTXT chunk (chunkID) to output file" << std::endl;
                    return;
                }

                std::cout << "[saveWaveFile] Write LTXT chunkDataSize " << INT32(ltxt_chank->chunkDataSize) << std::endl;
                if (fwrite(ltxt_chank->chunkDataSize, sizeof(char), 4, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LTXT chunk (chunkDataSize) to output file" << std::endl;
                    return;
                }

                std::cout << "[saveWaveFile] Write LTXT cuePointID " << INT32(ltxt_chank->cuePointID) << std::endl;
                if (fwrite(ltxt_chank->cuePointID, sizeof(char), 4, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LTXT chunk (cuePointID) to output file" << std::endl;
                    return;
                }

                std::cout << "[saveWaveFile] Write LTXT sampleLength " << INT32(ltxt_chank->sampleLength) << std::endl;
                if (fwrite(ltxt_chank->sampleLength, sizeof(char), 4, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LTXT chunk (sampleLength) to output file" << std::endl;
                    return;
                }

                std::cout << "[saveWaveFile] Write LTXT purposeID " << ltxt_chank->purposeID[0] << ltxt_chank->purposeID[1] << ltxt_chank->purposeID[2] << ltxt_chank->purposeID[3] << std::endl;
                if (fwrite(ltxt_chank->purposeID, sizeof(char), 4, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LTXT chunk (purposeID) to output file" << std::endl;
                    return;
                }

                std::cout << "[saveWaveFile] Write LTXT country " << INT16(ltxt_chank->country) << std::endl;
                if (fwrite(ltxt_chank->country, sizeof(char), 2, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LTXT chunk (country) to output file" << std::endl;
                    return;
                }

                std::cout << "[saveWaveFile] Write LTXT language " << INT16(ltxt_chank->language) << std::endl;
                if (fwrite(ltxt_chank->language, sizeof(char), 2, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LTXT chunk (language) to output file" << std::endl;
                    return;
                }

                std::cout << "[saveWaveFile] Write LTXT dialect " << INT16(ltxt_chank->dialect) << std::endl;
                if (fwrite(ltxt_chank->dialect, sizeof(char), 2, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LTXT chunk (dialect) to output file" << std::endl;
                    return;
                }

                std::cout << "[saveWaveFile] Write LTXT codePage " << INT16(ltxt_chank->codePage) << std::endl;
                if (fwrite(ltxt_chank->codePage, sizeof(char), 2, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LTXT chunk (codePage) to output file" << std::endl;
                    return;
                }

                if (ltxt_chank->text)
                {
                    std::cout << "[saveWaveFile] Write LTXT text " << ltxt_chank->text << std::endl;
                    uint32_t size = littleEndianBytesToUInt32(ltxt_chank->chunkDataSize) - 20;
                    if (fwrite(ltxt_chank->text, sizeof(char), size, waveFile->file) < 1)
                    {
                        std::cerr << "[saveWaveFile] Error writing LTXT chunk (text) to output file" << std::endl;
                        return;
                    }
                } else {
                    std::cout << "[saveWaveFile] LTXT text <skip>" << std::endl;
                }
            }

            for(int i=0; i<list_chunk->lablCount; i++)
            {
                std::cout << "[saveWaveFile] Write LABL chunk " << i << std::endl;
                LablChunk * labl_chank = &list_chunk->lablChunks[i];

                std::cout << "[saveWaveFile] Write LABL chunkID " << labl_chank->chunkID[0] << labl_chank->chunkID[1] << labl_chank->chunkID[2] << labl_chank->chunkID[3] << std::endl;
                if (fwrite(labl_chank->chunkID, sizeof(char), 4, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LABL chunk (chunkID) to output file" << std::endl;
                    return;
                }

                std::cout << "[saveWaveFile] Write LABL chunkDataSize " << INT32(labl_chank->chunkDataSize) << std::endl;
                if (fwrite(labl_chank->chunkDataSize, sizeof(char), 4, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LABL chunk (chunkDataSize) to output file" << std::endl;
                    return;
                }

                std::cout << "[saveWaveFile] Write LABL cuePointID " << INT32(labl_chank->cuePointID) << std::endl;
                if (fwrite(labl_chank->cuePointID, sizeof(char), 4, waveFile->file) < 1)
                {
                    std::cerr << "[saveWaveFile] Error writing LABL chunk (cuePointID) to output file" << std::endl;
                    return;
                }

                if (labl_chank->text)
                {
                    std::cout << "[saveWaveFile] Write LABL text " << labl_chank->text << std::endl;
                    uint32_t size = littleEndianBytesToUInt32(labl_chank->chunkDataSize) - 4;
                    if(fwrite(labl_chank->text, sizeof(char), size, waveFile->file) < 1)
                    {
                        std::cerr << "[saveWaveFile] Error writing LABL chunk (text) to output file" << std::endl;
                        return;
                    }
                } else {
                    std::cout << "[saveWaveFile] LABL text <skip>" << std::endl;
                }
            }
        }
    }
    fclose(waveFile->file);
    waveFile->file = nullptr;
}

enum HostEndiannessType getHostEndianness()
{
    int i = 1;
    char *p = (char *)&i;

    if (p[0] == 1)
        return LittleEndian;
    else
        return BigEndian;
}

uint32_t littleEndianBytesToUInt32(char littleEndianBytes[4])
{
    if (HostEndianness == EndiannessUndefined)
    {
        HostEndianness = getHostEndianness();
    }

    uint32_t uInt32Value;
    char *uintValueBytes = (char *)&uInt32Value;

    if (HostEndianness == LittleEndian)
    {
        uintValueBytes[0] = littleEndianBytes[0];
        uintValueBytes[1] = littleEndianBytes[1];
        uintValueBytes[2] = littleEndianBytes[2];
        uintValueBytes[3] = littleEndianBytes[3];
    }
    else
    {
        uintValueBytes[0] = littleEndianBytes[3];
        uintValueBytes[1] = littleEndianBytes[2];
        uintValueBytes[2] = littleEndianBytes[1];
        uintValueBytes[3] = littleEndianBytes[0];
    }

    return uInt32Value;
}

void uint32ToLittleEndianBytes(uint32_t uInt32Value, char out_LittleEndianBytes[4])
{
    if (HostEndianness == EndiannessUndefined)
    {
        HostEndianness = getHostEndianness();
    }

    char *uintValueBytes = (char *)&uInt32Value;

    if (HostEndianness == LittleEndian)
    {
        out_LittleEndianBytes[0] = uintValueBytes[0];
        out_LittleEndianBytes[1] = uintValueBytes[1];
        out_LittleEndianBytes[2] = uintValueBytes[2];
        out_LittleEndianBytes[3] = uintValueBytes[3];
    }
    else
    {
        out_LittleEndianBytes[0] = uintValueBytes[3];
        out_LittleEndianBytes[1] = uintValueBytes[2];
        out_LittleEndianBytes[2] = uintValueBytes[1];
        out_LittleEndianBytes[3] = uintValueBytes[0];
    }
}

uint16_t littleEndianBytesToUInt16(char littleEndianBytes[2])
{
    if (HostEndianness == EndiannessUndefined)
    {
        HostEndianness = getHostEndianness();
    }

    uint32_t uInt16Value;
    char *uintValueBytes = (char *)&uInt16Value;

    if (HostEndianness == LittleEndian)
    {
        uintValueBytes[0] = littleEndianBytes[0];
        uintValueBytes[1] = littleEndianBytes[1];
    }
    else
    {
        uintValueBytes[0] = littleEndianBytes[1];
        uintValueBytes[1] = littleEndianBytes[0];
    }

    return uInt16Value;
}

void uint16ToLittleEndianBytes(uint16_t uInt16Value, char out_LittleEndianBytes[2])
{
    if (HostEndianness == EndiannessUndefined)
    {
        HostEndianness = getHostEndianness();
    }

    char *uintValueBytes = (char *)&uInt16Value;

    if (HostEndianness == LittleEndian)
    {
        out_LittleEndianBytes[0] = uintValueBytes[0];
        out_LittleEndianBytes[1] = uintValueBytes[1];
    }
    else
    {
        out_LittleEndianBytes[0] = uintValueBytes[1];
        out_LittleEndianBytes[1] = uintValueBytes[0];
    }
}

std::vector<double> waveformDataToVector(void *data, uint32_t byteSize, uint16_t bitDepth)
{
    std::vector<double> samples;
    int numSamples = byteSize / (bitDepth / 8);

    if (bitDepth == 16) {
        std::cout << "bit depth" << bitDepth << std::endl;
        int16_t *data_int16 = static_cast<int16_t*>(data);
        for (int i = 0; i < numSamples; i++) {
            samples.push_back(static_cast<double>(data_int16[i]) / 32768.0);
        }
    } else if (bitDepth == 8) {
        std::cout << "bit depth" << bitDepth << std::endl;
        uint8_t *data_int8 = static_cast<uint8_t*>(data);
        for (int i = 0; i < numSamples; i++) {
            samples.push_back((static_cast<double>(data_int8[i]) - 128.0) / 128.0);
        }
    } else if (bitDepth == 24) {
        std::cout << "bit depth" << bitDepth << std::endl;
        int8_t* data_int8 = static_cast<int8_t*>(data);
        for (int i = 0; i < numSamples; i++)
        {
            int32_t value = 0;
            value |= (data_int8[i*3+2] << 16);
            value |= (data_int8[i*3+1] << 8);
            value |= (data_int8[i*3+0]);
            if (value & 0x800000)
            {
                value |= ~0xffffff;
            }
            samples.push_back(static_cast<double>(value) / 8388608.0);
        }
    } else if (bitDepth == 32) {
        std::cout << "bit depth" << bitDepth << std::endl;
        int32_t *data_int32 = static_cast<int32_t*>(data);
        for (int i = 0; i < numSamples; i++) {
            samples.push_back(static_cast<double>(data_int32[i]) / 2147483648.0);
        }
    } else {
        std::cout << "Unsupported bit depth:" << bitDepth << std::endl;
    }

    return samples;
}

