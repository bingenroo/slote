import { contextBridge, ipcRenderer } from 'electron';
import { DatabaseInfo, HiveRecord } from '../shared/types';

contextBridge.exposeInMainWorld('electronAPI', {
  // File operations
  openFile: (): Promise<DatabaseInfo | null> => ipcRenderer.invoke('file:open'),
  saveFile: (): Promise<void> => ipcRenderer.invoke('file:save'),
  exportFile: (): Promise<string> => ipcRenderer.invoke('file:export'),

  // Database operations
  getDatabaseInfo: (): Promise<DatabaseInfo | null> => ipcRenderer.invoke('database:getInfo'),
  getRecords: (boxName: string): Promise<HiveRecord[]> => ipcRenderer.invoke('database:getRecords', boxName),
  updateRecord: (boxName: string, key: string | number, value: any): Promise<void> => 
    ipcRenderer.invoke('database:updateRecord', boxName, key, value),
  deleteRecord: (boxName: string, key: string | number): Promise<void> => 
    ipcRenderer.invoke('database:deleteRecord', boxName, key),
  addRecord: (boxName: string, key: string | number, value: any): Promise<void> => 
    ipcRenderer.invoke('database:addRecord', boxName, key, value),
});

