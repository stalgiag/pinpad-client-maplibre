#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

if [ "$CI" = "true" ]; then
    log_section "Running in CI environment"
fi

log_section "Setting up environment"
log_subsection "Cleaning up Metro bundler..."

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
        log_subsection "Setting up AVD environment..."
        export ANDROID_SDK_HOME=$HOME/.android
        export ANDROID_AVD_HOME=$HOME/.android/avd
        
        mkdir -p $ANDROID_AVD_HOME
        
        log_subsection "Checking available AVDs..."
        AVD_NAME=$($ANDROID_HOME/emulator/emulator -list-avds | head -n 1)
        echo "AVD_NAME: $AVD_NAME"
        
        if [ -z "$AVD_NAME" ]; then
            log_subsection "No AVD found. Creating new AVD..."
            echo "no" | avdmanager --verbose create avd -n "test_avd" \
                --package "system-images;android-34;google_apis;x86_64" \
                --device "pixel_6" \
                --force

            for i in {1..5}; do
                AVD_NAME=$($ANDROID_HOME/emulator/emulator -list-avds | grep "test_avd" || true)
                if [ ! -z "$AVD_NAME" ]; then
                    echo "✅ AVD created successfully"
                    break
                fi
                echo "Waiting for AVD to be available... (attempt $i)"
                echo "Current AVD directory contents:"
                ls -la $ANDROID_AVD_HOME || true
                sleep 5
            done

            if [ -z "$AVD_NAME" ]; then
                echo "❌ Failed to create AVD"
                echo "Environment variables:"
                echo "ANDROID_AVD_HOME: $ANDROID_AVD_HOME"
                echo "ANDROID_SDK_HOME: $ANDROID_SDK_HOME"
                echo "ANDROID_HOME: $ANDROID_HOME"
                echo "Contents of Android directories:"
                ls -la $ANDROID_SDK_HOME || true
                ls -la $ANDROID_HOME/emulator || true
                exit 1
            fi
        fi
        
        log_subsection "Starting emulator with AVD: $AVD_NAME"
        if [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
            echo "❌ KVM permissions not properly set"
            ls -la /dev/kvm
            groups
            exit 1
        fi
        
        echo "✅ KVM permissions verified"
        $ANDROID_HOME/emulator/emulator -avd "$AVD_NAME" \
            -no-window \
            -no-audio \
            -no-boot-anim \
            -accel on \
            -gpu swiftshader_indirect \
            -qemu -enable-kvm &
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
log_subsection "Generating test data..."
yarn generate-test-data

log_subsection "Running prebuild..."
yarn expo prebuild --platform android --clean

log_subsection "Cleaning Android project..."
cd android
./gradlew clean
cd ..

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

log_subsection "Waiting for Expo server to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8081/status | grep -q "packager-status:running"; then
        echo "✅ Expo server is ready"
        break
    fi
    echo "Waiting for Expo server... (attempt $i)"
    sleep 2
done

log_subsection "Waiting for app to initialize..."
sleep 30

log_subsection "Running Maestro tests..."
maestro test .maestro/
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
