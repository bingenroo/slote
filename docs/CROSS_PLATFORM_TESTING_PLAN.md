# Cross-Platform Testing Plan

## Overview

This document provides a comprehensive guide for testing Slote across all target platforms: Android, iOS, Web, Windows, macOS, and Linux. It includes setup instructions, emulator/simulator configuration, and testing procedures.

## Prerequisites

### Universal Requirements
- **Flutter SDK**: Latest stable version (3.7.2+)
- **Git**: For version control
- **IDE**: VS Code or Android Studio (recommended)

### Verify Flutter Installation
```bash
flutter doctor -v
```

This will show what platforms are available and what's missing.

---

## Platform-Specific Setup

## 1. Android (Already Set Up)

### Current Status
✅ You're already developing for Android

### Setup Verification
```bash
# Check Android setup
flutter doctor

# List available Android emulators
flutter emulators

# List connected devices
flutter devices
```

### Running on Android
```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in release mode
flutter run --release
```

### Android Emulator Setup (If Needed)
```bash
# Open Android Studio
# Tools > Device Manager
# Create Virtual Device
# Select device (e.g., Pixel 5)
# Select system image (e.g., API 33)
# Finish and start emulator
```

### Testing Checklist - Android
- [ ] App launches successfully
- [ ] Create note functionality
- [ ] Drawing works with touch/stylus
- [ ] Text input works
- [ ] Undo/redo works
- [ ] Save/load notes
- [ ] Theme switching
- [ ] Navigation works
- [ ] Performance is smooth (60 FPS)
- [ ] Test on different screen sizes
- [ ] Test on different Android versions (API 26+)

---

## 2. iOS

### Prerequisites
- **macOS**: Required (iOS development only works on Mac)
- **Xcode**: Latest version from App Store
- **Xcode Command Line Tools**
- **CocoaPods**: For iOS dependencies

### Initial Setup

#### Step 1: Install Xcode
```bash
# Install from App Store or:
xcode-select --install
```

#### Step 2: Install CocoaPods
```bash
sudo gem install cocoapods
```

#### Step 3: Setup iOS Dependencies
```bash
cd ios
pod install
cd ..
```

#### Step 4: Verify iOS Setup
```bash
flutter doctor
# Should show iOS toolchain as available
```

### iOS Simulator Setup

#### Option A: Using Xcode
1. Open Xcode
2. **Xcode > Open Developer Tool > Simulator**
3. **File > New Simulator**
4. Choose device (e.g., iPhone 15 Pro)
5. Choose iOS version (e.g., iOS 17.0)
6. Click **Create**

#### Option B: Using Command Line
```bash
# List available simulators
xcrun simctl list devices

# Boot a specific simulator
xcrun simctl boot "iPhone 15 Pro"

# Open Simulator app
open -a Simulator
```

#### Option C: Using Flutter
```bash
# List available iOS simulators
flutter emulators

# Launch specific simulator
flutter emulators --launch apple_ios_simulator

# Or launch by name
open -a Simulator --args -CurrentDeviceUDID <UDID>
```

### Running on iOS

#### Method 1: Flutter CLI
```bash
# Run on iOS simulator
flutter run -d ios

# Run on specific simulator
flutter run -d <simulator-id>

# List available devices
flutter devices
```

#### Method 2: Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select simulator from device dropdown
3. Click **Run** button (▶️)

### Common iOS Issues & Solutions

#### Issue: "No devices found"
```bash
# Solution: Boot a simulator first
open -a Simulator
# Then run: flutter run
```

#### Issue: "CocoaPods not installed"
```bash
# Solution:
sudo gem install cocoapods
cd ios && pod install && cd ..
```

#### Issue: "Signing for Runner requires a development team"
- Open `ios/Runner.xcodeproj` in Xcode
- Select **Runner** in project navigator
- Go to **Signing & Capabilities**
- Select your **Team** (Apple ID)
- Or enable **Automatically manage signing**

#### Issue: "Build failed"
```bash
# Clean and rebuild
flutter clean
cd ios && pod deintegrate && pod install && cd ..
flutter pub get
flutter run
```

