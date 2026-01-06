import * as fs from 'fs';
import * as path from 'path';
import { DatabaseInfo, HiveBox, HiveRecord, Note } from '../shared/types';

/**
 * Hive Parser - Parses binary Hive database files
 * 
 * Note: This is a simplified parser. For production, you may need to:
 * 1. Implement full binary format parsing based on Hive specification
 * 2. Handle encryption
 * 3. Support all Hive data types
 * 
 * For now, we'll use a workaround: Export Hive data to JSON from Flutter app,
 * then read that JSON file. This allows us to get started quickly.
 */

export class HiveParser {
  /**
   * Parse a Hive database file
   * For MVP: Expects a JSON file exported from Hive
   * TODO: Implement full binary parser
   */
  static async parseDatabase(filePath: string): Promise<DatabaseInfo> {
    const stats = fs.statSync(filePath);
    const fileContent = fs.readFileSync(filePath, 'utf-8');
    
    try {
      // Try to parse as JSON (exported format)
      const data = JSON.parse(fileContent);
      
      // If it's already in our expected format
      if (data.boxes && Array.isArray(data.boxes)) {
        return {
          path: filePath,
          boxes: data.boxes,
          fileSize: stats.size,
          lastModified: stats.mtime,
          version: data.version,
        };
      }
      
      // If it's a simple array of records, wrap it in a box
      if (Array.isArray(data)) {
        const records: HiveRecord[] = data.map((item: any, index: number) => ({
          key: item.id || index,
          value: item,
        }));
        
        return {
          path: filePath,
          boxes: [{
            name: 'notes',
            keys: records.map(r => r.key),
            recordCount: records.length,
          }],
          fileSize: stats.size,
          lastModified: stats.mtime,
        };
      }
      
      throw new Error('Unsupported file format');
    } catch (error) {
      // If JSON parsing fails, try binary format (placeholder)
      throw new Error(`Failed to parse Hive file: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Read records from a box
   */
  static async readBox(filePath: string, boxName: string): Promise<HiveRecord[]> {
    const fileContent = fs.readFileSync(filePath, 'utf-8');
    const data = JSON.parse(fileContent);
    
    // Handle different JSON structures
    if (data.boxes && data.boxes[boxName]) {
      return data.boxes[boxName].records || [];
    }
    
    if (Array.isArray(data)) {
      return data.map((item: any, index: number) => ({
        key: item.id || index,
        value: item,
      }));
    }
    
    return [];
  }

  /**
   * Write records back to file
   * For MVP: Writes as JSON
   * TODO: Implement binary format writing
   */
  static async writeDatabase(filePath: string, boxes: Record<string, HiveRecord[]>): Promise<void> {
    const data = {
      version: '1.0.0',
      boxes: Object.entries(boxes).map(([name, records]) => ({
        name,
        records,
        recordCount: records.length,
      })),
    };
    
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');
  }

  /**
   * Export database to JSON format
   */
  static async exportToJson(filePath: string, outputPath: string): Promise<void> {
    const database = await this.parseDatabase(filePath);
    const allBoxes: Record<string, HiveRecord[]> = {};
    
    for (const box of database.boxes) {
      allBoxes[box.name] = await this.readBox(filePath, box.name);
    }
    
    const exportData = {
      version: database.version || '1.0.0',
      exportedAt: new Date().toISOString(),
      boxes: allBoxes,
    };
    
    fs.writeFileSync(outputPath, JSON.stringify(exportData, null, 2), 'utf-8');
  }
}

