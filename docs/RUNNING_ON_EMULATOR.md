# Running Slote on Emulator - Quick Guide

## 🚀 Quick Reference (Copy These Commands)

### macOS/Linux

```bash
# 1. List available emulators
emu-list

# 2. Launch an emulator (replace <emulator_id> with actual ID)
emu <emulator_id>

# 3. Check if emulator is running
flutter devices

# 4. Navigate to app and run
cd /Users/bingenro/Documents/Slote
flutter pub get
flutter run
```

**Most Common Workflow:**

```bash
emu-list                    # See available emulators
emu Pixel_5_API_33          # Launch one (use ID from above)
cd /Users/bingenro/Documents/Slote && flutter run  # Run app
```

**One-Liner Workflow:**

```bash
emu-list && emu <emulator_id> && cd /Users/bingenro/Documents/Slote && flutter pub get && flutter run
```

### Windows

```batch
REM 1. List available emulators
flutter emulators

REM 2. Launch an emulator using the script
launch_emulator.bat

REM 3. Check if emulator is running
flutter devices

REM 4. Navigate to app and run
cd C:\path\to\Slote\slote_app
flutter pub get
flutter run
```

**Most Common Workflow:**

```batch
flutter emulators                                    REM See available emulators
launch_emulator.bat                                   REM Launch default emulator
cd C:\path\to\Slote && flutter pub get && flutter run  REM Run app
```

---

## Overview

This guide shows you how to run and test the Slote app on Android emulators using command-line tools, without needing to open Android Studio.

**Platform Support:**

- **macOS/Linux**: Use `launch_emulator.sh` (bash script)
- **Windows**: Use `launch_emulator.bat` (batch script)

## Prerequisites

- Flutter SDK installed and configured
- Android Studio installed (for creating emulators)
- Android Command Line Tools installed
- At least one Android Virtual Device (AVD) created

### Installing Android Command Line Tools

#### macOS/Linux

**Option 1: Using Homebrew (macOS only)**

```bash
brew install --cask android-commandlinetools
```

**Option 2: Direct Download**

1. Visit: https://developer.android.com/studio#command-tools
2. Download "Command line tools only" for your platform (macOS or Linux)
3. Extract and set up:
   ```bash
   mkdir -p ~/Android/Sdk/cmdline-tools
   unzip ~/Downloads/commandlinetools-*.zip -d ~/Android/Sdk/cmdline-tools
   cd ~/Android/Sdk/cmdline-tools
   mv tools latest
   ```

**Configure Environment Variables:**
Add to `~/.zshrc` (macOS) or `~/.bashrc` (Linux):

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
```

Then reload: `source ~/.zshrc` or `source ~/.bashrc`

#### Windows

**Direct Download (Recommended)**

1. Visit: https://developer.android.com/studio#command-tools
2. Download "Command line tools only" for Windows
3. Extract and set up:

   ```batch
   REM Create directory
   mkdir "%LOCALAPPDATA%\Android\Sdk\cmdline-tools"

   REM Extract (adjust path to your download location)
   REM Use built-in Windows extract or 7-Zip/WinRAR
   REM Then manually rename "tools" folder to "latest" in the extracted location
   ```

   **Or using PowerShell (if available):**

   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools"
   Expand-Archive -Path "$env:USERPROFILE\Downloads\commandlinetools-win-*.zip" -DestinationPath "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools"
   Rename-Item -Path "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\tools" -NewName "latest"
   ```

**Configure Environment Variables:**

1. Open **System Properties** → **Environment Variables**
2. Add new **User variables**:
   - `ANDROID_HOME` = `%LOCALAPPDATA%\Android\Sdk`
   - `ANDROID_SDK_ROOT` = `%LOCALAPPDATA%\Android\Sdk`
3. Edit **Path** variable and add:
   - `%ANDROID_HOME%\cmdline-tools\latest\bin`
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\emulator`

**Or via Command Prompt (temporary for current session):**

```batch
set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
set ANDROID_SDK_ROOT=%ANDROID_HOME%
set PATH=%PATH%;%ANDROID_HOME%\cmdline-tools\latest\bin
set PATH=%PATH%;%ANDROID_HOME%\platform-tools
set PATH=%PATH%;%ANDROID_HOME%\emulator
```

**Install Required SDK Components:**

```batch
REM Accept licenses (press 'y' for each)
sdkmanager --licenses

REM Install essential packages
sdkmanager "platform-tools" "platforms;android-33" "platforms;android-36" "build-tools;33.0.0" "emulator"
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
cd /Users/bingenro/Documents/Slote
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

## Helper Scripts

### macOS/Linux: `launch_emulator.sh`

Location: `/Users/bingenro/Documents/Slote/launch_emulator.sh` (or `./launch_emulator.sh` from project root)

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

### Windows: `launch_emulator.bat`

Location: `.\launch_emulator.bat` (from project root)

**Features:**

- Simple batch script that works on all Windows versions
- No execution policy issues
- Automatically detects Android SDK in common Windows locations
- Provides basic error diagnostics
- Can be run by double-clicking or from command prompt

**Usage:**

```batch
REM Launch default emulator (Medium_Phone_API_36.1)
launch_emulator.bat

REM Launch specific emulator
launch_emulator.bat Medium_Phone_API_36.1
```

**Or simply double-click the file** to launch the default emulator.

