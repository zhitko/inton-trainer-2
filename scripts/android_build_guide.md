# Android Build Guide — Intonation Trainer 2

Package id: `by.intontrainer`. Native library: `libappinton-trainer-2_<abi>.so`. Version: **1.0.0** (`versionCode` 1).

## Prerequisites

Override any of these with environment variables; the values below are the script defaults.

| Item | Default / notes |
|---|---|
| Qt for Android | `$QT_ROOT/android_arm64_v8a` (also `android_x86_64`, `android_armv7`) |
| Qt host tools | `$QT_ROOT/gcc_64` |
| `QT_ROOT` | `$HOME/Qt/6.11.1` |
| Android SDK | `$ANDROID_SDK` → `$HOME/Android/Sdk` |
| Android NDK | `$ANDROID_NDK` → `$ANDROID_SDK/ndk/27.2.12479018` (Clang 17) |
| Build tools | `36.0.0` |
| Target / compile SDK | **36** (`platforms;android-36` must be installed) |
| Min SDK | 26 (Android 8.0) |
| Java | OpenJDK 17 (`$JAVA_HOME`, default `/usr/lib/jvm/java-17-openjdk-amd64`) |
| Tools on `PATH` | `cmake`, `ninja`, `java` |
| OpenMP | NDK `libomp.so` (imported as `AndroidOMP`) |
| Local AVDs | `Pixel7a`, `Pixel7a_arm64`, `Pixel7a_x86_64` |

Install the Android 36 platform if CMake/Gradle fails looking for it:

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
yes | "$HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager" "platforms;android-36"
```

All commands below run from the **project root**.

Play Store uploads should use **arm64-v8a only**.

---

## Quick start

### Device / Play ARM64 (APK + AAB)

```bash
./scripts/build_android.sh arm64-v8a release
```

The script configures CMake, compiles `appinton-trainer-2`, then packages both Qt targets: **`apk`** (sideload / emulator) and **`aab`** (Play). Gradle uses Java 17 via `GRADLE_OPTS`.

Typical outputs:

```
build_android_arm64-v8a/android-build/build/outputs/apk/release/android-build-release.apk
build_android_arm64-v8a/android-build/build/outputs/bundle/release/android-build-release.aab
```

Build directory names follow the NDK ABI: `build_android_arm64-v8a`, `build_android_x86_64`, `build_android_armeabi-v7a`.

### x86_64 emulator (local development)

```bash
./scripts/build_android.sh x86_64 debug
./scripts/run_emulator.sh Pixel7a_x86_64
```

An ARM64 AVD cannot run on an x86_64 host. Use `Pixel7a_x86_64` for local testing.

---

## Scripts

### `scripts/build_android.sh`

```bash
./scripts/build_android.sh [arm64-v8a|armeabi-v7a|x86_64|all]  [debug|release]
```

Defaults: `arm64-v8a`, `release`. `armv7` is accepted as an alias for `armeabi-v7a`.

| Env var | Purpose |
|---|---|
| `QT_ROOT` | Qt install root (kits live in `android_*` subdirs) |
| `ANDROID_SDK` | SDK root (`ANDROID_HOME` is set to this) |
| `ANDROID_NDK` | NDK root |
| `JAVA_HOME` | JDK 17 for Gradle |
| `QT_ANDROID_KEYSTORE_PATH` | Upload keystore (enables `-DQT_ANDROID_SIGN_AAB=ON`) |
| `QT_ANDROID_KEYSTORE_ALIAS` | Key alias |
| `QT_ANDROID_KEYSTORE_STORE_PASS` | Keystore password |
| `QT_ANDROID_KEYSTORE_KEY_PASS` | Key password |

`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_ALIAS`, and `ANDROID_KEYSTORE_PASSWORD` are aliases that fill the `QT_ANDROID_*` vars when those are unset.

`all` builds each ABI in turn, then packages from the **arm64-v8a** build dir only.

Without a keystore the AAB is still produced but is **not** signed for Play.

### `scripts/run_emulator.sh`

```bash
./scripts/run_emulator.sh [avd_name]
./scripts/run_emulator.sh --logcat
```

| Behavior | Detail |
|---|---|
| AVD | Argument, or the first name from `emulator -list-avds` |
| Pre-flight | Requires executable `emulator` and `adb` under `$ANDROID_SDK` |
| Boot timeout | `BOOT_TIMEOUT_SEC` (default 120) |
| Emulator log | `$BUILD_DIR/emulator.log` (dumped if the emulator process dies) |
| Logcat | Started before `am start`; crash-filtered dump if the process is gone |
| APK search | `build_android_x86_64` first, then `build_android_arm64-v8a` (debug, then release, then unsigned) |
| Launch | `adb shell am start -n by.intontrainer/org.qtproject.qt.android.bindings.QtActivity` |

`--logcat` streams live logcat and always writes `build_android_arm64-v8a/logcat.log`, even if you installed an x86_64 APK. After a normal launch, inspect `$BUILD_DIR/logcat.log` (the dir of the APK that was found).

The APK ABI must match the emulator ABI:

| AVD | Build |
|---|---|
| `Pixel7a_x86_64` | `./scripts/build_android.sh x86_64 debug` |
| `Pixel7a_arm64` | `./scripts/build_android.sh arm64-v8a debug` (ARM host or translation only) |

### `scripts/clean_android_build.sh`

Removes every `build_android_*` directory in the project root:

```bash
./scripts/clean_android_build.sh            # prompt before deleting
./scripts/clean_android_build.sh --force    # skip confirmation
./scripts/clean_android_build.sh --dry-run  # preview only
```

---

## Manual CMake configure + build

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export GRADLE_OPTS="-Dorg.gradle.java.home=${JAVA_HOME}"

cmake \
  -S . \
  -B build_android_arm64-v8a \
  -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$HOME/Android/Sdk/ndk/27.2.12479018/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-26 \
  -DANDROID_NDK="$HOME/Android/Sdk/ndk/27.2.12479018" \
  -DCMAKE_ANDROID_NDK="$HOME/Android/Sdk/ndk/27.2.12479018" \
  -DCMAKE_FIND_ROOT_PATH="$HOME/Qt/6.11.1/android_arm64_v8a" \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.11.1/android_arm64_v8a" \
  -DQT_HOST_PATH="$HOME/Qt/6.11.1/gcc_64" \
  -DQT_HOST_PATH_CMAKE_DIR="$HOME/Qt/6.11.1/gcc_64/lib/cmake" \
  -DCMAKE_BUILD_TYPE=Release \
  -DANDROID_SDK_ROOT="$HOME/Android/Sdk"

cmake --build build_android_arm64-v8a --target appinton-trainer-2 -- -j"$(nproc)"
cmake --build build_android_arm64-v8a --target apk -- -j"$(nproc)"
cmake --build build_android_arm64-v8a --target aab -- -j"$(nproc)"
```

