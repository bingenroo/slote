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
      syncFromEmulator: () => Promise<string[]>;
      onDatabaseUpdated: (callback: () => void) => () => void;
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

  const handleSyncFromEmulator = async () => {
    if (!window.electronAPI) {
      setError('Electron API is not available');
      return;
    }
    try {
      setLoading(true);
      setError(null);
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'App.tsx:119',
            message: 'handleSyncFromEmulator called',
            data: {},
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run2',
            hypothesisId: 'J',
          }),
        }
      ).catch(() => {});
      // #endregion
      const filePaths = await window.electronAPI.syncFromEmulator();
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'App.tsx:127',
            message: 'syncFromEmulator returned',
            data: { filePathsCount: filePaths.length, filePaths },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run2',
            hypothesisId: 'J',
          }),
        }
      ).catch(() => {});
      // #endregion
      if (filePaths.length > 0) {
        // Wait a bit for main process to finish opening the file
        await new Promise((resolve) => setTimeout(resolve, 500));
        // After sync, refresh database info to show the newly opened file
        // The main process will auto-open the first file, so we just need to refresh
        // #region agent log
        fetch(
          'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              location: 'App.tsx:131',
              message: 'Calling getDatabaseInfo after sync',
              data: {},
              timestamp: Date.now(),
              sessionId: 'debug-session',
              runId: 'run2',
              hypothesisId: 'J',
            }),
          }
        ).catch(() => {});
        // #endregion
        const db = await window.electronAPI.getDatabaseInfo();
        // #region agent log
        fetch(
          'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              location: 'App.tsx:133',
              message: 'getDatabaseInfo returned',
              data: {
                db: db
                  ? {
                      boxesCount: db.boxes.length,
                      boxes: db.boxes.map((b) => b.name),
                    }
                  : null,
              },
              timestamp: Date.now(),
              sessionId: 'debug-session',
              runId: 'run2',
              hypothesisId: 'J',
            }),
          }
        ).catch(() => {});
        // #endregion
        setDatabase(db);
        // Show success message
        alert(
          `Synced and opened ${filePaths.length} database file(s) from emulator(s).`
        );
      } else {
        alert('No database files found on connected emulator(s).');
      }
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Failed to sync from emulator'
      );
      // #region agent log
      fetch(
        'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            location: 'App.tsx:142',
            message: 'handleSyncFromEmulator error',
            data: {
              error: err instanceof Error ? err.message : String(err),
            },
            timestamp: Date.now(),
            sessionId: 'debug-session',
            runId: 'run2',
            hypothesisId: 'J',
          }),
        }
      ).catch(() => {});
      // #endregion
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

    // Listen for database updates from main process
    const setupDatabaseListener = () => {
      if (window.electronAPI && window.electronAPI.onDatabaseUpdated) {
        return window.electronAPI.onDatabaseUpdated(() => {
          // #region agent log
          fetch(
            'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                location: 'App.tsx:149',
                message: 'database-updated event received',
                data: {},
                timestamp: Date.now(),
                sessionId: 'debug-session',
                runId: 'run2',
                hypothesisId: 'K',
              }),
            }
          ).catch(() => {});
          // #endregion
          if (isMounted && window.electronAPI) {
            window.electronAPI
              .getDatabaseInfo()
              .then((db) => {
                // #region agent log
                fetch(
                  'http://127.0.0.1:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1',
                  {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                      location: 'App.tsx:162',
                      message: 'Refreshed database after update event',
                      data: {
                        db: db
                          ? {
                              boxesCount: db.boxes.length,
                              boxes: db.boxes.map((b) => b.name),
                            }
                          : null,
                      },
                      timestamp: Date.now(),
                      sessionId: 'debug-session',
                      runId: 'run2',
                      hypothesisId: 'K',
                    }),
                  }
                ).catch(() => {});
                // #endregion
                if (isMounted) {
                  setDatabase(db);
                }
              })
              .catch((err) => {
                console.error('Failed to get database info after update:', err);
              });
          }
        });
      }
    };

    // Try to setup listener immediately, or retry after API is available
    let removeListener: (() => void) | null = null;
    if (window.electronAPI && window.electronAPI.onDatabaseUpdated) {
      removeListener = setupDatabaseListener();
    } else {
      // Retry setting up listener after a delay
      setTimeout(() => {
        if (window.electronAPI && window.electronAPI.onDatabaseUpdated) {
          removeListener = setupDatabaseListener();
        }
      }, 1000);
    }

    return () => {
      isMounted = false;
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      window.removeEventListener('DOMContentLoaded', handleDOMContentLoaded);
      if (removeListener) {
        removeListener();
      }
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
      onSyncFromEmulator={handleSyncFromEmulator}
    />
  );
};

export default App;
