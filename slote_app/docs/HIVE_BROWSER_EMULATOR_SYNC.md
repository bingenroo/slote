---
name: Auto-pull Hive DB from Emulator
overview: Automatically pull Hive database files from all connected Android emulators when the Electron app starts, making them available for manual opening. Files will be saved to a local cache directory with device IDs in filenames to distinguish between multiple emulators.
todos:
  - id: create-cache-manager
    content: Create cache-manager.ts to manage local cache directory (~/.hive-browser/cache/)
    status: completed
  - id: create-emulator-sync
    content: Create emulator-sync.ts with functions to check ADB, get devices, and pull Hive files
    status: completed
    dependencies:
      - create-cache-manager
  - id: integrate-startup
    content: Modify main.ts to call syncFromEmulators() on app startup with notifications
    status: completed
    dependencies:
      - create-emulator-sync
  - id: add-ipc-handler
    content: Add emulator:sync IPC handler in main.ts for manual sync
    status: completed
    dependencies:
      - create-emulator-sync
  - id: update-preload
    content: Expose syncFromEmulator() API in preload.ts
    status: completed
    dependencies:
      - add-ipc-handler
  - id: optional-ui-button
    content: Add optional Sync from Emulator button in Layout.tsx (optional enhancement)
    status: completed
    dependencies:
      - update-preload
---

# Auto-Pull Hive Database from Android Emulator

## Overview

Automatically detect connected Android emulators and pull Hive database files (`notes.hive`) when the Electron app starts. Files will be saved to a local cache directory and made available for manual opening.

## Architecture

### High-Level Flow

```mermaid
flowchart TD
    A[Electron App Starts] --> B[Check for ADB]
    B -->|ADB Found| C[Get Connected Devices]
    B -->|ADB Not Found| D[Show Notification]
    C --> E{Any Devices?}
    E -->|No| F[Show Notification: No Emulator]
    E -->|Yes| G[For Each Device]
    G --> H[Pull notes.hive File]
    H --> I{File Exists?}
    I -->|Yes| J[Save to Cache with Device ID]
    I -->|No| K[Skip Device]
    J --> L[Show Notification: Files Ready]
    K --> M{More Devices?}
    M -->|Yes| G
    M -->|No| N[Continue App Startup]
    F --> N
    D --> N
```

### Detailed Flowchart

