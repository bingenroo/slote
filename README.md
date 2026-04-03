# Slote - Cross-Platform Note-Taking Application

A lightweight, cross-platform note-taking application that combines drawing and typing capabilities in a unified interface.

## Table of Contents

- [Repository Structure](README.md#repository-structure)
- [Getting Started](README.md#getting-started)
  - [Prerequisites](README.md#prerequisites)
  - [Setup](README.md#setup)
- [Running cmd.py (Command-Line Tool)](README.md#running-cmdpy-command-line-tool)
  - [Prerequisites](README.md#prerequisites-1)
  - [How to Run](README.md#how-to-run)
  - [Command Reference](README.md#command-reference)
  - [Bootstrap and Flutter upgrade](README.md#bootstrap-and-flutter-upgrade)
  - [Android Emulator Setup (From Scratch)](README.md#android-emulator-setup-from-scratch)
  - [Running the App](README.md#running-the-app)
  - [Troubleshooting](README.md#troubleshooting)
- [Development](README.md#development)
  - [Development process and architecture](README.md#development-process-and-architecture)
  - [Development workflow](README.md#development-workflow)
  - [Working with Components](README.md#working-with-components)
  - [Branches](README.md#branches)
- [Documentation](README.md#documentation)
- [Project Status](README.md#project-status)
- [License](README.md#license)

## Repository Structure

This is a **monorepo** containing:

- **Main Flutter application** (at repo root)
  - `lib/`, `test/`, `pubspec.yaml` – models, views, controllers
  - SQLite database (`notes.db`) for notes storage
  - Platform-specific code (Android, iOS, Web, Windows, macOS, Linux)
- `**components/**` - Reusable component packages
  - `viewport/` - Viewport/zoom/pan functionality
  - `undo_redo/` - Standalone plain-text undo demo (root app does not depend on it)
  - `rich_text/` - Rich text (AppFlowy Document JSON; used by main note editor)
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


#### Setup: run without the `python3 cmd.py` prefix

Add Slote’s `bin/` directory to your **PATH** so you can run the same commands without the prefix (e.g. `run` instead of `python3 cmd.py run`, `viewport flutter run` instead of `python3 cmd.py viewport flutter run`). This is **global shell configuration**: it applies to every new terminal you open on that machine.

**One-time (current shell only):**
```bash
cd /path/to/Slote
export PATH="$PWD/bin:$PATH"
rehash
```

**Permanent (all new terminals) — put Slote’s `bin` first so `emulator` uses the Slote shim (default AVD) instead of the Android SDK binary:**

| Platform | Config file | Add this line (use your actual Slote path) |
|----------|-------------|--------------------------------------------|
| **macOS** (zsh) | `~/.zshrc` | `export PATH="/path/to/Slote/bin:$PATH"` |
| **Linux** (bash) | `~/.bashrc` or `~/.profile` | `export PATH="/path/to/Slote/bin:$PATH"` |
| **Linux** (zsh) | `~/.zshrc` | `export PATH="/path/to/Slote/bin:$PATH"` |
| **Windows** (Git Bash / WSL) | `~/.bashrc` or `~/.bash_profile` | `export PATH="/c/path/to/Slote/bin:$PATH"` |

Then open a new terminal or run `source ~/.zshrc` (or `source ~/.bashrc`) and `rehash`. Verify with `which emulator` — it should show `.../Slote/bin/emulator`. See [bin/README.md](bin/README.md) for details.

**Windows (PowerShell / CMD):** The `bin/` scripts are Bash; use `python cmd.py ...` from the repo root, or add the repo root to your user PATH and run e.g. `python cmd.py emulator launch` from anywhere.

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

# Run a component’s example app (e.g. viewport): runs the given command in components/<name>/example
python3 cmd.py viewport flutter run
python3 cmd.py viewport flutter pub get
# With bin on PATH: viewport flutter run   or   viewport flutter pub get

# Bootstrap: upgrade Flutter SDK and run pub get in all packages
python3 cmd.py bootstrap
```

### Command Reference

All commands are run as `python3 cmd.py <command> ...` (or `./cmd.py` on macOS/Linux). If `bin/` is on your PATH, you can use the shim name without the prefix (e.g. `run`, `bootstrap`, `viewport flutter run`).

| Command | Description |
|--------|--------------|
| `cmd.py -h` | Show top-level help |
| `cmd.py bootstrap` | Run `flutter upgrade` once, then `flutter pub get` in every package directory |
| `cmd.py viewport [CMD...]` | Run command in `components/viewport/example` (default: `flutter run`). E.g. `viewport flutter pub get`. |
| `cmd.py draw [CMD...]` | Same, in `components/draw/example` |
| `cmd.py rich_text [CMD...]` | Same, in `components/rich_text/example` |
| `cmd.py undo_redo [CMD...]` | Same, in `components/undo_redo/example` |
| `cmd.py component run <name> [flutter_args...]` | Run that component’s **test** app (`flutter run` from `components/<name>/test`) |
| `cmd.py db open [mode]` | Open `notes.db` in DB Browser. Modes: `auto`, `android`, `ios`, `host`, `web` |
| `cmd.py db push` | Push `notes.db` from current dir to Android device |
| `cmd.py emulator list` | List available Android emulators |
| `cmd.py emulator launch [name]` | Launch default or named emulator |
| `cmd.py run [flutter_args...]` | Run app from repo root (`flutter run`) |
| `cmd.py test` | Run `flutter test` at repo root and in each component test app |

For subcommand help: `python3 cmd.py db -h`, `python3 cmd.py emulator -h`, `python3 cmd.py component -h`, `python3 cmd.py run -h`.

### Bootstrap and Flutter upgrade

`python3 cmd.py bootstrap` (or `./bin/bootstrap` if `bin/` is on your PATH) does two things:

1. Runs **`flutter upgrade`** once (upgrades the Flutter SDK).
2. Runs **`flutter pub get`** in the repo root and in every subdirectory that has a `pubspec.yaml`.

**If you see: "Your flutter checkout has local changes that would be erased by upgrading"**

That message refers to the **Flutter SDK directory** (where Flutter is installed), not to this Slote repo. Flutter’s own git checkout has uncommitted changes, so `flutter upgrade` refuses to run until that SDK directory is clean.

**Options:**

- **Upgrade anyway and discard SDK changes**  
  Run: `flutter upgrade --force` (once), then run `bootstrap` again. Use only if you don’t care about any local edits in the Flutter SDK folder.

- **Clean the Flutter SDK repo**  
  In the Flutter install directory, stash or commit the changes, then run `bootstrap`:
  ```bash
  cd $(dirname $(which flutter))/..
  git status
  git stash   # or commit/discard as you prefer
  ```
  Then from Slote: `python3 cmd.py bootstrap` (or `bootstrap` if `bin/` is on PATH).

You do **not** need to stash or change anything in the Slote project; the requirement is about the Flutter SDK directory being clean (or using `--force`).

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

Add to `~/.zshrc` (macOS) or `~/.bashrc` / `~/.zshrc` (Linux). So that `emulator` runs Slote’s shim (with default AVD) instead of the SDK binary, add **Slote’s `bin` before** the Android paths:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator

# Slote CLI — before Android so "emulator" uses Slote's script (default AVD)
export PATH="/path/to/Slote/bin:$PATH"
```

Use your actual Slote path. Then reload: `source ~/.zshrc` or `source ~/.bashrc`.

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

### Troubleshooting

#### `emulator launch` prints "No AVD specified"

**Symptom:** You run `emulator launch` (using the `bin/` shim) and see:

```
ERROR | No AVD specified. Use '@foo' or '-avd foo' to launch a virtual device named 'foo'
```

**Cause:** The shell is running the **Android SDK’s** `emulator` binary instead of Slote’s `bin/emulator` script. That happens when the Android SDK path is earlier in `PATH` than Slote’s `bin/` (e.g. you have `ANDROID_HOME/emulator` in PATH from setup).

**Fix:**

1. Put Slote’s `bin` **first** in PATH and refresh the shell’s command cache:
   ```bash
   cd /path/to/Slote
   export PATH="$PWD/bin:$PATH"
   rehash
   ```
2. Confirm the right command is used:
   ```bash
   which emulator
   ```
   You should see `.../Slote/bin/emulator`. Then `emulator launch` will use the default AVD (`Medium_Phone_API_36.1`).

**Permanent fix (global terminal):** Add Slote’s `bin` to the **start** of PATH in your shell config so it overrides the SDK’s `emulator` in every new terminal. Use your actual Slote path.

- **macOS (zsh):** Add to `~/.zshrc`:  
  `export PATH="/path/to/Slote/bin:$PATH"`
- **Linux (bash):** Add to `~/.bashrc` or `~/.profile`:  
  `export PATH="/path/to/Slote/bin:$PATH"`
- **Linux (zsh):** Add to `~/.zshrc`:  
  `export PATH="/path/to/Slote/bin:$PATH"`
- **Windows (Git Bash / WSL):** Add to `~/.bashrc`:  
  `export PATH="/c/path/to/Slote/bin:$PATH"`

Then open a new terminal or run `source ~/.zshrc` (or `source ~/.bashrc`) and run `rehash`. On Windows PowerShell/CMD, use `python cmd.py emulator launch` from the repo root instead of the `emulator` shim.

**Without changing PATH:** From the Slote repo root you can always run:

```bash
./bin/emulator launch
```

See also [bin/README.md](bin/README.md) for the full `bin/` shim setup.

## Development

### Development process and architecture

This section explains how the app starts, what calls what, and how components are included when you run the app.

#### Two ways to run

1. **Full Slote app** (project root) – The real product: notes, drawing, viewport, undo/redo, etc.
2. **Example apps** (one per component) – Small demos to try a single component without the rest of the app.

#### Running the full app from the project root

When you run from the repo root:

```bash
flutter run
# or: python3 cmd.py run
```

Flutter uses **`lib/main.dart`** at the root as the entry point.

**What runs, in order:**

1. **`lib/main.dart`** – Starts the app, initializes theme preferences (using the **theme** component), then builds the main `App` widget from **`lib/src/app.dart`**.
2. **`lib/src/app.dart`** – Builds the real UI: navigation, screens, theming. It uses the **theme** and **shared** components.
3. When you open or edit a note, **`lib/src/views/create_note.dart`** runs. It uses **`rich_text`** (AppFlowy editor, `RichTextEditorController`, format toolbar) plus **theme** and **shared** as needed.

So the flow is: **root `main.dart`** → **app.dart** → your views; each view imports the packages it needs. Root `main.dart` does not wire every component directly.

**How components are included:**

- In the root **`pubspec.yaml`**, components are listed as `path: components/...` dependencies (e.g. **rich_text**, **draw**, **theme**, **shared**, **viewport**).
- When you run `flutter run` or `flutter pub get`, Flutter **links** those local folders as packages.
- Any file that `import`s `package:rich_text/...` (or theme, shared, etc.) is **using** that component. **Each screen imports only what it needs.**

#### Running a single-component example

To work on or try one component in isolation:

```bash
# From repo root: run a command in that component’s example dir (no cd needed)
python3 cmd.py viewport flutter run
python3 cmd.py viewport flutter pub get
# With bin on PATH: viewport flutter run
```

Or manually:

```bash
cd components/viewport/example   # or draw, rich_text, undo_redo
flutter pub get
flutter run
```

Flutter then uses **`components/viewport/example/lib/main.dart`** (not the root `lib/main.dart`). That file builds a small app that only uses the **viewport** package. No notes, no full app – just the viewport demo. Same idea for draw, rich_text, and undo_redo: each has an **`example/`** folder with its own **`lib/main.dart`** that uses only that component.

#### Call flow (plain words)

**Full app (from root):**

- **Root `lib/main.dart`** → starts the app, uses **theme** → builds **`lib/src/app.dart`**
- **`lib/src/app.dart`** → uses **theme** and **shared**, shows your screens
- **Screens** (e.g. `create_note`) → use **rich_text**, **theme**, **shared** (and other components where imported)

**Viewport example:**

- **`components/viewport/example/lib/main.dart`** → builds one screen that uses **viewport** only.

So: root **main.dart** does not call the components directly; it calls **app.dart**, and **app.dart** and the **view files** call the components. To “include” components when you run the root app, they are (1) listed in the root **pubspec.yaml** and (2) imported in the screens that need them (and in app.dart for theme/shared). No extra step is needed in root **main.dart**.

### Development workflow

For a single place that describes day-to-day flow (setup, running the app or a component, before merging), see **[docs/DEV_WORKFLOW.md](docs/DEV_WORKFLOW.md)**.

### Working with Components

Components are developed independently but used by the main app via path dependencies:

```yaml
# pubspec.yaml (at repo root)
dependencies:
  viewport:
    path: components/viewport
  rich_text:
    path: components/rich_text
  draw:
    path: components/draw
  theme:
    path: components/theme
  shared:
    path: components/shared
```

Each component can be tried in isolation via its **example** app (e.g. `components/viewport/example`). See [components/README.md](components/README.md) and [COMPONENT_TEST_PLATFORMS.md](components/COMPONENT_TEST_PLATFORMS.md).

### Branches

- `main` - Main development branch
- `noobee` - Feature branch
- `the_bird` - Feature branch

## Documentation

- [Development workflow](docs/DEV_WORKFLOW.md) – day-to-day setup, run, test, and before-merge steps
- [Product Requirements Document (PRD)](PRD.md)
- [Slote Components](components/README.md) – packages and component test apps
- [Component Example Apps](components/COMPONENT_TEST_PLATFORMS.md)
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