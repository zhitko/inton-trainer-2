# Intonation Trainer 2 — Data Processing and Comparison Algorithm

This document describes how Intonation Trainer 2 processes, aligns, and compares audio recordings to evaluate intonation similarity.

```
+-----------------------------------------------------------+
|                   1. Audio Recording & VAD                 |
|   - Incremental 128-sample frames                         |
|   - Energy / Periodicity (Autocorrelation) calculation    |
|   - Two-stage smoothing: Raw -> Mean -> Delta -> Var      |
|   - Hysteresis speech gate & automatic recording stop     |
+-----------------------------+-----------------------------+
                              |
                              v
+-----------------------------------------------------------+
|                 2. Signal Feature Extraction              |
|   - F0 (Pitch) contour extraction (RAPT via SPTK)          |
|   - Envelope Amplitude calculation                        |
|   - Spectrum & Cepstrum (2D frame matrices)               |
+-----------------------------+-----------------------------+
                              |
                              v
+-----------------------------------------------------------+
|                     3. DTW Alignment                      |
|   - Stream weights, match/insert/delete DP coefficients   |
|   - Grid alignment (free start/end vs fixed start/end)    |
|   - Traceback to build temporal mapping path              |
|   - Warping of user pitch/cue points to reference timeline|
+-----------------------------+-----------------------------+
                              |
                              v
+-----------------------------------------------------------+
|              4. Unified Melodic Profile (UMP)             |
|   - Cue-point-based segmentation (Pre, Nucleus, Post)    |
|   - Resampling segments to template structural lengths     |
|   - Zero-gap interpolation & final curve smoothing        |
+-----------------------------+-----------------------------+
                              |
                              v
+-----------------------------------------------------------+
|                5. Comparison & Scoring                    |
|   - Pearson correlation on UMP profiles (Shape score)     |
|   - Range span overlap comparison (Range match score)     |
|   - Result output (0-100% similarity score)               |
+-----------------------------------------------------------+
```

---

## 1. Audio Recording & Voice Activity Detection (VAD)

Voice Activity Detection (VAD) handles real-time audio analysis to automatically start and stop recording.

### Frame Processing
The input audio is processed incrementally in frames:
- **Frame size**: 128 samples ($\approx$ 16 ms at 8 kHz).
- **Hop size / Advance**: 64 samples ($\approx$ 8 ms, 50% overlap).

### VAD Algorithms
The system supports four VAD modes configurable in settings:
1. **Energy**: Tracks signal amplitude.
2. **Autocorrelation**: Periodicity check using the Normalized Autocorrelation Function (NACF) calculated over a lag range corresponding to a specified $F_0$ frequency bounds window (e.g., 80 Hz to 200 Hz).
3. **Hybrid AND**: Speech detected only if both energy and autocorrelation thresholds are exceeded.
4. **Hybrid OR**: Speech detected if either energy or autocorrelation threshold is exceeded.

### Two-Stage Smoothing Pipeline
To prevent noise spikes from triggering false speech detections, both Energy and Autocorrelation pipelines use a two-stage moving average over a sliding window of $K = 16$ frames:

1. **Calculate Raw Metric**:
   - For Energy VAD: $A(n) = \sqrt{\frac{1}{N}\sum_{i=0}^{N-1} x_i^2}$ (RMS amplitude).
   - For Autocorrelation VAD: $C(n) = \text{max NACF lag value}$. If frame energy is below a minimum gate threshold (default $0.0001$), $C(n)$ is forced to $0$.

2. **First-Stage Smoothing**: Compute local mean:
   $$U(n) = \frac{1}{2K - 1} \sum_{i = -K + 1}^{K - 1} A(n + i)$$

3. **Compute Deviation**: Find absolute difference from local mean:
   $$H(n) = |A(n) - U(n)|$$

4. **Second-Stage Smoothing**: Compute smoothed variation (VAD decision metric):
   $$V(n) = \frac{1}{2K - 1} \sum_{i = -K + 1}^{K - 1} H(n + i)$$

### Hysteresis Decision Gate
The final speech decision is made by comparing $V(n)$ against high and low thresholds:
- **State turns ON (Speech)**: If $V(n) > \text{Threshold}_{\text{High}}$
- **State turns OFF (Silence)**: If $V(n) < \text{Threshold}_{\text{Low}}$ (typically $90\%$ of High threshold).

If silence persists longer than the user-defined `Silence Duration (ms)` setting, the recording automatically stops.

---

## 2. Signal Feature Extraction

Once a recording is complete (or when a reference template file is loaded), the application extracts the acoustic parameters needed for DTW alignment.

1. **Fundamental Frequency ($F_0$ / Pitch)**:
   - Extracted using the **RAPT (Robust Algorithm for Pitch Tracking)** algorithm.
   - Values in unvoiced segments are set to zero.
   - **Post-processing**: 
     - *Interpolation*: Interpolates missing unvoiced frames (linear, cubic, spline, akima, or monotone) to span across voiceless segments without extrapolation artifacts at the edges.
     - *Smoothing*: Removes jitter via median filters, moving averages, gaussian filters, or spline penalties.
     - *Normalization*: Scales pitch contours by `min_max`, `mean`, or `mean_deviation`.
     - *Mask Transform (Log Pitch)*: Toggles a binary voiced/unvoiced mask where values above a threshold are set to $1.0$ and others to $0.0$.

2. **Envelope Amplitude**:
   - Calculated as root-mean-square (RMS) values over sliding windows.
   - First-order derivative calculated as:
     $$\Delta\text{Amp}[i] = \text{Amp}[i+1] - \text{Amp}[i]$$

