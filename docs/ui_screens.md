# Intonation Trainer 2 — User Interface Screens

This document provides a comprehensive guide to the user interface of **Intonation Trainer 2**, describing the purpose, display details, user interactions, and navigation flow of all screens implemented in the application.

---

## UI Architecture & Global Controls

The application uses **Qt Quick (QML)** with a **Material Design 3** style system. It adapts dynamically to light, dark, and system themes, supports multiple custom primary accent colors, and provides font scaling for responsiveness across various desktop display sizes.

The main page manager is a `StackView` inside `Main.qml`, which handles page navigation (push/pop) and top-bar toolbar commands.

### Navigation Modes
The interface supports two navigation schemes depending on the **Show Navigation Menu** setting:
1. **Presentation / Full Screen Mode** (Navigation Menu Hidden): A desktop-style layout with a side-drawer menu (accessed via the top-left menu icon ☰) and a persistent, always-visible vertical scrollbar on list and scrollable views to match traditional desktop apps.
2. **Standard Mode** (Navigation Menu Visible): Displays a bottom navigation bar for quick toggling between the most common sections (**Home**, **Advanced** (during active training), and **Settings**).

---

## 1. Core Screens

These are the primary user-facing screens involved in the training and configuration pipeline.

### 1.1 Home Page (`HomePage.qml`)
* **Purpose**: Serves as the landing dashboard of the application, presenting overall progress statistics and acting as the main entry point to training.
* **What it Shows**:
  * **Hero Header**: Branding banner ("Inton@Trainer 2.0") matching the selected Material Design 3 theme.
  * **Start Training Button**: Floating accent button laid over a stylized audio waveform backdrop.
  * **Language Chip**: A visual chip displaying the currently active locale (e.g., `en`, `ru`).
  * **Overall Completion Circle**: A large circular progress indicator showing the user's total course completion percentage.
  * **Quick Statistics**: Three summary cards showing:
    * *Avg Accuracy*: Average score across all processed template files.
    * *Mastered Files*: Count of template files trained to $\ge 80\%$ accuracy.
    * *Files Trained*: Fraction of total templates completed (e.g., `12 / 48`).
* **What the User Can Do**:
  * Click **Start Training**:
    * If `Auto Calibrate` is enabled in Settings, it opens the **VAD Calibration Dialog** to measure ambient noise for 2 seconds before proceeding.
    * If calibration is disabled or completed, it pushes `TemplateCategoriesPage.qml` onto the stack.
  * Access the sidebar menu (via ☰) or change settings using the bottom navigation bar.

---

### 1.2 Template Categories Page (`TemplateCategoriesPage.qml`)
* **Purpose**: Displays the categories (folders) of reference speech samples available in `data/patterns/`.
* **What it Shows**:
  * **Search Bar**: Input field to filter folder titles instantly.
  * **Category List**: A vertically scrollable list of pattern folders (e.g., *Phrases*, *Intonation Models*) styled with folder icons.
  * **External Desktop Scrollbar**: Positioned on the right side of the list (non-overlapping) if the navigation menu is hidden.
  * **Empty State View**: Displays a friendly "No categories found" message when filters yield no results.
* **What the User Can Do**:
  * Search for specific category folders.
  * Click a category folder item to navigate to the **Template Files Page** (`TemplateFilesPage.qml`) for that category.

---

### 1.3 Template Files Page (`TemplateFilesPage.qml`)
* **Purpose**: Lists the reference audio templates (`.wav` files) within the chosen category, grouped by their subdirectories, showing training completion indicators.
* **What it Shows**:
  * **Search Bar**: Allows searching files by their filename.
  * **Filter Chips**: Quick filters to isolate files based on training status:
    * *All files*: Displays everything.
    * *New*: Files with no registered training scores.
    * *Improve*: Files with a best score below 80%.
    * *Mastered*: Files with a best score of 80% or higher.
  * **Collapsible Accordions (Subcategories)**: Groups files under subfolder headers (e.g., *Question*, *Statement*) with an animated chevron. Subsections fold and unfold smoothly. Searching automatically expands all accordions.
  * **File Items**: Lists individual speech files showing their names and the best historical accuracy score recorded for them.
