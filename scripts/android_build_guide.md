# Android Build Guide — Intonation Trainer 2

Package id: `by.intoncore.intontrainer2`. Native library: `libappinton-trainer-2_<abi>.so`. Version: **1.0.0** (`versionCode` 1).

## Prerequisites

Override any of these with environment variables; the values below are the script defaults.

| Item | Default / notes |
|---|---|
| Qt for Android | `$QT_ROOT/android_arm64_v8a` (also `android_x86_64`, `android_armv7`) |
| Qt host tools | `$QT_ROOT/gcc_64` |
| `QT_ROOT` | `$HOME/Qt/6.11.1` |
| Android SDK | `$ANDROID_SDK` → `$HOME/Android/Sdk` |
| Android NDK | `$ANDROID_NDK` → `$ANDROID_SDK/ndk/27.2.12479018` (Clang 18) |
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

If a manual `cmake --build ... --target apk` reports that Gradle is using
Java 11, export both variables before retrying:

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export GRADLE_OPTS="-Dorg.gradle.java.home=${JAVA_HOME}"
```

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
| Launch | `adb shell am start -n by.intoncore.intontrainer2/org.qtproject.qt.android.bindings.QtActivity` |

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

- Package: `by.intoncore.intontrainer2` (permanent once uploaded to Play)
- Permission: **`RECORD_AUDIO` only**
- Qt Core’s `INTERNET` / `WRITE_EXTERNAL_STORAGE` are stripped (`tools:node="remove"` and no `%%INSERT_PERMISSIONS%%` placeholder)
- Required feature: `android.hardware.microphone`
- Portrait only (`android:screenOrientation="portrait"`)
- Min SDK 26, target / compile SDK 36
- Version placeholders `%%INSERT_VERSION_CODE%%` / `%%INSERT_VERSION_NAME%%` (filled from CMake: code `1`, name `1.0.0`)
- `<meta-data android:name="android.app.lib_name" android:value="appinton-trainer-2"/>` is set **manually**
- Launcher icon: `@mipmap/ic_launcher`
- Round launcher icon: `@mipmap/ic_launcher_round`

### `android/res/values/styles.xml`

`AppTheme` uses a black `windowBackground` to avoid a light flash on launch.

### CMake target properties (`CMakeLists.txt`)

`QT_ANDROID_PACKAGE_SOURCE_DIR`, target/compile SDK **36**, min SDK 26, package `by.intoncore.intontrainer2`, version `1.0.0`. Native link flags `-Wl,-z,max-page-size=16384` for Play’s 16 KB page-size requirement.

OpenMP: desktop uses `find_package(OpenMP)`; Android locates NDK `libomp` and links the `AndroidOMP` imported target. alglib `kernels_avx2.cpp` / `kernels_fma.cpp` / `kernels_sse2.cpp` are omitted on Android.

---

## App icons

The selected A1 artwork is installed as both a legacy launcher icon and an
Android 8+ adaptive icon. The manifest already references
`@mipmap/ic_launcher` and `@mipmap/ic_launcher_round`.

Legacy launcher resources:

```
android/res/mipmap-mdpi/ic_launcher.png         (48×48)
android/res/mipmap-hdpi/ic_launcher.png         (72×72)
android/res/mipmap-xhdpi/ic_launcher.png        (96×96)
android/res/mipmap-xxhdpi/ic_launcher.png       (144×144)
android/res/mipmap-xxxhdpi/ic_launcher.png      (192×192)
android/res/mipmap-mdpi/ic_launcher_round.png   (48×48)
… (same sizes for round variants)
```

Adaptive resources:

```
android/res/mipmap-anydpi-v26/ic_launcher.xml
android/res/mipmap-anydpi-v26/ic_launcher_round.xml
android/res/drawable-mdpi/ic_launcher_foreground.png       (108×108)
android/res/drawable-hdpi/ic_launcher_foreground.png       (162×162)
android/res/drawable-xhdpi/ic_launcher_foreground.png      (216×216)
android/res/drawable-xxhdpi/ic_launcher_foreground.png     (324×324)
android/res/drawable-xxxhdpi/ic_launcher_foreground.png    (432×432)
android/res/values/colors.xml                              (#F9F9FF background)
```

The opaque **512×512** Play Console icon is
`packaging/google-play/icon-512.png`. The Play listing still needs a
**1024×500** feature graphic; it is store artwork and is not packaged in the
APK/AAB.

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

## Google Play readiness

Requirements checked against the official Google Play and Android
documentation on **8 September 2026**.

### Done in the repo

| Item | Status |
|---|---|
| ARM64 / x86_64 compile | Verified |
| OpenMP via NDK `libomp.so` | Linked |
| alglib x86 kernels excluded on Android | Done |
| `android.app.lib_name` meta-data | Done |
| Target / compile SDK 36 | Complies with the API 36 requirement for new apps and updates since 31 August 2026 |
| Version 1.0.0 / `versionCode` 1 | Set |
| Storage / media permissions removed | `RECORD_AUDIO` only; Qt `INTERNET` stripped |
| 16 KB ELF page-size linker flags | Added on the app target; packaged libraries still require final verification |
| Android App Bundle | `build_android.sh` produces the AAB required for new Play apps |
| Signing env vars | `QT_ANDROID_KEYSTORE_*` (and `ANDROID_KEYSTORE_*` aliases) wired |
| File picker | Hidden on Android |
| Recordings in app-private storage | No `MediaStore` needed |
| `armeabi-v7a` ABI name | Script maps `armv7` → `armeabi-v7a` |
| Font Awesome 7 on Android | Fixed (weight + `qrc:` paths) |
| Keystore files gitignored | `*.jks`, `*.keystore` |
| Launcher icons | Legacy, round, and adaptive resources added; manifest wired |
| Play Console icon | 512×512 RGBA PNG, 220 KB: `packaging/google-play/icon-512.png` |
| Play Console account | Verified |

### Required before the first Play release

| Item | What to do |
|---|---|
| **Upload key and Play App Signing** | Generate and back up the upload keystore, build a signed release AAB, and upload it. New apps are automatically enrolled in Play App Signing; keep the upload key separate and enable 2-Step Verification for Console users. |
| **Release identity** | Confirm package `by.intoncore.intontrainer2` before the first upload. Increment `versionCode` for every later upload; the package name cannot be changed after publishing. |
| **Privacy policy** | Publish an active public HTTPS policy and make the same policy accessible inside the app. Explain microphone access, local voice recordings, retention/deletion, no upload/sharing, and `allowBackup=false`. |
| **Data safety** | Complete the form even if no data leaves the device. Declare the actual handling of microphone/voice recordings and keep it consistent with the app and privacy policy. Internal-only testing is exempt; closed, open, and production tracks are not. |
| **App content declarations** | Complete Ads, App access, Target audience and content, and the IARC content-rating questionnaire. Declare no ads and unrestricted access only if that matches the release. Do not include children unless the app is intended to meet Families requirements. |
| **Store listing text** | Supply localized app name (≤30 characters), short description (≤80), and full description (≤4,000), plus a support email. Avoid rankings, prices, repetitive keywords, and misleading claims. |
| **Feature graphic** | Create a 1024×500 JPEG or 24-bit PNG with no alpha. It is mandatory listing artwork and is not bundled in the app. |
| **Phone screenshots** | Upload at least 2 actual app screenshots: JPEG/24-bit PNG, 320–3840 px, with the long side no more than twice the short side. For stronger Play promotion eligibility, provide at least 4 portrait 1080×1920 screenshots. |
| **16 KB compatibility** | Required for 64-bit native apps targeting Android 15+ since 1 November 2025. Run the official `check_elf_alignment.sh` or inspect every packaged `.so` (Qt, app, SPTK, alglib, `libomp`), verify APK zip alignment with `zipalign -c -P 16 -v 4`, inspect the AAB with `bundletool`, and test on a 16 KB image/device. |
| **Physical ARM64 QA** | Confirm microphone permission, recording/VAD, guided mode, packaged templates, record saving/deletion, offline behavior, and startup on a physical ARM64 device. |
| **Closed testing, if applicable** | Personal accounts created after 13 November 2023 need at least 12 testers continuously opted in for 14 days, followed by a production-access application. Testers must remain engaged; opting out breaks continuity. |
| **Developer verification** | Check Play Console account identity and package registration. Enforcement begins 30 September 2026 for participating stores in Brazil, Indonesia, Singapore, and Thailand, then expands globally in 2027; most existing verified Play developers need no extra identity action. |
| **Native debug symbols** | Configure the release bundle to include full native symbols (`ndk.debugSymbolLevel = 'FULL'`) and confirm them in App Bundle Explorer. With AAB and AGP 4.1+, Play extracts included symbols automatically; upload a ZIP manually only if they are not bundled. |
| **Licences** | Add Qt LGPL notices and relink offer where applicable, plus Font Awesome, SPTK, and alglib attributions. |
| **Portrait-only decision** | Keep `screenOrientation="portrait"` only if this is intentional and phone QA confirms all content remains usable. |

### Official references

- [Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [16 KB page-size compatibility](https://developer.android.com/guide/practices/page-sizes)
- [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [Store listing assets](https://support.google.com/googleplay/android-developer/answer/9866151)
- [Prepare an app for review](https://support.google.com/googleplay/android-developer/answer/9859455)
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)
- [New personal-account testing](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Android developer verification](https://developer.android.com/developer-verification/guides)
- [Native debug symbols](https://support.google.com/googleplay/android-developer/answer/9848633)
