# Intonation Trainer 2

**Inton@Trainer 2.0** is a cross-platform desktop (and Android) application for learning and improving speech intonation. It records your voice, compares your pitch contour against a reference recording using Constrained Dynamic Time Warping (CDTW), and gives you an instant similarity score — so you can hear, see, and track how closely your melody matches the target.

Designed for language learners, phonetics students, speech therapists, and researchers who need objective, repeatable feedback on intonation patterns.

---

## What It Does

### Core Concept

The application works on a **template-based training** model:

1. A **reference WAV file** (template) represents the target intonation pattern — e.g. a native speaker's recording of a sentence.
2. You **record yourself** speaking the same phrase.
3. The app **aligns** your recording to the template using constrained DTW across multiple configurable acoustic streams (pitch, pitch derivative, log pitch, amplitude, amplitude derivative, spectrum, cepstrum).
4. It computes a **Unified Melodic Profile (UMP)** — a normalized pitch contour — for both recordings and compares their shapes.
5. You get a **similarity score (0–100%)** with a trend indicator showing whether you're improving.

---

## User Experience Flow

### 1. Home Screen

The home screen greets you with:
- **"Start Training"** — the main call to action.
- **Live statistics**: average accuracy, number of mastered files, and files trained vs. total.
- **Circular progress ring** showing your overall training completion across the template library.

### 2. Selecting a Template

Tapping **Start Training** navigates to the **Template Categories** browser:

- Templates are organized in **folders** (categories and subcategories).
- Each folder can be drilled into; leaf folders show the individual WAV files.
- Files are displayed in an **accordion list** — subcategories collapse and expand with animated chevrons.
- Filter chips let you quickly show: **All**, **New** (not yet trained), **Improve** (score < 80%), or **Mastered** (score ≥ 80%).
- A **search bar** instantly narrows the list; active search auto-expands all accordion sections so results are never hidden.
- Each file item shows its **best score** so you can see progress at a glance.

### 3. Training

Selecting a template opens the **Training Page**:

**Automatic recording mode (VAD)**
- Recording starts immediately and automatically. You speak the phrase, then go silent — the app detects the end of speech via Voice Activity Detection (VAD) and stops the recording on its own.
- While you speak, a live **waveform visualizer** (symmetric bar graph around a pulsing dot) shows your microphone input in real time. Bars use a logarithmic scale to make quiet sounds visible and peaks expressive.
- After each utterance the app processes your recording and immediately shows the result, then restarts listening for the next attempt — a seamless, hands-free loop.
- A **Pause / Continue** button lets you temporarily suspend the recording loop (e.g. to listen to the reference or check graphs) without leaving the page.

**Guided ("Play & Listen") mode**
- An alternative to Auto mode, enabled in Settings. The training flow becomes a step-by-step cycle: press play → hear the reference → a short delay → the app opens a timed "listen window" → speak the phrase → the recording is automatically stopped and processed.
- A large play button (with redo icon on timeout) replaces the continuous VAD loop controls.
- If no speech is detected within the configurable **Listen Window Timeout**, the app returns to idle and lets you try again.
- The **Post-Playback Delay** setting controls the pause between the end of reference playback and microphone activation.
- You can switch between Auto and Guided at any time; pending recordings are cancelled cleanly.

**Manual recording mode**
- When auto-stop is disabled, a **Record button** appears. Tap once to start, tap again to stop. Useful for controlled environments or when VAD mis-fires.

**Result display**
- A **Similarity card** at the top shows your current score as a large percentage with an animated scale-bounce on update.
- A **trend indicator** (▲/▼/●) shows delta versus your immediately previous attempt.
- Up to **5 recent historical scores** are shown fading out to the right — closest result largest, oldest smallest — giving you an at-a-glance improvement curve.
- The **UMP graph** plots the reference pitch contour (red) and your aligned contour (dark red) together, so you can visually compare the melody shape.

**Playback controls**
- **Play Reference** — listen to the reference recording while pausing the recording loop.
- **Play Me** — listen to your last captured attempt.

