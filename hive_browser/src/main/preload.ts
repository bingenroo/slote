import { contextBridge, ipcRenderer } from 'electron';
import { DatabaseInfo, HiveRecord } from '../shared/types';

// Send message to main process to confirm preload is executing
try {
  ipcRenderer.invoke('preload:ping').catch(() => {
    // IPC handler might not exist yet, that's OK
  });
} catch (e) {
  console.error('[PRELOAD] Error sending ping:', e);
}

console.log('[PRELOAD] About to call contextBridge.exposeInMainWorld');
try {
  contextBridge.exposeInMainWorld('electronAPI', {
    // File operations
    openFile: (): Promise<DatabaseInfo | null> =>
      ipcRenderer.invoke('file:open'),
    saveFile: (): Promise<void> => ipcRenderer.invoke('file:save'),
    exportFile: (): Promise<string> => ipcRenderer.invoke('file:export'),

    // Database operations
    getDatabaseInfo: (): Promise<DatabaseInfo | null> =>
      ipcRenderer.invoke('database:getInfo'),
    getRecords: (boxName: string): Promise<HiveRecord[]> =>
      ipcRenderer.invoke('database:getRecords', boxName),
    updateRecord: (
      boxName: string,
      key: string | number,
      value: any
    ): Promise<void> =>
      ipcRenderer.invoke('database:updateRecord', boxName, key, value),
    deleteRecord: (boxName: string, key: string | number): Promise<void> =>
      ipcRenderer.invoke('database:deleteRecord', boxName, key),
    addRecord: (
      boxName: string,
      key: string | number,
      value: any
    ): Promise<void> =>
      ipcRenderer.invoke('database:addRecord', boxName, key, value),
  });

  // Send confirmation to main process
  try {
    ipcRenderer.invoke('preload:expose-complete').catch(() => {});
  } catch (e) {
    console.error('[PRELOAD] Error sending expose-complete:', e);
  }
} catch (error) {
  console.error('[PRELOAD] contextBridge.exposeInMainWorld FAILED:', error);
  // Send error to main process
  const errorMessage = error instanceof Error ? error.message : String(error);
  try {
    ipcRenderer.invoke('preload:expose-error', errorMessage).catch(() => {});
  } catch (e) {
    console.error('[PRELOAD] Error sending expose-error:', e);
  }
  throw error;
}
