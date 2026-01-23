#!/bin/bash

# Android Emulator Launcher Script
# Usage: ./launch_emulator.sh [emulator_name]
# If no emulator is specified, launches Medium_Phone_API_36.1 by default

set -e  # Exit on error (but we'll handle it ourselves)

# Default emulator
DEFAULT_EMULATOR="Medium_Phone_API_36.1"

# Set Android SDK environment variables (required by emulator)
if [ -z "$ANDROID_HOME" ]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
fi
if [ -z "$ANDROID_SDK_ROOT" ]; then
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
fi

# Check if emulator name is provided
if [ -z "$1" ]; then
    echo "No emulator specified. Launching default: $DEFAULT_EMULATOR"
    EMULATOR="$DEFAULT_EMULATOR"
else
    EMULATOR="$1"
fi

# Launch the specified emulator
echo "Launching emulator: $EMULATOR"
echo "ANDROID_HOME: $ANDROID_HOME"
echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
echo ""

# Capture both stdout and stderr, and get exit code
set +e  # Don't exit on error, we'll handle it
OUTPUT=$(ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" ANDROID_HOME="$ANDROID_HOME" flutter emulators --launch "$EMULATOR" 2>&1)
EXIT_CODE=$?
set -e  # Re-enable exit on error

# Print all output
echo "=== Flutter Command Output ==="
echo "$OUTPUT"
echo ""

# Check for error messages in output (Flutter may return 0 even on failure)
HAS_ERROR=false
if echo "$OUTPUT" | grep -qi "exited with code"; then
    HAS_ERROR=true
fi
if echo "$OUTPUT" | grep -qi "Address these issues"; then
    HAS_ERROR=true
fi
if echo "$OUTPUT" | grep -qi "error"; then
    HAS_ERROR=true
fi

# Check exit code and provide detailed error information
if [ $EXIT_CODE -ne 0 ] || [ "$HAS_ERROR" = true ]; then
    echo "=== ERROR: Emulator launch failed ==="
    if [ $EXIT_CODE -ne 0 ]; then
        echo "Exit code: $EXIT_CODE"
    fi
    if [ "$HAS_ERROR" = true ]; then
        echo "Error detected in output"
    fi
    echo ""
    
    # Check for missing system image
    echo "=== Checking for system image ==="
    ANDROID_SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
    
    # Find AVD config file - check .ini file first to get the actual AVD path
    AVD_INI="$HOME/.android/avd/$(echo "$EMULATOR" | tr ' ' '_').ini"
    AVD_CONFIG=""
    
    if [ -f "$AVD_INI" ]; then
        # Read the path from the .ini file
        AVD_PATH=$(grep "^path=" "$AVD_INI" | cut -d'=' -f2 | tr -d '\r\n' || echo "")
        if [ -n "$AVD_PATH" ]; then
            AVD_CONFIG="$AVD_PATH/config.ini"
        fi
    fi
    
    # Fallback: try direct path
    if [ ! -f "$AVD_CONFIG" ]; then
        AVD_CONFIG="$HOME/.android/avd/$(echo "$EMULATOR" | tr ' ' '_').avd/config.ini"
    fi
    
    # Also try finding by searching for the AVD name
    if [ ! -f "$AVD_CONFIG" ]; then
        AVD_CONFIG=$(find "$HOME/.android/avd" -name "config.ini" -type f 2>/dev/null | grep -i "$(echo "$EMULATOR" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')" | head -1)
    fi
    
    if [ -f "$AVD_CONFIG" ]; then
        echo "AVD Config file: $AVD_CONFIG"
        TARGET=$(grep "^target=" "$AVD_CONFIG" 2>/dev/null | cut -d'=' -f2 | tr -d '\r\n ' || echo "")
        ABI=$(grep "^abi.type=" "$AVD_CONFIG" 2>/dev/null | cut -d'=' -f2 | tr -d '\r\n ' || echo "")
        PLAYSTORE=$(grep "^PlayStore.enabled=" "$AVD_CONFIG" 2>/dev/null | cut -d'=' -f2 | tr -d '\r\n ' || echo "")
        
        # If target not found in config.ini, try the .ini file
        if [ -z "$TARGET" ] && [ -f "$AVD_INI" ]; then
            TARGET=$(grep "^target=" "$AVD_INI" 2>/dev/null | cut -d'=' -f2 | tr -d '\r\n ' || echo "")
        fi
        
        if [ -n "$TARGET" ] && [ -n "$ABI" ]; then
            echo "AVD requires: target=$TARGET, abi=$ABI, PlayStore=$PLAYSTORE"
            
            # Determine system image path
            if [ "$PLAYSTORE" = "true" ]; then
                IMAGE_TYPE="google_apis_playstore"
            else
                IMAGE_TYPE="google_apis"
            fi
            
            EXPECTED_PATH="$ANDROID_SDK/system-images/$TARGET/$IMAGE_TYPE/$ABI"
            echo "Expected system image path: $EXPECTED_PATH"
            
            if [ ! -d "$EXPECTED_PATH" ]; then
                echo "✗ System image NOT found at: $EXPECTED_PATH"
                echo ""
                echo "=== SOLUTION: Install the missing system image ==="
                echo "Run this command to install it:"
                echo "  sdkmanager \"system-images;$TARGET;$IMAGE_TYPE;$ABI\""
                echo ""
                echo "Or install via Android Studio:"
                echo "  1. Open Android Studio"
                echo "  2. Tools → SDK Manager"
                echo "  3. SDK Platforms tab → Show Package Details"
                echo "  4. Check: Android $TARGET → $IMAGE_TYPE → $ABI"
                echo "  5. Apply"
            else
                echo "✓ System image found at: $EXPECTED_PATH"
            fi
        else
            echo "Could not determine system image requirements from config"
            echo "TARGET: '$TARGET', ABI: '$ABI', PlayStore: '$PLAYSTORE'"
        fi
    else
        echo "Could not find AVD config file"
        echo "Searched for: $AVD_INI"
        echo "And: $HOME/.android/avd/$(echo "$EMULATOR" | tr ' ' '_').avd/config.ini"
    fi
    echo ""
    
    # Try to launch emulator directly for more detailed errors
    echo "=== Attempting direct emulator launch for detailed errors ==="
    if [ -n "$ANDROID_HOME" ] && [ -f "$ANDROID_HOME/emulator/emulator" ]; then
        # Get the AVD name from the emulator ID
        AVD_NAME=$(echo "$EMULATOR" | tr ' ' '_')
        echo "Trying to launch AVD: $AVD_NAME"
        echo "Running: $ANDROID_HOME/emulator/emulator -list-avds"
        ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" "$ANDROID_HOME/emulator/emulator" -list-avds 2>&1 || true
        echo ""
        echo "Running: $ANDROID_HOME/emulator/emulator -avd $AVD_NAME -verbose 2>&1 | head -50"
        ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" "$ANDROID_HOME/emulator/emulator" -avd "$AVD_NAME" -verbose 2>&1 | head -50 || true
        echo ""
    elif [ -f "$HOME/Android/Sdk/emulator/emulator" ]; then
        AVD_NAME=$(echo "$EMULATOR" | tr ' ' '_')
        echo "Trying to launch AVD: $AVD_NAME"
        ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" "$HOME/Android/Sdk/emulator/emulator" -list-avds 2>&1 || true
        echo ""
        ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" "$HOME/Android/Sdk/emulator/emulator" -avd "$AVD_NAME" -verbose 2>&1 | head -50 || true
        echo ""
    else
        echo "Could not find emulator binary for direct launch"
    fi
    echo ""
    
    # Try to get more detailed error information
    echo "=== Checking available emulators ==="
    flutter emulators
    echo ""
    
    echo "=== Checking Flutter doctor (Android) ==="
    flutter doctor -v | grep -A 10 "Android toolchain" || flutter doctor -v
    echo ""
    
    echo "=== Checking if emulator exists ==="
    if flutter emulators | grep -q "$EMULATOR"; then
        echo "✓ Emulator '$EMULATOR' is listed as available"
    else
        echo "✗ Emulator '$EMULATOR' NOT found in available emulators"
        echo "Available emulators:"
        flutter emulators
    fi
    echo ""
    
    echo "=== Checking Android SDK setup ==="
    if [ -n "$ANDROID_HOME" ]; then
        echo "ANDROID_HOME: $ANDROID_HOME"
    else
        echo "WARNING: ANDROID_HOME is not set"
        echo "Trying default: $HOME/Android/Sdk"
    fi
    
    if [ -n "$ANDROID_SDK_ROOT" ]; then
        echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
    else
        echo "WARNING: ANDROID_SDK_ROOT is not set (required by emulator)"
        echo "Set it to: $HOME/Android/Sdk"
    fi
    
    ANDROID_SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
    if [ -d "$ANDROID_SDK" ]; then
        echo "Android SDK directory: $ANDROID_SDK"
        if [ -d "$ANDROID_SDK/emulator" ]; then
            echo "✓ Emulator directory exists: $ANDROID_SDK/emulator"
            if [ -f "$ANDROID_SDK/emulator/emulator" ]; then
                echo "✓ Emulator binary found"
                echo "Emulator version:"
                "$ANDROID_SDK/emulator/emulator" -version 2>&1 || true
            else
                echo "✗ Emulator binary NOT found"
            fi
        else
            echo "✗ Emulator directory not found: $ANDROID_SDK/emulator"
        fi
    else
        echo "✗ Android SDK directory not found: $ANDROID_SDK"
    fi
    echo ""
    
    echo "=== Checking PATH ==="
    echo "PATH includes Android tools:"
    echo "$PATH" | tr ':' '\n' | grep -i android || echo "No Android paths found in PATH"
    echo ""
    
    # Try to get emulator error logs if available
    if [ -d "$HOME/.android/avd" ]; then
        echo "=== AVD Configuration Directory ==="
        ls -la "$HOME/.android/avd" 2>/dev/null || echo "Could not list AVD directory"
        echo ""
        echo "=== AVD Config Files ==="
        find "$HOME/.android/avd" -name "*.ini" -o -name "config.ini" 2>/dev/null | head -5 | while read file; do
            echo "File: $file"
            cat "$file" 2>/dev/null | head -10
            echo ""
        done
    fi
    
    # Check for common issues
    echo "=== Checking for common issues ==="
    if ! command -v adb &> /dev/null; then
        echo "✗ ADB not found in PATH"
    else
        echo "✓ ADB found: $(which adb)"
        echo "ADB version:"
        adb version 2>&1 || true
    fi
    echo ""
    
    exit 1
else
    echo "✓ Emulator launch command completed successfully"
    echo "Note: The emulator may take 30-60 seconds to fully boot"
    echo "Check status with: flutter devices"
fi

