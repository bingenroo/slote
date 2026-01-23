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

REM Export environment variables to child processes
set "ANDROID_HOME=%ANDROID_HOME%"
set "ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT%"

REM Check if emulator name is provided
if "%~1"=="" (
    echo No emulator specified. Launching default: %DEFAULT_EMULATOR%
    set "EMULATOR=%DEFAULT_EMULATOR%"
) else (
    set "EMULATOR=%~1"
)

REM Check if Flutter is available
where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Flutter is not in your PATH
    echo Please ensure Flutter is installed and added to your PATH
    echo.
    exit /b 1
)

REM Launch the specified emulator
echo Launching emulator: %EMULATOR%
echo ANDROID_HOME: %ANDROID_HOME%
echo ANDROID_SDK_ROOT: %ANDROID_SDK_ROOT%
echo.

REM Launch emulator and capture output
set "ERROR_FOUND=0"
echo === Flutter Command Output ===
set "TEMP_OUTPUT=%TEMP%\flutter_emulator_output.txt"

REM Ensure environment variables are set for this session
set "ANDROID_HOME=%ANDROID_HOME%"
set "ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT%"

REM Run flutter command and capture output
flutter emulators --launch "%EMULATOR%" > "%TEMP_OUTPUT%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"

REM Display the output
type "%TEMP_OUTPUT%"
echo.

REM Check for common error patterns in output
findstr /i /c:"exited with code" "%TEMP_OUTPUT%" >nul 2>&1
if %ERRORLEVEL%==0 set "ERROR_FOUND=1"

findstr /i /c:"Address these issues" "%TEMP_OUTPUT%" >nul 2>&1
if %ERRORLEVEL%==0 set "ERROR_FOUND=1"

findstr /i /c:"error" "%TEMP_OUTPUT%" >nul 2>&1
if %ERRORLEVEL%==0 set "ERROR_FOUND=1"

REM If error detected, show diagnostics
if %EXIT_CODE% neq 0 set "ERROR_FOUND=1"

REM Clean up temp file
del "%TEMP_OUTPUT%" >nul 2>&1

if %ERROR_FOUND%==1 (
    echo.
    echo === ERROR: Flutter emulator launch failed ===
    echo.
    echo === Attempting direct emulator launch as fallback ===
    if exist "%ANDROID_HOME%\emulator\emulator.exe" (
        REM Get AVD name (replace spaces with underscores, as AVD names use underscores)
        set "AVD_NAME=%EMULATOR%"
        set "AVD_NAME=!AVD_NAME: =_!"
        echo Trying direct launch with AVD name: !AVD_NAME!
        echo Command: "%ANDROID_HOME%\emulator\emulator.exe" -avd !AVD_NAME!
        echo.
        REM Launch emulator directly in background
        set "ANDROID_HOME=%ANDROID_HOME%"
        set "ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT%"
        REM First, check available AVDs to find the correct name
        echo Checking available AVDs:
        "%ANDROID_HOME%\emulator\emulator.exe" -list-avds
        echo.
        REM Try with underscore version first
        echo Attempting launch with: !AVD_NAME!
        start "" "%ANDROID_HOME%\emulator\emulator.exe" -avd !AVD_NAME!
        timeout /t 2 /nobreak >nul
        REM Check if emulator process started
        tasklist /FI "IMAGENAME eq emulator.exe" 2>nul | find /I "emulator.exe" >nul
        if %ERRORLEVEL%==0 (
            echo.
            echo Direct emulator launch initiated successfully
            echo The emulator window should appear shortly (may take 30-60 seconds to boot)
            echo Check status with: flutter devices
            echo.
            exit /b 0
        ) else (
            REM Try with original name (in case it has spaces and that's the actual AVD name)
            echo Trying with original name: "%EMULATOR%"
            start "" "%ANDROID_HOME%\emulator\emulator.exe" -avd "%EMULATOR%"
            timeout /t 2 /nobreak >nul
            tasklist /FI "IMAGENAME eq emulator.exe" 2>nul | find /I "emulator.exe" >nul
            if %ERRORLEVEL%==0 (
                echo.
                echo Direct emulator launch initiated successfully (using original name)
                echo The emulator window should appear shortly (may take 30-60 seconds to boot)
                echo Check status with: flutter devices
                echo.
                exit /b 0
            ) else (
                echo Direct launch failed - emulator process did not start
                echo Please check the AVD name matches one of the listed AVDs above
                echo.
            )
        )
    )
    echo.
    echo === ERROR: Emulator launch failed ===
    echo.
    
    echo === Checking available emulators ===
    flutter emulators
    echo.
    
    echo === Checking if emulator exists ===
    flutter emulators | findstr /i /c:"%EMULATOR%" >nul 2>&1
    if %ERRORLEVEL%==0 (
        echo Emulator '%EMULATOR%' is listed as available
    ) else (
        echo WARNING: Emulator '%EMULATOR%' NOT found in available emulators
        echo Available emulators:
        flutter emulators
    )
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
        echo Emulator version:
        "%ANDROID_HOME%\emulator\emulator.exe" -version 2>&1
    ) else (
        echo WARNING: Emulator binary NOT found at %ANDROID_HOME%\emulator\emulator.exe
        echo Searching for emulator.exe...
        where /r "%ANDROID_HOME%" emulator.exe 2>nul || echo Could not find emulator.exe
    )
    echo.
    
    echo === Attempting direct emulator launch for detailed errors ===
    if exist "%ANDROID_HOME%\emulator\emulator.exe" (
        REM Get AVD name (replace spaces with underscores, as AVD names use underscores)
        set "AVD_NAME=%EMULATOR%"
        set "AVD_NAME=!AVD_NAME: =_!"
        echo Trying to launch AVD: !AVD_NAME!
        echo.
        echo Running: "%ANDROID_HOME%\emulator\emulator.exe" -list-avds
        set "ANDROID_HOME=%ANDROID_HOME%"
        set "ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT%"
        "%ANDROID_HOME%\emulator\emulator.exe" -list-avds 2>&1
        echo.
        echo Attempting direct launch (this will show detailed errors):
        echo Command: "%ANDROID_HOME%\emulator\emulator.exe" -avd !AVD_NAME!
        echo.
        REM Try launching in background to see initial errors
        start /B "" "%ANDROID_HOME%\emulator\emulator.exe" -avd !AVD_NAME! 2>&1
        timeout /t 3 /nobreak >nul
        echo.
        echo Note: If emulator window appeared, it may take 30-60 seconds to boot
        echo Check if emulator is running with: flutter devices
        echo.
    ) else (
        echo Emulator binary not found, cannot attempt direct launch
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

