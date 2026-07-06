#!/usr/bin/env bash
# =============================================================================
# build_android.sh — Build Intonation Trainer 2 as an Android App Bundle (.aab)
#
# Usage:
#   chmod +x scripts/build_android.sh
#   ./scripts/build_android.sh [arm64-v8a|armv7|x86_64|all]  [debug|release]
#
# Defaults: ABI=arm64-v8a, BUILD_TYPE=release
#
# Optional signing env vars:
#   ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_ALIAS, ANDROID_KEYSTORE_PASSWORD
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — override any of these via environment variables
# ---------------------------------------------------------------------------
QT_ROOT="${QT_ROOT:-$HOME/Qt/6.11.1}"
ANDROID_SDK="${ANDROID_SDK:-$HOME/Android/Sdk}"
ANDROID_NDK="${ANDROID_NDK:-$ANDROID_SDK/ndk/27.2.12479018}"
# Android Gradle Plugin requires Java 17+
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_ABI="${1:-arm64-v8a}"   # arm64-v8a | armv7 | x86_64 | all
BUILD_TYPE="${2:-release}"      # debug | release

# ---------------------------------------------------------------------------
# Helper: build a single ABI
# ---------------------------------------------------------------------------
build_abi() {
    local ABI="$1"
    local QT_ANDROID_DIR

    case "$ABI" in
        arm64-v8a)  QT_ANDROID_DIR="$QT_ROOT/android_arm64_v8a" ;;
        armv7)      QT_ANDROID_DIR="$QT_ROOT/android_armv7"     ;;
        x86_64)     QT_ANDROID_DIR="$QT_ROOT/android_x86_64"    ;;
        *)
            echo "ERROR: unknown ABI '$ABI'. Valid: arm64-v8a armv7 x86_64"
            exit 1
            ;;
    esac

    if [[ ! -d "$QT_ANDROID_DIR" ]]; then
        echo "ERROR: Qt for Android not found at '$QT_ANDROID_DIR'"
        echo "       Install the '${ABI}' component via Qt Maintenance Tool."
        exit 1
    fi

    local BUILD_DIR="$PROJECT_ROOT/build_android_${ABI}"
    echo ""
    echo "============================================================"
    echo "  Building ABI: $ABI"
    echo "  Qt:  $QT_ANDROID_DIR"
    echo "  NDK: $ANDROID_NDK"
    echo "  Build dir: $BUILD_DIR"
    echo "============================================================"

    cmake \
        -S "$PROJECT_ROOT" \
        -B "$BUILD_DIR" \
        -G "Ninja" \
        -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM="android-26" \
        -DANDROID_NDK="$ANDROID_NDK" \
        -DCMAKE_ANDROID_NDK="$ANDROID_NDK" \
        -DCMAKE_FIND_ROOT_PATH="$QT_ANDROID_DIR" \
        -DCMAKE_PREFIX_PATH="$QT_ANDROID_DIR" \
        -DQT_HOST_PATH="$QT_ROOT/gcc_64" \
        -DQT_HOST_PATH_CMAKE_DIR="$QT_ROOT/gcc_64/lib/cmake" \
        -DCMAKE_BUILD_TYPE="$(tr '[:lower:]' '[:upper:]' <<< ${BUILD_TYPE:0:1})${BUILD_TYPE:1}" \
        -DANDROID_SDK_ROOT="$ANDROID_SDK"

    cmake --build "$BUILD_DIR" --target appinton-trainer-2 -- -j"$(nproc)"

    echo ""
    echo "  ABI $ABI build complete. Artifacts in: $BUILD_DIR"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
export JAVA_HOME
export ANDROID_HOME="$ANDROID_SDK"
# Gradle picks up the JDK via GRADLE_OPTS (Android Gradle Plugin requires Java 17)
export GRADLE_OPTS="-Dorg.gradle.java.home=${JAVA_HOME}"

echo "Android SDK:   $ANDROID_SDK"
echo "Android NDK:   $ANDROID_NDK"
echo "Java home:     $JAVA_HOME"
echo "Build type:    $BUILD_TYPE"
echo "Target ABI(s): $TARGET_ABI"
echo ""

# Verify essential tools
for tool in cmake ninja java; do
    command -v "$tool" >/dev/null || { echo "ERROR: '$tool' not found in PATH"; exit 1; }
done

if [[ "$TARGET_ABI" == "all" ]]; then
    for abi in arm64-v8a armv7 x86_64; do
        build_abi "$abi"
    done
else
    build_abi "$TARGET_ABI"
fi

# ---------------------------------------------------------------------------
# Package into an AAB (App Bundle) via Qt's built-in `aab` CMake target
# ---------------------------------------------------------------------------
# Qt6's CMake integration exposes an `aab` target that:
#   1. Stages the compiled .so into android-build/libs/<ABI>/
#   2. Calls androiddeployqt to copy Qt libs and generate the Gradle project
#   3. Runs Gradle bundleRelease/bundleDebug to produce the .aab
#
# Prerequisite: platforms;android-35 must be installed in the SDK:
#   JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
#     $HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager "platforms;android-35" <<< "y"
# ---------------------------------------------------------------------------
echo ""
echo "============================================================"
echo "  Packaging Android App Bundle (.aab)"
echo "============================================================"

# For multi-ABI bundles, use the arm64 build dir as the entry point
MAIN_ABI="${TARGET_ABI:-arm64-v8a}"
[[ "$TARGET_ABI" == "all" ]] && MAIN_ABI="arm64-v8a"
BUILD_DIR="$PROJECT_ROOT/build_android_${MAIN_ABI}"

cmake --build "$BUILD_DIR" --target apk -- -j"$(nproc)"

# Qt puts the final AAB under: android-build/build/outputs/bundle/release/
RELEASE_AAB="$BUILD_DIR/android-build/build/outputs/bundle/release/android-build-release.aab"
DEBUG_AAB="$BUILD_DIR/android-build/build/outputs/bundle/debug/android-build-debug.aab"

echo ""
if [[ -f "$RELEASE_AAB" ]]; then
    echo "Android App Bundle (release) created:"
    echo "  $RELEASE_AAB"
elif [[ -f "$DEBUG_AAB" ]]; then
    echo "Android App Bundle (debug) created:"
    echo "  $DEBUG_AAB"
else
    echo "WARNING: .aab not found; check $BUILD_DIR/android-build for Gradle output."
    echo "  Run with --stacktrace for Gradle details:"
    echo "  cd $BUILD_DIR/android-build && ./gradlew bundleRelease --stacktrace"
fi
