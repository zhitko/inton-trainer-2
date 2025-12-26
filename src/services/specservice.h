#ifndef SPECSERVICE_H
#define SPECSERVICE_H

#include <vector>

class SpecService {
public:
    SpecService();
    ~SpecService();

    /**
     * Extract spectrum from waveform data using SPTK.
     * 
     * @param inputWaveData Input waveform data as vector of doubles
     * @param f0 Fundamental frequency (F0) data in Hz - should match the frame count
     * @param fftLength FFT length for spectrum analysis
     * @param frameShift Frame shift in samples (points)
     * @param sampleRate Sampling rate in Hz
     * @param f0Refinement Whether to refine F0 (default: false)
     * @return Vector of spectrum frames, where each frame is a vector of spectral values
     */
    std::vector<std::vector<double>> getSpec(
        const std::vector<double>& inputWaveData,
        const std::vector<double>& f0,
        int fftLength,
        int frameShift,
        double sampleRate,
        bool f0Refinement = false
    );

    /**
     * Extract cepstrum from waveform data.
     * 
     * @param inputWaveData Input waveform data as vector of doubles
     * @param f0 Fundamental frequency (F0) data in Hz
     * @param fftLength FFT length for spectrum analysis
     * @param frameShift Frame shift in samples
     * @param sampleRate Sampling rate in Hz
     * @param numOrder Order of cepstral coefficients
     * @param f0Refinement Whether to refine F0 (default: false)
     * @return Vector of cepstrum frames
     */
    std::vector<std::vector<double>> getCepstr(
        const std::vector<double>& inputWaveData,
        const std::vector<double>& f0,
        int fftLength,
        int frameShift,
        double sampleRate,
        int numOrder,
        bool f0Refinement = false
    );
};

#endif // SPECSERVICE_H
