import { app, BrowserWindow, ipcMain, Notification } from 'electron';
import * as path from 'path';
import * as fs from 'fs';
import { FileHandler } from './file-handler';
import { DatabaseInfo, HiveRecord } from '../shared/types';
import { EmulatorSync } from './emulator-sync';

const fileHandler = new FileHandler();

let mainWindow: BrowserWindow | null = null;
let autoRefreshInterval: NodeJS.Timeout | null = null;

function createWindow(): void {
  // Use the compiled preload script
  const preloadPath = path.resolve(__dirname, 'preload.js');
  console.log('[MAIN] Using preload path:', preloadPath);
  console.log('[MAIN] Preload exists:', fs.existsSync(preloadPath));

  // Verify preload path is absolute and exists
  const absolutePreloadPath = path.isAbsolute(preloadPath)
    ? preloadPath
    : path.resolve(__dirname, preloadPath);
  console.log('[MAIN] Absolute preload path:', absolutePreloadPath);
  console.log(
    '[MAIN] Preload file exists:',
    fs.existsSync(absolutePreloadPath)
  );
  console.log(
    '[MAIN] Preload file readable:',
    fs.accessSync(absolutePreloadPath, fs.constants.R_OK) === undefined
  );

  // Log the exact path that will be used
  console.log(
    '[MAIN] Creating BrowserWindow with preload:',
    absolutePreloadPath
  );
  console.log('[MAIN] Preload file stats:', fs.statSync(absolutePreloadPath));

  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: absolutePreloadPath,
      webSecurity: false, // Disable for debugging
      sandbox: false, // Disable sandbox to ensure preload works
    },
    titleBarStyle: 'default',
    show: false, // Don't show until ready
  });

  console.log('[MAIN] BrowserWindow created successfully');

  // Load the renderer
  // Preload script is working, so we can load directly from Vite dev server
  // Check for development mode: either NODE_ENV is 'development' or not set (defaults to dev)
  const isDevelopment = process.env.NODE_ENV !== 'production';
  if (isDevelopment) {
    console.log('[MAIN] Loading from Vite dev server: http://localhost:3000');
    if (mainWindow) {
      mainWindow.webContents.once('did-finish-load', () => {
        console.log('Window loaded, electronAPI should be available');
      });
      mainWindow.webContents.on(
        'preload-error',
        (event, preloadPath, error) => {
          console.error('[MAIN] Preload script error:', error);
          console.error('[MAIN] Preload path:', preloadPath);
        }
      );

      // Also listen for console messages from preload and renderer
      mainWindow.webContents.on(
        'console-message',
        (event, level, message, line, sourceId) => {
          const logMessage = `[CONSOLE-${level}] ${message}`;
          console.log(logMessage);
        }
      );
      console.log('[MAIN] About to load URL: http://localhost:3000');
      console.log('[MAIN] Preload path configured:', preloadPath);

      mainWindow.webContents.on('did-start-loading', () => {
        console.log('[MAIN] Window started loading');
      });
      mainWindow.webContents.on('did-stop-loading', () => {
        console.log('[MAIN] Window stopped loading');
      });
      mainWindow.webContents.on('dom-ready', () => {
        console.log('[MAIN] DOM ready');
        if (mainWindow) {
          // Show window immediately when DOM is ready
          mainWindow.show();
          // Check if electronAPI is available
          mainWindow.webContents
            .executeJavaScript('typeof window.electronAPI !== "undefined"')
            .then((hasAPI) => {
              console.log('[MAIN] electronAPI available in renderer:', hasAPI);
            })
            .catch((err) => {
              console.error('[MAIN] Error checking electronAPI:', err);
            });
        }
      });
      mainWindow
        .loadURL('http://localhost:3000')
        .then(() => {
          console.log('[MAIN] loadURL promise resolved');
        })
        .catch((err) => {
          console.error('[MAIN] loadURL failed:', err);
        });
      // Show window after a short delay as fallback if dom-ready doesn't fire
      setTimeout(() => {
        if (mainWindow && !mainWindow.isVisible()) {
          console.log('[MAIN] Fallback: showing window after timeout');
          mainWindow.show();
        }
      }, 2000);
      mainWindow.webContents.openDevTools();
    }
  } else {
    if (mainWindow) {
      mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
    }
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

/**
 * Start auto-refresh polling for emulator database files
 */
function startAutoRefresh(): void {
  // #region agent log
  fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      location: 'main.ts:140',
      message: 'startAutoRefresh called',
      data: {},
      timestamp: Date.now(),
      sessionId: 'debug-session',
      runId: 'auto-refresh-debug',
      hypothesisId: 'A',
    }),
  }).catch(() => {});
  // #endregion
  // Clear any existing interval
  if (autoRefreshInterval) {
    clearInterval(autoRefreshInterval);
  }

  // Poll every 5 seconds
  autoRefreshInterval = setInterval(async () => {
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'main.ts:148',
        message: 'Auto-refresh polling tick',
        data: {},
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'auto-refresh-debug',
        hypothesisId: 'A',
      }),
    }).catch(() => {});
    // #endregion

    const currentFilePath = fileHandler.getCurrentFilePath();
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'main.ts:155',
        message: 'Current file path check',
        data: { currentFilePath },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'auto-refresh-debug',
        hypothesisId: 'A',
      }),
    }).catch(() => {});
    // #endregion
    if (!currentFilePath) {
      return; // No file open
    }

    // Check if file is from emulator (filename pattern: notes-emulator-XXXX.hive)
    const filename = path.basename(currentFilePath);
    const deviceId = EmulatorSync.extractDeviceIdFromFilename(filename);
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'main.ts:167',
        message: 'Device ID extraction',
        data: { filename, deviceId },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'auto-refresh-debug',
        hypothesisId: 'B',
      }),
    }).catch(() => {});
    // #endregion
    if (!deviceId) {
      return; // Not an emulator file
    }

    // Check if device is still connected
    const devices = await EmulatorSync.getConnectedDevices();
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'main.ts:177',
        message: 'Device connection check',
        data: { deviceId, devices, isConnected: devices.includes(deviceId) },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'auto-refresh-debug',
        hypothesisId: 'C',
      }),
    }).catch(() => {});
    // #endregion
    if (!devices.includes(deviceId)) {
      return; // Device not connected
    }

    // Get current file size
    try {
      const stats = fs.statSync(currentFilePath);
      let currentSize = stats.size;
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'main.ts:189',
            message: 'Current file size check',
            data: { currentFilePath, currentSize },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'auto-refresh-debug',
            hypothesisId: 'D',
          }),
        }
      ).catch(() => {});
      // #endregion

      // Check if remote file has changed
      const hasChanged = await EmulatorSync.checkFileChanged(
        deviceId,
        currentSize
      );
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'main.ts:200',
            message: 'File change detection result',
            data: { deviceId, hasChanged, currentSize },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'auto-refresh-debug',
            hypothesisId: 'E',
          }),
        }
      ).catch(() => {});
      // #endregion

      if (hasChanged) {
        console.log(
          `[MAIN] Database file changed on ${deviceId}, re-syncing...`
        );
        // #region agent log
        fetch(
          'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              location: 'main.ts:210',
              message: 'File changed detected, starting re-sync',
              data: { deviceId, currentFilePath },
              timestamp: Date.now(),
              sessionId: 'debug-session',
              runId: 'auto-refresh-debug',
              hypothesisId: 'F',
            }),
          }
        ).catch(() => {});
        // #endregion
        // Re-sync the file
        const pulledFiles = await EmulatorSync.syncFromEmulators();
        // #region agent log
        fetch(
          'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              location: 'main.ts:222',
              message: 'Re-sync completed',
              data: {
                pulledFiles,
                currentFilePath,
                fileInPulledFiles: pulledFiles.includes(currentFilePath),
              },
              timestamp: Date.now(),
              sessionId: 'debug-session',
              runId: 'auto-refresh-debug',
              hypothesisId: 'F',
            }),
          }
        ).catch(() => {});
        // #endregion
        if (pulledFiles.includes(currentFilePath)) {
          // Reload the database
          try {
            await fileHandler.openDatabase(currentFilePath);
            // Update currentSize after reload to prevent false positives
            const updatedStats = fs.statSync(currentFilePath);
            currentSize = updatedStats.size;
            // #region agent log
            fetch(
              'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
              {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  location: 'main.ts:233',
                  message: 'Database reloaded successfully',
                  data: { currentFilePath, newSize: currentSize },
                  timestamp: Date.now(),
                  sessionId: 'debug-session',
                  runId: 'auto-refresh-debug',
                  hypothesisId: 'G',
                }),
              }
            ).catch(() => {});
            // #endregion
            // Notify renderer
            if (mainWindow) {
              mainWindow.webContents.send('database-updated');
              // #region agent log
              fetch(
                'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
                {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({
                    location: 'main.ts:241',
                    message: 'Sent database-updated event to renderer',
                    data: {},
                    timestamp: Date.now(),
                    sessionId: 'debug-session',
                    runId: 'auto-refresh-debug',
                    hypothesisId: 'G',
                  }),
                }
              ).catch(() => {});
              // #endregion
            }
          } catch (err) {
            console.error('[MAIN] Failed to reload database:', err);
            // #region agent log
            fetch(
              'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
              {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  location: 'main.ts:250',
                  message: 'Failed to reload database',
                  data: {
                    error: err instanceof Error ? err.message : String(err),
                  },
                  timestamp: Date.now(),
                  sessionId: 'debug-session',
                  runId: 'auto-refresh-debug',
                  hypothesisId: 'G',
                }),
              }
            ).catch(() => {});
            // #endregion
          }
        }
      }
    } catch (err) {
      console.error('[MAIN] Error in auto-refresh:', err);
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'main.ts:262',
            message: 'Error in auto-refresh polling',
            data: { error: err instanceof Error ? err.message : String(err) },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'auto-refresh-debug',
            hypothesisId: 'H',
          }),
        }
      ).catch(() => {});
      // #endregion
    }
  }, 5000); // Poll every 5 seconds
}

