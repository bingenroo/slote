import { app, BrowserWindow, ipcMain } from 'electron';
import * as path from 'path';
import * as fs from 'fs';
import { FileHandler } from './file-handler';
import { DatabaseInfo, HiveRecord } from '../shared/types';

const fileHandler = new FileHandler();

let mainWindow: BrowserWindow | null = null;

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

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
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
