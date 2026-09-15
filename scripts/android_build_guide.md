# Android Build Guide — Intonation Trainer 2

Package id: `by.intoncore.intontrainer2.zh` (Chinese edition). Native library: `libappinton-trainer-2_<abi>.so`. Later language apps use a different suffix (`.en`, `.ru`, `.de`, …) and a separate Play listing; the package id cannot be changed after the first upload.

Every Google Play upload is built from a **git tag**. Current release: tag **`1.0.0`** (`versionName` `1.0.0`, `versionCode` 1, internal testing). See [Release versioning](#release-versioning-git-tags) below.

## Release versioning (git tags)

Play `versionName` and the in-app version come from [Semantic Versioning](https://semver.org/) `MAJOR.MINOR.PATCH`. The git tag is that same string, **without** a `v` prefix (the first Play upload is `1.0.0`).

| Field | Source | Rule |
|---|---|---|
| Git tag | `git tag -a MAJOR.MINOR.PATCH` | One annotated tag per Play upload. Tags are immutable; never move `1.0.0`. |
| `versionName` | `project(... VERSION ...)` in `CMakeLists.txt` (`PROJECT_VERSION`) | Must equal the git tag. |
| `versionCode` | `QT_ANDROID_VERSION_CODE` in `CMakeLists.txt` | Integer. **Must increase** for every new AAB of this package. Independent of the semver numbers. |

Bump meaning:

- **PATCH** (`1.0.0` → `1.0.1`) — bug fixes, listing/packaging-only changes, a rebuild that still needs a new Play artifact.
- **MINOR** (`1.0.0` → `1.1.0`) — new features that stay compatible.
- **MAJOR** (`1.0.0` → `2.0.0`) — breaking changes for users or an incompatible data/format change.

Default bump is **PATCH** unless the release notes call for minor or major. Every Play upload still increments `versionCode` by 1, even when `versionName` stays in the same MAJOR.MINOR line.

### Releases uploaded to Play

| Git tag | `versionName` | `versionCode` | Play track |
|---|---|---|---|
| `1.0.0` | `1.0.0` | 1 | Internal testing |

### Next Play upload

1. Choose the next semver (PATCH unless a MINOR/MAJOR is warranted).
2. Update `CMakeLists.txt`: `project(inton-trainer-2 VERSION x.y.z)` and `QT_ANDROID_VERSION_CODE` (previous + 1).
3. Record the row in the table above. Update the version line in this intro.
4. Add English and Russian **What’s new** for that version in `packaging/google-play/store-listing.md`.
5. Commit the version bump, then create an annotated tag on that commit:

```bash
git tag -a 1.0.1 -m "Play release 1.0.1 (versionCode 2)"
```

6. Build the signed AAB **from the tag**, not from a dirty working tree:

```bash
git checkout 1.0.1
./scripts/build_android.sh arm64-v8a release
```

7. Upload `build_android_arm64-v8a/android-build/build/outputs/bundle/release/android-build-release.aab` to Play. Paste the matching What’s new from `store-listing.md`.
8. Keep the tag (and a source archive of that tag) for as long as the binary is distributed — required for the ALGLIB/GPL source offer. See `licenses/THIRD_PARTY_NOTICES.md`.

Do not upload an AAB that does not correspond to a tag. If the Console rejects an artifact, fix it, bump PATCH + `versionCode`, tag again, and upload the new AAB.

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
| Local AVDs | `Pixel7a_x86_64` (3-button nav, Play phone shots); `Pixel7a_gesture_x86_64` (gesture nav / SafeArea, created by `run_emulator.sh --gesture`); tablet screenshots: `PlayTablet7_x86_64`, `PlayTablet10_x86_64` (created by `run_emulator.sh --tablet`) |

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
build_android_arm64-v8a/android-build/build/outputs/native-debug-symbols/release/native-debug-symbols.zip
```

The script also lists `BUNDLE-METADATA/com.android.tools.build.debugsymbols/` inside the release AAB. Play extracts those automatically; do not upload the ZIP unless that metadata is missing.

Build directory names follow the NDK ABI: `build_android_arm64-v8a`, `build_android_x86_64`, `build_android_armeabi-v7a`.

### x86_64 emulator (local development)

```bash
./scripts/build_android.sh x86_64 debug
./scripts/run_emulator.sh Pixel7a_x86_64          # 3-button nav (Play screenshots)
./scripts/run_emulator.sh --gesture               # Pixel7a_gesture_x86_64, gesture nav
```

An ARM64 AVD cannot run on an x86_64 host. Use `Pixel7a_x86_64` or `--gesture` for local testing. `--gesture` is the emulator stand-in for a physical Pixel with gesture navigation (the system bars overlay the app, which is what the SafeArea padding in `ui/Main.qml` is for).

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

Release packaging also runs `scripts/check_16kb_alignment.sh` on the APK and AAB (ELF LOAD alignment, `zipalign -P 16`, AAB `PAGE_ALIGNMENT_16K`).

### `scripts/check_16kb_alignment.sh`

```bash
./scripts/check_16kb_alignment.sh path/to/app.apk [path/to/app.aab]
VERBOSE=1 ./scripts/check_16kb_alignment.sh path/to/app.apk   # list every .so
```

Fails if any 64-bit `.so` has ELF `LOAD` alignment below `2**14`, if APK zip alignment is not 16 KB, or if the AAB BundleConfig is not `PAGE_ALIGNMENT_16K` with uncompressed native libraries enabled. `armeabi-v7a` is reported but does not fail (32-bit is exempt).

### `scripts/run_emulator.sh`

```bash
./scripts/run_emulator.sh [avd_name]
./scripts/run_emulator.sh --tablet 7
./scripts/run_emulator.sh --tablet 10
./scripts/run_emulator.sh --gesture
./scripts/run_emulator.sh --screenshot home
./scripts/run_emulator.sh --logcat
```

| Behavior | Detail |
|---|---|
| AVD | Argument, or the first name from `emulator -list-avds` |
| Tablets | `--tablet 7` / `--tablet 10` create and boot Play listing AVDs (`PlayTablet7_x86_64`, `PlayTablet10_x86_64`) if they do not exist, then force portrait `1200×1920` or `1600×2560` |
| Gesture nav | `--gesture` creates and boots `Pixel7a_gesture_x86_64` (Pixel 7a, `1080×2400`) and switches SystemUI to gesture navigation (`navigation_mode=2`). `Pixel7a_x86_64` stays on 3-button nav for Play phone screenshots. |
| Screenshots | `--screenshot [name]` writes a PNG under `packaging/google-play/screenshots/{phone,tablet7,tablet10}/` |
| Pre-flight | Requires executable `emulator` and `adb` under `$ANDROID_SDK` |
| Boot timeout | `BOOT_TIMEOUT_SEC` (default 120; tablet boots use 240 if the default is still in effect) |
| Emulator log | `$BUILD_DIR/emulator.log` (dumped if the emulator process dies) |
| Logcat | Started before `am start`; crash-filtered dump if the process is gone |
| APK search | `build_android_x86_64` first, then `build_android_arm64-v8a` (debug, then release, then unsigned) |
| Launch | `adb shell am start -n by.intoncore.intontrainer2.zh/org.qtproject.qt.android.bindings.QtActivity` |

`--logcat` streams live logcat and always writes `build_android_arm64-v8a/logcat.log`, even if you installed an x86_64 APK. After a normal launch, inspect `$BUILD_DIR/logcat.log` (the dir of the APK that was found).

Play Console tablet slots are **7-inch** and **10-inch** (there is no 19-inch slot). Use those flags for listing screenshots. The app is portrait-locked, so tablet captures stay portrait.

Tablet screenshot workflow:

```bash
./scripts/build_android.sh x86_64 debug
./scripts/run_emulator.sh --tablet 7
# pose Home / Training / library / Records, then:
./scripts/run_emulator.sh --screenshot home
./scripts/run_emulator.sh --screenshot training
./scripts/run_emulator.sh --tablet 10
./scripts/run_emulator.sh --screenshot home
```

`--tablet` stops a different running emulator first, so the phone AVD is not reused by accident. Combine launch and capture with `--tablet 7 --screenshot home` (press Enter when the screen is ready).

The APK ABI must match the emulator ABI:

| AVD | Build |
|---|---|
| `Pixel7a_x86_64` | `./scripts/build_android.sh x86_64 debug` |
| `Pixel7a_gesture_x86_64` | `./scripts/build_android.sh x86_64 debug` (same APK; `--gesture` after boot) |
| `PlayTablet7_x86_64` / `PlayTablet10_x86_64` | `./scripts/build_android.sh x86_64 debug` |
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
  -DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON \
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

## Native debug symbols

Google Play can symbolicate native crashes only if the upload includes debug
metadata for the packaged `.so` files. The release AAB is configured to
embed **full** native symbols so Play Console extracts them automatically
(AGP 4.1+ / the Qt 6.11 template uses AGP 9.0.0).

What the repo does:

1. `android/build.gradle` (copied from the Qt 6.11.1 template, then customized)
   sets `android.buildTypes.release.ndk.debugSymbolLevel = 'FULL'`.
2. `CMakeLists.txt` adds `-g` to Android **Release** objects so DWARF exists
   for `libappinton-trainer-2_<abi>.so` (and SPTK objects compiled in this
   tree). RelWithDebInfo already has `-g`. Gradle still **strips** the `.so`
   files that ship inside the APK/AAB; the extra data goes into AAB metadata.
3. `scripts/build_android.sh` prints the `com.android.tools.build.debugsymbols`
   entries after a release AAB, and the path of
   `native-debug-symbols.zip` when Gradle writes one.

Confirm after a release build:

```bash
unzip -l build_android_arm64-v8a/android-build/build/outputs/bundle/release/android-build-release.aab \
  | grep com.android.tools.build.debugsymbols
```

Expect paths such as
`BUNDLE-METADATA/com.android.tools.build.debugsymbols/arm64-v8a/*.so.dbg`.
After the first Play upload, also open **Release → App bundle explorer** and
check that native debug symbols are present for the artifact.

Official Qt Android libraries are already stripped (`.dynsym` only). Play
stack traces will name frames in **our** library and any other unstripped
`.so` (for example NDK `libomp` still has a symbol table). That is enough
for app crashes; Qt-internal frames stay numeric.

If the AAB metadata is missing (Gradle log:
`Unable to extract native debug metadata ... already been stripped`), build
a ZIP by hand and upload it under App bundle explorer:

```bash
ABI=arm64-v8a
BUILD_DIR=build_android_${ABI}
mkdir -p "/tmp/native-debug-symbols/${ABI}"
cp "$BUILD_DIR"/libappinton-trainer-2_${ABI}.so "/tmp/native-debug-symbols/${ABI}/"
(cd /tmp/native-debug-symbols && zip -r native-debug-symbols.zip "${ABI}")
```

Keep that ZIP under 1.6 GB. If FULL DWARF is too large, change
`debugSymbolLevel` to `'SYMBOL_TABLE'` (function names only).

See [Include native symbols in your release build](https://developer.android.com/build/include-native-symbols)
and [Native debug symbols](https://support.google.com/googleplay/android-developer/answer/9848633).

---

## 16 KB page-size compatibility

Google Play requires 64-bit native apps that target Android 15+ (API 35+) to
support **16 KB memory pages**. Enforcement for new apps and updates started
**1 November 2025**; from **1 February 2027** updates that are not 16 KB
compatible cannot be released. See
[Support 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes).

This project is configured for the recommended AGP 8.5.1+ path: uncompressed
native libraries, 16 KB zip-aligned in the APK, and `PAGE_ALIGNMENT_16K` in
the AAB so Play-generated APKs mmap `.so` files on 16 KB devices.

What the repo does:

1. **ELF 16 KB alignment (NDK r27).** NDK r28+ aligns by default; r27 does
   not. `CMakeLists.txt` adds `-Wl,-z,max-page-size=16384` and
   `-Wl,-z,common-page-size=16384` to `appinton-trainer-2`.
   `scripts/build_android.sh` also passes `-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON`.
   SPTK and alglib are statically linked into `libappinton-trainer-2_<abi>.so`,
   so they inherit that alignment. There is no `PAGE_SIZE` / `4096` hard-coding
   in app code.
2. **Uncompressed JNI libs (AGP 9.0.0).** `android/build.gradle` parses
   `legacyPackaging` with `Boolean.parseBoolean` so the gradle.properties
   string `"false"` is not treated as Groovy-true. That was causing
   compressed `.so` files and `extractNativeLibs=true`. The app target also
   sets `QT_ANDROID_LEGACY_PACKAGING FALSE`. The release APK stores native
   libs uncompressed (`STORE`) with `extractNativeLibs=false`.
3. **Qt 6.11.1 prebuilts.** Official `android_arm64_v8a` libraries, including
   FFmpeg (`libavcodec`, `libavformat`, `libavutil`, `libswresample`,
   `libswscale`), the Android and FFmpeg multimedia plugins, and NDK
   `libc++_shared.so` / 64-bit `libomp.so`, already report `LOAD align 2**14`.
   (Qt 6.9 FFmpeg builds were often 4 KB; 6.11.1 is not.)
4. **Verification.** After packaging, `build_android.sh` runs
   `scripts/check_16kb_alignment.sh` on the APK and AAB.

Confirm locally (also done automatically by the build script):

```bash
APK=build_android_arm64-v8a/android-build/build/outputs/apk/release/android-build-release-unsigned.apk
AAB=build_android_arm64-v8a/android-build/build/outputs/bundle/release/android-build-release.aab
./scripts/check_16kb_alignment.sh "$APK" "$AAB"
```

Expect: every `arm64-v8a` / `x86_64` `.so` `ALIGNED (2**14)`,
`zipalign: Verification successful` with uncompressed `lib/**/*.so (OK)`
entries (not `OK - compressed`), and AAB
`uncompress_native_libraries.enabled=1` /
`alignment=PAGE_ALIGNMENT_16K`.

Verified on **13 September 2026** for the arm64-v8a release APK/AAB: 90
packaged `.so` files, all `2**14`, zip 16 KB aligned, AAB
`PAGE_ALIGNMENT_16K`. The sideload APK is larger (~96 MB) because native
libs are uncompressed; the AAB stays compressed internally (~51 MB) and Play
generates the device APKs.

`armeabi-v7a` is exempt from the 16 KB ELF rule (32-bit). Play uploads from
this project are **arm64-v8a only**.

Runtime check on a 16 KB kernel (emulator 16 KB system image, or Pixel 8/9
developer option **Boot with 16KB page size**):

```bash
adb shell getconf PAGE_SIZE    # must print 16384
```

Then exercise microphone recording, VAD, guided mode, and WAV playback. A
16 KB AVD is not required to *build*; it is recommended before the first
Play production push. 32-bit `libomp` in the NDK is still 4 KB aligned and
must not be packaged into a 64-bit Play artifact.

---

## Runtime assets

On Android, `CMakeLists.txt` copies `settings.ini` and `data/` into `android/assets/` so `androiddeployqt` packs them into the APK (extracted under `AppDataLocation` on device).

`android/assets/` is gitignored — it is generated at build time. Rebuild after changing templates or `settings.ini`. Recordings are written to app-private storage (`AppDataLocation/data/records`); `MediaStore` is not required.

---

## Package source (`android/`)

### `android/AndroidManifest.xml`

- Package: `by.intoncore.intontrainer2.zh` (permanent once uploaded to Play)
- Permission: **`RECORD_AUDIO` only**
- Qt Core’s `INTERNET` / `WRITE_EXTERNAL_STORAGE` are stripped (`tools:node="remove"` and no `%%INSERT_PERMISSIONS%%` placeholder)
- Required feature: `android.hardware.microphone`
- Portrait only (`android:screenOrientation="portrait"`)
- Min SDK 26, target / compile SDK 36
- Version placeholders `%%INSERT_VERSION_CODE%%` / `%%INSERT_VERSION_NAME%%` (filled from CMake: `QT_ANDROID_VERSION_CODE` and `PROJECT_VERSION`). Those must match the git tag for the Play upload. Current tag `1.0.0` is code `1`, name `1.0.0`.
- `<meta-data android:name="android.app.lib_name" android:value="appinton-trainer-2"/>` is set **manually**
- Launcher icon: `@mipmap/ic_launcher`
- Round launcher icon: `@mipmap/ic_launcher_round`

### `android/res/values/styles.xml`

`AppTheme` uses a black `windowBackground` to avoid a light flash on launch.

### `android/build.gradle`

Qt template from 6.11.1 (`android_arm64_v8a/src/android/templates/build.gradle`)
plus `buildTypes.release.ndk.debugSymbolLevel = 'FULL'` so the release AAB
includes native debug symbols for Play, and
`jniLibs.useLegacyPackaging = Boolean.parseBoolean("${legacyPackaging}")` so
native libs stay uncompressed and 16 KB zip-aligned. Re-copy the template if
a future Qt upgrade changes AGP / Kotlin plugin versions, then re-apply the
`ndk` block and the `Boolean.parseBoolean` packaging line.

### CMake target properties (`CMakeLists.txt`)

`QT_ANDROID_PACKAGE_SOURCE_DIR`, target/compile SDK **36**, min SDK 26, package `by.intoncore.intontrainer2.zh`, `QT_ANDROID_VERSION_NAME` from `PROJECT_VERSION` (git tag), `QT_ANDROID_VERSION_CODE` incremented per Play upload, `QT_ANDROID_LEGACY_PACKAGING FALSE`. Native link flags `-Wl,-z,max-page-size=16384` / `-Wl,-z,common-page-size=16384` and CMake `-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON` for Play’s 16 KB page-size requirement. Android Release compiles with `-g` so AGP can extract FULL native symbols.

OpenMP: desktop uses `find_package(OpenMP)`; Android locates NDK `libomp` and links the `AndroidOMP` imported target. alglib `kernels_avx2.cpp` / `kernels_fma.cpp` / `kernels_sse2.cpp` are omitted on Android.

---

## App icons

The Chinese launcher and adaptive icons are generated from
`packaging/google-play/icon-512-zh.png` (中文 mark). The manifest already
references `@mipmap/ic_launcher` and `@mipmap/ic_launcher_round`.

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

The opaque **512×512** Play Console icon for this Chinese edition is
`packaging/google-play/icon-512-zh.png`. The same file is the source for the
Android launcher / adaptive icons under `android/res/`.

The upload-ready **1024×500** feature graphic is
`packaging/google-play/feature-graphic-zh.png` (24-bit sRGB PNG, no alpha).
Its editable vector source is `feature-graphic-zh.svg` in the same folder.
The graphic uses the Chinese-edition mark, the app palette, and a simplified
pitch-comparison result. If the SVG changes, regenerate the Play asset from
the project root:

```bash
convert packaging/google-play/feature-graphic-zh.svg \
  -background '#f9f9ff' -alpha remove -alpha off \
  \( packaging/google-play/icon-512-zh.png -resize 76x76 \) \
  -geometry +62+49 -composite -alpha off \
  PNG24:packaging/google-play/feature-graphic-zh.png
```

Store listing copy (EN/RU app name, short description, full description,
contact fields, category, and What’s new) is in
`packaging/google-play/store-listing.md`. Phone, 7-inch, and 10-inch
screenshots used on the listing are in `packaging/google-play/screenshots/`
(see that folder’s README). All listing artwork is separate from the APK/AAB.

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

## Open-source licences

The side menu exposes **Open-source licences**. `LicensesPage.qml` reads
the complete licence texts from Qt resources, so the notices remain available
offline inside every APK/AAB.

The bundled notice set covers:

- the application's MIT-licensed source;
- Qt 6.11.1 under LGPLv3, including GPLv3 and LGPLv3 texts, matching Qt source,
  and instructions for rebuilding/signing an APK with modified Qt shared
  libraries;
- ALGLIB 4.06.0 under GPL-2.0-or-later, including the source offer and rebuild
  instructions;
- SPTK 4.3 under Apache-2.0 and its WORLD, REAPER, SWIPE, Snack, and ya_getopt
  notices;
- Font Awesome Free 7.2.0 fonts under SIL OFL 1.1;
- the Android NDK LLVM OpenMP runtime under Apache-2.0 with LLVM Exceptions.

The application's own files remain MIT-licensed, but ALGLIB is compiled into
the native application library. Consequently, a distributed combined
executable is subject to the GNU GPL; do not describe the Play binary as
MIT-only. `licenses/THIRD_PARTY_NOTICES.md` is the authoritative component
index and source/relinking offer.

Before publishing each release, create the annotated git tag for that Play
upload (see [Release versioning](#release-versioning-git-tags)) and keep a
source archive of that tag available from the repository. It must retain the
application source, CMake/build scripts, and the matching ALGLIB and SPTK
sources (or durable, unambiguous access to those exact upstream sources).

---

## Privacy policy

Public HTTPS policy (required for Play Console, Data safety, and the
User Data policy):

[https://intontrainer.by/intontrainer2policy.html](https://intontrainer.by/intontrainer2policy.html)

Last updated **10 September 2026**. It matches the Android packaging:

- microphone used only for on-device intonation training;
- WAV recordings, scores, and settings stored in app-private storage;
- no upload, analytics, ads, accounts, or cloud backup;
- `RECORD_AUDIO` only; Qt `INTERNET` stripped;
- `android:allowBackup="false"`;
- user can delete individual records, all records, or user data in Settings.

Paste that URL into the Play Console privacy-policy field.

The same notice is bundled offline in `docs/privacy_policy_en.md` and
`docs/privacy_policy_ru.md`. `PrivacyPolicyPage.qml` loads it like the
user guide (language follows Settings). The side menu exposes
**Privacy Policy** between User Guide and Open-source licences. The
APK has no `INTERNET` permission, so the page does not fetch the URL
at runtime.

---

## Google Play store listing

Paste-ready copy lives in `packaging/google-play/store-listing.md`. Folder
index: `packaging/google-play/README.md`.

Default locale is **English (United States)**; add **Russian** as a
translation. Do not put rankings, prices, “free”, or keyword stuffing in
any field.

This is the **Chinese** edition (`by.intoncore.intontrainer2.zh`). Later
language apps should keep the same bracket pattern
(`Intonation Trainer 2 (English)`, `(Russian)`, `(German)`) and ship as
separate Play listings with packages `.en`, `.ru`, `.de`.

| Field | English | Russian | Limit |
|---|---|---|---|
| Package name | `by.intoncore.intontrainer2.zh` | same | — |
| App name | Intonation Trainer 2 (Chinese) | Тренер интонации 2 (китайский) | 30 |
| Short description | Practice Chinese tones with on-device pitch comparison and visual feedback | Тренируйте китайские тоны, сравнивая мелодику с эталоном на устройстве | 80 |
| Full description | in `store-listing.md` | in `store-listing.md` | 4,000 |
| What’s new (per git tag) | in `store-listing.md` | in `store-listing.md` | 500 |
| Email | zhitko.vladimir@gmail.com | same | — |
| Website | https://intontrainer.by/ | same | — |
| Privacy policy | https://intontrainer.by/intontrainer2policy.html | same | — |
| Category | Education | — | — |
| Tags | Language learning | — | — |

Console path: **Grow users → Store presence → Main store listing** for name
and descriptions; **Store settings** for category, email, and website.

Listing screenshots (uploaded): 6 phone (`screenshots/phone/`, `1080×2400`),
6 seven-inch tablet (`screenshots/tablet7/`, `1200×1920`), and 6 ten-inch
tablet (`screenshots/tablet10/`, `1600×2560`). Screen index:
`packaging/google-play/screenshots/README.md`.

Do not upload the desktop captures in `docs/screenshots/`.

---

## Google Play readiness

Requirements checked against the official Google Play and Android
documentation on **13 September 2026**.

### Done in the repo

| Item | Status |
|---|---|
| ARM64 / x86_64 compile | Verified |
| OpenMP via NDK `libomp.so` | Linked |
| alglib x86 kernels excluded on Android | Done |
| `android.app.lib_name` meta-data | Done |
| Target / compile SDK 36 | Complies with the API 36 requirement for new apps and updates since 31 August 2026 |
| Version 1.0.0 / `versionCode` 1 | First internal-testing upload; git tag `1.0.0` |
| Storage / media permissions removed | `RECORD_AUDIO` only; Qt `INTERNET` stripped |
| 16 KB page-size compatibility | ELF `LOAD` `2**14` on all packaged 64-bit `.so` (app, Qt 6.11.1, FFmpeg, `libc++_shared`); uncompressed JNI libs (`extractNativeLibs=false`); APK `zipalign -c -P 16`; AAB `PAGE_ALIGNMENT_16K` `enabled=1`. `build_android.sh` runs `scripts/check_16kb_alignment.sh`. Verified 13 September 2026 on arm64-v8a release artifacts. |
| Android App Bundle | `build_android.sh` produces the AAB required for new Play apps |
| Signing env vars | `QT_ANDROID_KEYSTORE_*` (and `ANDROID_KEYSTORE_*` aliases) wired |
| File picker | Hidden on Android |
| Recordings in app-private storage | No `MediaStore` needed |
| `armeabi-v7a` ABI name | Script maps `armv7` → `armeabi-v7a` |
| Font Awesome 7 on Android | Fixed (weight + `qrc:` paths) |
| Keystore files gitignored | `*.jks`, `*.keystore` |
| Launcher icons | Legacy, round, and adaptive resources added; manifest wired |
| Play Console icon | 512×512 RGBA PNG, 220 KB: `packaging/google-play/icon-512-zh.png` (Chinese copy of `icon-512.png`) |
| Feature graphic | Upload-ready 1024×500 24-bit sRGB PNG with no alpha: `packaging/google-play/feature-graphic-zh.png`; editable SVG source is alongside it |
| Store listing screenshots | 6 phone + 6 seven-inch + 6 ten-inch Android captures in `packaging/google-play/screenshots/` (uploaded to the Play listing) |
| Store listing text | EN/RU app name, short description, full description, What’s new, contact, category, and alt text in `packaging/google-play/store-listing.md` |
| Play Console account | Verified |
| Open-source licences | Offline in-app notices and full texts added for Qt/LGPL, ALGLIB/GPL, SPTK and embedded components, Font Awesome/OFL, and LLVM OpenMP; source/relinking offer documented |
| Privacy policy (HTTPS) | Published at [https://intontrainer.by/intontrainer2policy.html](https://intontrainer.by/intontrainer2policy.html) (revised 10 September 2026). Covers microphone access, on-device WAV recordings and scores, local retention/deletion, no upload/sharing, no Internet permission, and `allowBackup=false`. Paste this URL into the Play Console privacy-policy field. |
| Privacy policy in the app | Offline EN/RU markdown via `PrivacyPolicyPage.qml`; side-menu item next to User Guide / Open-source licences |
| Native debug symbols | Release AAB embeds FULL native symbols (`android/build.gradle` `ndk.debugSymbolLevel = 'FULL'`, Android Release `-g`). `build_android.sh` checks `BUNDLE-METADATA/com.android.tools.build.debugsymbols`. Play extracts them from the AAB; confirm in App Bundle Explorer after the first upload |

### Remaining Play Console work

Internal testing is live on git tag `1.0.0`. The items below are still needed
before closed testing or production, and on every later tagged upload.

| Item | What to do |
|---|---|
| **Upload key and Play App Signing** | Generate and back up the upload keystore, build a signed release AAB, and upload it. New apps are automatically enrolled in Play App Signing; keep the upload key separate and enable 2-Step Verification for Console users. |
| **Release identity** | Package `by.intoncore.intontrainer2.zh` is set. Further uploads of this Chinese app use a new git tag (`MAJOR.MINOR.PATCH`) and a higher `versionCode`. English/Russian/… editions need new packages (`.en`, `.ru`, …) and new Play listings; a package name cannot be changed after publishing. |
| **Data safety** | Complete the form even if no data leaves the device. Declare the actual handling of microphone/voice recordings and keep it consistent with the app and [privacy policy](https://intontrainer.by/intontrainer2policy.html). Internal-only testing is exempt; closed, open, and production tracks are not. |
| **App content declarations** | Complete Ads, App access, Target audience and content, and the IARC content-rating questionnaire. Declare no ads and unrestricted access only if that matches the release. Do not include children unless the app is intended to meet Families requirements. |
| **Feature graphic** | Upload `packaging/google-play/feature-graphic-zh.png`. It is already 1024×500, 24-bit sRGB, and has no alpha. It is mandatory listing artwork and is not bundled in the app. |
| **16 KB runtime QA** | Static ELF/zip/AAB checks already pass. Before production, boot a 16 KB emulator image or a Pixel 8/9 with **Boot with 16KB page size**, confirm `adb shell getconf PAGE_SIZE` is `16384`, and run recording/playback. |
| **Physical ARM64 QA** | Confirm microphone permission, recording/VAD, guided mode, packaged templates, record saving/deletion, offline behavior, and startup on a physical ARM64 device. |
| **Closed testing, if applicable** | Personal accounts created after 13 November 2023 need at least 12 testers continuously opted in for 14 days, followed by a production-access application. Testers must remain engaged; opting out breaks continuity. |
| **Developer verification** | Check Play Console account identity and package registration. Enforcement begins 30 September 2026 for participating stores in Brazil, Indonesia, Singapore, and Thailand, then expands globally in 2027; most existing verified Play developers need no extra identity action. |
| **Release source archive** | Build each Play AAB from its annotated git tag. Retain that tag/archive for as long as the binary is distributed. Include the build scripts and matching ALGLIB/SPTK sources or durable access to those exact sources; verify every packaged native library against the in-app notices. |
| **Portrait-only decision** | Keep `screenOrientation="portrait"` only if this is intentional and phone QA confirms all content remains usable. |

### Official references

- [Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [16 KB page-size compatibility](https://developer.android.com/guide/practices/page-sizes)
- [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [Store listing assets](https://support.google.com/googleplay/android-developer/answer/9866151)
- [Prepare an app for review](https://support.google.com/googleplay/android-developer/answer/9859455)
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)
- [IntonTrainer 2 privacy policy](https://intontrainer.by/intontrainer2policy.html)
- [New personal-account testing](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Android developer verification](https://developer.android.com/developer-verification/guides)
- [Native debug symbols](https://support.google.com/googleplay/android-developer/answer/9848633)
