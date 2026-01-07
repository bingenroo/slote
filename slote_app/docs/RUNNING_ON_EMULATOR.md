# Running Slote on Emulator - Quick Guide

## 🚀 Quick Reference (Copy These Commands)

```bash
# 1. List available emulators
emu-list

# 2. Launch an emulator (replace <emulator_id> with actual ID)
emu <emulator_id>

# 3. Check if emulator is running
flutter devices

# 4. Navigate to app and run
cd /Users/bingenro/Documents/Slote/slote_app
flutter pub get
flutter run
```

**Most Common Workflow:**

```bash
emu-list                    # See available emulators
emu Pixel_5_API_33          # Launch one (use ID from above)
cd /Users/bingenro/Documents/Slote/slote_app && flutter run  # Run app
```

---

## Overview

This guide shows you how to run and test the Slote app on Android emulators using command-line tools, without needing to open Android Studio.

## Prerequisites

- Flutter SDK installed and configured
- Android Studio installed (for creating emulators)
- Android Command Line Tools installed
- At least one Android Virtual Device (AVD) created

### Installing Android Command Line Tools

**Option 1: Using Homebrew (Recommended)**

```bash
brew install --cask android-commandlinetools
```

**Option 2: Direct Download**

1. Visit: https://developer.android.com/studio#command-tools
2. Download "Command line tools only" for macOS
3. Extract and set up:
   ```bash
   mkdir -p ~/Android/Sdk/cmdline-tools
   unzip ~/Downloads/commandlinetools-mac-*.zip -d ~/Android/Sdk/cmdline-tools
   cd ~/Android/Sdk/cmdline-tools
   mv tools latest
   ```

**Configure Environment Variables:**
Add to `~/.zshrc`:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
```

Then reload: `source ~/.zshrc`

**Install Required SDK Components:**

```bash
# Accept licenses
yes | sdkmanager --licenses

# Install essential packages
sdkmanager "platform-tools" \
           "platforms;android-33" \
           "platforms;android-36" \
           "build-tools;33.0.0" \
           "emulator"
```

### Creating Your First Emulator

If `emu-list` shows "Unable to find any emulator sources", you need to create an AVD:

**Important:** Install the system image **before** creating the AVD to avoid launch failures.

1. **Open Android Studio**
2. **Go to**: Tools → Device Manager (or More Actions → Virtual Device Manager)
3. **Click**: "Create Device" button
4. **Select a device**: Choose any device (e.g., Pixel 5, Pixel 6)
5. **Select system image**:
   - Choose an API level (recommended: API 33, 34, or 36)
   - **CRITICAL**: Click "Download" if the system image isn't installed
   - Wait for download to complete before proceeding
   - If you skip this step, the emulator will fail to launch later
6. **Finish setup**: Click "Next" → "Finish"
7. **Close Android Studio** (you don't need it running to use the emulator)

**Alternative: Install system image via command line first:**

```bash
# Install system image before creating AVD
sdkmanager "system-images;android-36;google_apis_playstore;arm64-v8a"

# Then create AVD via Android Studio or command line
avdmanager create avd -n MyEmulator -k "system-images;android-36;google_apis_playstore;arm64-v8a"
```

After creating the emulator, verify it's available:

```bash
emu-list
```

You should now see your emulator listed!

## Quick Start

### 1. Check Available Emulators

List all available emulators:

```bash
emu-list
```

Or use the full command:

```bash
flutter emulators
```

### 2. Launch an Emulator

Use the shortest alias:

```bash
emu <emulator_id>
```

Example:

```bash
emu Pixel_5_API_33
```

Alternative commands:

```bash
# Using alias
emu-launch <emulator_id>

# Using script
launch-emu <emulator_id>

# Direct script
cd /Users/bingenro/Documents/Slote
./launch_emulator.sh <emulator_id>
```

### 3. Verify Emulator is Running

Check connected devices:

```bash
flutter devices
```

You should see your emulator listed (e.g., `emulator-5554`).

### 4. Run Your App

Navigate to the app directory and run:

```bash
cd /Users/bingenro/Documents/Slote/slote_app
flutter pub get
flutter run
```

Or target a specific device:

```bash
flutter run -d <device-id>
```

## Available Aliases

The following aliases are configured in your `~/.zshrc`:

| Alias        | Command                      | Description                      |
| ------------ | ---------------------------- | -------------------------------- |
| `emu-list`   | `flutter emulators`          | List all available emulators     |
| `emu`        | `flutter emulators --launch` | Launch an emulator (shortest)    |
| `emu-launch` | `flutter emulators --launch` | Launch an emulator (alternative) |
| `launch-emu` | `./launch_emulator.sh`       | Run the helper script            |

## Helper Script

Location: `/Users/bingenro/Documents/Slote/launch_emulator.sh`

**Features:**

- Automatically launches `Medium_Phone_API_36.1` by default if no emulator is specified
- Automatically sets `ANDROID_SDK_ROOT` and `ANDROID_HOME` environment variables
- Detects missing system images and provides exact installation commands
- Provides detailed error diagnostics when emulator launch fails
- Shows comprehensive troubleshooting information

**Usage:**

```bash
# Launch default emulator (Medium_Phone_API_36.1)
./launch_emulator.sh

# Launch specific emulator
./launch_emulator.sh <emulator_id>

