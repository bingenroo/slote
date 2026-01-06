import React, { useState, useEffect } from 'react';
import Layout from './Layout';
import { DatabaseInfo } from '../../shared/types';

declare global {
  interface Window {
    electronAPI: {
      openFile: () => Promise<DatabaseInfo | null>;
      saveFile: () => Promise<void>;
      exportFile: () => Promise<string>;
      getDatabaseInfo: () => Promise<DatabaseInfo | null>;
      getRecords: (boxName: string) => Promise<any[]>;
      updateRecord: (boxName: string, key: string | number, value: any) => Promise<void>;
      deleteRecord: (boxName: string, key: string | number) => Promise<void>;
      addRecord: (boxName: string, key: string | number, value: any) => Promise<void>;
    };
  }
}

const App: React.FC = () => {
  const [database, setDatabase] = useState<DatabaseInfo | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleOpenFile = async () => {
    try {
      setLoading(true);
      setError(null);
      const db = await window.electronAPI.openFile();
      setDatabase(db);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to open file');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      setLoading(true);
      await window.electronAPI.saveFile();
      // Refresh database info
      const db = await window.electronAPI.getDatabaseInfo();
      setDatabase(db);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save file');
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async () => {
    try {
      setLoading(true);
      const path = await window.electronAPI.exportFile();
      alert(`Database exported to: ${path}`);
    } catch (err) {
      if (err instanceof Error && err.message !== 'Export cancelled') {
        setError(err.message);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleImport = async (records: any[]) => {
    if (!database || database.boxes.length === 0) {
      setError('No database open');
      return;
    }

    try {
      setLoading(true);
      const boxName = database.boxes[0].name; // Import to first box for now
      
      // Add each record
      for (const record of records) {
        const key = record.key || record.id || Date.now();
        const value = record.value || record;
        await window.electronAPI.addRecord(boxName, key, value);
      }

      // Refresh database
      const db = await window.electronAPI.getDatabaseInfo();
      setDatabase(db);
      alert(`Imported ${records.length} records successfully`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to import records');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Check if there's already a database open
    window.electronAPI.getDatabaseInfo().then(setDatabase);
  }, []);

  return (
    <Layout
      database={database}
      loading={loading}
      error={error}
      onOpenFile={handleOpenFile}
      onSave={handleSave}
      onExport={handleExport}
      onImport={handleImport}
    />
  );
};

export default App;

