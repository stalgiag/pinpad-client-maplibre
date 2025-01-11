#!/bin/bash
# test-ios.sh
set -e 

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

if [ "$CI" = "true" ]; then
    log_section "Running in CI environment"
fi

# Find an available iOS simulator with
# the given name or use the first available iPhone simulator
DEVICE_ID=$(find_available_ios_simulator "iPhone 15")

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

log_subsection "Checking for running simulator..."
if ! xcrun simctl list | grep -q "Booted"; then
    log_subsection "Starting simulator..."
    xcrun simctl boot "$DEVICE_ID"
    SIMULATOR_STARTED=true
else
    log_subsection "Using already running simulator..."
    SIMULATOR_STARTED=false
fi

log_subsection "Prebuilding app..."
yarn expo prebuild --platform ios --clean

log_subsection "Installing dependencies..."
cd ios
pod install
cd ..

log_subsection "Generating test data..."
yarn generate-test-data

log_section "Building and installing app"
log_subsection "Building app..."
cd ios
xcodebuild -workspace pinpadclientmaplibre.xcworkspace \
  -scheme pinpadclientmaplibre \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath build \
  build

log_subsection "Installing app..."
xcrun simctl install "$DEVICE_ID" "build/Build/Products/Debug-iphonesimulator/pinpadclientmaplibre.app"
cd ..

log_subsection "Starting Metro bundler..."
yarn expo start &
EXPO_PID=$!
sleep 5

log_section "Running tests..."
maestro test .maestro/
TEST_RESULT=$?

log_section "Cleaning up processes..."
kill $EXPO_PID 2>/dev/null || true

if [ "$SIMULATOR_STARTED" = true ]; then
    log_subsection "Shutting down simulator..."
    xcrun simctl shutdown "$DEVICE_ID"
fi

if [ $TEST_RESULT -eq 0 ]; then
    log_section "✅ Tests completed successfully"
else
    log_section "❌ Tests failed"
fi

exit $TEST_RESULT