**Advanced analysis**
- A button opens the full **Analysis Page** (TemplatePage) for a deep dive:
  - Side-by-side waveforms for reference and user.
  - Raw F0, processed pitch, log pitch, UMP graphs for both sides.
  - Amplitude and amplitude derivative envelopes.
  - Spectrogram and cepstrogram heat maps (color scheme selectable: Viridis, Plasma, Hot, Cool).
  - DTW alignment path visualization and per-stream distance curves.
  - VAD diagnostic curves (A(n), U(n), V(n), autocorrelation series) — togglable via Settings.

Each result is **automatically saved** to statistics. The home screen and file list update their scores the next time you visit.

### 4. Records

The **Records page** lists every WAV file saved from microphone sessions:

- Each entry shows the **file name**, the **reference it was trained against**, the **similarity score**, and the **recording date**.
- Tapping a record opens the **Analysis Page** with that recording pre-loaded against its reference, so you can review any past attempt in full detail.
- **Search bar** filters by file name or pattern name.
- **Delete All** button (with confirmation) clears the entire history; individual swipe-to-delete is available per item.

### 5. Reference Samples Browser

A separate **Categories / Reference Samples** section (accessible from the navigation menu) lets you browse the template library independently of training — useful for previewing files and checking scores without immediately launching the training loop.

### 6. Settings

A comprehensive settings panel organized with an **Advanced** toggle (non-persistent, at the top of the page). When Advanced is off, only the primary controls are shown:

| Section | What you control |
|---------|-----------------|
| **General (always visible)** | UI language (EN/RU), light/dark/system theme, accent color (Blue/Green/Purple/Orange/Red/Stainless Steel), navigation menu visibility, font size, delete user data |
| **Automated Recording (always visible)** | Enable Guided Mode, Auto Stop Recording, Auto-calibrate before recording, Calibrate button |
| **Advanced (hidden behind toggle)** | Language Title, Guided Mode subs (listen window timeout, post-playback delay), VAD Method, Calibration Duration, Silence Duration, Min Record Length %, Energy Threshold, Autocorrelation Threshold/K/MinF0/MaxF0, both Calibrate buttons, diagnostic curve toggles (A, U, V, Corr) |
| **Pitch (advanced)** | F0 algorithm (RAPT), frame shift, sample rate, F0 min/max range, voicing threshold, normalization (min_max / mean), interpolation (Linear/Cubic/Akima/Monotone), smoothing (Moving Average/Median/Gaussian/Spline) with window/sigma/penalty controls |
| **Pitch Log (advanced)** | Median smoothing window, moving average size, binary transform on/off with threshold |
| **UMP (advanced)** | Smoothing type (None / MovingAverage / Median / Gaussian / Spline) with window size, sigma, and penalty controls; show/hide toggle |
| **Amplitude (advanced)** | Window/shift sizes, smoothing (MovingAverage / Median / Gaussian) with window and sigma controls; show/hide amplitude and derivative |
| **Spectrum (advanced)** | FFT length, F0 refinement toggle, log scale toggle, color scheme (Viridis / Plasma / Hot / Cool), cepstrum order, show/hide spectrum and cepstrum |
| **DP Calculation (advanced)** | Which acoustic streams feed the DTW (pitch, pitch derivative, log pitch, amplitude, amplitude derivative, spectrum, cepstrum), per-stream weights, match/insertion/deletion costs, fixed start/end alignment (morph) mode, pitch-log-as-mask, DTW distance limit for auto-rejecting noisy recordings |

Settings persist across sessions and take effect immediately (most DSP settings re-trigger analysis on the open page automatically).

---

## Key Technical Features

| Feature | Description |
|---------|-------------|
| **Constrained DTW (CDTW)** | Multi-stream alignment of user vs. reference with configurable stream weights and match/insert/delete costs. Supports both free-start/best-end (substring search) and fixed-start/fixed-end (full morph) modes. |
| **Unified Melodic Profile (UMP)** | Normalized pitch contour computed on syllable-nucleus cue points, providing a speaker-independent shape for comparison. |
| **VAD** | Voice Activity Detection with four modes: energy threshold, autocorrelation-based periodicity detection, and two hybrid combinations. Configurable auto-calibration measures background noise before each session. |
| **Pitch (F0) extraction** | RAPT algorithm via SPTK, with full normalization, interpolation, and smoothing pipeline. |
| **Spectrogram / Cepstrogram** | 2-D heat map visualizations rendered in QML using Canvas, supporting multiple color palettes (Viridis, Plasma, Hot, Cool). |
| **Statistics persistence** | Best scores, average accuracy, and full per-recording history are stored locally and surfaced across all views. |
| **DTW distance limit** | Microphone recordings whose alignment cost exceeds a configurable threshold are silently skipped, keeping only meaningful utterances in statistics. |
| **Guided training mode** | Step-by-step "Play & Listen" cycle (listen to reference → short delay → timed recording window) as an alternative to continuous VAD auto-stop. Configurable listen timeout and post-playback delay. |
| **Live waveform visualizer** | Real-time logarithmic bar graph driven by 20-sample rolling audio-level history, updating at 50 ms intervals during recording. |
| **i18n** | Full English and Russian UI translation via Qt Linguist. |

