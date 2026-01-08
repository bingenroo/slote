import { exec } from 'child_process';
import { promisify } from 'util';
import * as path from 'path';
import * as fs from 'fs';
import { CacheManager } from './cache-manager';

const execAsync = promisify(exec);

// Configuration
const PACKAGE_NAME = 'com.example.slote';
const BOX_NAME = 'notes';
const REMOTE_PATH = `/data/data/${PACKAGE_NAME}/app_flutter/${BOX_NAME}.hive`;
const REMOTE_JSON_PATH = `/data/data/${PACKAGE_NAME}/app_flutter/${BOX_NAME}.json`;

/**
 * Emulator Sync Service - Syncs Hive database files from Android emulators
 */
export class EmulatorSync {
  /**
   * Check if ADB is available in PATH
   */
  static async checkAdbAvailable(): Promise<boolean> {
    try {
      await execAsync('adb version');
      return true;
    } catch (err) {
      console.log('[EMULATOR-SYNC] ADB not found in PATH');
      return false;
    }
  }

  /**
   * Get list of connected Android devices
   * Returns array of device IDs (e.g., ['emulator-5554', 'emulator-5556'])
   */
  static async getConnectedDevices(): Promise<string[]> {
    try {
      const { stdout } = await execAsync('adb devices');
      const lines = stdout.split('\n');
      const devices: string[] = [];

      for (const line of lines) {
        // Skip header line and empty lines
        if (line.trim() === '' || line.includes('List of devices')) {
          continue;
        }

        // Parse device line: "emulator-5554    device"
        const parts = line.trim().split(/\s+/);
        if (parts.length >= 2 && parts[1] === 'device') {
          devices.push(parts[0]);
        }
      }

      console.log(
        `[EMULATOR-SYNC] Found ${devices.length} connected device(s):`,
        devices
      );
      return devices;
    } catch (err) {
      console.error('[EMULATOR-SYNC] Error getting connected devices:', err);
      return [];
    }
  }

