# Intonation Trainer 2 — User Interface Screens

This document summarizes the current QML UI flow of the app as it exists in the codebase today. It intentionally focuses on the screens and controls that are currently in active use, rather than historical or experimental layouts.

---

## UI architecture and global behavior

The application is built with Qt Quick/QML and uses a Material-style visual system with light, dark, and system theme support. The main navigation is managed from `Main.qml` through a `StackView` and a small set of global settings exposed by `SettingsApi`.

### Navigation modes

The interface changes its navigation affordance depending on the `Show Navigation Menu` setting:

1. `Show Navigation Menu = false`
   - Desktop-style presentation mode.
   - The application uses the top-left menu icon to open the navigation drawer.
   - Scrollable pages keep a desktop-style vertical scrollbar visible to match traditional desktop interaction.

2. `Show Navigation Menu = true`
   - Standard mode.
   - A bottom navigation bar is shown for quick access to the main parts of the app.

---

## Core screens

### Home Page (`HomePage.qml`)

Purpose:
- Landing dashboard and progress overview.

What it shows:
- Brand header and theme-aware accent styling.
- A large Start Training action.
- Current language chip and completion summary.
- Quick stats such as average score and training progress.

User actions:
- Start training to open the template category flow.
- If auto-calibration is enabled, the app may run the VAD calibration step before continuing.

### Template Categories Page (`TemplateCategoriesPage.qml`)

Purpose:
- Browse the available pattern folders from `data/patterns`.

What it shows:
- Search bar for folder filtering.
- Category list with icons and scroll support.
- Desktop-style visible scrollbar when navigation is hidden.

User actions:
- Open a category and continue to the template file list.

### Template Files Page (`TemplateFilesPage.qml`)

Purpose:
- Display the reference `.wav` files inside the selected category.

What it shows:
- Search field.
- Filter chips such as All, New, Improve, and Mastered.
- Accordion-style subcategory headers with animated expand/collapse behavior.
- Per-file training status and score summary.

User actions:
- Expand or collapse folder sections.
- Search while preserving visibility of matching files.
- Tap a template to open the training screen.

### Training Page (`TrainingPage.qml`)

Purpose:
- The main interactive training workspace where speech is recorded, evaluated, and compared against a reference template.

Current workflow:
- The page supports two operating modes:
  - Auto mode: continuous VAD-driven recording loop.
  - Guided mode: reference playback first, then a timed listen window for user speech.

What the user sees:
- Similarity score card with current result and recent score history.
- Reference/user waveform comparison.
- A live listening indicator and VAD state visuals during recording.
- Playback controls for reference audio and the user’s last recording.
- Open test file support for comparing local `.wav` files.
- A toggle between guided and auto training flows when guided mode is enabled.

Current behavior of guided mode:
- The user first listens to the reference clip.
- After playback finishes, the app waits the configured post-playback delay.
- A listen timeout bounds how long the app waits for speech onset.
- When the recording stops, the signal is processed and scored.

### Advanced Template Analysis Page (`TemplatePage.qml`)

Purpose:
- Deep inspection and diagnostic view of the user/reference signal and alignment.

What it shows:
- Waveforms and cue-point overlays.
- Pitch, UMP, amplitude, and spectrogram/cepstrum diagnostics.
- DTW distance and alignment path displays.
- A settings panel for tuning analysis parameters.

User actions:
- Play the reference and user audio.
- Inspect alignment and signal processing details.
- Recalculate the analysis with the current DSP settings.

### Records Page (`RecordsPage.qml`)

Purpose:
- Archive previously recorded attempts.

What it shows:
- Search and delete-all controls.
- A saved-record list with record metadata and score history.
- Per-item delete actions.

User actions:
- Open historical records for inspection.
- Revisit a previous attempt in the advanced template analysis view.

### Settings Page (`SettingsPage.qml`)

Purpose:
- Central user configuration page.

Current UI structure:
- A top-level `Advanced` toggle is present at the top of the page.
- This toggle is local to the page and is not persisted in the settings file.
- When `Advanced` is off, only the common settings remain visible.
- When `Advanced` is on, the lower-level VAD, pitch, spectrum, and DTW tuning sections become visible.

Visible common settings:
- Language
- Language Title
- Theme
- Primary Color
- Show Navigation Menu
- Font Size
- Delete user data
- Guided mode and auto-stop controls
- Autocalibrate and calibration actions

Advanced-only settings:
- VAD method and detailed thresholds
- Minimum record length percentage
- Pitch / pitch log / UMP / amplitude / spectrum / DP tuning controls
- DTW distance limit and DTW alignment options

The page saves changes immediately through `SettingsApi`.

---

## Supplementary and legacy screens

### Recording Page (`RecordingPage.qml`)

Purpose:
- Standalone microphone sandbox for quick audio check and playback testing.

### Templates Page (`TemplatesPage.qml`)

Purpose:
- Alternative template-list presentation.

Status:
- This screen exists in the codebase but is not the primary navigation path used by the live workflow.

### Categories Page (`CategoriesPage.qml`)

Purpose:
- Legacy or alternate category navigation.

Status:
- The current app flow prefers `TemplateCategoriesPage.qml` + `TemplateFilesPage.qml` for the normal user journey.
