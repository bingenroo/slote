#!/bin/bash

# Android Emulator Launcher Script
# Usage: ./launch_emulator.sh [emulator_name]

# Check if emulator name is provided
if [ -z "$1" ]; then
    echo "Available emulators:"
    flutter emulators
    echo ""
    echo "Usage: $0 <emulator_id>"
    echo "Example: $0 Pixel_5_API_33"
    exit 1
fi

# Launch the specified emulator
echo "Launching emulator: $1"
flutter emulators --launch "$1"

