# Intonation Trainer 2

**Inton@Trainer 2.0** is a desktop application for learning and improving speech intonation. It records your voice, compares your pitch contour against a reference recording using Dynamic Time Warping (DTW), and gives you an instant similarity score — so you can hear, see, and track how closely your melody matches the target.

Designed for language learners, phonetics students, speech therapists, and researchers who need objective, repeatable feedback on intonation patterns.

---

## What It Does

### Core Concept

The application works on a **template-based training** model:

1. A **reference WAV file** (template) represents the target intonation pattern — e.g. a native speaker's recording of a sentence.
2. You **record yourself** speaking the same phrase.
3. The app **aligns** your recording to the template using constrained DTW across multiple acoustic streams (pitch, amplitude, spectrum, cepstrum).
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

A comprehensive settings panel organized into collapsible sections:

| Section | What you control |
|---------|-----------------|
| **General** | UI language (EN/RU), light/dark/system theme, accent color (Blue/Green/Purple/Orange/Red/Stainless Steel), navigation menu visibility, font size |
| **Automated Recording (VAD)** | Auto-stop on/off, auto-calibrate before recording, VAD method (Energy / Autocorrelation / Hybrid AND / Hybrid OR), silence duration, minimum record length %, energy threshold, autocorrelation thresholds and F0 range, diagnostic curve toggles |
| **Pitch** | F0 algorithm (RAPT), frame shift, sample rate, F0 min/max range, voicing threshold, normalization (min_max / mean), interpolation (Linear/Cubic/Akima/Monotone), smoothing (Moving Average/Median/Gaussian/Spline) with window/sigma/penalty controls |
| **Pitch Log** | Median smoothing window, moving average size, binary transform on/off with threshold |
| **UMP** | Smoothing type and parameters for the melodic profile |
| **Amplitude** | Window/shift sizes, smoothing |
| **Spectrum** | FFT length, F0 refinement, log scale, color scheme, cepstrum order |
| **DP Calculation** | Which acoustic streams feed the DTW (pitch, pitch derivative, log pitch, amplitude, amplitude derivative, spectrum, cepstrum), per-stream weights, match/insertion/deletion costs, fixed start/end alignment (morph) mode, pitch-log-as-mask, DTW distance limit for auto-rejecting noisy recordings |

Settings persist across sessions and take effect immediately (most DSP settings re-trigger analysis on the open page automatically).

---

## Key Technical Features

| Feature | Description |
|---------|-------------|
| **Constrained DTW (CDTW)** | Multi-stream alignment of user vs. reference with configurable stream weights and match/insert/delete costs. Supports both free-start/best-end (substring search) and fixed-start/fixed-end (full morph) modes. |
| **Unified Melodic Profile (UMP)** | Normalized pitch contour computed on syllable-nucleus cue points, providing a speaker-independent shape for comparison. |
| **VAD** | Voice Activity Detection with four modes: energy threshold, autocorrelation-based periodicity detection, and two hybrid combinations. Configurable auto-calibration measures background noise before each session. |
| **Pitch (F0) extraction** | RAPT algorithm via SPTK, with full normalization, interpolation, and smoothing pipeline. |
| **Spectrogram / Cepstrogram** | 2-D heat map visualizations rendered in QML using Canvas, supporting multiple color palettes. |
| **Statistics persistence** | Best scores, average accuracy, and full per-recording history are stored locally and surfaced across all views. |
| **DTW distance limit** | Microphone recordings whose alignment cost exceeds a threshold are silently skipped, keeping only meaningful utterances in statistics. |
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
├── Records (past microphone sessions)
│   └── [record] → Analysis Page
└── Settings
```

---

## Requirements

### Build Requirements

- **CMake**: 3.16 or higher
- **Qt**: 6.10 or higher with the following modules:
  - Qt Quick
  - Qt Multimedia
  - Qt Linguist Tools
- **C++ Compiler**: Supporting C++17 or higher
- **OpenMP**: For parallelized DSP routines
- **Git**: For cloning the repository and submodules

### Runtime Requirements

- Operating System: Windows, Linux, or macOS
- Audio input/output device (microphone required for training)

---

## Build Instructions

### Clone the Repository

```bash
git clone <repository-url>
cd inton-trainer-2
```

### Clone 3rd-Party Dependencies

The SPTK (Speech Signal Processing Toolkit) library is required but not included in the repository. Clone it into the `3rdparty` directory:

```bash
git clone https://github.com/sp-nitech/SPTK.git 3rdparty/SPTK
```

The ALGLIB library is required but not included in the repository. Download it into the `3rdparty` directory:

```bash
wget https://www.alglib.net/translator/re/alglib-4.06.0.cpp.gpl.zip
unzip alglib-4.06.0.cpp.gpl.zip -d 3rdparty/alglib-cpp
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