* **What the User Can Do**:
  * Toggle subcategory accordion folders to expand/collapse file lists.
  * Filter templates by category or search term.
  * Click a template file to launch the **Training Page** (`TrainingPage.qml`) for that reference sample.

---

### 1.4 Training Page (`TrainingPage.qml`)
* **Purpose**: The interactive playground where speech training, real-time audio recording, VAD automated stop/starts, and similarity comparisons happen.
* **What it Shows**:
  * **Similarity Score Card**:
    * Large percentage display showing the intonation similarity of the latest attempt.
    * *Trend Indicator*: An arrow showing progress compared to the previous attempt (e.g., `▲ +5%` green, `▼ -2%` red, or `● 0%` neutral).
    * *History Trail*: A horizontal sequence of up to 5 previous scores, scaling down in size and opacity to show learning trends.
  * **WaveFormGraph**: A dual-line plot plotting the **Reference UMP** pitch contour (red line) and the **User's Aligned UMP** pitch contour (brown line) overlaid to visualize structural mismatches.
  * **Live VAD / Listening Module** (Active when `Auto Stop Recording` is enabled):
    * *Pulsing Center Dot*: Green when recording speech, blue when playing audio, red/disabled when silent or processing.
    * *Symmetric Equalizer Waves*: Floating bars expanding left and right from the center dot, visualizing ambient microphone levels on a logarithmic scale for high visual expressiveness.
  * **Playback Controls**:
    * *Play Reference*: Plays the template voice file.
    * *Play Me*: Plays the user's last recorded attempt (enabled only after recording).
  * **Manual Record Button**: Replaces the VAD listening module if auto-stop recording is turned off.
  * **VAD Pause/Continue Button**: Temporarily halts the automatic recording loop.
  * **Open Test File Button**: Opens a local file picker targeting `data/test/` to compare a pre-recorded file instead of microphone input.
* **What the User Can Do**:
  * Speak immediately upon entering (VAD automatically initiates recording, listens for speech, auto-stops when silence is detected, and scores).
  * Manually record and stop (if manual mode is set).
  * Play back both the reference audio and their last recording.
  * Pause/resume the automatic recording loop.
  * Load a local `.wav` test file to compare.
  * Open the **Advanced Template Analysis** screen (`TemplatePage.qml`) via the bottom bar or drawer menu.

---

### 1.5 Advanced Template Analysis Page (`TemplatePage.qml`)
* **Purpose**: A deep signal processing diagnostic screen showing exact acoustic alignment features side-by-side.
* **What it Shows**:
  * **Waveforms**: Reference vs. User audio waveforms, overlaid with syllabic cue points (Pre-Nucleus, Nucleus, Post-Nucleus).
  * **Pitch Contours**: Reference vs. User pitch graphs, toggleable between *Raw Pitch (F0)*, *Processed Pitch*, and *Log Pitch (LOG_F0)*.
  * **Acoustic Profiles**:
    * *UMP (Unified Melodic Profile)*: Segment-normalized pitch profiles.
    * *Amplitude*: Envelopes and their first-order derivatives.
    * *Spectrograms / Cepstrograms*: 2D thermal color maps (using Viridis, Plasma, Hot, or Cool color schemes) capturing spectral dynamics.
  * **DTW Alignment Metrics**:
    * Cumulative DTW cost distance line.
    * Path mapping projections.
  * **Slide-out Settings Panel**: Panel toggled via "Show Settings" containing tuning parameters (F0 limits, FFT window lengths, stream weights, etc.).
* **What the User Can Do**:
  * Play back reference and user audio clips.
  * Adjust DSP extraction constants and weights live and watch the signal alignments recalculate instantly.

---