---

## Application Pages

```
Home
├── Start Training → Template Categories
│   └── [category] → [subcategory] → Template Files
│       └── [file] → Training Page → Analysis Page (advanced)
├── Categories (browse reference library)
│   └── [category] → Templates (reference samples)
├── Records (past microphone sessions)
│   └── [record] → Analysis Page
└── Settings
```

---

## Requirements

### Build Requirements

- **CMake**: 3.16 or higher
- **Qt**: 6.11 or higher with the following modules:
  - Qt Quick
  - Qt Multimedia
  - Qt Linguist Tools
- **C++ Compiler**: Supporting C++17 or higher
- **OpenMP**: For parallelized DSP routines
- **Git**: For cloning the repository and submodules

### Android Build Requirements (optional)

- **Android NDK**: 26+ (with LLVM/clang toolchain)
- **Java**: 17 (required by Gradle for AAB/APK packaging)
- **Android SDK**: compileSdk 35+, build tools 35+

### Runtime Requirements

- Operating System: Windows, Linux, macOS, or Android 8+ (API 26+)
- Audio input/output device (microphone required for training)

---

## Build Instructions

### Clone the Repository

```bash
git clone <repository-url>
cd inton-trainer-2
```

### Clone 3rd-Party Dependencies

The following third-party libraries are required. They are **not** included in the repository and must be fetched separately:

#### SPTK (Speech Signal Processing Toolkit 4.3)

F0 extraction (RAPT algorithm) and audio feature processing.

```bash
git clone https://github.com/sp-nitech/SPTK.git 3rdparty/SPTK
cd 3rdparty/SPTK && git checkout 68f4158 && cd ../..
```

#### ALGLIB 4.06.0

Spline smoothing for pitch and UMP profiles.

```bash
wget https://www.alglib.net/translator/re/alglib-4.06.0.cpp.gpl.zip
unzip alglib-4.06.0.cpp.gpl.zip -d 3rdparty/alglib-cpp
```

#### ten-vad

Additional VAD support (energy + autocorrelation-based).

```bash
git clone https://github.com/TEN-framework/ten-vad.git 3rdparty/ten-vad
cd 3rdparty/ten-vad && git checkout 22a3bcd && cd ../..
```

### Build Steps

#### Linux/macOS

```bash
mkdir build
cd build
cmake ..
cmake --build . --target appinton-trainer-2 -- -j2
```

#### Windows (with MSVC)

```bash
mkdir build
cd build
cmake -G "Visual Studio 17 2022" ..
cmake --build . --config Release --target appinton-trainer-2
```

#### Android (arm64-v8a)

```bash
# Requires Android NDK + SDK and Java 17
chmod +x scripts/build_android.sh
./scripts/build_android.sh
```

The script produces an Android App Bundle (`.aab`) at:
`build_android_arm64_v8a/android-build/build/outputs/bundle/release/android-build-release.aab`

An emulator launch script is also available:

```bash
./scripts/run_emulator.sh
```

Use `--logcat` mode to stream logs from a running device:

```bash
./scripts/run_emulator.sh --logcat
```

### Run the Application

After building, the executable will be located in the build directory:

- **Linux/macOS**: `./appinton-trainer-2`
- **Windows**: `Release\appinton-trainer-2.exe`

---

## Project Structure

