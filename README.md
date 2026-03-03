# Slote - Cross-Platform Note-Taking Application

A lightweight, cross-platform note-taking application that combines drawing and typing capabilities in a unified interface.

## Repository Structure

This is a **monorepo** containing:

- **Main Flutter application** (at repo root)
  - `lib/`, `test/`, `pubspec.yaml` – models, views, controllers
  - SQLite database (`notes.db`) for notes storage
  - Platform-specific code (Android, iOS, Web, Windows, macOS, Linux)
- `**components/**` - Reusable component packages
  - `viewport/` - Viewport/zoom/pan functionality
  - `undo_redo/` - Undo/redo system
  - `rich_text/` - Rich text editing (Word-style)
  - `draw/` - Custom drawing implementation
  - `theme/` - Theming system
  - `shared/` - Shared utilities and resources
- `**cmd.py**` (project root) - Unified command-line tool for emulator, database, and running the app (see below).

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

# Install dependencies for the main app (from repo root)
flutter pub get

# Install dependencies for components (if developing components)
cd components/viewport
flutter pub get
# Repeat for other components as needed
```

## Running cmd.py (Command-Line Tool)

The project includes a Python script `**cmd.py**` at the repository root for emulator management, database operations, and running the Flutter app. Use it from the **project root** (`Slote/`).

### Prerequisites

- **Python 3** (no extra packages required; uses only the standard library)
- **Flutter** in `PATH` (for `emulator` and `run` commands)
- For **database** commands: [DB Browser for SQLite](https://sqlitebrowser.org/) (optional but recommended for `db open`)

### How to Run

From the repository root:


| Platform      | Command                        |
| ------------- | ------------------------------ |
| macOS / Linux | `python3 cmd.py` or `./cmd.py` |
| Windows       | `python cmd.py`                |


**Examples:**

```bash
# From project root (e.g. /Users/you/Documents/Slote)
cd /path/to/Slote

# Show all commands
python3 cmd.py -h

# Emulator: list and launch
python3 cmd.py emulator list
python3 cmd.py emulator launch
python3 cmd.py emulator launch "Medium_Phone_API_36.1"

# Database: open in DB Browser (auto-detects Android / host / iOS)
python3 cmd.py db open
python3 cmd.py db open android
python3 cmd.py db open ios
python3 cmd.py db open host

# Push local notes.db to Android device
python3 cmd.py db push

# Run the Flutter app (runs from repo root with flutter run)
python3 cmd.py run
python3 cmd.py run --device-id chrome   # pass through to flutter run
```

### Command Reference


| Command                         | Description                                                                   |
| ------------------------------- | ----------------------------------------------------------------------------- |
| `cmd.py -h`                     | Show top-level help                                                           |
| `cmd.py db open [mode]`         | Open `notes.db` in DB Browser. Modes: `auto`, `android`, `ios`, `host`, `web` |
| `cmd.py db push`                | Push `notes.db` from current dir to Android device                            |
| `cmd.py emulator list`          | List available Android emulators                                              |
| `cmd.py emulator launch [name]` | Launch default or named emulator                                              |
| `cmd.py run [flutter_args...]`  | Run app from repo root (e.g. `flutter run`)                                 |


For subcommand help: `python3 cmd.py db -h`, `python3 cmd.py emulator -h`, `python3 cmd.py run -h`.

### Android Emulator Setup (From Scratch)

To run the app on Android emulators using the unified command tool (`cmd.py`), you need to set up Android Command Line Tools and create an emulator.

#### Step 1: Install Android Command Line Tools

**macOS/Linux:**

**Option 1: Using Homebrew (macOS only)**

```bash
brew install --cask android-commandlinetools
```

**Option 2: Direct Download**

1. Visit: [https://developer.android.com/studio#command-tools](https://developer.android.com/studio#command-tools)
2. Download "Command line tools only" for your platform
3. Extract and set up:
  ```bash
   mkdir -p ~/Android/Sdk/cmdline-tools
   unzip ~/Downloads/commandlinetools-*.zip -d ~/Android/Sdk/cmdline-tools
   cd ~/Android/Sdk/cmdline-tools
   mv tools latest
  ```

**Windows:**

1. Visit: [https://developer.android.com/studio#command-tools](https://developer.android.com/studio#command-tools)
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
python3 cmd.py emulator list

# Or use Flutter directly
flutter emulators
```

You should see your emulator listed!

### Running the App

Use the command-line tool from the project root (see [Running cmd.py](#running-cmdpy-command-line-tool) above):

```bash
# Launch emulator, then run the app
python3 cmd.py emulator launch
python3 cmd.py run
```

Or use Flutter directly:

```bash
flutter emulators --launch <emulator_id>   # optional
flutter pub get
flutter run
```

**Note:** `cmd.py run` runs `flutter run` from the repo root for you. The `cmd.py` tool provides better error diagnostics and sets Android env vars for emulator launch. See [docs/RUNNING_ON_EMULATOR.md](docs/RUNNING_ON_EMULATOR.md) for troubleshooting.

## Development

### Development workflow

For a single place that describes day-to-day flow (setup, running the app or a component, before merging), see **[docs/DEV_WORKFLOW.md](docs/DEV_WORKFLOW.md)**.

### Working with Components

Components are developed independently but used by the main app via path dependencies:

```yaml
# pubspec.yaml (at repo root)
dependencies:
  slote_viewport:
    path: components/viewport
```

Each component can be tested in isolation via its `test/` app (e.g. `components/viewport/test`). See [components/README.md](components/README.md) and [COMPONENT_TEST_PLATFORMS.md](components/COMPONENT_TEST_PLATFORMS.md).

### Branches

- `main` - Main development branch
- `noobee` - Feature branch
- `the_bird` - Feature branch

## Documentation

- [Development workflow](docs/DEV_WORKFLOW.md) – day-to-day setup, run, test, and before-merge steps
- [Product Requirements Document (PRD)](PRD.md)
- [Slote Components](components/README.md) – packages and component test apps
- [Component Test Platforms](components/COMPONENT_TEST_PLATFORMS.md)
- [Running on Emulator Guide](docs/RUNNING_ON_EMULATOR.md) – Android emulator setup and troubleshooting
- [Repository Restructure Plan](docs/REPOSITORY_RESTRUCTURE_PLAN.md)
- [Concurrent Development Guide](docs/CONCURRENT_DEVELOPMENT_GUIDE.md)
- [Cross-Platform Testing Plan](docs/CROSS_PLATFORM_TESTING_PLAN.md)

## Project Status

This project is in active development. See the [PRD](PRD.md) for feature roadmap and priorities.

## License

[Add your license here]

---

**Note**: This repository was restructured into a monorepo format while preserving all git history. The main app now lives at repo root; all branches and commit history from the original app repository are maintained.