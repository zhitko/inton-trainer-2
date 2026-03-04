#ifndef WAVFILEAPI_H
#define WAVFILEAPI_H

#include "src/services/helpers/wavFile.h"
#include <QObject>
#include <QVariant>

struct WaveFile;

/**
 * WavFileApi class provides methods for opening WAV files, extracting audio
 * data, pitch, spectrum, cepstrum, and amplitude information. It also includes
 * methods for comparing patterns using dynamic programming. This class is
 * designed to be used in a QML context, allowing for easy integration with the
 * UI components of the application. The methods in this class enable the
 * application to analyze audio files and provide feedback to the user based on
 * the extracted features.
 */
class WavFileApi : public QObject {
    Q_OBJECT
public:
    explicit WavFileApi(QObject* parent = nullptr);

public slots:
    /**
     * Opens a WAV file from the specified file path and returns a pointer to a
     * WaveFile object containing the audio data and metadata. This method
     * allows the application to load audio files for analysis and processing.
     *
     * @param filePath - The file path of the WAV file to be opened.
     * @return A pointer to a WaveFile object containing the loaded audio data
     * and metadata.
     */
    Q_INVOKABLE WaveFile* openWavFile(const QString& filePath);

    /**
     * Retrieves the cue points from the given WaveFile object and returns them
     * as a QVariantList. Cue points are specific time markers in the audio that
     * can be used for synchronization or analysis purposes.
     *
     * @param waveFile - A pointer to the WaveFile object from which to extract
     * cue points.
     * @return A QVariantList containing the cue points extracted from the
     * WaveFile.
     */
    Q_INVOKABLE QVariantList getCuePoints(WaveFile* waveFile);

    /**
     * Retrieves the audio data from the given WaveFile object and returns it as
     * a QVariantList. The audio data can be normalized if the normalized
     * parameter is set to true, which scales the values to a range of -1.0
     * to 1.0.
     *
     * @param waveFile - A pointer to the WaveFile object from which to extract
     * audio data.
     * @param normalized - A boolean flag indicating whether to normalize the
     * audio data (default is true).
     * @return A QVariantList containing the audio data extracted from the
     * WaveFile, optionally normalized.
     */
    Q_INVOKABLE QVariantList getWaveData(WaveFile* waveFile,
        bool normalized = true);

    /**
     * Extracts the pitch contour from the given WaveFile object using the
     * specified parameters and returns it as a QVariantList. The method allows
     * for various configurations such as frame shift, sample rate, F0 range,
     * voicing threshold, normalization mode, interpolation type, and smoothing
     * options.
     *
     * @param waveFile - A pointer to the WaveFile object from which to extract
     * pitch.
     * @param algorithm - The pitch extraction algorithm to use (e.g., "RAPT",
     * "SWIPE").
     * @param frameShift - The frame shift in milliseconds for pitch extraction.
     * @param sampleRate - The sample rate to use for pitch extraction.
     * @param minF0 - The minimum F0 value for pitch extraction.
     * @param maxF0 - The maximum F0 value for pitch extraction.
     * @param voicingThreshold - The voicing threshold for pitch extraction.
     * @param outputFormat - The format of the output pitch data (e.g., "Hz",
     * "MIDI").
     * @param normalizationMode - The mode for normalizing the pitch data (e.g.,
     * "max", "min_max").
     * @param pitchInterpolationType - The type of interpolation to apply to the
     * pitch contour (e.g., "Linear", "Cubic").
     * @param pitchSmoothing - The type of smoothing to apply to the pitch
     * contour (default is "None").
     * @param pitchSmoothingWindowSize - The window size for smoothing (default
     * is 5).
     * @param pitchGaussianSmoothingSigma - The sigma value for Gaussian
     * smoothing (default is 2.0).
     * @param pitchSplineSmoothingPenalty - The penalty value for spline
     * smoothing (default is 10.0).
     * @param normalized - A boolean flag indicating whether to normalize the
     * output pitch data (default is true).
     * @return A QVariantList containing the extracted pitch contour based on
     * the specified parameters.
     */
    Q_INVOKABLE QVariantList getPitch(
        WaveFile* waveFile, const QString& algorithm, double frameShift,
        double sampleRate, double minF0, double maxF0, double voicingThreshold,
        const QString& outputFormat, const QString& normalizationMode,
        const QString& pitchInterpolationType,
        const QString& pitchSmoothing = "None",
        int pitchSmoothingWindowSize = 5,
        double pitchGaussianSmoothingSigma = 2.0,
        double pitchSplineSmoothingPenalty = 10.0, bool normalized = true);

