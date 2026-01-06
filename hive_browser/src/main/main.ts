import { app, BrowserWindow, ipcMain } from 'electron';
import * as path from 'path';
import { FileHandler } from './file-handler';
import { DatabaseInfo, HiveRecord } from '../shared/types';

const fileHandler = new FileHandler();

let mainWindow: BrowserWindow | null = null;

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
    },
    titleBarStyle: 'default',
  });

  // Load the renderer
  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:3000');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
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

ipcMain.handle('database:getRecords', async (_event, boxName: string): Promise<HiveRecord[]> => {
  return fileHandler.getBoxRecords(boxName);
});

ipcMain.handle('database:updateRecord', async (_event, boxName: string, key: string | number, value: any): Promise<void> => {
  fileHandler.updateRecord(boxName, key, value);
});

ipcMain.handle('database:deleteRecord', async (_event, boxName: string, key: string | number): Promise<void> => {
  fileHandler.deleteRecord(boxName, key);
});

ipcMain.handle('database:addRecord', async (_event, boxName: string, key: string | number, value: any): Promise<void> => {
  fileHandler.addRecord(boxName, key, value);
});

