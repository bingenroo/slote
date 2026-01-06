import { HiveRecord, DatabaseInfo } from '../../shared/types';

export class DatabaseService {
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