### Testing Checklist - iOS
- [ ] App launches successfully
- [ ] Create note functionality
- [ ] Drawing works with touch/stylus
- [ ] Text input works
- [ ] Undo/redo works
- [ ] Save/load notes
- [ ] Theme switching
- [ ] Navigation works
- [ ] Test on iPhone (different sizes)
- [ ] Test on iPad
- [ ] Test on different iOS versions (iOS 14+)
- [ ] Test with different orientations
- [ ] Test with keyboard (external keyboard)

---

## 3. Web

### Prerequisites
- **Chrome/Edge**: For testing (recommended)
- **Firefox/Safari**: For cross-browser testing
- **Web Server**: Optional (Flutter web can run without)

### Enable Web Support
```bash
# Enable web support (if not already enabled)
flutter config --enable-web

# Verify web support
flutter doctor
```

### Running on Web

#### Method 1: Flutter CLI (Recommended)
```bash
# Run on Chrome (default)
flutter run -d chrome

# Run on specific browser
flutter run -d chrome
flutter run -d edge
flutter run -d firefox
flutter run -d safari  # macOS only

# Run in release mode
flutter run -d chrome --release

# Build for web
flutter build web
```

#### Method 2: Using Local Server
```bash
# Build web app
flutter build web

# Serve using Python (if installed)
cd build/web
python3 -m http.server 8000
# Open http://localhost:8000

# Or use any static file server
```

### Web Browser Setup

#### Chrome/Edge
- No setup needed, just run `flutter run -d chrome`

#### Firefox
```bash
# Install Firefox if not installed
# Then run:
flutter run -d firefox
```

#### Safari (macOS)
```bash
# Enable Safari WebDriver (for automated testing)
# Safari > Preferences > Advanced > Show Develop menu
# Develop > Allow Remote Automation

# Run:
flutter run -d safari
```

### Web-Specific Considerations

#### Performance
- Web performance may differ from native
- Test drawing performance (may be slower)
- Test with different screen sizes

#### Limitations
- File system access is limited
- Some plugins may not work on web
- Hive database may need web-specific configuration

### Testing Checklist - Web
- [ ] App loads in browser
- [ ] Create note functionality
- [ ] Drawing works with mouse/touch
- [ ] Text input works
- [ ] Undo/redo works
- [ ] Save/load notes (check browser storage)
- [ ] Theme switching
- [ ] Navigation works
- [ ] Test on Chrome
- [ ] Test on Firefox
- [ ] Test on Safari (if macOS)
- [ ] Test on Edge
- [ ] Test responsive design (mobile/tablet/desktop)
- [ ] Test with different screen sizes
- [ ] Test keyboard shortcuts
- [ ] Test touch gestures (on touchscreen devices)
- [ ] Check browser console for errors

---

## 4. Windows

### Prerequisites
- **Windows 10/11**: Required
- **Visual Studio 2022**: With "Desktop development with C++" workload
- **Windows SDK**: Latest version
- **CMake**: Usually included with Visual Studio

### Initial Setup