```
inton-trainer-2/
├── src/
│   ├── api/                            # QML-exposed C++ backends
│   │   ├── audioapi.{h,cpp}           # Microphone recording, VAD, audio level
│   │   ├── wavfileapi.{h,cpp}         # WAV loading, pitch/amplitude/spectrum/UMP/DTW
│   │   ├── analysisapi.{h,cpp}        # UMP comparison, shape similarity
│   │   ├── fileapi.{h,cpp}            # File system browsing
│   │   ├── statisticsapi.{h,cpp}      # Score persistence and history
│   │   ├── settingsapi.{h,cpp}        # All settings exposed to QML
│   │   ├── qmllogger.{h,cpp}          # QML-side logging bridge
│   │   └── helpers/                    # AppSettings struct, load/save, statistics
│   └── services/                       # DSP business logic
│       ├── cdtwservice.{h,cpp}        # Constrained DTW alignment
│       ├── pitchservice.{h,cpp}       # F0 extraction (RAPT via SPTK)
│       ├── umpservice.{h,cpp}         # Unified Melodic Profile computation
│       ├── specservice.{h,cpp}        # Spectrum / cepstrum
│       ├── amplitudeservice.{h,cpp}
│       ├── vadautocorrelationservice.{h,cpp}
│       ├── vadenergryservice.{h,cpp}
│       ├── dpservice.{h,cpp}          # DP stream combination
│       ├── wavfileservice.{h,cpp}     # WAV file I/O
│       └── helpers/                    # Vector utils, interpolation, smoothing, normalization, file logger
├── ui/
│   ├── pages/                          # Application screens (QML)
│   │   ├── HomePage.qml
│   │   ├── TrainingPage.qml
│   │   ├── TemplatePage.qml            # Advanced analysis
│   │   ├── TemplateCategoriesPage.qml
│   │   ├── TemplateFilesPage.qml
│   │   ├── TemplatesPage.qml           # Reference samples browser
│   │   ├── CategoriesPage.qml
│   │   ├── RecordsPage.qml
│   │   ├── RecordingPage.qml
│   │   └── SettingsPage.qml
│   ├── components/                     # Reusable QML components
│   └── utils/                          # Theme, icons, scale helpers, logger
│       ├── AppScale.qml
│       ├── Icons.qml
│       ├── Logger.qml
│       └── Theme.qml
├── res/                                # Qt resource files
│   ├── fonts/                          # Font Awesome 6 (brands, regular, solid)
│   ├── images/                         # PNG assets (wave.png)
│   ├── src/                            # C++ source resources (api/, helpers/, services/)
│   └── ui/                             # QML resource copies (components/, pages/, utils/)
├── i18n/                               # Translation files (EN, RU)
├── android/                            # Android packaging
│   ├── AndroidManifest.xml
│   └── res/values/styles.xml
├── scripts/                            # Build and automation scripts
│   ├── build_android.sh
│   ├── run_emulator.sh
│   ├── android_build_guide.md
│   └── build-appimage/                 # AppImage packaging (empty)
├── docs/                               # Documentation
│   ├── data_flow.md
│   ├── settings_guide_ru.md
│   └── ui_screens.md
├── data/
│   ├── patterns/                       # Reference WAV templates (organized in folders)
│   └── records/                        # User microphone recordings
├── 3rdparty/
│   ├── SPTK/                           # Speech Signal Processing Toolkit 4.3
│   ├── alglib-cpp/                     # ALGLIB 4.06.0 (spline math)
│   └── ten-vad/                        # Local VAD package
├── CMakeLists.txt
├── settings.ini                        # Default user preferences
└── README.md
```

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

---

## Third-Party Libraries

| Library | Purpose |
|---------|---------|
| **[SPTK](https://github.com/sp-nitech/SPTK)** (Speech Signal Processing Toolkit 4.3) | F0 extraction (RAPT algorithm), audio feature processing |
| **[ALGLIB](https://www.alglib.net/)** 4.06.0 | Spline smoothing for pitch and UMP profiles |
| **[Font Awesome](https://fontawesome.com/)** (Free 6.x) | Icon font used throughout the UI |
| **[ten-vad](https://github.com/TEN-framework/ten-vad)** | Additional VAD support (energy + autocorrelation-based) |

---

## Authors

- **Zhitko Vladimir** — Development — [LinkedIn](https://www.linkedin.com/in/zhitko-vladimir-92662255/)
- **Boris Lobanov** — Scientific — [LinkedIn](https://www.linkedin.com/in/boris-lobanov-50628384/)