/**
 * Stop auto-refresh polling
 */
function stopAutoRefresh(): void {
  if (autoRefreshInterval) {
    clearInterval(autoRefreshInterval);
    autoRefreshInterval = null;
  }
}

app.whenReady().then(() => {
  createWindow();
  // Auto-refresh polling disabled - use "Sync from Emulator" button to refresh
  // startAutoRefresh(); // Disabled - manual sync only

  // Sync from emulators on startup (non-blocking)
  syncFromEmulatorsOnStartup();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

/**
 * Sync Hive files from emulators on startup
 * Shows notifications for different scenarios
 */
async function syncFromEmulatorsOnStartup(): Promise<void> {
  try {
    // Check if ADB is available
    const adbAvailable = await EmulatorSync.checkAdbAvailable();
    if (!adbAvailable) {
      showNotification(
        'ADB Not Found',
        'ADB not found. Install Android SDK platform-tools to sync from emulators.'
      );
      return;
    }

    // Get connected devices
    const devices = await EmulatorSync.getConnectedDevices();
    if (devices.length === 0) {
      showNotification(
        'No Emulators Detected',
        'No Android emulators detected. Connect an emulator to sync database files.'
      );
      return;
    }

    // Sync from all devices
    const pulledFiles = await EmulatorSync.syncFromEmulators();
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'main.ts:176',
        message: 'syncFromEmulators returned',
        data: { pulledFilesCount: pulledFiles.length, pulledFiles },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'run1',
        hypothesisId: 'H',
      }),
    }).catch(() => {});
    // #endregion

    if (pulledFiles.length === 0) {
      showNotification(
        'Sync Complete',
        `No database files found on ${devices.length} connected device(s).`
      );
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'main.ts:178',
            message: 'No files pulled - showing notification',
            data: { devicesCount: devices.length },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run1',
            hypothesisId: 'H',
          }),
        }
      ).catch(() => {});
      // #endregion
    } else {
      showNotification(
        'Sync Complete',
        `Pulled ${pulledFiles.length} database file(s) from ${devices.length} emulator(s). Opening first file...`
      );
      // Automatically open the first synced file on startup
      if (pulledFiles.length > 0) {
        const fileToOpen = pulledFiles[0];
        console.log('[MAIN] Auto-opening synced file on startup:', fileToOpen);
        // #region agent log
        fetch(
          'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              location: 'main.ts:189',
              message: 'Attempting to open synced file',
              data: { fileToOpen, pulledFilesCount: pulledFiles.length },
              timestamp: Date.now(),
              sessionId: 'debug-session',
              runId: 'run1',
              hypothesisId: 'E',
            }),
          }
        ).catch(() => {});
        // #endregion
        try {
          await fileHandler.openDatabase(fileToOpen);
          // #region agent log
          fetch(
            'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                location: 'main.ts:193',
                message: 'File opened successfully',
                data: { fileToOpen },
                timestamp: Date.now(),
                sessionId: 'debug-session',
                runId: 'run1',
                hypothesisId: 'E',
              }),
            }
          ).catch(() => {});
          // #endregion
        } catch (err) {
          console.error(
            '[MAIN] Failed to auto-open synced file on startup:',
            err
          );
          // #region agent log
          fetch(
            'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                location: 'main.ts:195',
                message: 'File open failed',
                data: {
                  fileToOpen,
                  error: err instanceof Error ? err.message : String(err),
                  errorStack: err instanceof Error ? err.stack : undefined,
                },
                timestamp: Date.now(),
                sessionId: 'debug-session',
                runId: 'run1',
                hypothesisId: 'E',
              }),
            }
          ).catch(() => {});
          // #endregion
          // Don't throw - sync was successful, just couldn't open the file
        }
      }
    }
  } catch (err) {
    console.error('[MAIN] Error during emulator sync:', err);
    showNotification(
      'Sync Failed',
      `Failed to sync from emulators: ${err instanceof Error ? err.message : 'Unknown error'}`
    );
  }
}