**What the Script Does:**

1. Set required Android SDK environment variables
2. Attempt to launch the emulator
3. If launch fails, provide detailed diagnostics:
   - Check for missing system images
   - Show exact `sdkmanager` command to install missing images
   - Verify Android SDK setup
   - Check PATH configuration
   - Display AVD configuration details

## Complete Workflow Example

```bash
# Step 1: List available emulators
emu-list

# Step 2: Launch an emulator (replace with actual ID from step 1)
emu Pixel_5_API_33

# Step 3: Wait for emulator to boot (check with flutter devices)
flutter devices

# Step 4: Navigate to app and install dependencies
cd /Users/bingenro/Documents/Slote
flutter pub get

# Step 5: Run the app
flutter run
```

## Useful Flutter Commands

### Hot Reload & Development (While App Running)

- **`r`** - Hot reload (apply code changes without restarting)
- **`R`** - Hot restart (full app restart)
- **`d`** - Open DevTools
- **`q`** - Quit app

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
- **Solution**:
  - **macOS/Linux**: Use `launch_emulator.sh` to detect and get the exact install command
  - **Windows**: Use `launch_emulator.bat` to detect and get the exact install command
  - Or install via `sdkmanager` directly
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

   **macOS/Linux:**

   ```bash
   cd /Users/bingenro/Documents/Slote
   ./launch_emulator.sh
   ```

   **Windows:**

   ```batch
   cd C:\path\to\Slote
   launch_emulator.bat
   ```

   The script will automatically detect the missing system image and show you the exact command to install it.

2. **Install the missing system image:**

   **macOS/Linux:**

   ```bash
   # The script will show you the exact command, typically something like:
   sdkmanager "system-images;android-36.1;google_apis_playstore;arm64-v8a"
   ```

   **Windows:**

   ```batch
   REM The script will show you the exact command, typically something like:
   sdkmanager "system-images;android-36.1;google_apis_playstore;arm64-v8a"
   ```

3. **Verify installation:**

   **macOS/Linux:**

   ```bash
   # Check that the system image directory exists
   ls -la $HOME/Android/Sdk/system-images/android-36.1/google_apis_playstore/arm64-v8a/
   ```

   **Windows:**

   ```batch
   REM Check that the system image directory exists
   dir "%LOCALAPPDATA%\Android\Sdk\system-images\android-36.1\google_apis_playstore\arm64-v8a"
   ```

4. **Launch the emulator again:**
   **macOS/Linux:**
   ```bash
   ./launch_emulator.sh
   ```
   **Windows:**
   ```batch
   launch_emulator.bat
   ```

**Prevention:**

- Always install the system image **before** creating an AVD
- When creating an AVD in Android Studio, make sure to click "Download" for the system image if it's not already installed
- Verify system images are installed: `sdkmanager --list | grep system-images`

**Environment Variables:**
The launch scripts automatically set `ANDROID_SDK_ROOT` and `ANDROID_HOME`, but for permanent setup:

**macOS/Linux:** Add to `~/.zshrc` (macOS) or `~/.bashrc` (Linux):

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
```

**Windows:** Set via System Properties → Environment Variables:

1. Open **System Properties** → **Environment Variables**
2. Add new **User variables**:
   - `ANDROID_HOME` = `%LOCALAPPDATA%\Android\Sdk`
   - `ANDROID_SDK_ROOT` = `%LOCALAPPDATA%\Android\Sdk`
3. Edit **Path** variable and add:
   - `%ANDROID_HOME%\cmdline-tools\latest\bin`
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\emulator`

**Or via Command Prompt (temporary for current session):**

```batch
set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
set ANDROID_SDK_ROOT=%ANDROID_HOME%
set PATH=%PATH%;%ANDROID_HOME%\cmdline-tools\latest\bin
set PATH=%PATH%;%ANDROID_HOME%\platform-tools
set PATH=%PATH%;%ANDROID_HOME%\emulator
```

### Windows-Specific Issues

**Android SDK Not Found:**

The `.bat` script automatically searches common Windows locations:

- `%LOCALAPPDATA%\Android\Sdk` (most common)
- `%USERPROFILE%\AppData\Local\Android\Sdk`
- `%USERPROFILE%\Android\Sdk`

If your SDK is in a different location, set the environment variable:

```batch
set ANDROID_HOME=C:\Your\Custom\Path\Android\Sdk
set ANDROID_SDK_ROOT=%ANDROID_HOME%
```

**Path Separator Issues:**

Windows uses semicolons (`;`) in PATH, not colons (`:`). The script handles this automatically, but if setting manually:

```batch
set PATH=%PATH%;%ANDROID_HOME%\cmdline-tools\latest\bin
set PATH=%PATH%;%ANDROID_HOME%\platform-tools
set PATH=%PATH%;%ANDROID_HOME%\emulator
```

**Emulator Binary Location:**

On Windows, the emulator executable is `emulator.exe` (not just `emulator`). The `.bat` script handles this automatically.

### App Won't Build

```bash
# Clean build cache
cd /Users/bingenro/Documents/Slote
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
cd /Users/bingenro/Documents/Slote
flutter pub get
flutter run -d chrome
```

## Alternative: Running on macOS Desktop

Test directly on your Mac:

```bash
cd /Users/bingenro/Documents/Slote
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
cd /Users/bingenro/Documents/Slote && flutter run
```