# Example: Launch iOS simulator instead
./launch_emulator.sh apple_ios_simulator
```

**What the Script Does:**

1. Sets required Android SDK environment variables
2. Attempts to launch the emulator
3. If launch fails, provides detailed diagnostics:
   - Checks for missing system images
   - Shows exact `sdkmanager` command to install missing images
   - Verifies Android SDK setup
   - Checks PATH configuration
   - Displays AVD configuration details

## Complete Workflow Example

```bash
# Step 1: List available emulators
emu-list

# Step 2: Launch an emulator (replace with actual ID from step 1)
emu Pixel_5_API_33

# Step 3: Wait for emulator to boot (check with flutter devices)
flutter devices

# Step 4: Navigate to app and install dependencies
cd /Users/bingenro/Documents/Slote/slote_app
flutter pub get

# Step 5: Run the app
flutter run
```

## Useful Flutter Commands

### Hot Reload & Development

- **Hot Reload**: Press `r` in terminal while app is running
- **Hot Restart**: Press `R` (capital R)
- **Open DevTools**: Press `d`
- **Quit**: Press `q`

### Running Modes

```bash
# Debug mode (default)
flutter run

# Release mode
flutter run --release

# Verbose output
flutter run -v
```

### Testing

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## Troubleshooting

### Common Root Causes

**Most Common Issue: Missing System Image**

- **Root Cause**: AVD created but system image package not installed
- **Why**: Creating an AVD doesn't automatically install the system image; it must be installed separately
- **Solution**: Use `launch_emulator.sh` to detect and get the exact install command, or install via `sdkmanager`
- **Prevention**: Always install system image before creating AVD

**Secondary Issues:**

- Missing `ANDROID_SDK_ROOT` environment variable (script handles this automatically)
- Android Command Line Tools not properly configured
- System image path mismatch between AVD config and installed packages

### No Emulators Found

If `emu-list` shows "Unable to find any emulator sources":

**You need to create your first Android Virtual Device (AVD):**

1. Open Android Studio
2. Go to **Tools → Device Manager** (or **More Actions → Virtual Device Manager**)
3. Click **"Create Device"** button
4. Select a device (e.g., Pixel 5)
5. Select a system image (API 33 or 34 recommended)
   - Click **"Download"** if the system image isn't installed
   - Wait for download to complete
6. Click **Next** → **Finish**
7. Close Android Studio

After creating the emulator, verify it's available:

```bash
emu-list
```

You should now see your emulator listed. Then launch it with:

```bash
emu <emulator_id>
```

### Emulator Won't Start

```bash
# Check if emulator is already running
flutter devices

# Kill existing emulator processes
adb kill-server
adb start-server

# Try launching again
emu <emulator_id>
```

### Emulator Exits with Code 1 - Missing System Image

**Root Cause:** The AVD (Android Virtual Device) was created but the required system image package is not installed. This is the most common cause of emulator launch failures.

**Symptoms:**

- Error message: `The Android emulator exited with code 1 during startup`
- Error message: `FATAL | Cannot find AVD system path` or `Broken AVD system path`
- Warning: `system-images/android-X.X/google_apis_playstore/arm64-v8a/ is not a valid directory`

**Why This Happens:**

- Creating an AVD in Android Studio or via Flutter doesn't automatically install the system image
- The system image must be installed separately using `sdkmanager`
- If you create an AVD before installing the system image, the emulator will fail to launch

**Solution:**

1. **Use the launch script to identify the missing system image:**

   ```bash
   cd /Users/bingenro/Documents/Slote
   ./launch_emulator.sh
   ```

   The script will automatically detect the missing system image and show you the exact command to install it.

2. **Install the missing system image:**

   ```bash
   # The script will show you the exact command, typically something like:
   sdkmanager "system-images;android-36.1;google_apis_playstore;arm64-v8a"
   ```

3. **Verify installation:**

   ```bash
   # Check that the system image directory exists
   ls -la $HOME/Android/Sdk/system-images/android-36.1/google_apis_playstore/arm64-v8a/
   ```

4. **Launch the emulator again:**
   ```bash
   ./launch_emulator.sh
   ```

**Prevention:**

- Always install the system image **before** creating an AVD
- When creating an AVD in Android Studio, make sure to click "Download" for the system image if it's not already installed
- Verify system images are installed: `sdkmanager --list | grep system-images`

**Environment Variables:**
The `launch_emulator.sh` script automatically sets `ANDROID_SDK_ROOT` and `ANDROID_HOME`, but for permanent setup, add to `~/.zshrc`:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
```

### App Won't Build

```bash
# Clean build cache
cd /Users/bingenro/Documents/Slote/slote_app
flutter clean

# Reinstall dependencies
flutter pub get

# Try running again
flutter run
```

### Check Flutter Setup

```bash
# Full diagnostic
flutter doctor -v

# Check specific platform
flutter doctor --android-licenses
```

## Alternative: Running on Web (No Emulator Needed)

If you want to test quickly without an emulator:

```bash
cd /Users/bingenro/Documents/Slote/slote_app
flutter pub get
flutter run -d chrome
```

## Alternative: Running on macOS Desktop

Test directly on your Mac:

```bash
cd /Users/bingenro/Documents/Slote/slote_app
flutter pub get
flutter run -d macos
```

## Notes

- Emulators take time to boot (30-60 seconds typically)
- First launch of an emulator may take longer
- Keep the emulator window open while developing
- Use hot reload (`r`) for faster iteration during development

---

**Quick Reference Card** (Copy these commands):

```bash
# List emulators
emu-list

# Launch emulator
emu <emulator_id>

# Check devices
flutter devices

# Run app
cd /Users/bingenro/Documents/Slote/slote_app && flutter run
```
