#!/usr/bin/env bash
# =============================================================================
# run_emulator.sh — Start Android emulator, install the built APK, and run it.
#
# Usage:
#   chmod +x scripts/run_emulator.sh
#   ./scripts/run_emulator.sh [avd_name]
#   ./scripts/run_emulator.sh --logcat    # capture logs only (emulator already running)
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
ANDROID_SDK="${ANDROID_SDK:-$HOME/Android/Sdk}"
EMULATOR_CMD="$ANDROID_SDK/emulator/emulator"
ADB_CMD="$ANDROID_SDK/platform-tools/adb"

BOOT_TIMEOUT_SEC="${BOOT_TIMEOUT_SEC:-120}"

# Pre-flight checks
for cmd in "$EMULATOR_CMD" "$ADB_CMD"; do
    if [[ ! -x "$cmd" ]]; then
        echo "ERROR: '$cmd' not found or not executable."
        echo "Set ANDROID_SDK or install Android SDK tools."
        exit 1
    fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --logcat mode: just capture logs from a running emulator
if [[ "${1:-}" == "--logcat" ]]; then
    LOGCAT_LOG="$PROJECT_ROOT/build_android_arm64-v8a/logcat.log"
    echo "Clearing and capturing logcat to: $LOGCAT_LOG"
    "$ADB_CMD" logcat -c 2>/dev/null || true
    "$ADB_CMD" logcat -v time | tee "$LOGCAT_LOG"
    exit 0
fi

# Find the APK
APK_PATH=""
# Look for common APK targets built by the script/CMake
# Prefer x86_64 (host arch), then arm64-v8a
# Prefer signed debug APK, then signed release APK, then unsigned
for build_dir in \
    "$PROJECT_ROOT/build_android_x86_64" \
    "$PROJECT_ROOT/build_android_arm64-v8a"; do
    for path in \
        "$build_dir/android-build/build/outputs/apk/debug/android-build-debug.apk" \
        "$build_dir/android-build/build/outputs/apk/release/android-build-release.apk" \
        "$build_dir/android-build/appinton-trainer-2.apk" \
        "$build_dir/android-build/build/outputs/apk/release/android-build-release-unsigned.apk"; do
        if [[ -f "$path" ]]; then
            APK_PATH="$path"
            break 2
        fi
    done
done

if [[ -z "$APK_PATH" ]]; then
    echo "ERROR: No built APK found."
    echo "Please build the project first: ./scripts/build_android.sh"
    exit 1
fi

echo "Found APK: $APK_PATH"
# Derive build dir from APK path: .../build_android_<abi>/android-build/.../file.apk
BUILD_DIR="$PROJECT_ROOT/$(echo "$APK_PATH" | sed -n 's|.*/\(build_android_[^/]*\)/.*|\1|p')"

# ---------------------------------------------------------------------------
# 1. Start Emulator
# ---------------------------------------------------------------------------
# Check if any emulator/device is already online
RUNNING_DEVICES=$("$ADB_CMD" devices | awk 'NR>1 {print $1}' | grep -v '^$' || true)

if [[ -z "$RUNNING_DEVICES" ]]; then
    echo "No running emulator detected. Starting one..."

    # Get AVD list (use readarray to handle names with spaces)
    readarray -t AVDS < <("$EMULATOR_CMD" -list-avds)
    if [[ ${#AVDS[@]} -eq 0 ]]; then
        echo "ERROR: No Android Virtual Devices (AVDs) found."
        echo "Please create one using Android Studio."
        exit 1
    fi

    # Select AVD
    SELECTED_AVD="${1:-}"
    if [[ -z "$SELECTED_AVD" ]]; then
        # Default to the first one in the list
        SELECTED_AVD="${AVDS[0]}"
    fi

    echo "Starting emulator with AVD: $SELECTED_AVD..."
    # Launch emulator in background, log output for debugging
    EMULATOR_LOG="$BUILD_DIR/emulator.log"
    "$EMULATOR_CMD" -avd "$SELECTED_AVD" -no-snapshot-load > "$EMULATOR_LOG" 2>&1 &
    EMULATOR_PID=$!

    # Give the emulator a few seconds to initialize before polling ADB
    echo "Waiting for emulator to initialize..."
    sleep 5

    echo "Waiting for emulator to boot (timeout: ${BOOT_TIMEOUT_SEC}s)..."
    ELAPSED=5
    while true; do
        # Check if emulator process is still alive
        if ! kill -0 "$EMULATOR_PID" 2>/dev/null; then
            echo ""
            echo "ERROR: Emulator process died unexpectedly."
            echo "Last 20 lines of emulator log ($EMULATOR_LOG):"
            tail -20 "$EMULATOR_LOG" 2>/dev/null || true
            exit 1
        fi
        # Use timeout to prevent adb from hanging indefinitely
        BOOT_STATUS=$(timeout 5 "$ADB_CMD" shell getprop sys.boot_completed 2>/dev/null || echo "0")
        BOOT_STATUS="${BOOT_STATUS//[$'\r\n']/}"
        if [[ "$BOOT_STATUS" == "1" ]]; then
            break
        fi
        if [[ $ELAPSED -ge $BOOT_TIMEOUT_SEC ]]; then
            echo ""
            echo "ERROR: Emulator did not boot within ${BOOT_TIMEOUT_SEC} seconds."
            echo "Check emulator log: $EMULATOR_LOG"
            kill "$EMULATOR_PID" 2>/dev/null || true
            exit 1
        fi
        sleep 2
        ELAPSED=$((ELAPSED + 2))
        echo -n "."
    done
    echo ""
    echo "Emulator is online!"
else
    echo "Using already running emulator/device..."
fi

# ---------------------------------------------------------------------------
# 2. Install and Run the APK
# ---------------------------------------------------------------------------
echo "Installing APK..."
"$ADB_CMD" install -r "$APK_PATH"

echo "Launching application..."
LOGCAT_LOG="$BUILD_DIR/logcat.log"
# Clear old logcat and start capturing in background
"$ADB_CMD" logcat -c 2>/dev/null || true
"$ADB_CMD" logcat -v time > "$LOGCAT_LOG" 2>&1 &
LOGCAT_PID=$!

"$ADB_CMD" shell am start -n "by.intontrainer/org.qtproject.qt.android.bindings.QtActivity"

# Wait a few seconds for the app to start (or crash), then dump relevant logs
echo "Waiting for app startup..."
sleep 5

# Check if app process is still running
APP_PID=$("$ADB_CMD" shell pidof by.intontrainer 2>/dev/null || echo "")
if [[ -z "$APP_PID" ]]; then
    echo ""
    echo "WARNING: App process not found — it may have crashed on startup."
    echo "--- Last 40 lines of logcat (filtered for errors & Qt) ---"
    grep -iE 'FATAL|ERROR|Qt|inton|crash|signal|SIGSEGV|SIGABRT|dlopen|UnsatisfiedLinkError|NoClassDefFoundError' "$LOGCAT_LOG" | tail -40 || true
    echo "--- Full logcat saved to: $LOGCAT_LOG ---"
else
    echo "App is running (PID: $APP_PID)"
fi

# Keep logcat running in background for live debugging
echo "Logcat capturing to: $LOGCAT_LOG (PID: $LOGCAT_PID)"
echo "To stop logcat: kill $LOGCAT_PID"