Do not call `androiddeployqt` by hand. Qt’s `apk` / `aab` CMake targets stage libs and generate the Gradle project.

---

## Signing for Google Play

Google Play needs a **signed AAB**. Generate an upload keystore once, keep a backup offline, and never commit it (`*.jks` is gitignored).

```bash
keytool -genkey -v \
  -keystore "$HOME/inton-trainer-2.jks" \
  -alias inton-trainer-2 \
  -keyalg RSA -keysize 2048 -validity 10000
```

Then:

```bash
export QT_ANDROID_KEYSTORE_PATH="$HOME/inton-trainer-2.jks"
export QT_ANDROID_KEYSTORE_ALIAS=inton-trainer-2
export QT_ANDROID_KEYSTORE_STORE_PASS='<password>'
export QT_ANDROID_KEYSTORE_KEY_PASS='<key-password>'

./scripts/build_android.sh arm64-v8a release
```

The script passes `-DQT_ANDROID_SIGN_AAB=ON` (and `QT_ANDROID_SIGN_APK`) at configure time. The keystore env vars must stay exported during the Gradle/`androiddeployqt` step — CMake `set()` is not enough.

See [QT_ANDROID_SIGN_AAB](https://doc.qt.io/qt-6.11/cmake-variable-qt-android-sign-aab.html) and [Publishing to Google Play](https://doc.qt.io/qt-6.11/android-publishing-to-googleplay.html).

---

## Runtime assets

On Android, `CMakeLists.txt` copies `settings.ini` and `data/` into `android/assets/` so `androiddeployqt` packs them into the APK (extracted under `AppDataLocation` on device).

`android/assets/` is gitignored — it is generated at build time. Rebuild after changing templates or `settings.ini`. Recordings are written to app-private storage (`AppDataLocation/data/records`); `MediaStore` is not required.

---

## Package source (`android/`)

### `android/AndroidManifest.xml`

- Package: `by.intontrainer` (permanent once uploaded to Play)
- Permission: **`RECORD_AUDIO` only**
- Qt Core’s `INTERNET` / `WRITE_EXTERNAL_STORAGE` are stripped (`tools:node="remove"` and no `%%INSERT_PERMISSIONS%%` placeholder)
- Required feature: `android.hardware.microphone`
- Portrait only (`android:screenOrientation="portrait"`)
- Min SDK 26, target / compile SDK 36
- Version placeholders `%%INSERT_VERSION_CODE%%` / `%%INSERT_VERSION_NAME%%` (filled from CMake: code `1`, name `1.0.0`)
- `<meta-data android:name="android.app.lib_name" android:value="appinton-trainer-2"/>` is set **manually**
- No launcher icons in the manifest yet — add mipmaps before restoring `android:icon` / `android:roundIcon`

### `android/res/values/styles.xml`

`AppTheme` uses a black `windowBackground` to avoid a light flash on launch.

### CMake target properties (`CMakeLists.txt`)

`QT_ANDROID_PACKAGE_SOURCE_DIR`, target/compile SDK **36**, min SDK 26, package `by.intontrainer`, version `1.0.0`. Native link flags `-Wl,-z,max-page-size=16384` for Play’s 16 KB page-size requirement.

OpenMP: desktop uses `find_package(OpenMP)`; Android locates NDK `libomp` and links the `AndroidOMP` imported target. alglib `kernels_avx2.cpp` / `kernels_fma.cpp` / `kernels_sse2.cpp` are omitted on Android.

---

## App icons (TODO — manual)

Add launcher images, then restore `android:icon="@mipmap/ic_launcher"` and `android:roundIcon="@mipmap/ic_launcher_round"` on `<application>`. Prefer an adaptive icon (`mipmap-anydpi-v26`) plus:

```
android/res/mipmap-mdpi/ic_launcher.png         (48×48)
android/res/mipmap-hdpi/ic_launcher.png         (72×72)
android/res/mipmap-xhdpi/ic_launcher.png        (96×96)
android/res/mipmap-xxhdpi/ic_launcher.png       (144×144)
android/res/mipmap-xxxhdpi/ic_launcher.png      (192×192)
android/res/mipmap-mdpi/ic_launcher_round.png   (48×48)
… (same sizes for round variants)
```

Play Console also needs a **512×512** high-res icon and a **1024×500** feature graphic (not stored in the APK).

---

## Font Awesome 7 on Android

`fa-solid-900.ttf` and `fa-regular-400.ttf` share the family name `Font Awesome 7 Free`. On Android, `font.family` alone can pick the regular (400) face, which lacks most solid glyphs.

Required:

1. `FontLoader` URLs in `ui/utils/Icons.qml` use the `qrc:` prefix (a bare `:` is resolved relative to the QML file on Android).
2. Pair `font.family: Icons.familySolid` with `font.weight: Font.Black` (900), not `Icons.fontSolid.weight` (that assignment warns and is ignored).
3. Glyphs that exist only in solid (e.g. `faBars`) must use the solid family.

---

## File picker

The **Open Test File** button on `TrainingPage.qml` is desktop-only (`visible: !AppScale.isMobile`). Android uses microphone recording only.

---

## Status

### Done in the repo

| Item | Status |
|---|---|
| ARM64 / x86_64 compile | Verified |
| OpenMP via NDK `libomp.so` | Linked |
| alglib x86 kernels excluded on Android | Done |
| `android.app.lib_name` meta-data | Done |
| Target / compile SDK 36 | Set in CMake; platform installed at `$HOME/Android/Sdk/platforms/android-36` (Android 16, Pkg.Revision 2) |
| Version 1.0.0 / `versionCode` 1 | Set |
| Storage / media permissions removed | `RECORD_AUDIO` only; Qt `INTERNET` stripped |
| 16 KB ELF page-size linker flags | Added on the app target |
| APK + AAB from `build_android.sh` | Script builds both |
| Signing env vars | `QT_ANDROID_KEYSTORE_*` (and `ANDROID_KEYSTORE_*` aliases) wired |
| File picker | Hidden on Android |
| Recordings in app-private storage | No `MediaStore` needed |
| `armeabi-v7a` ABI name | Script maps `armv7` → `armeabi-v7a` |
| Font Awesome 7 on Android | Fixed (weight + `qrc:` paths) |
| Keystore files gitignored | `*.jks`, `*.keystore` |
| Play Console account | Verified |

### Remaining — do these manually before Play production

| Item | What to do |
|---|---|
| **Upload keystore** | Generate with `keytool`, back up offline, export `QT_ANDROID_*` and rebuild a **signed** AAB |
| **Launcher + store icons** | Mipmaps in `android/res/`, 512×512 Play icon, 1024×500 feature graphic |
| **Phone screenshots** | At least 2 portrait (9:16) shots from a device/emulator — desktop `docs/screenshots` will not pass |
| **Privacy policy** | Public HTTPS page: on-device audio only, not uploaded, deletable via Delete User Data, `allowBackup=false` |
| **Store listing** | Short (80) + full description, Data safety (mic/audio, not shared), IARC rating, no ads, not Designed for Families unless intended. Package id `by.intontrainer` is permanent after first upload. |
| **Sensitive permission** | Justify `RECORD_AUDIO` as the core training feature |
| **Closed testing** | Only if this is a personal account created after Nov 2023: 12 testers opted in for 14 consecutive days, then apply for production. Organization / older personal accounts can go to production directly. |
| **Physical ARM64 device** | Confirm mic permission, VAD, guided mode, templates from assets, recordings save |
| **16 KB alignment check** | After packaging, run `check_elf_alignment.sh` (or Play pre-launch report) on every `.so`, including Qt and `libomp` |
| **Native debug symbols** | Upload the symbols zip with the AAB for readable crash reports |
| **Licenses** | Qt LGPL notices + relink offer if using LGPL Qt; Font Awesome / SPTK / alglib attributions |
| **Android Developer Verification** | Enforced from 30 Sep 2026 |
| **Portrait-only** | Relax `screenOrientation` only if landscape is desired |
