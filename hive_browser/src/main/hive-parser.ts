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
  /**
   * Check if a file is binary (Hive binary format)
   * Hive binary files start with magic byte 'F' (0x46)
   */
  static isBinaryHiveFile(filePath: string): boolean {
    try {
      const buffer = fs.readFileSync(filePath);
      // Check if file starts with Hive magic byte 'F' (0x46)
      // Binary Hive files typically start with 'F' followed by version info
      if (buffer.length > 0 && buffer[0] === 0x46) {
        return true;
      }
      // Also check if file contains non-UTF8 characters
      try {
        buffer.toString('utf-8');
      } catch {
        return true; // Contains invalid UTF-8, likely binary
      }
      return false;
    } catch {
      return false;
    }
  }

  /**
   * Parse a Note object from binary bytes
   * Format based on NoteAdapter:
   * - typeId: 0 (1 byte) - but may not be present if already extracted
   * - numFields: 5 (1 byte)
   * - field 0 (1 byte) + id (int, 4 bytes LE)
   * - field 1 (1 byte) + title (string: length byte + UTF-8)
   * - field 2 (1 byte) + body (string: length byte + UTF-8)
   * - field 3 (1 byte) + drawingData (nullable string: 0x01 if null, else length + UTF-8)
   * - field 4 (1 byte) + lastMod (DateTime: 8 bytes as microseconds since epoch)
   */
  static parseNoteObject(bytes: Buffer, keyHint: string): Note | null {
    try {
      let offset = 0;

      // NoteAdapter format: numFields (1 byte) + fields
      // No typeId in the value bytes - it's stored separately in Hive metadata
      // Read number of fields
      if (offset >= bytes.length) return null;
      const numFields = bytes[offset];
      offset += 1;

      if (numFields !== 5) {
        // Not a Note object (Note has 5 fields)
        return null;
      }

      const fields: { [key: number]: any } = {};

      // Read fields: fieldIndex (1 byte) + value
      while (offset < bytes.length && Object.keys(fields).length < numFields) {
        if (offset >= bytes.length) break;
        const fieldIndex = bytes[offset];
        offset += 1;

        if (fieldIndex === 0) {
          // id: int (4 bytes little-endian)
          if (offset + 4 > bytes.length) break;
          fields[0] = bytes.readInt32LE(offset);
          offset += 4;
        } else if (fieldIndex === 1) {
          // title: string
          if (offset >= bytes.length) break;
          const strLength = bytes[offset];
          offset += 1;
          if (offset + strLength > bytes.length) break;
          fields[1] = bytes.slice(offset, offset + strLength).toString('utf-8');
          offset += strLength;
        } else if (fieldIndex === 2) {
          // body: string
          if (offset >= bytes.length) break;
          const strLength = bytes[offset];
          offset += 1;
          if (offset + strLength > bytes.length) break;
          fields[2] = bytes.slice(offset, offset + strLength).toString('utf-8');
          offset += strLength;
        } else if (fieldIndex === 3) {
          // drawingData: nullable string
          if (offset >= bytes.length) break;
          if (bytes[offset] === 0x01) {
            // Null value
            fields[3] = null;
            offset += 1;
          } else {
            const strLength = bytes[offset];
            offset += 1;
            if (offset + strLength > bytes.length) break;
            fields[3] = bytes
              .slice(offset, offset + strLength)
              .toString('utf-8');
            offset += strLength;
          }
        } else if (fieldIndex === 4) {
          // lastMod: DateTime (8 bytes as microseconds since epoch)
          if (offset + 8 > bytes.length) break;
          // Hive stores DateTime as microseconds since Unix epoch
          const microsecondsBigInt = bytes.readBigUInt64LE(offset);
          // Convert microseconds to milliseconds
          const milliseconds = Number(microsecondsBigInt / 1000n);
          fields[4] = new Date(milliseconds);
          offset += 8;
        } else {
          // Unknown field, skip (but we need to know how to skip it)
          // This is a simplified parser - might need more work
          break;
        }
      }

      if (Object.keys(fields).length === 5 && fields[0] !== undefined) {
        return {
          id: fields[0],
          title: fields[1] || '',
          body: fields[2] || '',
          drawingData: fields[3] ?? null,
          lastMod: fields[4] ? fields[4].getTime() : Date.now(),
        };
      }

      return null;
    } catch (err) {
      return null;
    }
  }

  /**
   * Parse binary Hive file format
   * Based on reverse engineering of Hive binary structure:
   * - Magic byte: 0x46 ('F')
   * - Version info: 4 bytes
   * - Records: Each record has type info, key, and value
   */
  static parseBinaryHiveFile(filePath: string): DatabaseInfo {
    const stats = fs.statSync(filePath);
    const buffer = fs.readFileSync(filePath);

    if (buffer.length < 5 || buffer[0] !== 0x46) {
      throw new Error('Invalid Hive binary file: missing magic byte');
    }

    let offset = 5; // Skip magic byte (1) + version (4)
    const records: HiveRecord[] = [];
    const keys: (string | number)[] = [];

    // Parse records until end of file
    // Format: type byte (0x02 for key, 0x03 for value) + length (4 bytes LE) + data
    while (offset < buffer.length - 10) {
      try {
        // Look for key-value pairs
        // Keys can be integers or strings
        // For Note objects: key is note.id (integer), value is Note object
        // Hive binary format for records:
        // - Key type byte + key data
        // - Value type byte + value data

        // Try to detect integer key first (common for Note objects)
        // Integer keys in Hive: might be stored as type byte + 4-byte int
        // But the exact format depends on Hive's internal encoding

        if (buffer[offset] === 0x02 && offset + 5 < buffer.length) {
          // String key: type byte (0x02), then 0x04, then actual length byte, then 0x00 0x00 0x00
          // Format: 0x02 0x04 [length_byte] 0x00 0x00 0x00 [key_data]
          // So length is at offset + 2, not offset + 1
          const lengthByte = buffer[offset + 2];

          if (
            lengthByte > 0 &&
            lengthByte < 1000 &&
            offset + 6 + lengthByte < buffer.length
          ) {
            const keyLength = lengthByte;
            // Key data starts after: 0x02 (1) + 0x04 (1) + [length] (1) + 0x00 0x00 0x00 (3) = 6 bytes
            const keyBytes = buffer.slice(offset + 6, offset + 6 + keyLength);
            const key = keyBytes.toString('utf-8');

            // Look for value (type 0x03) after key
            const valueStartOffset = offset + 6 + keyLength;

            if (
              valueStartOffset < buffer.length &&
              buffer[valueStartOffset] === 0x03
            ) {
              // Value length might be stored in different formats
              // Try multiple interpretations:
              // 1. Single byte at offset + 2
              // 2. 4-byte little-endian integer
              // 3. Variable-length encoding
              const valueLengthByte = buffer[valueStartOffset + 2];
              // Try 4-byte little-endian first (more likely for larger values)
              const valueLengthLE = buffer.readUInt32LE(valueStartOffset + 2);
              // Use single byte if it's reasonable, otherwise try 4-byte
              const valueLength =
                valueLengthByte < 250 && valueLengthByte > 0
                  ? valueLengthByte
                  : valueLengthLE < 10000 && valueLengthLE > 0
                    ? valueLengthLE
                    : valueLengthByte;

              if (
                valueLength > 0 &&
                valueLength < 10000 &&
                valueStartOffset + 6 + valueLength <= buffer.length
              ) {
                // Value data starts after: 0x03 (1) + 0x04 (1) + [length] (1) + 0x00 0x00 0x00 (3) = 6 bytes
                const valueBytes = buffer.slice(
                  valueStartOffset + 6,
                  valueStartOffset + 6 + valueLength
                );

                // Check if this is a typed object (Note with typeId 0)
                // Hive typed objects: numFields (1 byte) + fields (fieldIndex + value pairs)
                // NoteAdapter writes: 5 (numFields), then field indices 0,1,2,3,4 with values
                // The typeId is stored separately in Hive's metadata, not in the value bytes
                let value: any;

                // Try to parse as Note object if it starts with 0x05 (5 fields)
                // or if it's a reasonable size for a Note object
                if (
                  valueBytes.length > 0 &&
                  (valueBytes[0] === 0x05 ||
                    (valueBytes.length > 10 && valueBytes.length < 1000))
                ) {
                  try {
                    value = HiveParser.parseNoteObject(valueBytes, key);
                  } catch (err) {
                    // Failed to parse as Note, will try JSON below
                  }
                }

                // If not parsed as Note, try as JSON string
                if (!value) {
                  const valueStr = valueBytes.toString('utf-8');

                  try {
                    value = JSON.parse(valueStr);

                    // Check if this is the wrong format: key is title, value is {"lines":[]}
                    // We need to reconstruct a Note object from the key (title)
                    if (
                      value &&
                      typeof value === 'object' &&
                      'lines' in value &&
                      Array.isArray(value.lines)
                    ) {
                      // Reconstruct Note object: key is title, body is from lines array
                      // Generate a stable ID from the key string
                      let noteId: number;
                      if (typeof key === 'string' && /^\d+$/.test(key)) {
                        noteId = parseInt(key, 10);
                      } else {
                        // Generate ID from string hash
                        let hash = 0;
                        for (let i = 0; i < key.length; i++) {
                          const char = key.charCodeAt(i);
                          hash = (hash << 5) - hash + char;
                          hash = hash & hash; // Convert to 32-bit integer
                        }
                        noteId = Math.abs(hash) & 0xffffffff;
                      }

                      value = {
                        id: noteId,
                        title: String(key),
                        body:
                          value.lines && value.lines.length > 0
                            ? value.lines.join('\n')
                            : '',
                        drawingData: null,
                        lastMod: Date.now(),
                      } as Note;
                    }
                  } catch {
                    // Not JSON, use as raw string value
                    value = valueStr;
                  }
                }

                // If we have a value (either from Note parsing or JSON/string parsing)
                if (value !== undefined) {
                  // If value is a Note object, use note.id as the key
                  let recordKey: string | number = key;
                  if (
                    value &&
                    typeof value === 'object' &&
                    'id' in value &&
                    'title' in value &&
                    'body' in value
                  ) {
                    // This is a Note object - use the id as the key
                    recordKey = (value as Note).id;
                  } else {
                    // Try to parse key as integer if it's numeric
                    recordKey = /^\d+$/.test(key) ? parseInt(key, 10) : key;
                  }

                  records.push({ key: recordKey, value });
                  keys.push(recordKey);

                  offset = valueStartOffset + 6 + valueLength;
                  continue;
                }
              }
            }
          }
        }

        // Advance offset if we didn't find a valid record
        offset += 1;
      } catch (err) {
        offset += 1;
      }
    }

    return {
      path: filePath,
      boxes: [
        {
          name: 'notes',
          keys: keys,
          recordCount: records.length,
        },
      ],
      fileSize: stats.size,
      lastModified: stats.mtime,
    };
  }

  static async parseDatabase(filePath: string): Promise<DatabaseInfo> {
    const stats = fs.statSync(filePath);

    // Check if file is binary Hive format
    const isBinary = this.isBinaryHiveFile(filePath);
    if (isBinary) {
      return this.parseBinaryHiveFile(filePath);
    }

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

      // Handle export format from hive_export.dart: { boxes: [...], notes: [...] }
      if (data.notes && Array.isArray(data.notes)) {
        const records: HiveRecord[] = data.notes.map((item: any) => ({
          key: item.id || item.key || 0,
          value: item,
        }));

        return {
          path: filePath,
          boxes: [
            {
              name: 'notes',
              keys: records.map((r) => r.key),
              recordCount: records.length,
            },
          ],
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
          boxes: [
            {
              name: 'notes',
              keys: records.map((r) => r.key),
              recordCount: records.length,
            },
          ],
          fileSize: stats.size,
          lastModified: stats.mtime,
        };
      }

      throw new Error('Unsupported file format');
    } catch (error) {
      // If JSON parsing fails, try binary format (placeholder)
      throw new Error(
        `Failed to parse Hive file: ${error instanceof Error ? error.message : 'Unknown error'}`
      );
    }
  }

  /**
   * Read records from a box
   */
  static async readBox(
    filePath: string,
    boxName: string
  ): Promise<HiveRecord[]> {
    // Check if file is binary Hive format
    if (this.isBinaryHiveFile(filePath)) {
      // Parse binary file and extract records
      const buffer = fs.readFileSync(filePath);
      if (buffer.length < 5 || buffer[0] !== 0x46) {
        return [];
      }

      let offset = 5; // Skip magic byte (1) + version (4)
      const records: HiveRecord[] = [];

      while (offset < buffer.length - 10) {
        try {
          if (buffer[offset] === 0x02 && offset + 6 < buffer.length) {
            const lengthByte = buffer[offset + 2];

            if (
              lengthByte > 0 &&
              lengthByte < 1000 &&
              offset + 6 + lengthByte < buffer.length
            ) {
              const keyLength = lengthByte;
              const keyBytes = buffer.slice(offset + 6, offset + 6 + keyLength);
              const key = keyBytes.toString('utf-8');

              // Look for value (type 0x03) after key
              const valueStartOffset = offset + 6 + keyLength;

              if (
                valueStartOffset < buffer.length &&
                buffer[valueStartOffset] === 0x03
              ) {
                const valueLengthByte = buffer[valueStartOffset + 2];
                const valueLength = valueLengthByte;

                if (
                  valueLength > 0 &&
                  valueLength < 10000 &&
                  valueStartOffset + 6 + valueLength <= buffer.length
                ) {
                  const valueBytes = buffer.slice(
                    valueStartOffset + 6,
                    valueStartOffset + 6 + valueLength
                  );
                  const valueStr = valueBytes.toString('utf-8');

                  // Try to parse as JSON
                  try {
                    const value = JSON.parse(valueStr);
                    const recordKey = /^\d+$/.test(key)
                      ? parseInt(key, 10)
                      : key;
                    records.push({ key: recordKey, value });
                    offset = valueStartOffset + 6 + valueLength;
                    continue;
                  } catch {
                    // Not JSON, try as raw string value
                    const recordKey = /^\d+$/.test(key)
                      ? parseInt(key, 10)
                      : key;
                    records.push({ key: recordKey, value: valueStr });
                    offset = valueStartOffset + 6 + valueLength;
                    continue;
                  }
                }
              }
            }
          }

          // Advance offset if we didn't find a valid record
          offset += 1;
        } catch (err) {
          offset += 1;
        }
      }

      return records;
    }

    // Handle JSON format
    const fileContent = fs.readFileSync(filePath, 'utf-8');
    const data = JSON.parse(fileContent);

    // Handle export format from hive_export.dart: { boxes: [...], notes: [...] }
    if (data.notes && Array.isArray(data.notes)) {
      const records = data.notes.map((item: any) => ({
        key: item.id || item.key || 0,
        value: item,
      }));
      return records;
    }

    // Handle structure with boxes object containing records
    if (data.boxes && typeof data.boxes === 'object') {
      // If boxes is an object with boxName key
      if (data.boxes[boxName] && data.boxes[boxName].records) {
        return data.boxes[boxName].records.map((item: any) => ({
          key: item.id || item.key || 0,
          value: item,
        }));
      }
      // If boxes is an array
      if (Array.isArray(data.boxes)) {
        const box = data.boxes.find((b: any) => b.name === boxName);
        if (box && box.records) {
          return box.records.map((item: any) => ({
            key: item.id || item.key || 0,
            value: item,
          }));
        }
      }
    }

    // Handle simple array format
    if (Array.isArray(data)) {
      return data.map((item: any, index: number) => ({
        key: item.id || item.key || index,
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
  static async writeDatabase(
    filePath: string,
    boxes: Record<string, HiveRecord[]>
  ): Promise<void> {
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
  static async exportToJson(
    filePath: string,
    outputPath: string
  ): Promise<void> {
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
