# VAD regression checks

Build independently of the application with the installed Qt kit:

```sh
cmake -S tests/vad -B /tmp/opencode/inton-vad-tests -DCMAKE_PREFIX_PATH="$HOME/Qt/6.12.0/gcc_64"
cmake --build /tmp/opencode/inton-vad-tests --parallel 2
ctest --test-dir /tmp/opencode/inton-vad-tests --output-on-failure
```

Checks cover callback-size independence, calibration/live windowed energy equivalence, digital silence with the energy gate disabled, voiced input, energy-gate rejection, and reset. Synthetic signals do not establish real speech accuracy.

Manual checks after building the application:

- Calibrate energy, autocorrelation, Hybrid AND, and Hybrid OR. Hybrid calibration should complete both phases and navigate only once.
- Restart the application and confirm `autoCorrEnergyThreshold` persists in `settings.ini`, including after unrelated settings changes.
- In guided mode, try silence, a click, quiet speech, normal speech, and a too-short utterance. Verify the onset timeout, retained beginning of speech, and retry after rejection.
- Repeat with reference playback and the optional beep enabled, using both speakers and headphones.
- Compare in quiet and noisy rooms on desktop and Android microphones.

The onset confirmation operates on smoothed VAD decisions; a noise impulse can still spread across several frames. Calibration assumes a quiet user, and sustained tonal noise can still resemble voice. These cases need microphone testing before claiming an accuracy improvement.
