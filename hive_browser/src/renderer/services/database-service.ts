import { HiveRecord, DatabaseInfo, Note } from '../../shared/types';

export class DatabaseService {
  /**
   * Transform records to note format: [{ "note title": [note description] }]
   * Handles both proper Note objects and the current binary parser output
   */
  static transformToNoteFormat(records: HiveRecord[]): Array<Record<string, string[]>> {
    return records.map((record, index) => {
      let noteTitle: string;
      let noteDescription: string = '';
      let lastMod: Date | null = null;

      // Check if value is a proper Note object
      if (
        record.value &&
        typeof record.value === 'object' &&
        'id' in record.value &&
        'title' in record.value &&
        'body' in record.value
      ) {
        const note = record.value as Note;
        noteTitle = note.title || String(record.key);
        noteDescription = note.body || '';
        if (note.lastMod) {
          lastMod = new Date(note.lastMod);
        }
      } else {
        // Fallback: use key as title, try to extract description from value
        noteTitle = String(record.key);
        
        if (record.value && typeof record.value === 'object') {
          // Try to find body/description in various possible fields
          if ('body' in record.value && typeof record.value.body === 'string') {
            noteDescription = record.value.body;
          } else if ('description' in record.value && typeof record.value.description === 'string') {
            noteDescription = record.value.description;
          } else if ('lines' in record.value && Array.isArray(record.value.lines)) {
            // If lines is an array, join it as description
            noteDescription = record.value.lines
              .filter((line: any) => typeof line === 'string')
              .join('\n');
          } else if (Array.isArray(record.value)) {
            // If value is directly an array, join it
            noteDescription = record.value
              .filter((line: any) => typeof line === 'string')
              .join('\n');
          }
          
          // Try to extract lastMod for date-based title replacement
          if ('lastMod' in record.value) {
            const lastModValue = record.value.lastMod;
            if (typeof lastModValue === 'number') {
              lastMod = new Date(lastModValue);
            } else if (lastModValue instanceof Date) {
              lastMod = lastModValue;
            }
          }
        } else if (typeof record.value === 'string') {
          noteDescription = record.value;
        }
      }

      // Handle empty title - replace with date format (matching app behavior)
      // Format: "Slote DD/MM" where DD and MM are zero-padded
      if (!noteTitle || noteTitle.trim() === '') {
        const dateToUse = lastMod || new Date();
        noteTitle = `Slote ${dateToUse.getDate().toString().padStart(2, '0')}/${(dateToUse.getMonth() + 1).toString().padStart(2, '0')}`;
      }

      // Return in desired format: { "note title": [note description] }
      // If description is empty, use empty array, otherwise split by newlines
      const descriptionArray = noteDescription.trim()
        ? noteDescription.split('\n').filter(line => line.trim())
        : [];

      return { [noteTitle]: descriptionArray };
    });
  }
  /**
   * Search records by text
   */
  static searchRecords(records: HiveRecord[], searchText: string): HiveRecord[] {
    if (!searchText.trim()) {
      return records;
    }

    const lowerSearch = searchText.toLowerCase();
    return records.filter((record) => {
      const valueStr = JSON.stringify(record.value).toLowerCase();
      return (
        String(record.key).toLowerCase().includes(lowerSearch) ||
        valueStr.includes(lowerSearch)
      );
    });
  }

  /**
   * Filter records by field value
   */
  static filterRecords(
    records: HiveRecord[],
    field: string,
    value: any
  ): HiveRecord[] {
    return records.filter((record) => {
      if (!record.value || typeof record.value !== 'object') {
        return false;
      }
      return record.value[field] === value;
    });
  }

  /**
   * Sort records
   */
  static sortRecords(
    records: HiveRecord[],
    field: string,
    direction: 'asc' | 'desc' = 'asc'
  ): HiveRecord[] {
    return [...records].sort((a, b) => {
      let aVal: any;
      let bVal: any;

      if (field === 'key') {
        aVal = a.key;
        bVal = b.key;
      } else if (a.value && typeof a.value === 'object') {
        aVal = a.value[field];
        bVal = b.value && typeof b.value === 'object' ? b.value[field] : undefined;
      } else {
        return 0;
      }

      if (aVal === bVal) return 0;
      if (aVal === undefined || aVal === null) return 1;
      if (bVal === undefined || bVal === null) return -1;

      const comparison = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
      return direction === 'asc' ? comparison : -comparison;
    });
  }

  /**
   * Get record by key
   */
  static getRecordByKey(records: HiveRecord[], key: string | number): HiveRecord | undefined {
    return records.find((r) => r.key === key);
  }
}

