export interface HiveBox {
  name: string;
  keys: (string | number)[];
  recordCount: number;
  metadata?: BoxMetadata;
}

export interface BoxMetadata {
  version?: number;
  encryptionKey?: string;
}

export interface HiveRecord {
  key: string | number;
  value: any;
  typeId?: number;
  timestamp?: number;
}

export interface DatabaseInfo {
  path: string;
  boxes: HiveBox[];
  fileSize: number;
  lastModified: Date;
  version?: string;
}

export interface Note {
  id: number;
  title: string;
  body: string;
  drawingData?: string | null;
  lastMod: number; // Unix timestamp in milliseconds
}

