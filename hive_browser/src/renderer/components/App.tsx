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
      updateRecord: (
        boxName: string,
        key: string | number,
        value: any
      ) => Promise<void>;
      deleteRecord: (boxName: string, key: string | number) => Promise<void>;
      addRecord: (
        boxName: string,
        key: string | number,
        value: any
      ) => Promise<void>;
    };
  }
}

const App: React.FC = () => {
  const [database, setDatabase] = useState<DatabaseInfo | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleOpenFile = async () => {
    if (!window.electronAPI) {
      setError('Electron API is not available');
      return;
    }
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
    if (!window.electronAPI) {
      setError('Electron API is not available');
      return;
    }
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
    if (!window.electronAPI) {
      setError('Electron API is not available');
      return;
    }
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
    if (!window.electronAPI) {
      setError('Electron API is not available');
      return;
    }
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
    let timeoutId: NodeJS.Timeout | null = null;
    let isMounted = true;
    let retryCount = 0;
    const maxRetries = 50; // 5 seconds max (50 * 100ms)

    // Wait for electronAPI to be available (preload script may load after React)
    const checkAndLoadDatabase = () => {
      if (!isMounted) return;

      if (window.electronAPI) {
        window.electronAPI
          .getDatabaseInfo()
          .then((db) => {
            if (isMounted) {
              setDatabase(db);
            }
          })
          .catch((err) => {
            console.error('Failed to get database info:', err);
          });
      } else {
        // Retry after a short delay if API is not yet available
        if (retryCount < maxRetries) {
          retryCount++;
          timeoutId = setTimeout(checkAndLoadDatabase, 100);
        } else {
          console.warn('electronAPI is not available after multiple retries');
        }
      }
    };

    // Start checking immediately
    checkAndLoadDatabase();

    // Also listen for when the window is fully loaded
    const handleDOMContentLoaded = () => {
      if (isMounted) {
        checkAndLoadDatabase();
      }
    };

    if (document.readyState === 'loading') {
      window.addEventListener('DOMContentLoaded', handleDOMContentLoaded);
    }

    return () => {
      isMounted = false;
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      window.removeEventListener('DOMContentLoaded', handleDOMContentLoaded);
    };
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
