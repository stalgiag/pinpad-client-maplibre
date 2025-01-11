#!/bin/bash

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

find_available_ios_simulator() {
    local device_name="$1"
    
    # First try to find the specified device
    local DEVICE_ID=$(xcrun simctl list devices | grep "$device_name" | grep -v "unavailable" | head -n 1 | sed -E 's/.*\(([A-Z0-9-]+)\).*/\1/')
    if [ -n "$DEVICE_ID" ]; then
        echo "$DEVICE_ID"
        return 0
    fi
    
    # If not found, get the first available iPhone simulator
    DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone" | head -n 1 | sed -E 's/.*\(([A-Z0-9-]+)\).*/\1/')
    if [ -n "$DEVICE_ID" ]; then
        echo "Warning: $device_name not found, using first available iPhone simulator" >&2
        echo "$DEVICE_ID"
        return 0
    fi
    
    echo "Error: No iPhone simulators available" >&2
    exit 1
}

