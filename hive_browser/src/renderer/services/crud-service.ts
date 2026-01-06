import { HiveRecord } from '../../shared/types';

export class CrudService {
  /**
   * Validate record data
   */
  static validateRecord(value: any): { valid: boolean; error?: string } {
    if (value === null || value === undefined) {
      return { valid: false, error: 'Value cannot be null or undefined' };
    }

    try {
      JSON.stringify(value);
      return { valid: true };
    } catch (e) {
      return { valid: false, error: 'Value must be JSON serializable' };
    }
  }

  /**
   * Generate a new key for a record
   */
  static generateKey(existingKeys: (string | number)[]): number {
    if (existingKeys.length === 0) {
      return 1;
    }

    const numericKeys = existingKeys
      .filter((k) => typeof k === 'number')
      .map((k) => k as number);

    if (numericKeys.length === 0) {
      return 1;
    }

    return Math.max(...numericKeys) + 1;
  }

  /**
   * Prepare record for saving
   */
  static prepareRecord(key: string | number, value: any): HiveRecord {
    return {
      key,
      value,
      timestamp: Date.now(),
    };
  }
}

