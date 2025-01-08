#!/bin/bash
set -e

log_section() {
    echo ""
    echo "============================================"
    echo "🚀 $1"
    echo "============================================"
}

log_subsection() {
    echo ""
    echo ">> $1"
}

if [ "$CI" = "true" ]; then
    log_section "Running in CI environment"
fi

log_section "Setting up environment"
log_subsection "Cleaning up Metro bundler..."
# Check if lsof command exists
if command -v lsof >/dev/null 2>&1; then
    METRO_PID=$(lsof -t -i:8081 || true)
    if [ ! -z "$METRO_PID" ]; then
        echo "Found Metro process(es): $METRO_PID"
        kill $METRO_PID 2>/dev/null || true
        sleep 2
    else
        echo "No Metro process found on port 8081"
    fi
else
    echo "lsof command not found, skipping Metro cleanup"
fi

log_section "Emulator Setup"
log_subsection "Checking if emulator is running..."
if ! adb devices | grep -q "emulator-"; then
    echo "No emulator running. Starting new emulator..."
    
    if [ "$CI" = "true" ]; then
        log_subsection "Creating AVD for CI environment..."
        echo "no" | avdmanager create avd -n test_avd --package "system-images;android-33;google_apis;x86_64" --device "pixel_6"
        $ANDROID_HOME/emulator/emulator -avd test_avd -no-window -no-audio -no-boot-anim &
    else
        $ANDROID_HOME/emulator/emulator -avd Pixel_6_Pro_API_34 -no-snapshot -gpu swiftshader_indirect -no-boot-anim -skin 1440x3120 &
    fi
    
    EMULATOR_PID=$!
    
    log_subsection "Waiting for emulator to boot..."
    adb wait-for-device
    sleep 30
else
    echo "Using already running emulator..."
    EMULATOR_PID=""
fi

log_section "Building Application"
log_subsection "Running prebuild..."
yarn expo prebuild --platform android --clean

log_subsection "Cleaning Android project..."
cd android
./gradlew clean
cd ..

log_subsection "Generating test data..."
yarn generate-test-data

log_subsection "Building APK..."
cd android
./gradlew assembleDebug
cd ..

log_section "Testing"
log_subsection "Installing APK..."
log_subsection "Checking APK location..."
echo "Looking for APK in android/app/build/outputs/apk/debug/"
ls -la android/app/build/outputs/apk/debug/

APK_PATH="android/app/build/outputs/apk/debug/app-debug.apk"

# Check if APK exists
if [ ! -f "$APK_PATH" ]; then
    echo "❌ Error: APK not found at $APK_PATH"
    echo "Available files in build directory:"
    find android/app/build/outputs/apk -type f -name "*.apk"
    exit 1
fi

echo "Installing APK from: $APK_PATH"
adb install "$APK_PATH"

log_subsection "Starting Expo server..."
yarn expo start &
EXPO_PID=$!
sleep 5

log_subsection "Running Maestro tests..."
maestro test ./tests/*.yaml
TEST_RESULT=$?

log_section "Cleanup"
log_subsection "Cleaning up processes..."
kill $EXPO_PID 2>/dev/null || true

if [ ! -z "$EMULATOR_PID" ]; then
    log_subsection "Shutting down emulator..."
    kill $EMULATOR_PID 2>/dev/null || true
fi

if [ $TEST_RESULT -eq 0 ]; then
    log_section "✅ Tests completed successfully"
else
    log_section "❌ Tests failed"
fi

exit $TEST_RESULT