/**
 * Show system notification
 */
function showNotification(title: string, body: string): void {
  // Check if notifications are supported
  if (Notification.isSupported()) {
    new Notification({
      title,
      body,
    }).show();
  } else {
    // Fallback to console log if notifications not supported
    console.log(`[NOTIFICATION] ${title}: ${body}`);
  }
}

app.on('window-all-closed', () => {
  stopAutoRefresh(); // Stop polling when all windows are closed
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// IPC Handlers
ipcMain.handle('preload:ping', async () => {
  console.log('[MAIN] Preload script is executing! Received ping.');
  return true;
});

ipcMain.handle('preload:expose-complete', async () => {
  console.log(
    '[MAIN] Preload script reports contextBridge.exposeInMainWorld completed!'
  );
  return true;
});

ipcMain.handle('preload:expose-error', async (_event, errorMessage: string) => {
  console.error(
    '[MAIN] Preload script reports contextBridge.exposeInMainWorld FAILED:',
    errorMessage
  );
  return true;
});

ipcMain.handle('file:open', async (): Promise<DatabaseInfo | null> => {
  return await fileHandler.openDatabase();
});

ipcMain.handle('file:save', async (): Promise<void> => {
  await fileHandler.saveDatabase();
});

ipcMain.handle('file:export', async (): Promise<string> => {
  return await fileHandler.exportToJson();
});

ipcMain.handle('database:getInfo', async (): Promise<DatabaseInfo | null> => {
  return fileHandler.getCurrentDatabase();
});

ipcMain.handle(
  'database:getRecords',
  async (_event, boxName: string): Promise<HiveRecord[]> => {
    return fileHandler.getBoxRecords(boxName);
  }
);

ipcMain.handle(
  'database:updateRecord',
  async (
    _event,
    boxName: string,
    key: string | number,
    value: any
  ): Promise<void> => {
    fileHandler.updateRecord(boxName, key, value);
  }
);

ipcMain.handle(
  'database:deleteRecord',
  async (_event, boxName: string, key: string | number): Promise<void> => {
    fileHandler.deleteRecord(boxName, key);
  }
);

ipcMain.handle(
  'database:addRecord',
  async (
    _event,
    boxName: string,
    key: string | number,
    value: any
  ): Promise<void> => {
    fileHandler.addRecord(boxName, key, value);
  }
);

// Emulator sync IPC handler
ipcMain.handle('emulator:sync', async (): Promise<string[]> => {
  console.log('[MAIN] Manual emulator sync requested');
  try {
    const pulledFiles = await EmulatorSync.syncFromEmulators();
    const currentFilePath = fileHandler.getCurrentFilePath();

    if (pulledFiles.length > 0) {
      showNotification(
        'Sync Complete',
        `Pulled ${pulledFiles.length} database file(s) from emulator(s).`
      );

      // Check if currently open file was updated
      let shouldRefresh = false;
      if (currentFilePath && pulledFiles.includes(currentFilePath)) {
        // Current file was updated - refresh it
        console.log(
          '[MAIN] Current file was updated, refreshing:',
          currentFilePath
        );
        try {
          await fileHandler.openDatabase(currentFilePath);
          shouldRefresh = true;
        } catch (err) {
          console.error('[MAIN] Failed to refresh current file:', err);
        }
      } else if (pulledFiles.length > 0) {
        // No current file or different file - open the first synced file
        const fileToOpen = pulledFiles[0];
        console.log('[MAIN] Opening synced file:', fileToOpen);
        try {
          await fileHandler.openDatabase(fileToOpen);
          shouldRefresh = true;
        } catch (err) {
          console.error('[MAIN] Failed to open synced file:', err);
          const errorMessage = err instanceof Error ? err.message : String(err);
          if (errorMessage.includes('Binary Hive file format')) {
            showNotification(
              'File Format Not Supported',
              'Binary Hive files are not yet supported. The file was synced successfully but cannot be opened. Please export to JSON format from the Flutter app.'
            );
          } else {
            showNotification(
              'Failed to Open File',
              `File synced but failed to open: ${errorMessage.substring(0, 100)}`
            );
          }
        }
      }

      // Notify renderer that database was updated
      if (shouldRefresh && mainWindow) {
        mainWindow.webContents.send('database-updated');
      }
    } else {
      // Even if no files were pulled, refresh current file if it exists (in case it was updated)
      if (currentFilePath) {
        const filename = path.basename(currentFilePath);
        const deviceId = EmulatorSync.extractDeviceIdFromFilename(filename);
        if (deviceId) {
          // Current file is from emulator - refresh it
          console.log(
            '[MAIN] Refreshing current emulator file:',
            currentFilePath
          );
          try {
            await fileHandler.openDatabase(currentFilePath);
            if (mainWindow) {
              mainWindow.webContents.send('database-updated');
            }
          } catch (err) {
            console.error('[MAIN] Failed to refresh current file:', err);
          }
        }
      }

      showNotification(
        'Sync Complete',
        'No database files found on connected emulator(s).'
      );
    }

    return pulledFiles;
  } catch (err) {
    console.error('[MAIN] Error during manual emulator sync:', err);
    const errorMessage = err instanceof Error ? err.message : 'Unknown error';
    showNotification(
      'Sync Failed',
      `Failed to sync from emulators: ${errorMessage}`
    );
    throw err;
  }
});
