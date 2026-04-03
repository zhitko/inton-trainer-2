#ifndef AUDIOAPI_H
#define AUDIOAPI_H

#include "src/services/helpers/wavFile.h"
#include "src/services/wavfileservice.h"
#include <QAudioFormat>
#include <QAudioSource>
#include <QMediaDevices>
#include <QObject>
#include <memory>

#include <QMediaPlayer>
#include <vector>

class WavFileService;
struct WaveFile;

/*
 * AudioApi class provides methods for recording audio from the microphone,
 * saving it as a WAV file, and playing back audio files. It uses Qt's
 * multimedia framework to handle audio input and output. The class maintains
 * the state of recording and playback, as well as the current audio level for
 * visual feedback in the UI.
 *
 * The startRecording method begins recording audio, optionally for a specified
 * duration. The stopRecording method stops the recording process. The
 * saveWavFile method saves the recorded audio to a WAV file with an optional
 * file name. The play method plays an audio file from a given file path, and
 * the stopPlayback method stops any ongoing playback.
 *
 * Signals are emitted when the recording state, audio level, or playback state
 * changes, allowing the UI to update accordingly.
 */
class AudioApi : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isRecording READ isRecording NOTIFY isRecordingChanged)
    Q_PROPERTY(qreal audioLevel READ audioLevel NOTIFY isAudioLevelChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY isPlayingChanged)
    Q_PROPERTY(bool isVoiceDetected READ isVoiceDetected NOTIFY isVoiceDetectedChanged)

public:
    explicit AudioApi(QObject* parent = nullptr);

    /**
     * Returns whether the application is currently recording audio.
     *
     * @return true if recording is in progress, false otherwise.
     */
    bool isRecording() const;

    /**
     * Returns the current audio level as a value between 0.0 and 1.0, where
     * 0.0 represents silence and 1.0 represents the maximum audio level.
     *
     * @return The current audio level for visual feedback in the UI.
     */
    qreal audioLevel() const;

    /**
     * Returns whether the application is currently playing audio.
     *
     * @return true if audio playback is in progress, false otherwise.
     */
    bool isPlaying() const;

    /**
     * Returns whether the Voice Activity Detection (VAD) has detected speech.
     *
     * @return true if speech is currently detected in the recording.
     */
    bool isVoiceDetected() const;

public slots:
    /**
     * Starts recording audio from the microphone. If durationSeconds is greater
     * than 0, the recording will automatically stop after the specified number of
     * seconds. If durationSeconds is -1 (the default), recording will continue
     * until stopRecording is called.
     *
     * @param durationSeconds - The duration in seconds for automatic stop, or -1
     *                         for manual stop.
     */
    Q_INVOKABLE void startRecording(int durationSeconds = -1);
    /**
     * Stops the ongoing audio recording process. If recording is not in progress,
     * this method has no effect.
     */
    Q_INVOKABLE void stopRecording();

    /**
     * Internal VAD curves for visualization.
     * Returns data from the last recording.
     */
    Q_INVOKABLE QVariantList getVadA() const;
    Q_INVOKABLE QVariantList getVadU() const;
    Q_INVOKABLE QVariantList getVadV() const;
    /**
     * Saves the recorded audio to a WAV file. If fileName is provided, it will be
     * used as the name of the saved file. If fileName is empty, a default name
     * based on the current timestamp will be generated. The method returns the
     * file path of the saved WAV file.
     *
     * @param fileName - Optional name for the saved WAV file.
     * @return The file path of the saved WAV file.
     */
    Q_INVOKABLE QString saveWavFile(QString fileName = "");
    /**
     * Plays an audio file from the specified file path. If a playback is already
     * in progress, it will be stopped before starting the new playback.
     *
     * @param filePath - The file path of the audio file to be played.
     */
    Q_INVOKABLE void play(const QString& filePath);
    /**
     * Stops any ongoing audio playback. If no playback is in progress, this
     * method has no effect.
     */
    Q_INVOKABLE void stopPlayback();

    /**
     * Records 2 seconds of silence and calculates the VAD threshold (Pe)
     * based on the background noise level. Emits calibrationFinished(threshold)
     * when done.
     */
    Q_INVOKABLE void calibrateVad();

signals:
    /**
     * Signal emitted when the recording state changes (started or stopped).
     */
    void isRecordingChanged();
    /**
     * Signal emitted when the audio level changes, providing visual feedback for
     * the UI.
     */
    void isAudioLevelChanged();
    /**
     * Signal emitted when the playback state changes (started or stopped).
     */
    void isPlayingChanged();
    /**
     * Signal emitted when voice activity detection state changes.
     */
    void isVoiceDetectedChanged();
    /**
     * Emitted when VAD calibration completes. The parameter is the computed
     * threshold value that should be saved in settings.
     */
    void calibrationFinished(double threshold);

private:
    /**
     * Updates the current audio level based on the recorded audio data. This
     * method is called internally during recording to provide real-time feedback
     * on the audio level for visualization in the UI.
     *
     * @param level - The new audio level value to be set, typically between 0.0
     *                and 1.0.
     */
    void setAudioLevel(qreal level = 0.0);

    // Base buffer elements
    QAudioDevice m_audioDevice;
    std::unique_ptr<QAudioSource> m_audioSource;
    QAudioFormat m_format;
    QByteArray m_buffer;
    qint64 m_bufferOffsetBytes = 0; // Tracks bytes removed from m_buffer
    bool m_isRecording = false;
    qreal m_audioLevel = 0.0;
    std::unique_ptr<WavFileService> m_wavFileService;
    QMediaPlayer* m_player = nullptr;
    QAudioOutput* m_audioOutput = nullptr;
    bool m_isPlaying = false;

    bool m_autoStopEnabled = false;
    int m_silenceDurationMs = 2000;
    bool m_voiceDetected = false;
    static constexpr int PRE_BUFFER_MS = 250; // Pre/post buffer duration in ms

    // New VAD logic properties
    static constexpr int K_FRAMES = 16;
    static constexpr int CALIBRATION_FRAMES = 50; // Increased for reliable percentile

    std::vector<qint16> m_sampleBuf;
    std::vector<double> m_A;
    std::vector<double> m_U;
    std::vector<double> m_H;
    std::vector<double> m_V;

    std::vector<double> m_savedA;
    std::vector<double> m_savedU;
    std::vector<double> m_savedV;

    int m_valid_U = 0;
    int m_valid_V = 0;
    int m_calibrationCounter = 0;
    std::vector<double> m_calibrationFrames; // Individual V(n) frames during calibration
    double m_Pe = 0.0;

    int m_firstSpeechFrame = -1;
    int m_lastSpeechFrame = -1;
    int m_silenceFramesCount = 0;

    void processVadFrame(int frameIndex, double V_n);
    static double percentileValue(std::vector<double> values, double percentile);
};

#endif // AUDIOAPI_H
