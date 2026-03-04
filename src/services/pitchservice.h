#ifndef PITCHSERVICE_H
#define PITCHSERVICE_H

#include <string>
#include <vector>

/**
 * PitchService provides methods for extracting pitch information from audio data
 * using various algorithms. It allows for configuring parameters such as frame
 * shift, sample rate, minimum and maximum F0, voicing threshold, and output
 * format. The service is designed to be flexible and can be used in different
 * contexts where pitch analysis is required, such as in the Inton Trainer
 * application for providing feedback on pitch accuracy.
 */
enum class PitchAlgorithm { RAPT,
    SWIPE,
    REAPER,
    DIO,
    Harvest,
    NumAlgorithm };

/**
 * PitchOutputFormat defines the format of the output pitch data, which can be
 * either in terms of pitch (e.g., MIDI note numbers), fundamental frequency (F0)
 * in Hz, or logarithmic F0 (logarithm of the fundamental frequency). This allows
 * for flexibility in how the pitch information is represented and used in
 * different parts of the application.
 */
enum class PitchOutputFormat { PITCH,
    F0,
    LOG_F0 };

/**
 * The PitchService class provides methods for extracting pitch information from
 * audio data using various algorithms. It allows for configuring parameters such
 * as frame shift, sample rate, minimum and maximum F0, voicing threshold, and
 * output format. The service is designed to be flexible and can be used in
 * different contexts where pitch analysis is required, such as in the Inton
 * Trainer application for providing feedback on pitch accuracy.
 */
class PitchService {
public:
    PitchService();
    ~PitchService();

    /**
     * Extracts the pitch contour from the given input waveform data using the
     * specified parameters and returns it as a vector of doubles. The method
     * allows for various configurations such as frame shift, sample rate, F0
     * range, voicing threshold, normalization mode, interpolation type, and
     * smoothing options.
     *
     * @param inputWaveData - A vector of doubles representing the input waveform
     * data (single channel).
     * @param algorithm - The pitch extraction algorithm to use (e.g., RAPT,
     * SWIPE).
     * @param frameShift - The frame shift in milliseconds for pitch extraction.
     * @param sampleRate - The sample rate to use for pitch extraction.
     * @param minF0 - The minimum F0 value for pitch extraction.
     * @param maxF0 - The maximum F0 value for pitch extraction.
     * @param voicingThreshold - The voicing threshold for pitch extraction.
     * @param outputFormat - The format of the output pitch data (e.g., PITCH,
     * F0, LOG_F0).
     * @return A vector of doubles containing the extracted pitch contour based on
     * the specified parameters.
     */
    std::vector<double> getPitch(const std::vector<double>& inputWaveData,
        PitchAlgorithm algorithm, double frameShift,
        double sampleRate, double minF0, double maxF0,
        double voicingThreshold,
        PitchOutputFormat outputFormat);
};

#endif // PITCHSERVICE_H