#### Step 1: Install Visual Studio 2022
1. Download from [visualstudio.microsoft.com](https://visualstudio.microsoft.com/)
2. Install with these workloads:
   - **Desktop development with C++**
   - **Windows 10/11 SDK** (latest version)
   - **CMake tools for Windows**

#### Step 2: Verify Windows Setup
```bash
flutter doctor
# Should show Windows toolchain as available
```

#### Step 3: Enable Windows Support
```bash
# Windows support is usually enabled by default
# Verify:
flutter config --enable-windows-desktop
```

### Running on Windows

#### Method 1: Flutter CLI
```bash
# Run on Windows
flutter run -d windows

# Run in release mode
flutter run -d windows --release

# Build Windows app
flutter build windows
```

#### Method 2: Visual Studio
1. Open `windows/runner/Runner.sln` in Visual Studio
2. Select **Debug** or **Release** configuration
3. Click **Run** (F5)

### Windows-Specific Considerations

#### Architecture Support
- **x64**: Default (64-bit)
- **x86**: 32-bit (if needed)
- **ARM64**: Windows on ARM (if available)

```bash
# Build for specific architecture
flutter build windows --target-platform windows-x64
flutter build windows --target-platform windows-x86
flutter build windows --target-platform windows-arm64
```

### Common Windows Issues & Solutions

#### Issue: "Visual Studio not found"
```bash
# Solution: Install Visual Studio 2022 with C++ workload
# Or set environment variable:
set VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community
```

#### Issue: "CMake not found"
```bash
# Solution: Install CMake or use Visual Studio's CMake
# Add to PATH or install separately
```

#### Issue: "Build failed"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d windows
```

### Testing Checklist - Windows
- [ ] App launches successfully
- [ ] Create note functionality
- [ ] Drawing works with mouse/stylus
- [ ] Text input works
- [ ] Keyboard shortcuts work
- [ ] Undo/redo works
- [ ] Save/load notes
- [ ] Theme switching
- [ ] Navigation works
- [ ] Test on Windows 10
- [ ] Test on Windows 11
- [ ] Test with different screen resolutions
- [ ] Test with different DPI settings
- [ ] Test window resizing
- [ ] Test fullscreen mode

---

## 5. macOS

### Prerequisites
- **macOS**: Required (macOS 11+)
- **Xcode**: Latest version
- **CocoaPods**: For macOS dependencies

### Initial Setup

#### Step 1: Install Xcode
```bash
# Install from App Store
# Or verify installation:
xcode-select --install
```

#### Step 2: Install CocoaPods
```bash
sudo gem install cocoapods
```

#### Step 3: Setup macOS Dependencies
```bash
cd macos
pod install
cd ..
```

#### Step 4: Verify macOS Setup
```bash
flutter doctor
# Should show macOS toolchain as available
```

### Running on macOS

#### Method 1: Flutter CLI
```bash
# Run on macOS
flutter run -d macos

# Run in release mode
flutter run -d macos --release

# Build macOS app
flutter build macos
```

#### Method 2: Xcode
1. Open `macos/Runner.xcworkspace` in Xcode
2. Select **My Mac** as target
3. Click **Run** button (▶️)

### macOS-Specific Considerations

#### Architecture Support
- **x64**: Intel Macs
- **ARM64**: Apple Silicon (M1/M2/M3)

```bash
# Build for specific architecture
flutter build macos --target-platform darwin-x64
flutter build macos --target-platform darwin-arm64
```

#### Code Signing
- For distribution, you'll need Apple Developer account
- For development, use "Sign to Run Locally"

### Common macOS Issues & Solutions

#### Issue: "CocoaPods not installed"
```bash
# Solution:
sudo gem install cocoapods
cd macos && pod install && cd ..
```

#### Issue: "Code signing required"
- Open Xcode project
- Go to **Signing & Capabilities**
- Select **Sign to Run Locally** (for development)

### Testing Checklist - macOS
- [ ] App launches successfully
- [ ] Create note functionality
- [ ] Drawing works with trackpad/stylus
- [ ] Text input works
- [ ] Keyboard shortcuts work (Cmd+...)
- [ ] Undo/redo works
- [ ] Save/load notes
- [ ] Theme switching
- [ ] Navigation works
- [ ] Test on Intel Mac
- [ ] Test on Apple Silicon (M1/M2/M3)
- [ ] Test with different screen sizes
- [ ] Test window management
- [ ] Test menu bar integration
- [ ] Test with external displays

---

## 6. Linux

### Prerequisites
- **Linux**: Ubuntu, Fedora, or other supported distribution
- **Development Tools**: Build essentials
- **GTK Development Libraries**: For GUI
- **CMake**: Build system

### Initial Setup

#### Step 1: Install Dependencies (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libstdc++-12-dev
```

#### Step 2: Install Dependencies (Fedora)
```bash
sudo dnf install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  gtk3-devel \
  lzma-devel
```

#### Step 3: Verify Linux Setup
```bash
flutter doctor
# Should show Linux toolchain as available
```

### Running on Linux

#### Method 1: Flutter CLI
```bash
# Run on Linux
flutter run -d linux

# Run in release mode
flutter run -d linux --release

# Build Linux app
flutter build linux
```

#### Method 2: Direct Execution
```bash
# After building:
cd build/linux/x64/release/bundle
./slote
```

### Linux-Specific Considerations

#### Desktop Environment
- Works with GNOME, KDE, XFCE, etc.
- May need different configurations for different DEs

#### Architecture Support
- **x64**: Most common
- **ARM64**: For ARM-based Linux systems

```bash
# Build for specific architecture
flutter build linux --target-platform linux-x64
flutter build linux --target-platform linux-arm64
```

### Common Linux Issues & Solutions

#### Issue: "GTK not found"
```bash
# Solution: Install GTK development libraries
sudo apt-get install libgtk-3-dev  # Ubuntu/Debian
sudo dnf install gtk3-devel        # Fedora
```

#### Issue: "CMake not found"
```bash
# Solution:
sudo apt-get install cmake  # Ubuntu/Debian
sudo dnf install cmake      # Fedora
```

#### Issue: "Build failed"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d linux
```

### Testing Checklist - Linux
- [ ] App launches successfully
- [ ] Create note functionality
- [ ] Drawing works with mouse/stylus
- [ ] Text input works
- [ ] Keyboard shortcuts work
- [ ] Undo/redo works
- [ ] Save/load notes
- [ ] Theme switching
- [ ] Navigation works
- [ ] Test on Ubuntu
- [ ] Test on Fedora
- [ ] Test on other distributions
- [ ] Test with different desktop environments
- [ ] Test with different screen resolutions
- [ ] Test window management

---

## Testing Strategy

### 1. Daily Testing
- Test on primary platform (Android) during development
- Run on other platforms before committing major changes

### 2. Weekly Testing
- Full test suite on all platforms
- Check for platform-specific issues
- Verify new features work across platforms

### 3. Pre-Release Testing
- Comprehensive testing on all platforms
- Performance testing
- UI/UX consistency check
- Platform-specific feature testing

### 4. Automated Testing
```bash
# Run all tests
flutter test

# Test on multiple devices (if available)
flutter test --device-id=<device1>
flutter test --device-id=<device2>
```

## Quick Reference Commands

### Check Available Devices
```bash
flutter devices
```

### List Emulators
```bash
flutter emulators
```

### Run on Specific Platform
```bash
flutter run -d android
flutter run -d ios
flutter run -d chrome
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

### Build for Platform
```bash
flutter build apk          # Android APK
flutter build ios           # iOS (requires Mac)
flutter build web           # Web
flutter build windows      # Windows
flutter build macos         # macOS (requires Mac)
flutter build linux        # Linux
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

## Platform-Specific Testing Matrix

| Feature | Android | iOS | Web | Windows | macOS | Linux |
|--------|---------|-----|-----|---------|-------|--------|
| App Launch | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create Note | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Drawing | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Text Input | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Undo/Redo | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Save/Load | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Theme | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Navigation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Keyboard Shortcuts | ⚠️ | ⚠️ | ✅ | ✅ | ✅ | ✅ |
| Touch Gestures | ✅ | ✅ | ⚠️ | ❌ | ⚠️ | ❌ |
| Stylus Support | ✅ | ✅ | ❌ | ✅ | ✅ | ⚠️ |
| File System | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ |

Legend:
- ✅ Fully supported
- ⚠️ Partially supported / Limited
- ❌ Not supported

## Common Cross-Platform Issues

### Issue: Platform-Specific Code
**Solution**: Use platform checks:
```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

if (Platform.isAndroid) {
  // Android-specific code
} else if (Platform.isIOS) {
  // iOS-specific code
} else if (kIsWeb) {
  // Web-specific code
}
```

### Issue: Different File Paths
**Solution**: Use `path_provider` package (already in dependencies):
```dart
import 'package:path_provider/path_provider.dart';

final directory = await getApplicationDocumentsDirectory();
final path = '${directory.path}/notes.db';
```

### Issue: Different UI Behaviors
**Solution**: Test UI on all platforms and adjust as needed:
- Mobile: Touch gestures
- Desktop: Mouse/keyboard interactions
- Web: Browser-specific behaviors

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Cross-Platform Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test
      - run: flutter build apk
      - run: flutter build web
      - run: flutter build linux
```

## Resources

- [Flutter Platform Support](https://docs.flutter.dev/deployment)
- [Flutter Device Setup](https://docs.flutter.dev/get-started/install)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)

---

*Keep this document updated as you discover platform-specific issues and solutions.*