```mermaid
flowchart TD
    Start([App Startup or Manual Sync]) --> Init[Initialize Sync Process]
    Init --> CheckADB{ADB Available?}

    CheckADB -->|No| NotifyADB[Show Notification:<br/>ADB Not Found]
    NotifyADB --> End1([End: Continue App])

    CheckADB -->|Yes| GetDevices[Execute: adb devices]
    GetDevices --> ParseDevices[Parse Output:<br/>Extract Device IDs]
    ParseDevices --> CheckDevices{Devices Found?}

    CheckDevices -->|No| NotifyNoDev[Show Notification:<br/>No Emulators Detected]
    NotifyNoDev --> End1

    CheckDevices -->|Yes| InitCache[Initialize Cache Manager:<br/>Get/Create Cache Directory]
    InitCache --> LoopStart[For Each Device]

    LoopStart --> CheckFile[Check File Exists:<br/>adb shell run-as<br/>test -f path]
    CheckFile --> FileExists{File Exists?}

    FileExists -->|No| LogSkip[Log: File Not Found<br/>Skip Device]
    LogSkip --> NextDevice{More Devices?}

    FileExists -->|Yes| SanitizeID[Sanitize Device ID:<br/>Replace Invalid Chars]
    SanitizeID --> GenFilename[Generate Filename:<br/>notes-deviceId.hive]
    GenFilename --> GetCachePath[Get Cache File Path]

    GetCachePath --> TryPull1[Try Method 1:<br/>Copy to /sdcard/temp<br/>Pull from temp]
    TryPull1 --> PullSuccess1{Pull Success?}

    PullSuccess1 -->|Yes| CleanTemp[Remove Temp File]
    PullSuccess1 -->|No| TryPull2[Try Method 2:<br/>exec-out run-as cat]

    TryPull2 --> PullSuccess2{Pull Success?}
    PullSuccess2 -->|Yes| WriteFile[Write File to Cache]
    PullSuccess2 -->|No| LogError[Log Error:<br/>Skip Device]

    CleanTemp --> VerifyFile[Verify File:<br/>Check Exists & Size > 0]
    WriteFile --> VerifyFile

    VerifyFile --> ValidFile{File Valid?}
    ValidFile -->|No| DeleteInvalid[Delete Invalid File]
    ValidFile -->|Yes| SaveMapping[Save Device Mapping:<br/>Update .devices.json]

    DeleteInvalid --> NextDevice
    SaveMapping --> AddToList[Add to Pulled Files List]
    LogError --> NextDevice

    AddToList --> NextDevice
    NextDevice -->|Yes| LoopStart
    NextDevice -->|No| CheckResults{Any Files<br/>Pulled?}

    CheckResults -->|Yes| NotifySuccess[Show Notification:<br/>Pulled X files from<br/>Y devices]
    CheckResults -->|No| NotifyNoFiles[Show Notification:<br/>No files found on<br/>connected devices]

    NotifySuccess --> End2([End: Files in Cache])
    NotifyNoFiles --> End2

    style Start fill:#e1f5ff
    style End1 fill:#ffe1e1
    style End2 fill:#e1ffe1
    style NotifyADB fill:#fff4e1
    style NotifyNoDev fill:#fff4e1
    style NotifySuccess fill:#e1ffe1
    style NotifyNoFiles fill:#fff4e1
    style LogError fill:#ffe1e1
    style LogSkip fill:#fff4e1
```

### Manual Sync Flow (UI Button)

```mermaid
sequenceDiagram
    participant User
    participant UI as Layout Component
    participant App as App Component
    participant Preload as Preload Script
    participant Main as Main Process
    participant Sync as EmulatorSync
    participant ADB as ADB Process
    participant Cache as CacheManager
    participant Notify as Notification API

    User->>UI: Click "Sync from Emulator"
    UI->>App: handleSyncFromEmulator()
    App->>App: setLoading(true)
    App->>Preload: window.electronAPI.syncFromEmulator()
    Preload->>Main: ipcRenderer.invoke('emulator:sync')
    Main->>Sync: syncFromEmulators()

    Sync->>Sync: checkAdbAvailable()
    Sync->>ADB: exec('adb version')
    ADB-->>Sync: Success/Failure

    alt ADB Not Available
        Sync-->>Main: []
        Main->>Notify: Show "ADB Not Found"
        Main-->>Preload: []
        Preload-->>App: []
        App->>App: setError('ADB not found')
    else ADB Available
        Sync->>Sync: getConnectedDevices()
        Sync->>ADB: exec('adb devices')
        ADB-->>Sync: Device List

        alt No Devices
            Sync-->>Main: []
            Main->>Notify: Show "No Emulators"
            Main-->>Preload: []
            Preload-->>App: []
            App->>App: setError('No emulators')
        else Devices Found
            loop For Each Device
                Sync->>Sync: pullHiveFile(deviceId)
                Sync->>Sync: fileExistsOnDevice()
                Sync->>ADB: exec('adb shell run-as ... test -f')
                ADB-->>Sync: File Exists Status

                alt File Exists
                    Sync->>Cache: getCacheFilePath(filename)
                    Cache-->>Sync: Local Path
                    Sync->>ADB: exec('adb shell run-as ... cp ... /sdcard/temp')
                    ADB-->>Sync: Copy Result
                    Sync->>ADB: exec('adb pull /sdcard/temp ...')
                    ADB-->>Sync: Pull Result
                    Sync->>ADB: exec('adb shell rm /sdcard/temp')

                    alt Pull Failed
                        Sync->>ADB: exec('adb exec-out run-as ... cat')
                        ADB-->>Sync: File Content
                        Sync->>Cache: Write File
                    end

                    Sync->>Cache: saveDeviceMapping()
                    Sync-->>Sync: Add to Results
                else File Not Found
                    Sync-->>Sync: Skip Device
                end
            end

            Sync-->>Main: [filePaths...]
            Main->>Notify: Show "Pulled X files"

            Note over Main: Auto-Open First File
            Main->>Main: Select first file: filePaths[0]
            Main->>FileHandler: openDatabase(filePath)
            FileHandler->>FileHandler: Parse & Load Database
            FileHandler-->>Main: DatabaseInfo

            Main-->>Preload: [filePaths...]
            Preload-->>App: [filePaths...]
            App->>App: getDatabaseInfo()
            App->>Preload: window.electronAPI.getDatabaseInfo()
            Preload->>Main: ipcRenderer.invoke('database:getInfo')
            Main->>FileHandler: getCurrentDatabase()
            FileHandler-->>Main: DatabaseInfo
            Main-->>Preload: DatabaseInfo
            Preload-->>App: DatabaseInfo
            App->>App: setDatabase(db)
            App->>App: Show Success Alert
        end
    end

    App->>App: setLoading(false)
```