    /**
     * Generates an UMP (Unified Musical Pattern) from the given pitch and cue
     * points. The UMP is a representation of musical patterns that can be used
     * for pattern matching and analysis.
     *
     * @param pitch - A QVariantList containing the pitch data.
     * @param cuePoints - A QVariantList containing the cue points.
     * @param pLength - The length of the pattern to generate.
     * @param nLength - The length of the note to generate.
     * @param tLength - The length of the tempo to generate.
     * @param waveDataSize - The size of the wave data.
     * @param pitchInterpolationType - The type of interpolation to apply to the
     * pitch contour (e.g., "Linear", "Cubic").
     * @param normalized - A boolean flag indicating whether to normalize the
     * output UMP data (default is true).
     * @return A QVariantMap containing the generated UMP data.
     */
    Q_INVOKABLE QVariantMap getUMP(const QVariantList& pitch,
        const QVariantList& cuePoints, int pLength,
        int nLength, int tLength, int waveDataSize,
        const QString& pitchInterpolationType,
        bool normalized = true);
    /**
     * Extracts the spectrum from the given WaveFile object using the specified
     * parameters and returns it as a QVariantList. The method allows for
     * various configurations such as FFT length, frame shift, sample rate,
     * pitch extraction algorithm, F0 range, voicing threshold, F0 refinement,
     * and normalization.
     *
     * @param waveFile - A pointer to the WaveFile object from which to extract
     * spectrum.
     * @param fftLength - The length of the FFT to use for spectrum extraction.
     * @param frameShift - The frame shift in milliseconds for spectrum
     * extraction.
     * @param sampleRate - The sample rate to use for spectrum extraction.
     * @param algorithm - The pitch extraction algorithm to use (e.g., "DIO").
     * @param minF0 - The minimum F0 value for pitch extraction (used for F0
     * refinement).
     * @param maxF0 - The maximum F0 value for pitch extraction (used for F0
     * refinement).
     * @param voicingThreshold - The voicing threshold for pitch extraction
     * (used for F0 refinement).
     * @param f0Refinement - A boolean flag indicating whether to perform F0
     * refinement using the extracted pitch data (default is false).
     * @param normalized - A boolean flag indicating whether to normalize the
     * output spectrum data (default is true).
     * @return A QVariantList containing the extracted spectrum based on the
     * specified parameters.
     */
    Q_INVOKABLE QVariantList getSpec(WaveFile* waveFile, int fftLength,
        int frameShift, double sampleRate,
        const QString& algorithm = "DIO",
        double minF0 = 71.0, double maxF0 = 800.0,
        double voicingThreshold = 0.9,
        bool f0Refinement = false,
        bool normalized = false);
    /**
     * Extracts the cepstrum from the given WaveFile object using the specified
     * parameters and returns it as a QVariantList. The method allows for
     * various configurations such as FFT length, frame shift, sample rate,
     * pitch extraction algorithm, F0 range, voicing threshold, F0 refinement,
     * number of cepstral coefficients, and normalization.
     *
     * @param waveFile - A pointer to the WaveFile object from which to extract
     * cepstrum.
     * @param fftLength - The length of the FFT to use for cepstrum extraction.
     * @param frameShift - The frame shift in milliseconds for cepstrum
     * extraction.
     * @param sampleRate - The sample rate to use for cepstrum extraction.
     * @param algorithm - The pitch extraction algorithm to use (e.g., "DIO").
     * @param minF0 - The minimum F0 value for pitch extraction (used for F0
     * refinement).
     * @param maxF0 - The maximum F0 value for pitch extraction (used for F0
     * refinement).
     * @param voicingThreshold - The voicing threshold for pitch extraction
     * (used for F0 refinement).
     * @param f0Refinement - A boolean flag indicating whether to perform F0
     * refinement using the extracted pitch data (default is false).
     * @param numOrder - The number of cepstral coefficients to extract (default
     * is 25).
     * @param normalized - A boolean flag indicating whether to normalize the
     * output cepstrum data (default is true).
     * @return A QVariantList containing the extracted cepstrum based on the
     * specified parameters.
     */
    Q_INVOKABLE QVariantList getCepstr(
        WaveFile* waveFile, int fftLength, int frameShift, double sampleRate,
        int numOrder, const QString& algorithm = "DIO", double minF0 = 71.0,
        double maxF0 = 800.0, double voicingThreshold = 0.9,
        bool f0Refinement = false, bool normalized = true);

    /**
     * Computes the dynamic programming distance between the pattern spectrum
     * and signal spectrum, optionally using pitch information for alignment.
     * The method returns a QVariantList containing the computed distance values
     * for each frame or segment.
     *
     * @param patternSpectrum - A QVariantList containing the spectrum data of
     * the pattern.
     * @param signalSpectrum - A QVariantList containing the spectrum data of
     * the signal.
     * @param pitch - A QVariantList containing the pitch data to be used for
     * alignment (optional).
     * @param targetLength - The target length for the distance computation
     * (e.g., number of frames).
     * @return A QVariantList containing the computed dynamic programming
     * distance values.
     */
    Q_INVOKABLE QVariantList getSpecDP(const QVariantList& patternSpectrum,
        const QVariantList& signalSpectrum,
        const QVariantList& pitch,
        const int targetLength);

