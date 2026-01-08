import { dialog, app } from 'electron';
import * as fs from 'fs';
import * as path from 'path';
import { HiveParser } from './hive-parser';
import { DatabaseInfo, HiveRecord } from '../shared/types';

export class FileHandler {
  private currentFilePath: string | null = null;
  private currentDatabase: DatabaseInfo | null = null;
  private boxData: Record<string, HiveRecord[]> = {};

  /**
   * Open a file dialog to select a Hive database file
   */
  async openFileDialog(): Promise<string | null> {
    const result = await dialog.showOpenDialog({
      title: 'Open Hive Database',
      filters: [
        { name: 'Hive Database', extensions: ['hive'] },
        { name: 'JSON Files', extensions: ['json'] },
        { name: 'All Files', extensions: ['*'] },
      ],
      properties: ['openFile'],
    });

    if (result.canceled || result.filePaths.length === 0) {
      return null;
    }

    return result.filePaths[0];
  }

  /**
   * Open and parse a Hive database file
   */
  async openDatabase(filePath?: string): Promise<DatabaseInfo | null> {
    try {
      const pathToOpen = filePath || await this.openFileDialog();
      if (!pathToOpen) {
        return null;
      }

      this.currentFilePath = pathToOpen;
      this.currentDatabase = await HiveParser.parseDatabase(pathToOpen);
      
      // Load all box data
      this.boxData = {};
      for (const box of this.currentDatabase.boxes) {
        this.boxData[box.name] = await HiveParser.readBox(pathToOpen, box.name);
      }

      return this.currentDatabase;
    } catch (error) {
      throw new Error(`Failed to open database: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Get records from a specific box
   */
  getBoxRecords(boxName: string): HiveRecord[] {
    return this.boxData[boxName] || [];
  }

  /**
   * Update a record in a box
   */
  updateRecord(boxName: string, key: string | number, value: any): void {
    if (!this.boxData[boxName]) {
      this.boxData[boxName] = [];
    }

    const index = this.boxData[boxName].findIndex(r => r.key === key);
    if (index >= 0) {
      this.boxData[boxName][index].value = value;
    } else {
      this.boxData[boxName].push({ key, value });
    }
  }

  /**
   * Delete a record from a box
   */
  deleteRecord(boxName: string, key: string | number): void {
    if (this.boxData[boxName]) {
      this.boxData[boxName] = this.boxData[boxName].filter(r => r.key !== key);
    }
  }

  /**
   * Delete all records from a box
   */
  deleteAllRecords(boxName: string): void {
    if (this.boxData[boxName]) {
      this.boxData[boxName] = [];
    }
  }

  /**
   * Add a new record to a box
   */
  addRecord(boxName: string, key: string | number, value: any): void {
    if (!this.boxData[boxName]) {
      this.boxData[boxName] = [];
    }
    this.boxData[boxName].push({ key, value });
  }

  /**
   * Save the current database
   */
  async saveDatabase(): Promise<void> {
    if (!this.currentFilePath) {
      throw new Error('No database file is open');
    }

    await HiveParser.writeDatabase(this.currentFilePath, this.boxData);
    
    // Update database info
    if (this.currentDatabase) {
      const stats = fs.statSync(this.currentFilePath);
      this.currentDatabase.fileSize = stats.size;
      this.currentDatabase.lastModified = stats.mtime;
      
      // Update box record counts
      for (const box of this.currentDatabase.boxes) {
        box.recordCount = this.boxData[box.name]?.length || 0;
        box.keys = this.boxData[box.name]?.map(r => r.key) || [];
      }
    }
  }

  /**
   * Export database to JSON
   */
  async exportToJson(outputPath?: string): Promise<string> {
    if (!this.currentFilePath) {
      throw new Error('No database file is open');
    }

    const result = await dialog.showSaveDialog({
      title: 'Export Database to JSON',
      defaultPath: outputPath || path.join(app.getPath('documents'), 'hive-export.json'),
      filters: [
        { name: 'JSON Files', extensions: ['json'] },
      ],
    });

    if (result.canceled || !result.filePath) {
      throw new Error('Export cancelled');
    }

    await HiveParser.exportToJson(this.currentFilePath, result.filePath);
    return result.filePath;
  }

  /**
   * Get current database info
   */
  getCurrentDatabase(): DatabaseInfo | null {
    return this.currentDatabase;
  }

  /**
   * Get current file path
   */
  getCurrentFilePath(): string | null {
    return this.currentFilePath;
  }
}

