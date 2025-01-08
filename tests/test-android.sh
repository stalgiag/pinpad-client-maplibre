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
log_subsection "Setting up hardware acceleration..."
# Add hardware acceleration check
if [ "$CI" = "true" ]; then
    if ! grep -q "^flags.*\bvmx\b" /proc/cpuinfo; then
        echo "❌ CPU does not support hardware virtualization"
        exit 1
    fi
fi

# Start logging
mkdir -p logs
adb logcat > logs/emulator.log &
LOGCAT_PID=$!

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
                --package "system-images;android-33;google_apis;x86_64" \
                --device "pixel_6" \
                --force

            log_subsection "Creating optimized AVD configuration..."
            CONFIG_PATH="$ANDROID_AVD_HOME/test_avd.avd/config.ini"
            # Enhanced emulator settings for stability
            cat >> "$CONFIG_PATH" << EOF
hw.ramSize=4096
hw.gpu.enabled=yes
hw.gpu.mode=swiftshader_indirect
hw.cpu.ncore=2
disk.dataPartition.size=6442450944
hw.lcd.density=440
hw.keyboard=yes
hw.mainKeys=no
hw.accelerometer=yes
hw.camera.back=none
hw.camera.front=none
hw.gps=no
hw.battery=yes
vm.heapSize=576
dalvik.vm.heapsize=576m
disk.dataPartition.size=2048M
hw.sensors.proximity=no
hw.sensors.magnetic_field=no
hw.audioInput=no
hw.audioOutput=no
EOF

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
                env | grep ANDROID
                echo "Contents of Android directories:"
                ls -la $ANDROID_SDK_HOME || true
                ls -la $ANDROID_HOME/emulator || true
                exit 1
            fi
        fi
        
        log_subsection "Starting emulator with optimized parameters..."
        export QEMU_AUDIO_DRV=none
        $ANDROID_HOME/emulator/emulator -avd "$AVD_NAME" \
            -no-window \
            -no-audio \
            -no-boot-anim \
            -accel on \
            -gpu swiftshader_indirect \
            -memory 4096 \
            -cores 2 \
            -no-snapshot \
            -screen no-touch \
            -no-cache \
            -wipe-data \
            -debug-init \
            -qemu -enable-kvm &
    else
        $ANDROID_HOME/emulator/emulator -avd Pixel_6_Pro_API_34 -no-snapshot -gpu swiftshader_indirect -no-boot-anim -skin 1440x3120 &
    fi
    
    EMULATOR_PID=$!
    
    log_subsection "Enhanced emulator boot checks..."
    # Add more robust boot checking
    BOOT_TIMEOUT=360
    BOOT_START_TIME=$(date +%s)
    while true; do
        if adb shell getprop sys.boot_completed 2>&1 | grep -q "1"; then
            echo "✅ System boot completed"
            break
        fi
        
        CURRENT_TIME=$(date +%s)
        ELAPSED_TIME=$((CURRENT_TIME - BOOT_START_TIME))
        
        if [ $ELAPSED_TIME -gt $BOOT_TIMEOUT ]; then
            echo "❌ Emulator boot timeout after ${BOOT_TIMEOUT} seconds"
            echo "Dumping system logs..."
            adb logcat -d > logs/emulator_boot_failure.log
            adb shell dumpsys > logs/system_dump.txt
            exit 1
        fi
        
        echo "Waiting for system boot... (${ELAPSED_TIME}s)"
        sleep 5
    done

    # System stability configuration
    log_subsection "Configuring system settings..."
    adb shell settings put global window_animation_scale 0
    adb shell settings put global transition_animation_scale 0
    adb shell settings put global animator_duration_scale 0
    adb shell settings put system screen_off_timeout 1800000
    
    # Additional stability settings
    adb shell svc power stayon true
    adb shell settings put global development_settings_enabled 1
    adb shell settings put global stay_on_while_plugged_in 3
    
    # Memory optimization
    adb shell settings put global cached_apps_freezer enabled
    adb shell settings put global always_finish_activities 1

    # SystemUI monitoring function
    monitor_systemui() {
        while true; do
            if ! adb shell pidof com.android.systemui >/dev/null; then
                echo "SystemUI process died, restarting..."
                adb shell stop
                sleep 2
                adb shell start
                sleep 5
                adb shell am start -n com.android.systemui/.SystemUIService
            fi
            sleep 5
        done
    }

    # Start SystemUI monitoring in background
    monitor_systemui &
    MONITOR_PID=$!

    # Additional boot stabilization delay
    sleep 30

    # Verify system stability
    if ! adb shell input keyevent KEYCODE_WAKEUP; then
        echo "❌ System UI might be unresponsive, attempting recovery..."
        adb shell dumpsys > logs/pre_recovery_dump.txt
        adb shell pkill -f com.android.systemui
        sleep 5
        adb shell am start -n com.android.systemui/.SystemUIService
        sleep 30
        adb shell dumpsys > logs/post_recovery_dump.txt
    fi
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
for i in {1..60}; do
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
maestro test ./tests/*.yaml
TEST_RESULT=$?

log_section "Cleanup"
log_subsection "Cleaning up processes..."
kill $EXPO_PID 2>/dev/null || true
kill $LOGCAT_PID 2>/dev/null || true
kill $MONITOR_PID 2>/dev/null || true

if [ ! -z "$EMULATOR_PID" ]; then
    log_subsection "Shutting down emulator..."
    adb emu kill || true
    kill $EMULATOR_PID 2>/dev/null || true
fi

# Save logs on failure
if [ $TEST_RESULT -ne 0 ]; then
    log_section "❌ Tests failed - saving logs"
    mkdir -p test-artifacts
    cp logs/* test-artifacts/
    adb logcat -d > test-artifacts/final_logcat.log
    adb shell dumpsys > test-artifacts/final_dumpsys.txt
else
    log_section "✅ Tests completed successfully"
fi

exit $TEST_RESULT
