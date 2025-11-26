#include "src/services/wavfileservice.h"
#include "src/helpers/wavFile.h"
#include <iostream>

int main() {
    WavFileService service(".");
    // Just checking if it compiles and links
    WaveFile *wf = nullptr; 
    std::vector<double> data = WavFileService::readWaveData(wf);
    std::cout << "Data size: " << data.size() << std::endl;
    return 0;
}
