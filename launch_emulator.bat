@echo off
REM Android Emulator Launcher Script (Batch)
REM Usage: launch_emulator.bat [emulator_name]
REM If no emulator is specified, launches Medium_Phone_API_36.1 by default

setlocal enabledelayedexpansion

REM Default emulator
set "DEFAULT_EMULATOR=Medium_Phone_API_36.1"

REM Set Android SDK environment variables (required by emulator)
if "%ANDROID_HOME%"=="" (
    REM Try common Windows locations
    if exist "%LOCALAPPDATA%\Android\Sdk" (
        set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
    ) else if exist "%USERPROFILE%\AppData\Local\Android\Sdk" (
        set "ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk"
    ) else if exist "%USERPROFILE%\Android\Sdk" (
        set "ANDROID_HOME=%USERPROFILE%\Android\Sdk"
    ) else (
        set "ANDROID_HOME=%USERPROFILE%\Android\Sdk"
    )
)

if "%ANDROID_SDK_ROOT%"=="" (
    set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
)

REM Check if emulator name is provided
if "%~1"=="" (
    echo No emulator specified. Launching default: %DEFAULT_EMULATOR%
    set "EMULATOR=%DEFAULT_EMULATOR%"
) else (
    set "EMULATOR=%~1"
)

REM Launch the specified emulator
echo Launching emulator: %EMULATOR%
echo ANDROID_HOME: %ANDROID_HOME%
echo ANDROID_SDK_ROOT: %ANDROID_SDK_ROOT%
echo.

REM Launch emulator and capture output
set "ERROR_FOUND=0"
flutter emulators --launch %EMULATOR% >nul 2>&1
set "EXIT_CODE=%ERRORLEVEL%"

REM Check for common error patterns in output (re-run to capture)
flutter emulators --launch %EMULATOR% 2>&1 | findstr /i /c:"exited with code" >nul
if %ERRORLEVEL%==0 set "ERROR_FOUND=1"

flutter emulators --launch %EMULATOR% 2>&1 | findstr /i /c:"Address these issues" >nul
if %ERRORLEVEL%==0 set "ERROR_FOUND=1"

REM If error detected, show diagnostics
if %EXIT_CODE% neq 0 set "ERROR_FOUND=1"

if %ERROR_FOUND%==1 (
    echo.
    echo === ERROR: Emulator launch failed ===
    echo.
    
    echo === Checking available emulators ===
    flutter emulators
    echo.
    
    echo === Checking Flutter doctor (Android) ===
    flutter doctor -v | findstr /i /c:"Android toolchain" /c:"Android SDK" /c:"ANDROID"
    echo.
    
    echo === Checking Android SDK setup ===
    if defined ANDROID_HOME (
        echo ANDROID_HOME: %ANDROID_HOME%
    ) else (
        echo WARNING: ANDROID_HOME is not set
    )
    
    if defined ANDROID_SDK_ROOT (
        echo ANDROID_SDK_ROOT: %ANDROID_SDK_ROOT%
    ) else (
        echo WARNING: ANDROID_SDK_ROOT is not set (required by emulator)
    )
    
    if exist "%ANDROID_HOME%\emulator\emulator.exe" (
        echo Emulator binary found: %ANDROID_HOME%\emulator\emulator.exe
    ) else (
        echo WARNING: Emulator binary NOT found at %ANDROID_HOME%\emulator\emulator.exe
    )
    echo.
    
    echo === Common Solutions ===
    echo 1. Make sure the system image is installed for your AVD
    echo 2. Check that ANDROID_HOME and ANDROID_SDK_ROOT are set correctly
    echo 3. Verify the emulator exists: flutter emulators
    echo 4. For detailed diagnostics, use: launch_emulator.ps1
    echo.
    
    echo === Checking for system image ===
    set "AVD_DIR=%USERPROFILE%\.android\avd"
    if exist "%AVD_DIR%" (
        echo AVD directory found: %AVD_DIR%
        echo.
        echo To check which system image is needed:
        echo 1. Open Android Studio
        echo 2. Tools ^> SDK Manager
        echo 3. SDK Platforms tab ^> Show Package Details
        echo 4. Install the system image matching your AVD
        echo.
        echo Or use sdkmanager to install:
        echo   sdkmanager "system-images;android-XX;google_apis_playstore;arm64-v8a"
        echo   (Replace XX with your API level)
    )
    echo.
    
    exit /b 1
) else (
    echo.
    echo Emulator launch command completed successfully
    echo Note: The emulator may take 30-60 seconds to fully boot
    echo Check status with: flutter devices
)

endlocal

