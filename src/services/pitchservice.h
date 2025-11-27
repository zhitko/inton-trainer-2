#ifndef PITCHSERVICE_H
#define PITCHSERVICE_H

#include <vector>
#include <string>

enum class PitchAlgorithm {
    RAPT,
    SWIPE,
    REAPER,
    DIO,
    Harvest,
    NumAlgorithm
};

enum class PitchOutputFormat {
    PITCH,
    F0,
    LOG_F0
};

class PitchService {
public:
    PitchService();
    ~PitchService();

    std::vector<double> getPitch(
        const std::vector<double>& inputWaveData,
        PitchAlgorithm algorithm,
        double frameShift,
        double sampleRate,
        double minF0,
        double maxF0,
        double voicingThreshold,
        PitchOutputFormat outputFormat
    );
};

#endif // PITCHSERVICE_H
