#!/bin/bash
set -e  # Exit on error

if [ "$CI" = "true" ]; then
    echo "Running in CI environment..."
fi

# Kill any running Metro bundler instances
echo "Cleaning up Metro bundler..."
METRO_PID=$(lsof -t -i:8081)
if [ ! -z "$METRO_PID" ]; then
    echo "Found Metro process(es): $METRO_PID"
    kill $METRO_PID 2>/dev/null || true
    sleep 2
fi

# Check if an emulator is already running
if ! adb devices | grep -q "emulator-"; then
    echo "No emulator running. Starting new emulator..."
    $ANDROID_HOME/emulator/emulator -avd Pixel_6_Pro_API_34 -no-snapshot -gpu swiftshader_indirect -no-boot-anim -skin 1440x3120 &
    EMULATOR_PID=$!
    
    echo "Waiting for emulator to boot..."
    adb wait-for-device
    sleep 30
else
    echo "Using already running emulator..."
    EMULATOR_PID=""
fi

yarn expo prebuild --platform android --clean
cd android
./gradlew clean
cd ..
yarn generate-test-data

cd android
./gradlew assembleDebug
cd ..

# apk name comes from android/app/build.gradle
adb install android/app/build/outputs/apk/debug/com.anonymous.pinpadclientmaplibre-debug.apk

yarn expo start &
EXPO_PID=$!
sleep 5
maestro test ./tests/*.yaml
TEST_RESULT=$?

echo "Cleaning up processes..."
kill $EXPO_PID 2>/dev/null || true

if [ ! -z "$EMULATOR_PID" ]; then
    echo "Shutting down emulator..."
    kill $EMULATOR_PID 2>/dev/null || true
fi

exit $TEST_RESULT