### 1.6 User Records Page (`RecordsPage.qml`)
* **Purpose**: Shows the archive of all saved user microphone recordings.
* **What it Shows**:
  * **Search & Action Bar**: Text field to search files by record name or matched pattern name, and a "Delete All" button.
  * **History List**: Recorded audio files categorized under folder sections.
  * **Record Details**: Displays user record name, target reference pattern template name, score obtained, and date recorded.
  * **Delete Button**: A garbage can icon to remove files.
* **What the User Can Do**:
  * Search/filter past records.
  * Click on a record to load it directly into the **Advanced Template Analysis Page** aligned against its original reference template.
  * Delete individual records or wipe the entire archive (requires confirmation).

---

### 1.7 Settings Page (`SettingsPage.qml`)
* **Purpose**: Central command for configuring the speech processing, UI preferences, and VAD parameters.
* **What it Shows**:
  * **General**: Settings for Language, Custom Language Title, Theme selection (Light/Dark/System), Primary Accent color selection, Font Size, and Show Navigation Menu toggle. Features a "Delete user data" override.
  * **Automated Recording (VAD)**:
    * *Auto Stop Recording*: Enables automatic voice gating.
    * *Autocalibrate*: Triggers noise calibration at training start.
    * *VAD Methods*: Energy, Autocorrelation, Hybrid AND, Hybrid OR.
    * *Thresholds*: Energy threshold (Pe), Autocorrelation threshold, Autocorr threshold coefficient K, and Pitch bounds (Min/Max F0) for Autocorrelation VAD.
    * *Timing*: Calibration duration (ms), Auto-stop silence gap (ms), and Minimum Record Length percentage.
    * *Visuals*: Toggle switches to overlay raw VAD calculations ($A(n), U(n), V(n)$, autocorrelation) in charts.
  * **Pitch**: Option to display raw, processed, or log pitch curves. Toggle `Use Only N` (syllable nucleus-only correlation). Adjust frame shifts, sample rates, RAPT min/max boundaries, voicing thresholds, normalization mode, interpolation types (Linear, Cubic, Akima, Monotone), and smoothing filters (Moving Average, Median, Gaussian, Spline) with window sizes.
  * **Pitch Log**: Adjust binary voicing threshold settings.
  * **Spectrum**: Select FFT length, F0 refinement options, spectrogram log scale, color maps, and Cepstral orders.
  * **DP Calculation (DTW)**: Toggle DTW alignment distance displays. Configure Fixed vs. Free start/end constraints, DTW distance rejection limits, and individual feature weights (Amplitude, Pitch, Spectrogram, etc.).
* **What the User Can Do**:
  * Modify any configuration toggle, text input, or combo box. Settings are auto-saved via `SettingsApi` on change.
  * Run noise calibration tests via the **Calibrate** buttons.
  * Reset/wipe statistics.

---

## 2. Supplementary & Sandbox Screens

These screens are part of the codebase but are either used as temporary sandboxes or represent alternative list layouts.

### 2.1 Recording Page (`RecordingPage.qml`)
* **Purpose**: A standalone microphone sandbox screen.
* **What it Shows**:
  * A central microphone button.
  * A linear progress bar visualizing audio input level.
  * A playback button for the recorded segment.
  * An "Open" button to view UMP analysis in `TemplatePage.qml`.
* **Note**: Not exposed in the primary navigation menu. Useful for microphone verification.

### 2.2 Templates Page (`TemplatesPage.qml`)
* **Purpose**: An alternative template list screen.
* **What it Shows**: A flat list of `.wav` patterns categorized under static subheaders.
* **Note**: Replaced in active use by `TemplateFilesPage.qml`, which supports accordion folding, collapsible headers, and training status chip filters.

### 2.3 Categories Page (`CategoriesPage.qml`)
* **Purpose**: An alternative categories listing.
* **What it Shows**: Folder structure lists that recursively push `CategoriesPage.qml` for nested subdirectories.
* **Note**: Replaced by `TemplateCategoriesPage.qml` in the default workflow, which pushes directly to the collapsed subcategory lists of `TemplateFilesPage.qml`.
