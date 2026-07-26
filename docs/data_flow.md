# Intonation Trainer 2 — Current Data Flow

This document summarizes the live processing pipeline used by the current application. It describes the real user-facing flow, not only the underlying DSP library layer.

---

## High-level flow

The current app operates in this order:

1. Load settings from `SettingsApi` / `AppSettings`.
2. Record or open a reference template audio file.
3. Run VAD and speech segmentation logic.
4. Extract pitch, amplitude, spectrum, and cepstrum features.
5. Align the user recording to the reference using DTW.
6. Build the UMP profile and compare it against the template.
7. Save the attempt, update statistics, and show the result on the training screen.

---

## 1. Settings and app state

Application behavior is configured from the settings layer:
- General UI settings
- Auto-stop and guided training flags
- VAD thresholds and timing values
- Pitch, amplitude, spectrum, and DP tuning values

This settings object is shared through `SettingsApi` into QML and the C++ services. The app therefore behaves differently depending on the active profile, especially between:
- `Auto` mode
- `Guided` mode
- desktop presentation mode vs standard navigation mode

---

## 2. Audio capture and VAD

The app records microphone input and runs voice-activity detection in real time.

### Frame structure

The current VAD implementation uses the same rolling frame model as the in-tree DSP services:
- Frame size: 128 samples
- Hop size: 64 samples
- Effective frame advance is roughly 8 ms at 8 kHz

### Supported VAD modes

The current UI exposes four VAD choices:
- Energy
- Autocorrelation
- Hybrid AND
- Hybrid OR

These modes feed the same decision loop: smooth short-term metrics, evaluate thresholds, and convert the result into a speech/silence state.

### Auto-stop and guided behavior

When auto-stop is enabled:
- the app keeps listening for speech;
- if silence exceeds the configured silence duration, recording stops automatically.

When guided mode is enabled:
- the reference audio is played first;
- a short post-playback delay is applied;
- the app opens a listen window waiting for speech onset;
- if the user does not speak in time, the guided cycle aborts and returns to the idle state.

---

## 3. Feature extraction

Once a recording is captured, the app extracts the signal properties needed for comparison.

### Pitch (`F0`)

The pitch contour is derived by the RAPT-based pipeline, then post-processed with the selected interpolation and smoothing profile.

Typical post-processing steps include:
- missing-frame interpolation
- smoothing (moving average, median, Gaussian, spline)
- normalization (for example `min_max` or `mean`)
- optional log-pitch transformation and masking

### Amplitude

The app computes the amplitude envelope and its derivative. These values are used as part of the multi-stream alignment cost.

### Spectrum and cepstrum

FFT-based spectrum and cepstrum features are extracted for deeper diagnostics and comparison. These streams can be shown in the advanced analysis view and used in DTW weighting.

---

## 4. DTW alignment

The comparison engine uses `CDTWService` to align the user signal against the reference template over time.

### Current alignment options

The app supports:
- free start/end search (default substring alignment style)
- fixed start/end DP mode (morph-style alignment)
- multi-stream costs that combine pitch, log pitch, amplitude, and spectral features

The alignment result is a time-warp path that maps the user signal onto the template timeline so that pitch contour comparison becomes meaningful even when durations differ.

### Distance gating

The current training flow also includes a `dtwDistanceLimit` guard for microphone recordings. If a recording’s alignment cost is above the threshold, it is dropped and the retry loop continues without cluttering the record history.

---

## 5. UMP and comparison scoring

After alignment, the app constructs the Unified Melodic Profile (UMP) from the cue-point structure of the template.

### UMP construction

The UMP procedure typically includes:
- segmentation into Pre-Nucleus / Nucleus / Post-Nucleus regions
- resampling each region to the expected structural length
- interpolation of missing values
- final smoothing of the combined profile

### Score output

The final similarity score is computed from the user/reference UMP relationship. In practice the screen shows the current result and the recent history of scores, so the user can see whether the latest attempt improved or regressed.

---

## 6. Result saving and UI update

Once the score is computed:
- the result is displayed on the `TrainingPage` summary card;
- history is updated for the current template;
- the user can replay the reference or playback the recorded attempt;
- the record can be opened later from the `RecordsPage` and re-analyzed in `TemplatePage`.

This means the app’s live data flow is not just a signal-processing pipeline: it is also a training loop that persists outcomes and lets the user revisit previous attempts in a diagnostic view.

