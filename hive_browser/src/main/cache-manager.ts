import * as path from 'path';
import * as fs from 'fs';
import { app } from 'electron';

/**
 * Cache Manager - Manages local cache directory for pulled Hive files
 */
export class CacheManager {
  private static cacheDir: string | null = null;

  /**
   * Get the cache directory path
   * Creates the directory if it doesn't exist
   */
  static getCacheDirectory(): string {
    if (this.cacheDir) {
      return this.cacheDir;
    }

    // Use app.getPath('userData') for cross-platform compatibility
    // This gives us:
    // - macOS: ~/Library/Application Support/hive-browser/cache
    // - Windows: %APPDATA%/hive-browser/cache
    // - Linux: ~/.config/hive-browser/cache
    const userDataPath = app.getPath('userData');
    this.cacheDir = path.join(userDataPath, 'cache');

    // Ensure cache directory exists
    if (!fs.existsSync(this.cacheDir)) {
      fs.mkdirSync(this.cacheDir, { recursive: true });
      console.log('[CACHE] Created cache directory:', this.cacheDir);
    }

    return this.cacheDir;
  }

  /**
   * Get full path for a cached file
   */
  static getCacheFilePath(filename: string): string {
    const cacheDir = this.getCacheDirectory();
    return path.join(cacheDir, filename);
  }

  /**
   * Clean up old files (optional: keep files from last 7 days)
   */
  static cleanupOldFiles(daysToKeep: number = 7): void {
    try {
      const cacheDir = this.getCacheDirectory();
      const files = fs.readdirSync(cacheDir);
      const now = Date.now();
      const maxAge = daysToKeep * 24 * 60 * 60 * 1000; // Convert days to milliseconds

      let deletedCount = 0;
      for (const file of files) {
        // Skip hidden files and the devices.json file
        if (file.startsWith('.') || file === 'devices.json') {
          continue;
        }

        const filePath = path.join(cacheDir, file);
        try {
          const stats = fs.statSync(filePath);
          const age = now - stats.mtime.getTime();

          if (age > maxAge) {
            fs.unlinkSync(filePath);
            deletedCount++;
            console.log(`[CACHE] Deleted old file: ${file}`);
          }
        } catch (err) {
          console.error(`[CACHE] Error checking file ${file}:`, err);
        }
      }

      if (deletedCount > 0) {
        console.log(`[CACHE] Cleaned up ${deletedCount} old file(s)`);
      }
    } catch (err) {
      console.error('[CACHE] Error during cleanup:', err);
    }
  }

  /**
   * Save device ID mapping
   */
  static saveDeviceMapping(deviceId: string, filename: string): void {
    try {
      const cacheDir = this.getCacheDirectory();
      const mappingPath = path.join(cacheDir, '.devices.json');
      
      let mappings: Record<string, string> = {};
      if (fs.existsSync(mappingPath)) {
        const content = fs.readFileSync(mappingPath, 'utf-8');
        mappings = JSON.parse(content);
      }

      mappings[deviceId] = filename;
      fs.writeFileSync(mappingPath, JSON.stringify(mappings, null, 2));
    } catch (err) {
      console.error('[CACHE] Error saving device mapping:', err);
    }
  }

  /**
   * Get device ID mapping
   */
  static getDeviceMapping(): Record<string, string> {
    try {
      const cacheDir = this.getCacheDirectory();
      const mappingPath = path.join(cacheDir, '.devices.json');
      
      if (fs.existsSync(mappingPath)) {
        const content = fs.readFileSync(mappingPath, 'utf-8');
        return JSON.parse(content);
      }
    } catch (err) {
      console.error('[CACHE] Error reading device mapping:', err);
    }
    return {};
  }
}

