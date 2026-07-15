# Android App Bundle Build Guide — Intonation Trainer 2

## Environment Summary

| Item | Value |
|---|---|
| Qt for Android | `~/Qt/6.11.1/android_arm64_v8a` (+ armv7, x86_64 available) |
| Qt host tools | `~/Qt/6.11.1/gcc_64` |
| Android NDK | `~/Android/Sdk/ndk/27.2.12479018` (Clang 17) |
| Android SDK | `~/Android/Sdk` |
| Build tools | `36.0.0` |
| Target API / compileSdk | Android 35 (min SDK 26 / Android 8.0) |
| Java | OpenJDK 17 (Required by Android Gradle Plugin) |
| OpenMP | `libomp.so` — found in NDK Clang runtime ✅ |
| Emulator AVDs | `Pixel7a`, `Pixel7a_arm64`, `Pixel7a_x86_64` |

---

## What Was Changed

### 1. `CMakeLists.txt`

| Change | Reason |
|---|---|
| Conditional `find_package(OpenMP)` (desktop only) | Android NDK's libomp isn't found by standard `FindOpenMP`; detected manually via `find_library` |
| `AndroidOMP` imported target | Wraps the NDK `libomp.so` so it gets packaged into the APK/AAB automatically |
| alglib sources guarded by `if(ANDROID)` | Excludes `kernels_avx2.cpp`, `kernels_fma.cpp`, `kernels_sse2.cpp` — these won't compile for ARM |
| `QT_ANDROID_*` target properties | Points Qt's deployment to `android/` package source dir, sets SDK versions, package name `by.intontrainer`, and bumps `QT_ANDROID_TARGET_SDK_VERSION` to 35. |

### 2. `android/AndroidManifest.xml` *(new)*

- Package: `by.intontrainer`
- Permissions: `RECORD_AUDIO`, `READ_EXTERNAL_STORAGE`, `READ_MEDIA_AUDIO`, `WRITE_EXTERNAL_STORAGE`
- Required feature: `android.hardware.microphone`
- Locked to **portrait** orientation
- Min SDK 26, target SDK 35
- **`android.app.lib_name` meta-data:** Manually added `<meta-data android:name="android.app.lib_name" android:value="appinton-trainer-2"/>` inside `<activity>`. Required because `androiddeployqt` does not reliably inject this on all build configurations. Without it, the app crashes with `QtLoader: The main library name is null or empty`.
- Icons removed from manifest until actual files are added to prevent AAPT link failures.

### 3. `android/res/values/styles.xml` *(new)*

- Minimal dark-background theme (`AppTheme`) to avoid white flash on launch.

### 4. `scripts/build_android.sh` *(new)*

Automated script for building and packaging the `.aab` using Qt's native target support.

---

## Quick Build (ARM64)

```bash
# From project root — build verified ✅
cd /home/zhitko/Vault/Dev/UIIP/inton-trainer-2
./scripts/build_android.sh arm64-v8a release
```

This script:
1. configures CMake for Android ARM64
2. runs compilation
3. compiles against Android SDK 35 (via `sdkmanager "platforms;android-35"`)
4. runs Gradle using Java 17 to build the `.aab` package

Output `.aab`:
`build_android_arm64_v8a/android-build/build/outputs/bundle/release/android-build-release.aab`

---

## Cleaning Android Builds

To remove all `build_android_*` directories:

```bash
./scripts/clean_android_build.sh            # prompt before deleting
./scripts/clean_android_build.sh --force    # skip confirmation
./scripts/clean_android_build.sh --dry-run  # preview only
```

---

## Manual CMake Configure + Build

If you want to run the configure steps manually:

```bash
# Export Java 17 for Gradle
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export GRADLE_OPTS="-Dorg.gradle.java.home=${JAVA_HOME}"

# Configure
cmake \
  -S . \
  -B build_android_arm64_v8a \
  -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=$HOME/Android/Sdk/ndk/27.2.12479018/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-26 \
  -DANDROID_NDK=$HOME/Android/Sdk/ndk/27.2.12479018 \
  -DCMAKE_ANDROID_NDK=$HOME/Android/Sdk/ndk/27.2.12479018 \
  -DCMAKE_FIND_ROOT_PATH=$HOME/Qt/6.11.1/android_arm64_v8a \
  -DCMAKE_PREFIX_PATH=$HOME/Qt/6.11.1/android_arm64_v8a \
  -DQT_HOST_PATH=$HOME/Qt/6.11.1/gcc_64 \
  -DQT_HOST_PATH_CMAKE_DIR=$HOME/Qt/6.11.1/gcc_64/lib/cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DANDROID_SDK_ROOT=$HOME/Android/Sdk

# Compile the binary
cmake --build build_android_arm64_v8a --target appinton-trainer-2 -- -j$(nproc)

# Build the Android App Bundle (.aab) via Qt's native target
cmake --build build_android_arm64_v8a --target aab -- -j$(nproc)
```

---

## Signing for Release (Google Play)

> [!IMPORTANT]
> Google Play requires a **signed** AAB. Generate a keystore once and keep it safe.

```bash
# Generate keystore (one-time)
keytool -genkey -v \
  -keystore inton-trainer-2.jks \
  -alias inton-trainer-2 \
  -keyalg RSA -keysize 2048 -validity 10000
```

To sign the AAB, set environment variables for the build script:

```bash
export ANDROID_KEYSTORE_PATH=~/inton-trainer-2.jks
export ANDROID_KEYSTORE_ALIAS=inton-trainer-2
export ANDROID_KEYSTORE_PASSWORD=<password>
./scripts/build_android.sh arm64-v8a release
```

