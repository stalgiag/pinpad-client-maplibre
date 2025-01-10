#!/bin/bash
# test-ios.sh
set -e 

# Use environment variable for device name with fallback
DEVICE_NAME=${SIMULATOR_DEVICE:-"iPhone XR"}

# Kill any running Metro bundler instances
echo "Cleaning up Metro bundler..."
METRO_PID=$(lsof -t -i:8081)
if [ ! -z "$METRO_PID" ]; then
    echo "Found Metro process(es): $METRO_PID"
    kill $METRO_PID 2>/dev/null || true
    sleep 2
fi

if ! xcrun simctl list | grep -q "Booted"; then
    echo "No simulator running. Starting $DEVICE_NAME..."
    xcrun simctl boot "$DEVICE_NAME"
    SIMULATOR_STARTED=true
else
    echo "Using already running simulator..."
    SIMULATOR_STARTED=false
fi

yarn expo prebuild --platform ios --clean
cd ios
pod install
cd ..
yarn generate-test-data

cd ios
xcodebuild -workspace pinpadclientmaplibre.xcworkspace \
  -scheme pinpadclientmaplibre \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -derivedDataPath build \
  build

xcrun simctl install "$DEVICE_NAME" "build/Build/Products/Debug-iphonesimulator/pinpadclientmaplibre.app"
cd ..

yarn expo start &
EXPO_PID=$!
sleep 5
maestro test .maestro/
TEST_RESULT=$?

echo "Cleaning up processes..."
kill $EXPO_PID 2>/dev/null || true

if [ "$SIMULATOR_STARTED" = true ]; then
    echo "Shutting down simulator..."
    xcrun simctl shutdown "$DEVICE_NAME"
fi

exit $TEST_RESULT