### Run the Application

After building, the executable will be located in the build directory:

- **Linux/macOS**: `./appinton-trainer-2`
- **Windows**: `Release\appinton-trainer-2.exe`

---

## Project Structure

```
inton-trainer-2/
├── src/
│   ├── api/              # QML-exposed C++ backends
│   │   ├── audioapi      # Microphone recording, VAD, audio level
│   │   ├── wavfileapi    # WAV loading, pitch/amplitude/spectrum/UMP/DTW
│   │   ├── analysisapi   # UMP comparison, shape similarity
│   │   ├── fileapi       # File system browsing
│   │   ├── statisticsapi # Score persistence and history
│   │   ├── settingsapi   # All settings exposed to QML
│   │   └── helpers/      # AppSettings struct, load/save
│   └── services/         # DSP business logic
│       ├── cdtwservice   # Constrained DTW alignment
│       ├── pitchservice  # F0 extraction (RAPT via SPTK)
│       ├── umpservice    # Unified Melodic Profile computation
│       ├── specservice   # Spectrum / cepstrum
│       ├── amplitudeservice
│       ├── vadautocorrelationservice
│       ├── vadenergryservice
│       └── dpservice     # DP stream combination
├── ui/
│   ├── pages/            # Application screens (QML)
│   │   ├── HomePage.qml
│   │   ├── TrainingPage.qml
│   │   ├── TemplatePage.qml      # Advanced analysis
│   │   ├── TemplateCategoriesPage.qml
│   │   ├── TemplateFilesPage.qml
│   │   ├── CategoriesPage.qml
│   │   ├── RecordsPage.qml
│   │   ├── RecordingPage.qml
│   │   └── SettingsPage.qml
│   ├── components/       # Reusable QML components
│   └── utils/            # Theme, icons, scale helpers
├── res/                  # Fonts (Font Awesome), images
├── i18n/                 # Translation files (EN, RU)
├── data/
│   ├── patterns/         # Reference WAV templates (organized in folders)
│   └── records/          # User microphone recordings
├── 3rdparty/
│   ├── SPTK/             # Speech Signal Processing Toolkit 4.3
│   ├── alglib-cpp/       # ALGLIB 4.06.0 (spline math)
│   └── ten-vad/          # Local VAD package
└── CMakeLists.txt
```

---

## Authors

- **Zhitko Vladimir** — Development — [LinkedIn](https://www.linkedin.com/in/zhitko-vladimir-92662255/)
- **Boris Lobanov** — Scientific — [LinkedIn](https://www.linkedin.com/in/boris-lobanov-50628384/)

---

## License

This project is licensed under the MIT License — see below for details:

```
MIT License

Copyright (c) 2025 Zhitko Vladimir, Boris Lobanov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Third-Party Libraries

| Library | Purpose |
|---------|---------|
| **SPTK** (Speech Signal Processing Toolkit 4.3) | F0 extraction (RAPT algorithm), audio feature processing |
| **ALGLIB** 4.06.0 | Spline smoothing for pitch and UMP profiles |
| **Font Awesome** | Icon font used throughout the UI |
| **ten-vad** | Additional VAD support |