Or configure the signing properties directly in Gradle by editing `build_android_arm64_v8a/android-build/gradle.properties` or passing variables to gradle.

---

## App Icons (TODO)

If you wish to configure launcher icons, create them at these paths:
```
android/res/mipmap-mdpi/ic_launcher.png        (48×48)
android/res/mipmap-hdpi/ic_launcher.png        (72×72)
android/res/mipmap-xhdpi/ic_launcher.png       (96×96)
android/res/mipmap-xxhdpi/ic_launcher.png      (144×144)
android/res/mipmap-xxxhdpi/ic_launcher.png     (192×192)
android/res/mipmap-mdpi/ic_launcher_round.png  (48×48)
… (same for round variants)
```
Once added, you can restore `android:icon="@mipmap/ic_launcher"` and `android:roundIcon="@mipmap/ic_launcher_round"` in `android/AndroidManifest.xml` under the `<application>` element.

---

## Running on Emulator

A convenience script automates booting the emulator, installing the compiled APK, and starting the app.

```bash
# Make executable and run (optional: pass a specific AVD name)
chmod +x scripts/run_emulator.sh
./scripts/run_emulator.sh [avd_name]
```

### Script features

| Feature | Detail |
|---------|--------|
| **AVD selection** | Accepts AVD name as argument; defaults to first available AVD |
| **Pre-flight checks** | Validates `emulator` and `adb` binaries exist before anything else |
| **Boot timeout** | `BOOT_TIMEOUT_SEC` (default 120s, env-overridable); exits with error if emulator doesn't boot in time |
| **Emulator log** | Saved to `$BUILD_DIR/emulator.log`; dumped on failure |
| **Logcat capture** | `adb logcat` started in background before app launch; filtered crash dump on failure |
| **`--logcat` mode** | `./scripts/run_emulator.sh --logcat` streams live logcat without restarting emulator |
| **Multi-ABI APK search** | Searches `build_android_x86_64` first (host arch), then `build_android_arm64-v8a` |
| **Dynamic build dir** | Logs go to the correct build directory based on which APK was found |

### Architecture matching

> **IMPORTANT:** The APK architecture must match the emulator architecture.

| Emulator AVD | Required APK build |
|---|---|
| `Pixel7a_x86_64` | `./scripts/build_android.sh x86_64 debug` |
| `Pixel7a_arm64` | `./scripts/build_android.sh arm64-v8a debug` |

The `Pixel7a_arm64` AVD **cannot run** on an x86_64 host — use `Pixel7a_x86_64` for local development.

### Typical workflow

```bash
# Build for x86_64 emulator
./scripts/build_android.sh x86_64 debug

# Launch on emulator
./scripts/run_emulator.sh Pixel7a_x86_64

# If the app crashes, check logs
./scripts/run_emulator.sh --logcat
# Or inspect: build_android_x86_64/logcat.log
```

---

## Font Awesome 7 Icons on Android

### Problem

Some icons rendered as empty squares (☐) on Android while working fine on desktop. Root cause: `fa-solid-900.ttf` and `fa-regular-400.ttf` share the same family name (`Font Awesome 7 Free`). On Android, `font.family: Icons.familySolid` alone caused the system font matcher to pick the **regular** weight (400) variant, which has only 225 PUA glyphs vs 1084 in solid.

### Fix

1. **FontLoader paths:** Use `qrc:` prefix instead of `:` in `ui/utils/Icons.qml` — on Android, `:` resolves relative to the QML file's directory, corrupting the path.
2. **Font weight:** Add `font.weight: Font.Black` alongside every `font.family: Icons.familySolid` across all QML files that render icons. This forces the system to select the solid (weight 900) variant.
3. **`faBars`:** Changed from `Icons.familyRegular` to `Icons.familySolid` — this glyph only exists in the solid font.

> **Key insight:** Never use `Icons.fontSolid.weight` in QML — accessing `.weight` on a `font` value type triggers "Property has already been assigned a value" warnings. Use `Font.Black` (900) / `Font.Normal` (400) literals instead.

---

## File Picker on Android

The current `FileApi` uses `QFileDialog`. On Android 11+ this requires the new `ActivityResultLauncher` approach via `Qt.labs.platform.FileDialog` or `QFileDialog` with the native file picker (Qt6 Multimedia platform plugin enables this). Test manually on device/emulator.

---

## Verified / Next Steps

| Item | Status |
|---|---|
| ARM64 compile (`libappinton-trainer-2_arm64-v8a.so`) | ✅ Verified |
| x86_64 compile (`libappinton-trainer-2_x86_64.so`) | ✅ Verified |
| OpenMP (libomp.so via NDK Clang 17) | ✅ Detected and linked |
| AVX2/FMA/SSE2 alglib kernels excluded on Android | ✅ |
| AndroidManifest.xml + permissions | ✅ |
| `android.app.lib_name` meta-data | ✅ Added manually |
| Target & Compile SDK 35 compatibility | ✅ |
| APK packaging via `cmake --build ... --target apk` | ✅ Verified |
| AAB packaging via `cmake --build ... --target aab` | ✅ Verified |
| App launches on x86_64 emulator | ✅ Verified |
| Font Awesome 7 icons render correctly | ✅ Fixed (font weight + qrc paths) |
| App icons | ⚠️ Placeholder needed |
| Keystore / signing | 🔲 Generate before Play upload |
| Test on physical ARM64 device | 🔲 |
| `screenOrientation` | Portrait only — relax if landscape desired |
| File storage paths (WAV recordings) | May need `MediaStore` API on Android 10+ |