3. **Spectrum and Cepstrum**:
   - Computed frame-by-frame via Fast Fourier Transform (FFT) and Mel-frequency filterbanks to capture spectral envelope dynamics.

---

## 3. Dynamic Time Warping (DTW) Alignment

Because the user and reference spoken tracks differ in duration and tempo, the time axes must be aligned. This is handled by `CDTWService` (Constrained Dynamic Time Warping).

### Multi-Stream Distance Calculation
Aligning on pitch alone is unreliable (due to voiceless gaps). The DTW cost matrix calculation combines multiple features:
- **Streams**: Pitch ($F_0$), Log Pitch, Pitch Derivative ($\Delta F_0$), Amplitude, Amplitude Derivative ($\Delta\text{Amp}$), Spectrogram, Cepstrogram.
- **Weights**: Each stream has a customizable weight.
- **Pre-processing**: Streams are scaled using linear interpolation to make the number of frames uniform across all features of the same recording.

For template frame $j$ and signal frame $i$, the frame-to-frame distance is:
$$D(j, i) = \sum_{k \in \text{Streams}} \text{dist}(V_j^{(k)}, V_i^{(k)}) \cdot W^{(k)}$$

where $\text{dist}()$ computes the Euclidean distance normalized by the dimensions of the stream's vector.

### Dynamic Programming Optimization
The accumulated distance matrix $C(i, j)$ is calculated iteratively:
$$C(i, j) = D(j, i) + \min \begin{cases} 
  C(i-1, j-1) \cdot \text{matchCoef} & \text{(Match)} \\
  C(i-1, j) \cdot \text{insertionCoef} & \text{(Insertion)} \\
  C(i, j-1) \cdot \text{deletionCoef} & \text{(Deletion)}
\end{cases}$$

### Boundary Constraints
- **Fixed Mode (Morphing)**:
  - Boundary: $C(0, 0) = 0$; $C(i, 0) = \infty$ for $i > 0$.
  - The path is forced to align the absolute beginning and end frames of both files.
- **Free-Start / Free-End (Substring Matching)**:
  - Boundary: $C(i, 0) = 0$ for all $i$.
  - Allows the template to align against any substring portion of a longer user recording. The path selects the lowest-cost endpoint across the last template column.

### Path Reconstruction (Traceback)
Starting from the selected optimal endpoint $(bestEndIndex, m)$, the algorithm steps backward through the recorded transitions in the traceback matrix:
- **Match ($0$)**: Advance both template and signal index ($i-1, j-1$).
- **Deletion ($2$)**: Advance template index only ($i, j-1$).
- **Insertion ($1$)**: Advance signal index only ($i-1, j$).

This produces a mapping path of length $m$ (matching the template length), where `path[j] = signalFrameIndex` corresponding to template frame $j$.

---

## 4. Unified Melodic Profile (UMP)

The Unified Melodic Profile represents the pitch contour normalized against structural syllables, making comparisons independent of absolute speech rate variations.

1. **Syllabic Segmentation**:
   - The template file contains embedded WAV cue markers classifying phonetic segments into:
     - **PRE_NUCLEUS**: Syllable onset.
     - **NUCLEUS**: Syllable nucleus (vocalic peak).
     - **POST_NUCLEUS**: Syllable coda.
   - If a boundary marker is sandwiched between two Nuclei, the service splits the boundary segment into a trailing Post-Nucleus and a leading Pre-Nucleus.

2. **Temporal Alignment**:
   - The user's cue points are mapped onto the template's timeline using the computed DTW path:
     $$\text{userStart} = \text{path}[\text{templateStart}]$$
     $$\text{userEnd} = \text{path}[\text{templateEnd}]$$

3. **Structure Normalization**:
   - Each cue segment is resampled to a fixed target length defined in settings (default: $pLength = 10$ frames for Pre-Nucleus, $nLength = 20$ frames for Nucleus, $tLength = 15$ frames for Post-Nucleus).
   - Resampled segments are concatenated to form the final UMP vector.
   - Gaps where pitch was not calculated or missing are filled using linear interpolation.
   - The final combined curve is smoothed to remove edge steps.

---

## 5. Comparison & Scoring

The comparison algorithm evaluates how well the user's UMP matches the reference UMP.

### Shape Similarity
Evaluated using the Pearson correlation coefficient between the reference UMP ($X$) and user UMP ($Y$):
$$r = \frac{\sum (X_i - \bar{X})(Y_i - \bar{Y})}{\sqrt{\sum (X_i - \bar{X})^2 \sum (Y_i - \bar{Y})^2}}$$

Since correlation spans $[-1, 1]$, the Shape Similarity score is calculated as:
$$\text{ShapeScore} = \max(0.0, r) \times 100$$

### Range Similarity
Evaluates if the pitch range (lowest to highest notes used) matches:
1. Span of reference UMP relative to full available frequency range:
   $$\text{refSpan} = \frac{\text{refMax} - \text{refMin}}{\text{fullMax} - \text{fullMin}}$$
2. Span of user UMP relative to full available frequency range:
   $$\text{userSpan} = \frac{\text{userMax} - \text{userMin}}{\text{fullMax} - \text{fullMin}}$$
3. Range Similarity is calculated as:
   $$\text{RangeScore} = 100 - |\text{refSpan} \times 100 - \text{userSpan} \times 100|$$

### Nucleus-Only Comparison Option
If the `useOnlyN` flag is enabled:
- The comparison masks out all Pre-Nucleus and Post-Nucleus frames.
- Pearson correlation and range comparisons are computed using **only** the frames corresponding to NUCLEUS (syllable core) segments.