  /**
   * Extract device ID from cached filename (e.g., "notes-emulator-5554.hive" -> "emulator-5554")
   */
  static extractDeviceIdFromFilename(filename: string): string | null {
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'emulator-sync.ts:69',
        message: 'extractDeviceIdFromFilename called',
        data: { filename },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'auto-refresh-debug',
        hypothesisId: 'B',
      }),
    }).catch(() => {});
    // #endregion
    const match = filename.match(/emulator-[0-9]+/);
    const deviceId = match ? match[0] : null;
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'emulator-sync.ts:75',
        message: 'extractDeviceIdFromFilename result',
        data: { filename, deviceId, match: match ? match[0] : null },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'auto-refresh-debug',
        hypothesisId: 'B',
      }),
    }).catch(() => {});
    // #endregion
    return deviceId;
  }

  /**
   * Check if remote file has changed by pulling it to a temp location and comparing size
   */
  static async checkFileChanged(
    deviceId: string,
    lastKnownSize: number
  ): Promise<boolean> {
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'emulator-sync.ts:77',
        message: 'checkFileChanged called',
        data: { deviceId, lastKnownSize },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'auto-refresh-debug',
        hypothesisId: 'E',
      }),
    }).catch(() => {});
    // #endregion
    try {
      const exists = await this.fileExistsOnDevice(deviceId, REMOTE_PATH);
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:95',
            message: 'File exists check result',
            data: { deviceId, exists, REMOTE_PATH },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'auto-refresh-debug',
            hypothesisId: 'E',
          }),
        }
      ).catch(() => {});
      // #endregion
      if (!exists) {
        return false;
      }

      // Pull file to temp location to check size
      const tempPath = path.join(
        CacheManager.getCacheDirectory(),
        `temp_check_${deviceId}_${Date.now()}.hive`
      );

      try {
        // Try method 1: copy to temp, then pull
        const sdcardTemp = `/sdcard/temp_check_${Date.now()}.hive`;
        try {
          await execAsync(
            `adb -s ${deviceId} shell run-as ${PACKAGE_NAME} cp ${REMOTE_PATH} ${sdcardTemp} 2>&1`
          );
          await execAsync(
            `adb -s ${deviceId} pull ${sdcardTemp} "${tempPath}"`
          );
          await execAsync(`adb -s ${deviceId} shell rm ${sdcardTemp} 2>&1`);
        } catch {
          // Fallback: use exec-out
          const { stdout } = await execAsync(
            `adb -s ${deviceId} exec-out run-as ${PACKAGE_NAME} cat ${REMOTE_PATH} 2>&1`,
            { maxBuffer: 10 * 1024 * 1024 }
          );
          fs.writeFileSync(tempPath, stdout);
        }

        // Check file size
        if (fs.existsSync(tempPath)) {
          const stats = fs.statSync(tempPath);
          const remoteSize = stats.size;
          const hasChanged = remoteSize !== lastKnownSize;
          // #region agent log
          fetch(
            'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                location: 'emulator-sync.ts:130',
                message: 'File size comparison result',
                data: { deviceId, remoteSize, lastKnownSize, hasChanged },
                timestamp: Date.now(),
                sessionId: 'debug-session',
                runId: 'auto-refresh-debug',
                hypothesisId: 'E',
              }),
            }
          ).catch(() => {});
          // #endregion
          // Clean up temp file
          fs.unlinkSync(tempPath);
          return hasChanged;
        }
      } catch (err) {
        // Clean up temp file if it exists
        if (fs.existsSync(tempPath)) {
          try {
            fs.unlinkSync(tempPath);
          } catch {}
        }
        throw err;
      }

      return false;
    } catch (err) {
      console.error(
        `[EMULATOR-SYNC] Error checking file change for device ${deviceId}:`,
        err
      );
      return false;
    }
  }

  /**
   * Check if package is installed and accessible on device
   */
  static async isPackageInstalled(deviceId: string): Promise<boolean> {
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'emulator-sync.ts:68',
        message: 'isPackageInstalled called',
        data: { deviceId, PACKAGE_NAME },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'run1',
        hypothesisId: 'A',
      }),
    }).catch(() => {});
    // #endregion
    try {
      const { stdout } = await execAsync(
        `adb -s ${deviceId} shell pm list packages | grep ${PACKAGE_NAME}`
      );
      const result = stdout.trim().includes(PACKAGE_NAME);
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:73',
            message: 'isPackageInstalled result',
            data: { deviceId, result, stdout: stdout.substring(0, 200) },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run1',
            hypothesisId: 'A',
          }),
        }
      ).catch(() => {});
      // #endregion
      return result;
    } catch (err) {
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:75',
            message: 'isPackageInstalled error',
            data: {
              deviceId,
              error: err instanceof Error ? err.message : String(err),
            },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run1',
            hypothesisId: 'A',
          }),
        }
      ).catch(() => {});
      // #endregion
      return false;
    }
  }

  /**
   * Check if file exists on device
   */
  static async fileExistsOnDevice(
    deviceId: string,
    remotePath: string
  ): Promise<boolean> {
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'emulator-sync.ts:82',
        message: 'fileExistsOnDevice called',
        data: { deviceId, remotePath },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'run1',
        hypothesisId: 'B',
      }),
    }).catch(() => {});
    // #endregion
    try {
      // First check if package is installed
      const packageInstalled = await this.isPackageInstalled(deviceId);
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:88',
            message: 'packageInstalled check result',
            data: { deviceId, packageInstalled },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run1',
            hypothesisId: 'B',
          }),
        }
      ).catch(() => {});
      // #endregion
      if (!packageInstalled) {
        console.log(
          `[EMULATOR-SYNC] Package ${PACKAGE_NAME} not installed on device ${deviceId}`
        );
        return false;
      }

      // Use 'adb shell run-as' to check if file exists without root
      const { stdout, stderr } = await execAsync(
        `adb -s ${deviceId} shell run-as ${PACKAGE_NAME} test -f ${remotePath} && echo "exists" || echo "not_exists" 2>&1`
      );
      const output = (stdout + stderr).trim();
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:97',
            message: 'fileExistsOnDevice output',
            data: { deviceId, output: output.substring(0, 200) },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run1',
            hypothesisId: 'B',
          }),
        }
      ).catch(() => {});
      // #endregion
      // Check for error messages
      if (
        output.includes('run-as:') ||
        output.includes('unknown package') ||
        output.includes('not found')
      ) {
        console.log(
          `[EMULATOR-SYNC] run-as failed for package ${PACKAGE_NAME}: ${output}`
        );
        // #region agent log
        fetch(
          'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              location: 'emulator-sync.ts:106',
              message: 'fileExistsOnDevice error detected',
              data: { deviceId, output: output.substring(0, 200) },
              timestamp: Date.now(),
              sessionId: 'debug-session',
              runId: 'run1',
              hypothesisId: 'B',
            }),
          }
        ).catch(() => {});
        // #endregion
        return false;
      }
      // Check for explicit "exists" or "not_exists" in output
      // The test command outputs "exists" or "not_exists" explicitly
      const hasExists = output.includes('exists');
      const hasNotExists = output.includes('not_exists');
      const exists = hasExists && !hasNotExists;

      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:112',
            message: 'fileExistsOnDevice result',
            data: {
              deviceId,
              remotePath,
              exists,
              hasExists,
              hasNotExists,
              output: output.substring(0, 200),
            },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run1',
            hypothesisId: 'B',
          }),
        }
      ).catch(() => {});
      // #endregion
      return exists;
    } catch (err) {
      // If run-as fails, try with ls command
      try {
        const { stdout, stderr } = await execAsync(
          `adb -s ${deviceId} shell run-as ${PACKAGE_NAME} ls ${remotePath} 2>&1`
        );
        const output = (stdout + stderr).trim();
        // Check for error messages
        if (
          output.includes('run-as:') ||
          output.includes('unknown package') ||
          output.includes('No such file')
        ) {
          return false;
        }
        return true;
      } catch {
        return false;
      }
    }
  }

  /**
   * Pull Hive file from a specific device
   * Returns local file path if successful, null otherwise
   */
  static async pullHiveFile(deviceId: string): Promise<string | null> {
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'emulator-sync.ts:139',
        message: 'pullHiveFile called',
        data: { deviceId, REMOTE_PATH },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'run1',
        hypothesisId: 'F',
      }),
    }).catch(() => {});
    // #endregion
    try {
      // First, try to pull JSON export if it exists (preferred format)
      const jsonExists = await this.fileExistsOnDevice(
        deviceId,
        REMOTE_JSON_PATH
      );
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:463',
            message: 'JSON file existence check result',
            data: { deviceId, jsonExists, REMOTE_JSON_PATH },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'json-export-debug',
            hypothesisId: 'I',
          }),
        }
      ).catch(() => {});
      // #endregion
      if (jsonExists) {
        console.log(`[EMULATOR-SYNC] Found JSON export, pulling JSON file...`);
        // #region agent log
        fetch(
          'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              location: 'emulator-sync.ts:475',
              message: 'Pulling JSON file',
              data: { deviceId, REMOTE_JSON_PATH },
              timestamp: Date.now(),
              sessionId: 'debug-session',
              runId: 'json-export-debug',
              hypothesisId: 'I',
            }),
          }
        ).catch(() => {});
        // #endregion
        const sanitizedDeviceId = deviceId.replace(/[^a-zA-Z0-9_-]/g, '_');
        const jsonFilename = `${BOX_NAME}-${sanitizedDeviceId}.json`;
        const jsonLocalPath = CacheManager.getCacheFilePath(jsonFilename);

        // Pull JSON file using exec-out (more reliable than cp)
        try {
          // #region agent log
          fetch(
            'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                location: 'emulator-sync.ts:507',
                message: 'Starting JSON file pull with exec-out',
                data: { deviceId, jsonLocalPath, REMOTE_JSON_PATH },
                timestamp: Date.now(),
                sessionId: 'debug-session',
                runId: 'json-pull-debug',
                hypothesisId: 'M',
              }),
            }
          ).catch(() => {});
          // #endregion
          // Use exec-out to directly get file content (more reliable)
          const { stdout, stderr } = await execAsync(
            `adb -s ${deviceId} exec-out run-as ${PACKAGE_NAME} cat ${REMOTE_JSON_PATH}`,
            { maxBuffer: 10 * 1024 * 1024 }
          );

          // Check if output looks like an error message
          const output = stdout.trim();
          if (
            output.startsWith('cat:') ||
            output.startsWith('run-as:') ||
            output.includes('No such file') ||
            output.length === 0
          ) {
            throw new Error(
              `Failed to read JSON file: ${output.substring(0, 100)}`
            );
          }

          // Try to parse as JSON to verify it's valid
          try {
            JSON.parse(output);
          } catch (parseErr) {
            throw new Error(
              `Pulled file is not valid JSON: ${output.substring(0, 100)}`
            );
          }

          fs.writeFileSync(jsonLocalPath, output);

          const fileExists = fs.existsSync(jsonLocalPath);
          const fileSize = fileExists ? fs.statSync(jsonLocalPath).size : 0;
          // #region agent log
          fetch(
            'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                location: 'emulator-sync.ts:530',
                message: 'JSON file pull result',
                data: {
                  deviceId,
                  jsonLocalPath,
                  fileExists,
                  fileSize,
                  willReturn: fileExists && fileSize > 0,
                },
                timestamp: Date.now(),
                sessionId: 'debug-session',
                runId: 'json-pull-debug',
                hypothesisId: 'M',
              }),
            }
          ).catch(() => {});
          // #endregion

          if (fileExists && fileSize > 0) {
            CacheManager.saveDeviceMapping(deviceId, jsonFilename);
            // #region agent log
            fetch(
              'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
              {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  location: 'emulator-sync.ts:545',
                  message: 'Returning JSON file path',
                  data: { deviceId, jsonLocalPath },
                  timestamp: Date.now(),
                  sessionId: 'debug-session',
                  runId: 'json-pull-debug',
                  hypothesisId: 'M',
                }),
              }
            ).catch(() => {});
            // #endregion
            return jsonLocalPath;
          } else {
            // #region agent log
            fetch(
              'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
              {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  location: 'emulator-sync.ts:558',
                  message: 'JSON file pull failed - file missing or empty',
                  data: { deviceId, jsonLocalPath, fileExists, fileSize },
                  timestamp: Date.now(),
                  sessionId: 'debug-session',
                  runId: 'json-pull-debug',
                  hypothesisId: 'M',
                }),
              }
            ).catch(() => {});
            // #endregion
          }
        } catch (err) {
          console.log(
            `[EMULATOR-SYNC] Failed to pull JSON, trying binary:`,
            err
          );
          // #region agent log
          fetch(
            'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                location: 'emulator-sync.ts:573',
                message: 'JSON file pull exception',
                data: {
                  deviceId,
                  error: err instanceof Error ? err.message : String(err),
                },
                timestamp: Date.now(),
                sessionId: 'debug-session',
                runId: 'json-pull-debug',
                hypothesisId: 'M',
              }),
            }
          ).catch(() => {});
          // #endregion
        }
      }

      // Fall back to binary .hive file
      // Check if file exists on device
      const exists = await this.fileExistsOnDevice(deviceId, REMOTE_PATH);
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:143',
            message: 'fileExistsOnDevice result in pullHiveFile',
            data: { deviceId, exists },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run1',
            hypothesisId: 'F',
          }),
        }
      ).catch(() => {});
      // #endregion
      if (!exists) {
        console.log(`[EMULATOR-SYNC] File not found on device ${deviceId}`);
        // #region agent log
        fetch(
          'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              location: 'emulator-sync.ts:145',
              message: 'pullHiveFile returning null - file not exists',
              data: { deviceId },
              timestamp: Date.now(),
              sessionId: 'debug-session',
              runId: 'run1',
              hypothesisId: 'F',
            }),
          }
        ).catch(() => {});
        // #endregion
        return null;
      }

      // Binary .hive files are now supported with the binary parser
      // Pull the binary file
      const sanitizedDeviceId = deviceId.replace(/[^a-zA-Z0-9_-]/g, '_');
      const filename = `${BOX_NAME}-${sanitizedDeviceId}.hive`;
      const localPath = CacheManager.getCacheFilePath(filename);

      console.log(
        `[EMULATOR-SYNC] Pulling binary .hive file from device ${deviceId}...`
      );

      // Pull file using adb
      const tempPath = `/sdcard/temp_${BOX_NAME}_${Date.now()}.hive`;
      try {
        // Copy file to temp location
        await execAsync(
          `adb -s ${deviceId} shell run-as ${PACKAGE_NAME} cp ${REMOTE_PATH} ${tempPath} 2>&1`
        );
        // Pull from temp location
        await execAsync(`adb -s ${deviceId} pull ${tempPath} "${localPath}"`);
        // Clean up temp file
        await execAsync(`adb -s ${deviceId} shell rm ${tempPath} 2>&1`);
      } catch (err) {
        // Fallback: use exec-out
        try {
          const { stdout, stderr } = await execAsync(
            `adb -s ${deviceId} exec-out run-as ${PACKAGE_NAME} cat ${REMOTE_PATH} 2>&1`,
            { maxBuffer: 10 * 1024 * 1024 }
          );
          const output = stdout || stderr || '';
          if (
            output.includes('run-as:') ||
            output.includes('unknown package') ||
            output.includes('not found')
          ) {
            return null;
          }
          if (output.length < 10) {
            return null;
          }
          fs.writeFileSync(localPath, output);
        } catch (fallbackErr) {
          console.error(
            `[EMULATOR-SYNC] Failed to pull from device ${deviceId}:`,
            fallbackErr
          );
          return null;
        }
      }

      // Verify file was pulled successfully
      if (fs.existsSync(localPath)) {
        const stats = fs.statSync(localPath);
        if (stats.size > 0) {
          console.log(
            `[EMULATOR-SYNC] Successfully pulled binary file from ${deviceId} to ${localPath} (${stats.size} bytes)`
          );
          CacheManager.saveDeviceMapping(deviceId, filename);
          return localPath;
        } else {
          fs.unlinkSync(localPath);
          return null;
        }
      } else {
        return null;
      }
    } catch (err) {
      console.error(
        `[EMULATOR-SYNC] Error pulling file from device ${deviceId}:`,
        err
      );
      return null;
    }
  }

  /**
   * Sync Hive files from all connected emulators
   * Returns array of local file paths
   */
  static async syncFromEmulators(): Promise<string[]> {
    console.log('[EMULATOR-SYNC] Starting sync from emulators...');
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'emulator-sync.ts:682',
        message: 'syncFromEmulators started',
        data: {},
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'run1',
        hypothesisId: 'G',
      }),
    }).catch(() => {});
    // #endregion

    // Check if ADB is available
    const adbAvailable = await this.checkAdbAvailable();
    if (!adbAvailable) {
      console.log('[EMULATOR-SYNC] ADB not available');
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:688',
            message: 'ADB not available',
            data: {},
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run1',
            hypothesisId: 'G',
          }),
        }
      ).catch(() => {});
      // #endregion
      return [];
    }

    // Get connected devices
    const devices = await this.getConnectedDevices();
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'emulator-sync.ts:693',
        message: 'Connected devices',
        data: { devices, deviceCount: devices.length },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'run1',
        hypothesisId: 'G',
      }),
    }).catch(() => {});
    // #endregion
    if (devices.length === 0) {
      console.log('[EMULATOR-SYNC] No devices connected');
      return [];
    }

    // Pull files from all devices
    const pulledFiles: string[] = [];
    for (const deviceId of devices) {
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:707',
            message: 'Processing device',
            data: { deviceId },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run1',
            hypothesisId: 'G',
          }),
        }
      ).catch(() => {});
      // #endregion
      const filePath = await this.pullHiveFile(deviceId);
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'emulator-sync.ts:710',
            message: 'pullHiveFile result',
            data: { deviceId, filePath, wasAdded: !!filePath },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run1',
            hypothesisId: 'G',
          }),
        }
      ).catch(() => {});
      // #endregion
      if (filePath) {
        pulledFiles.push(filePath);
      }
    }

    console.log(
      `[EMULATOR-SYNC] Sync complete. Pulled ${pulledFiles.length} file(s) from ${devices.length} device(s)`
    );
    // #region agent log
    fetch('http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        location: 'emulator-sync.ts:725',
        message: 'syncFromEmulators complete',
        data: { pulledFilesCount: pulledFiles.length, pulledFiles },
        timestamp: Date.now(),
        sessionId: 'debug-session',
        runId: 'run1',
        hypothesisId: 'G',
      }),
    }).catch(() => {});
    // #endregion
    return pulledFiles;
  }
}