### Auto-Open Flow After Sync

```mermaid
sequenceDiagram
    participant Sync as EmulatorSync
    participant Main as Main Process
    participant FileHandler as FileHandler
    participant Parser as HiveParser
    participant Cache as CacheManager
    participant Renderer as Renderer Process
    participant UI as UI Components

    Note over Sync,UI: After successful file pull

    Sync-->>Main: Return [filePaths...]
    Main->>Main: Select first file<br/>filePaths[0]
    Main->>FileHandler: openDatabase(filePath)

    FileHandler->>Parser: parseDatabase(filePath)
    Parser->>Parser: Read & Parse File
    Parser-->>FileHandler: DatabaseInfo

    FileHandler->>Parser: readBox(filePath, boxName)<br/>for each box
    Parser-->>FileHandler: HiveRecord[]
    FileHandler->>FileHandler: Store in boxData

    FileHandler-->>Main: DatabaseInfo

    Main->>Main: fileHandler.currentDatabase = db<br/>fileHandler.currentFilePath = path

    Note over Main,Renderer: Database now loaded in main process

    Renderer->>Renderer: Call getDatabaseInfo()
    Renderer->>Main: IPC: database:getInfo
    Main->>FileHandler: getCurrentDatabase()
    FileHandler-->>Main: DatabaseInfo
    Main-->>Renderer: DatabaseInfo

    Renderer->>UI: setDatabase(db)
    UI->>UI: Update UI:<br/>Show boxes in sidebar<br/>Display first box data

    Note over UI: Database appears in UI
```

### Complete Sync-to-View Flow

```mermaid
flowchart LR
    subgraph Sync["Sync Phase"]
        A[Click Sync Button] --> B[Pull Files from Emulator]
        B --> C{Files Pulled?}
        C -->|Yes| D[Files in Cache]
        C -->|No| E[Show Error]
    end

    subgraph Open["Auto-Open Phase"]
        D --> F[Select First File]
        F --> G[Parse Database]
        G --> H[Load Box Data]
        H --> I[Store in FileHandler]
    end

    subgraph Display["Display Phase"]
        I --> J[Refresh Database Info]
        J --> K[Update UI State]
        K --> L[Show Database in Sidebar]
        L --> M[Display Records]
    end

    Sync --> Open
    Open --> Display
    E --> End([End])
    M --> End

    style A fill:#e1f5ff
    style D fill:#e1ffe1
    style I fill:#e1ffe1
    style M fill:#e1ffe1
    style E fill:#ffe1e1
    style End fill:#f0f0f0
```

### Error Handling Flow