    /**
     * Computes the dynamic programming distance between the pattern and signal
     * features, including amplitude, amplitude derivative, pitch, and cepstrum.
     * The method returns a QVariantMap containing the computed distance values
     * for each feature type, allowing for a comprehensive analysis of the
     * similarity between the pattern and signal.
     * @param patternAmplitude - A QVariantList containing the amplitude data of
     * the pattern.
     * @param patternAmplitudeDerivative - A QVariantList containing the
     * amplitude derivative data of the pattern.
     * @param patternPitch - A QVariantList containing the pitch data of the
     * pattern.
     * @param patternCepstrum - A QVariantList containing the cepstrum data of
     * the pattern.
     * @param signalAmplitude - A QVariantList containing the amplitude data of
     * the signal.
     * @param signalAmplitudeDerivative - A QVariantList containing the
     * amplitude derivative data of the signal.
     * @param signalPitch - A QVariantList containing the pitch data of the
     * signal.
     * @param signalCepstrum - A QVariantList containing the cepstrum data of
     * the signal.
     * @param pitchToTransform - A QVariantList containing the pitch data to be
     * used for alignment and transformation.
     * @param cuePointsToTransform - A QVariantList containing the cue points to
     * be used for alignment and transformation.
     * @return A QVariantMap containing the computed dynamic programming
     * distance values for each feature type (e.g., "amplitudeDistance",
     * "pitchDistance", "cepstrumDistance").
     */
    Q_INVOKABLE QVariantMap
    getDP(const QVariantList& patternAmplitude,
        const QVariantList& patternAmplitudeDerivative,
        const QVariantList& patternPitch, const QVariantList& patternCepstrum,
        const QVariantList& signalAmplitude,
        const QVariantList& signalAmplitudeDerivative,
        const QVariantList& signalPitch, const QVariantList& signalCepstrum,
        const QVariantList& pitchToTransform,
        const QVariantList& cuePointsToTransform);

    /**
     * Extracts the amplitude contour from the given WaveFile object using the
     * specified parameters and returns it as a QVariantList. The method allows
     * for various configurations such as window size, frame shift, smoothing
     * options, and normalization.
     *
     * @param waveFile - A pointer to the WaveFile object from which to extract
     * amplitude.
     * @param window - The window size in milliseconds for amplitude extraction.
     * @param shift - The frame shift in milliseconds for amplitude extraction.
     * @param amplitudeSmoothing - The type of smoothing to apply to the
     * amplitude contour (default is "None").
     * @param amplitudeSmoothingWindowSize - The window size for smoothing
     * (default is 16).
     * @param amplitudeGaussianSmoothingSigma - The sigma value for Gaussian
     * smoothing (default is 1.0).
     * @param normalized - A boolean flag indicating whether to normalize the
     * output amplitude data (default is true).
     * @return A QVariantList containing the extracted amplitude contour based
     * on the specified parameters.
     */
    Q_INVOKABLE QVariantList getAmplitude(
        WaveFile* waveFile, int window, int shift,
        const QString& amplitudeSmoothing = "None",
        int amplitudeSmoothingWindowSize = 16,
        double amplitudeGaussianSmoothingSigma = 1.0, bool normalized = true);

    /**
     * Extracts the amplitude derivative contour from the given WaveFile object
     * using the specified parameters and returns it as a QVariantList. The
     * method allows for various configurations such as window size, frame
     * shift, smoothing options, and normalization.
     * @param waveFile - A pointer to the WaveFile object from which to extract
     * amplitude derivative.
     * @param window - The window size in milliseconds for amplitude derivative
     * extraction.
     * @param shift - The frame shift in milliseconds for amplitude derivative
     * extraction.
     * @param amplitudeSmoothing - The type of smoothing to apply to the
     * amplitude derivative contour (default is "None").
     * @param amplitudeSmoothingWindowSize - The window size for smoothing
     * (default is 16).
     * @param amplitudeGaussianSmoothingSigma - The sigma value for Gaussian
     * smoothing (default is 1.0).
     * @param normalized - A boolean flag indicating whether to normalize the
     * output amplitude derivative data (default is true).
     * @return A QVariantList containing the extracted amplitude derivative
     * contour based on the specified parameters.
     */
    Q_INVOKABLE QVariantList getAmplitudeDerivative(
        WaveFile* waveFile, int window, int shift,
        const QString& amplitudeSmoothing = "None",
        int amplitudeSmoothingWindowSize = 16,
        double amplitudeGaussianSmoothingSigma = 1.0, bool normalized = true);
};

#endif // WAVFILEAPI_H
