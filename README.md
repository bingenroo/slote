# Slote - Cross-Platform Note-Taking Application

A lightweight, cross-platform note-taking application that combines drawing and typing capabilities in a unified interface.

## Repository Structure

This is a **monorepo** containing:

- **`slote_app/`** - Main Flutter application

  - Models, views, controllers
  - HiveDB services
  - Platform-specific code (Android, iOS, Web, Windows, macOS, Linux)

- **`slote_components/`** - Reusable component packages
  - `slote_viewport/` - Viewport/zoom/pan functionality
  - `slote_undo_redo/` - Undo/redo system
  - `slote_rich_text/` - Rich text editing (Word-style)
  - `slote_draw/` - Custom drawing implementation
  - `slote_theme/` - Theming system
  - `slote_shared/` - Shared utilities and resources

## Getting Started

### Prerequisites

- Flutter SDK 3.7.2+
- Git
- Android Studio (for Android development)
- Android Command Line Tools (for command-line emulator management)

### Setup

```bash
# Clone the repository
git clone https://github.com/bingenroo/slote.git
cd slote

# Install dependencies for the main app
cd slote_app
flutter pub get

# Install dependencies for components (if developing components)
cd ../slote_components/slote_viewport
flutter pub get
# Repeat for other components as needed
```

### Android Emulator Setup (From Scratch)

To run the app on Android emulators using the `launch_emulator.sh` script, you need to set up Android Command Line Tools and create an emulator.

#### Step 1: Install Android Command Line Tools

**macOS/Linux:**

**Option 1: Using Homebrew (macOS only)**

```bash
brew install --cask android-commandlinetools
```

**Option 2: Direct Download**

1. Visit: https://developer.android.com/studio#command-tools
2. Download "Command line tools only" for your platform
3. Extract and set up:
   ```bash
   mkdir -p ~/Android/Sdk/cmdline-tools
   unzip ~/Downloads/commandlinetools-*.zip -d ~/Android/Sdk/cmdline-tools
   cd ~/Android/Sdk/cmdline-tools
   mv tools latest
   ```

**Windows:**

1. Visit: https://developer.android.com/studio#command-tools
2. Download "Command line tools only" for Windows
3. Extract and set up:
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools"
   Expand-Archive -Path "$env:USERPROFILE\Downloads\commandlinetools-win-*.zip" -DestinationPath "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools"
   Rename-Item -Path "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\tools" -NewName "latest"
   ```

#### Step 2: Configure Environment Variables

**macOS/Linux:**

Add to `~/.zshrc` (macOS) or `~/.bashrc` (Linux):

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
```

Then reload: `source ~/.zshrc` or `source ~/.bashrc`

**Windows:**

1. Open **System Properties** → **Environment Variables**
2. Add new **User variables**:
   - `ANDROID_HOME` = `%LOCALAPPDATA%\Android\Sdk`
   - `ANDROID_SDK_ROOT` = `%LOCALAPPDATA%\Android\Sdk`
3. Edit **Path** variable and add:
   - `%ANDROID_HOME%\cmdline-tools\latest\bin`
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\emulator`

#### Step 3: Install Required SDK Components

**macOS/Linux:**

```bash
# Accept licenses (press 'y' for each)
sdkmanager --licenses

# Install essential packages
sdkmanager "platform-tools" "platforms;android-33" "platforms;android-36" "build-tools;33.0.0" "emulator"
```

**Windows:**

```batch
REM Accept licenses (press 'y' for each)
sdkmanager --licenses

REM Install essential packages
sdkmanager "platform-tools" "platforms;android-33" "platforms;android-36" "build-tools;33.0.0" "emulator"
```

#### Step 4: Create Your First Android Virtual Device (AVD)

**Important:** Install the system image **before** creating the AVD to avoid launch failures.

**Using Android Studio (Recommended):**

1. Open Android Studio
2. Go to: **Tools → Device Manager** (or **More Actions → Virtual Device Manager**)
3. Click: **"Create Device"** button
4. Select a device: Choose any device (e.g., Pixel 5, Pixel 6)
5. Select system image:
   - Choose an API level (recommended: API 33, 34, or 36)
   - **CRITICAL**: Click **"Download"** if the system image isn't installed
   - Wait for download to complete before proceeding
6. Finish setup: Click **"Next"** → **"Finish"**
7. Close Android Studio (you don't need it running to use the emulator)

**Using Command Line:**

```bash
# Install system image first
sdkmanager "system-images;android-36;google_apis_playstore;arm64-v8a"

# Create AVD
avdmanager create avd -n Medium_Phone_API_36.1 -k "system-images;android-36;google_apis_playstore;arm64-v8a" -d "pixel_5"
```

#### Step 5: Verify Setup

```bash
# List available emulators
flutter emulators

# Or use the launch script to check
cd /Users/bingenro/Documents/Slote
./launch_emulator.sh
```

You should see your emulator listed!

### Running the App

#### Using the Launch Script (Recommended)

**macOS/Linux:**

```bash
# Navigate to project root
cd /Users/bingenro/Documents/Slote

# Launch default emulator (Medium_Phone_API_36.1)
./launch_emulator.sh

# Or launch a specific emulator
./launch_emulator.sh <emulator_id>

# Wait for emulator to boot, then run the app
cd slote_app
flutter pub get
flutter run
```

**Windows:**

```batch
REM Navigate to project root
cd C:\path\to\Slote

REM Launch default emulator
launch_emulator.bat

REM Or launch a specific emulator
launch_emulator.bat Medium_Phone_API_36.1

REM Wait for emulator to boot, then run the app
cd slote_app
flutter pub get
flutter run
```

#### Direct Flutter Commands

```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>

# Check connected devices
flutter devices

# Run the app
cd slote_app
flutter pub get
flutter run
```

**Note:** The `launch_emulator.sh` script provides better error diagnostics and automatically handles environment variables. See `slote_app/docs/RUNNING_ON_EMULATOR.md` for detailed troubleshooting.

## Development

### Working with Components

Components are developed independently but used by the main app via path dependencies:

```yaml
# slote_app/pubspec.yaml
dependencies:
  slote_viewport:
    path: ../slote_components/slote_viewport
```

### Branches

- `main` - Main development branch
- `noobee` - Feature branch
- `the_bird` - Feature branch

## Documentation

- [Product Requirements Document (PRD)](slote_app/PRD.md)
- [Running on Emulator Guide](slote_app/docs/RUNNING_ON_EMULATOR.md) - Detailed Android emulator setup and troubleshooting
- [Repository Restructure Plan](slote_app/docs/REPOSITORY_RESTRUCTURE_PLAN.md)
- [Concurrent Development Guide](slote_app/docs/CONCURRENT_DEVELOPMENT_GUIDE.md)
- [Cross-Platform Testing Plan](slote_app/docs/CROSS_PLATFORM_TESTING_PLAN.md)
- [Hive Browser Plan](slote_app/docs/HIVE_BROWSER_PLAN.md)

## Project Status

This project is in active development. See the [PRD](slote_app/PRD.md) for feature roadmap and priorities.

## License

[Add your license here]

---

**Note**: This repository was restructured into a monorepo format while preserving all git history. All branches and commit history from the original `slote_app` repository are maintained.