```mermaid
flowchart TD
    Start([Operation Start]) --> Try[Try Operation]
    Try --> Success{Success?}

    Success -->|Yes| Complete([Complete])

    Success -->|No| ErrorType{Error Type?}

    ErrorType -->|ADB Not Found| HandleADB[Log: ADB not in PATH<br/>Show Notification<br/>Return Empty Array]
    HandleADB --> Complete

    ErrorType -->|No Devices| HandleNoDev[Log: No devices<br/>Show Notification<br/>Return Empty Array]
    HandleNoDev --> Complete

    ErrorType -->|Device Not Accessible| HandleAccess[Log: Device access error<br/>Skip Device<br/>Continue with Next]
    HandleAccess --> Continue

    ErrorType -->|File Not Found| HandleNoFile[Log: File not found<br/>Skip Device<br/>Continue with Next]
    HandleNoFile --> Continue

    ErrorType -->|Permission Denied| HandlePerm[Log: Permission denied<br/>Skip Device<br/>Continue with Next]
    HandlePerm --> Continue

    ErrorType -->|Pull Failed Method 1| HandlePull1[Log: Method 1 failed<br/>Try Fallback Method 2]
    HandlePull1 --> TryMethod2[Try exec-out Method]
    TryMethod2 --> Method2Success{Success?}
    Method2Success -->|Yes| Complete
    Method2Success -->|No| HandlePull2[Log: All methods failed<br/>Skip Device]
    HandlePull2 --> Continue

    ErrorType -->|File Empty/Invalid| HandleInvalid[Log: File invalid<br/>Delete File<br/>Skip Device]
    HandleInvalid --> Continue

    ErrorType -->|Network/Other| HandleOther[Log: Unknown error<br/>Skip Device<br/>Continue with Next]
    HandleOther --> Continue

    Continue{More Devices?}
    Continue -->|Yes| Start
    Continue -->|No| Complete

    style Complete fill:#e1ffe1
    style HandleADB fill:#fff4e1
    style HandleNoDev fill:#fff4e1
    style HandleAccess fill:#ffe1e1
    style HandleNoFile fill:#fff4e1
    style HandlePerm fill:#ffe1e1
    style HandlePull1 fill:#fff4e1
    style HandlePull2 fill:#ffe1e1
    style HandleInvalid fill:#ffe1e1
    style HandleOther fill:#ffe1e1
```

## Implementation Plan

### 1. Create Emulator Sync Service

**File:** `hive_browser/src/main/emulator-sync.ts`

Create a new service that:

- Checks if `adb` is available in PATH
- Lists all connected Android devices using `adb devices`
- For each device, pulls the `notes.hive` file from `/data/data/com.example.slote/app_flutter/`
- Saves files to a local cache directory: `~/.hive-browser/cache/`
- Names files with device ID: `notes-<device-id>.hive` (e.g., `notes-emulator-5554.hive`)
- Handles errors gracefully (device not accessible, file doesn't exist, etc.)

**Key functions:**

- `checkAdbAvailable(): Promise<boolean>` - Verify ADB is installed
- `getConnectedDevices(): Promise<string[]>` - Get list of device IDs
- `pullHiveFile(deviceId: string): Promise<string | null>` - Pull file from specific device, returns local path
- `syncFromEmulators(): Promise<string[]>` - Main function that syncs from all devices, returns array of local file paths

### 2. Create Cache Directory Manager

**File:** `hive_browser/src/main/cache-manager.ts`

Utility to manage the local cache directory:

- Create cache directory if it doesn't exist: `~/.hive-browser/cache/` (or `%APPDATA%/.hive-browser/cache/` on Windows)
- Clean up old files (optional: keep last N files or files from last 7 days)
- Provide path utilities for cache directory

### 3. Integrate into Main Process

**File:** `hive_browser/src/main/main.ts`

Modify `app.whenReady()` to:

1. Call `syncFromEmulators()` after window creation
2. Show system notifications for:

   - Success: "Pulled X database file(s) from emulator(s)"
   - No emulator: "No Android emulators detected"
   - ADB not found: "ADB not found. Install Android SDK platform-tools"
   - Errors: "Failed to pull database from emulator"

**Location:** Add sync call in `app.whenReady().then()` after `createWindow()`

### 4. Add IPC Handler for Manual Sync

**File:** `hive_browser/src/main/main.ts`

Add IPC handler `emulator:sync` that allows manual triggering of sync from renderer:

- Can be called from UI button "Sync from Emulator"
- Returns array of pulled file paths

### 5. Update Preload Script

**File:** `hive_browser/src/main/preload.ts`

Expose new API method:

```typescript
syncFromEmulator: (): Promise<string[]> => ipcRenderer.invoke("emulator:sync");
```

### 6. Update Renderer (Optional UI Enhancement)

**File:** `hive_browser/src/renderer/components/Layout.tsx`

Add optional "Sync from Emulator" button that:

- Calls `window.electronAPI.syncFromEmulator()`
- Shows loading state
- Displays success/error message

### 7. Add Dependencies

**File:** `hive_browser/package.json`

No new npm dependencies needed - we'll use Node.js built-in `child_process` to execute `adb` commands.

### 8. Error Handling

Handle these scenarios:

- ADB not in PATH → Show notification, continue normally
- No devices connected → Show notification, continue normally
- Device not accessible → Skip device, continue with others
- File doesn't exist on device → Skip device, continue with others
- Permission denied → Skip device, log error
- Network issues → Skip device, log error

### 9. File Naming Convention

Files will be saved as:

- `notes-<device-id>.hive` (e.g., `notes-emulator-5554.hive`)
- If device ID contains invalid filename characters, sanitize them
- Store device ID mapping in a JSON file for reference: `cache/.devices.json`

### 10. Configuration (Optional)

**File:** `hive_browser/src/main/config.ts` (optional)

Allow configuration of:

- Package name (default: `com.example.slote`)
- Box name (default: `notes`)
- Cache directory path
- Auto-sync on startup (default: true)

## Files to Create/Modify

1. **Create:** `hive_browser/src/main/emulator-sync.ts` - Core sync logic
2. **Create:** `hive_browser/src/main/cache-manager.ts` - Cache directory management
3. **Modify:** `hive_browser/src/main/main.ts` - Add sync on startup and IPC handler
4. **Modify:** `hive_browser/src/main/preload.ts` - Expose sync API
5. **Modify:** `hive_browser/src/renderer/components/Layout.tsx` - Add optional sync button (optional)

## Implementation Status

✅ **All tasks completed**

### Completed Files:

- ✅ `hive_browser/src/main/cache-manager.ts` - Cache directory management with cleanup utilities
- ✅ `hive_browser/src/main/emulator-sync.ts` - ADB detection, device listing, and file pulling
- ✅ `hive_browser/src/main/main.ts` - Startup sync integration and IPC handler
- ✅ `hive_browser/src/main/preload.ts` - Exposed `syncFromEmulator()` API
- ✅ `hive_browser/src/renderer/components/App.tsx` - Added sync handler and TypeScript interface
- ✅ `hive_browser/src/renderer/components/Layout.tsx` - Added "Sync from Emulator" button

### Features Implemented:

- ✅ Automatic sync on app startup
- ✅ Support for multiple emulators (pulls from all connected devices)
- ✅ System notifications for sync status
- ✅ Manual sync via UI button
- ✅ Error handling for all edge cases
- ✅ File naming with device IDs
- ✅ Cache directory management
- ✅ Device ID mapping storage

## Testing

1. Test with no emulator running → Should show notification
2. Test with one emulator → Should pull file successfully
3. Test with multiple emulators → Should pull files from all
4. Test with ADB not in PATH → Should show notification
5. Test with device that doesn't have the app installed → Should skip gracefully

## Notes

- Uses `child_process.exec` to run `adb` commands
- Cache directory is created in app's userData directory for cross-platform compatibility:
  - macOS: `~/Library/Application Support/hive-browser/cache`
  - Windows: `%APPDATA%/hive-browser/cache`
  - Linux: `~/.config/hive-browser/cache`
- Files are pulled synchronously per device, but the process is non-blocking (runs after window creation)
- Uses `run-as` command to access app's private directory without root access
- Falls back to `exec-out` method if standard pull fails
