import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  Box,
  Tabs,
  Tab,
  Paper,
  Button,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  DialogContentText,
  TextField,
  InputAdornment,
} from '@mui/material';
import { Delete, Add, Search, DeleteSweep, Save } from '@mui/icons-material';
import JsonTreeView from './JsonTreeView';
import Editor, { EditorRef } from './Editor';
import AddRecordDialog from './AddRecordDialog';
import { HiveRecord } from '../../shared/types';
import { DatabaseService } from '../services/database-service';

interface DataViewerProps {
  boxName: string;
}

type ViewMode = 'tree' | 'raw';

const DataViewer: React.FC<DataViewerProps> = ({ boxName }) => {
  const [records, setRecords] = useState<HiveRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<ViewMode>('tree');
  const [selectedRecord, setSelectedRecord] = useState<HiveRecord | null>(null);
  const [rawJson, setRawJson] = useState('');
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleteAllDialogOpen, setDeleteAllDialogOpen] = useState(false);
  const [recordToDelete, setRecordToDelete] = useState<HiveRecord | null>(null);
  const [searchText, setSearchText] = useState('');
  const [filteredRecords, setFilteredRecords] = useState<HiveRecord[]>([]);
  const [editedRecords, setEditedRecords] = useState<
    Map<string | number, HiveRecord>
  >(new Map());
  const [hasChanges, setHasChanges] = useState(false);

  // Refs for scroll preservation
  const treeViewRef = useRef<HTMLDivElement>(null);
  const rawViewRef = useRef<HTMLDivElement>(null);
  const editorRef = useRef<EditorRef>(null);
  const scrollPositionsRef = useRef<{
    tree: number;
    raw: number;
  }>({
    tree: 0,
    raw: 0,
  });

  const loadRecords = useCallback(async () => {
    if (!window.electronAPI) {
      console.error('Electron API is not available');
      setLoading(false);
      return;
    }
    try {
      setLoading(true);
      const data = await window.electronAPI.getRecords(boxName);
      setRecords(data);
      setEditedRecords(new Map());
      setHasChanges(false);
    } catch (error) {
      console.error('Failed to load records:', error);
    } finally {
      setLoading(false);
    }
  }, [boxName]);

  // Listen for database updates to reload records
  useEffect(() => {
    if (!window.electronAPI || !window.electronAPI.onDatabaseUpdated) {
      return;
    }
    const removeListener = window.electronAPI.onDatabaseUpdated(() => {
      // Preserve scroll position before reloading
      saveScrollPosition();
      loadRecords();
    });
    return () => {
      removeListener();
    };
  }, [boxName]);

  // Restore scroll position after records load
  useEffect(() => {
    if (!loading && records.length > 0) {
      // Use requestAnimationFrame for smoother restoration
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          restoreScrollPosition();
        });
      });
    }
  }, [loading, records, viewMode]);

  useEffect(() => {
    loadRecords();
  }, [loadRecords]);

  const handleSave = useCallback(async () => {
    if (!window.electronAPI) {
      console.error('Electron API is not available');
      return;
    }

    if (!hasChanges) {
      return; // Nothing to save
    }

    // Preserve scroll position and current state before saving
    saveScrollPosition();
    const savedScrollPositions = { ...scrollPositionsRef.current };
    const recordsBeforeSave = [...records];
    const editedRecordsBeforeSave = new Map(editedRecords);

    try {
      // Don't show loading state - keep UI smooth
      // setLoading(true);

      if (editedRecords.size > 0) {
        // Save all edited records
        for (const [key, record] of editedRecords.entries()) {
          await window.electronAPI.updateRecord(boxName, key, record.value);
        }

        // Update records in place instead of reloading - smoother UX
        const updatedRecords = records.map((r) => {
          const edited = editedRecords.get(r.key);
          return edited || r;
        });
        setRecords(updatedRecords);
        setEditedRecords(new Map());
        setHasChanges(false);
        // Silent save - no alert
      } else if (selectedRecord) {
        // Save single selected record
        const displayRecord =
          editedRecords.get(selectedRecord.key) || selectedRecord;
        await window.electronAPI.updateRecord(
          boxName,
          displayRecord.key,
          displayRecord.value
        );

        // Update record in place instead of reloading
        const updatedRecords = records.map((r) =>
          r.key === displayRecord.key ? displayRecord : r
        );
        setRecords(updatedRecords);
        setEditedRecords(new Map());
        setHasChanges(false);
        // Silent save - no alert
      }

      // Smoothly restore scroll position after save
      // Use multiple requestAnimationFrame calls to ensure DOM is fully updated
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            if (viewMode === 'tree' && treeViewRef.current) {
              treeViewRef.current.scrollTop = savedScrollPositions.tree;
            } else if (viewMode === 'raw' && editorRef.current) {
              editorRef.current.setScrollTop(savedScrollPositions.raw);
            }
          });
        });
      });
    } catch (error) {
      console.error('Failed to save record:', error);
      // Restore previous state on error
      setRecords(recordsBeforeSave);
      setEditedRecords(editedRecordsBeforeSave);
      // Silent error - just log to console
    }
  }, [hasChanges, editedRecords, selectedRecord, boxName, records, viewMode]);

  // F5 shortcut for refresh, Cmd/Ctrl+S for save
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // F5 for refresh
      if (e.key === 'F5') {
        e.preventDefault();
        saveScrollPosition();
        loadRecords();
      }
      // Cmd/Ctrl+S for save
      if ((e.metaKey || e.ctrlKey) && e.key === 's') {
        e.preventDefault();
        if (hasChanges) {
          handleSave();
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [hasChanges, handleSave, loadRecords]);

  const saveScrollPosition = () => {
    if (viewMode === 'tree' && treeViewRef.current) {
      scrollPositionsRef.current.tree = treeViewRef.current.scrollTop;
    } else if (viewMode === 'raw' && editorRef.current) {
      scrollPositionsRef.current.raw = editorRef.current.getScrollTop();
    }
  };

  const restoreScrollPosition = () => {
    if (viewMode === 'tree' && treeViewRef.current) {
      treeViewRef.current.scrollTop = scrollPositionsRef.current.tree;
    } else if (viewMode === 'raw' && editorRef.current) {
      editorRef.current.setScrollTop(scrollPositionsRef.current.raw);
    }
  };

  useEffect(() => {
    // Preserve scroll position before updating rawJson
    if (viewMode === 'raw' && editorRef.current) {
      scrollPositionsRef.current.raw = editorRef.current.getScrollTop();
    }

    if (selectedRecord) {
      // For selected record, show full Note object with all fields
      const displayRecord =
        editedRecords.get(selectedRecord.key) || selectedRecord;
      setRawJson(JSON.stringify(displayRecord.value, null, 2));
    } else {
      // For all records, show full Note objects with all fields
      const recordsToShow = records.map((r) => editedRecords.get(r.key) || r);
      const recordsData = recordsToShow.map((r) => ({
        key: r.key,
        value: r.value,
      }));
      setRawJson(JSON.stringify(recordsData, null, 2));
    }

    // Restore scroll position after rawJson update (only in raw view)
    if (viewMode === 'raw' && editorRef.current) {
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          if (editorRef.current) {
            editorRef.current.setScrollTop(scrollPositionsRef.current.raw);
          }
        });
      });
    }
  }, [selectedRecord, records, editedRecords, viewMode]);

  useEffect(() => {
    if (searchText.trim()) {
      const filtered = DatabaseService.searchRecords(records, searchText);
      setFilteredRecords(filtered);
    } else {
      setFilteredRecords(records);
    }
  }, [searchText, records]);

  const handleJsonChange = (value: string | undefined) => {
    if (!value) return;

    // Preserve scroll position before state update (for raw view)
    if (editorRef.current) {
      scrollPositionsRef.current.raw = editorRef.current.getScrollTop();
    }

    try {
      const parsed = JSON.parse(value);

      if (selectedRecord) {
        // Editing a single record
        const updatedRecord = { ...selectedRecord, value: parsed };
        setSelectedRecord(updatedRecord);
        setEditedRecords(
          new Map(editedRecords.set(selectedRecord.key, updatedRecord))
        );
        setHasChanges(true);
      } else {
        // Editing all records - expect array of {key, value} objects
        if (Array.isArray(parsed)) {
          const updatedRecordsMap = new Map<string | number, HiveRecord>();
          parsed.forEach((item: any) => {
            if (item && 'key' in item && 'value' in item) {
              const existingRecord = records.find((r) => r.key === item.key);
              if (existingRecord) {
                updatedRecordsMap.set(item.key, {
                  key: item.key,
                  value: item.value,
                });
              }
            }
          });

          if (updatedRecordsMap.size > 0) {
            setEditedRecords(updatedRecordsMap);
            setHasChanges(true);
          }
        }
      }

      // Smoothly restore scroll position after state update
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          if (editorRef.current) {
            editorRef.current.setScrollTop(scrollPositionsRef.current.raw);
          }
        });
      });
    } catch (e) {
      // Invalid JSON, ignore - let user continue editing
    }
  };

  const handleRecordEdit = (record: HiveRecord, field: string, value: any) => {
    // Preserve scroll position before state update
    if (treeViewRef.current) {
      scrollPositionsRef.current.tree = treeViewRef.current.scrollTop;
    }

    // Get the current record (might be edited already)
    const currentRecord = editedRecords.get(record.key) || record;
    const updatedValue = {
      ...currentRecord.value,
      [field]: value,
      // Update lastMod when editing
      lastMod:
        field === 'title' || field === 'body'
          ? Date.now()
          : currentRecord.value.lastMod,
    };
    const updatedRecord = { ...currentRecord, value: updatedValue };
    setEditedRecords(new Map(editedRecords.set(record.key, updatedRecord)));
    setHasChanges(true);

    // Update records array
    const updatedRecords = records.map((r) =>
      r.key === record.key ? updatedRecord : r
    );
    setRecords(updatedRecords);

    // Update selected record if it's the one being edited
    if (selectedRecord?.key === record.key) {
      setSelectedRecord(updatedRecord);
    }

    // Smoothly restore scroll position after state update
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        if (treeViewRef.current) {
          treeViewRef.current.scrollTop = scrollPositionsRef.current.tree;
        }
      });
    });
  };

  const handleAddRecord = async (key: string | number, value: any) => {
    if (!window.electronAPI) {
      console.error('Electron API is not available');
      return;
    }
    try {
      setLoading(true);
      await window.electronAPI.addRecord(boxName, key, value);
      await loadRecords();
      setAddDialogOpen(false);
      // Silent add - no alert
    } catch (error) {
      console.error('Failed to add record:', error);
      // Silent error - just log to console
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteClick = (record: HiveRecord) => {
    setRecordToDelete(record);
    setDeleteDialogOpen(true);
  };

  const handleDeleteConfirm = async () => {
    if (!window.electronAPI) {
      alert('Electron API is not available');
      return;
    }
    if (recordToDelete) {
      try {
        setLoading(true);
        await window.electronAPI.deleteRecord(boxName, recordToDelete.key);
        await loadRecords();
        setSelectedRecord(null);
        setDeleteDialogOpen(false);
        setRecordToDelete(null);
      } catch (error) {
        console.error('Failed to delete record:', error);
        alert(
          `Failed to delete record: ${error instanceof Error ? error.message : 'Unknown error'}`
        );
      } finally {
        setLoading(false);
      }
    }
  };

  const handleDeleteAllClick = () => {
    setDeleteAllDialogOpen(true);
  };

  const handleDeleteAllConfirm = async () => {
    if (!window.electronAPI) {
      alert('Electron API is not available');
      return;
    }
    try {
      setLoading(true);
      await window.electronAPI.deleteAllRecords(boxName);
      await loadRecords();
      setSelectedRecord(null);
      setDeleteAllDialogOpen(false);
      alert('All records deleted successfully');
    } catch (error) {
      console.error('Failed to delete all records:', error);
      alert(
        `Failed to delete all records: ${error instanceof Error ? error.message : 'Unknown error'}`
      );
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <Box sx={{ p: 3 }}>Loading records...</Box>;
  }

  return (
    <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <Paper sx={{ borderRadius: 0 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column' }}>
          <Box
            sx={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              p: 1,
            }}
          >
            <Tabs
              value={viewMode}
              onChange={(_, newValue) => {
                saveScrollPosition();
                setViewMode(newValue);
              }}
              sx={{ borderBottom: 1, borderColor: 'divider', flex: 1 }}
            >
              <Tab label="Tree View" value="tree" />
              <Tab label="Raw JSON" value="raw" />
            </Tabs>
            <Box sx={{ pr: 2, display: 'flex', gap: 1, alignItems: 'center' }}>
              <Button
                variant="contained"
                startIcon={<Add />}
                onClick={() => setAddDialogOpen(true)}
                size="small"
              >
                Add Record
              </Button>
              <IconButton
                color="error"
                onClick={handleDeleteAllClick}
                size="small"
                title="Delete All Records"
              >
                <DeleteSweep />
              </IconButton>
              {hasChanges && (
                <Button
                  variant="contained"
                  color="primary"
                  startIcon={<Save />}
                  onClick={handleSave}
                  size="small"
                >
                  Save Changes
                </Button>
              )}
              {selectedRecord && !hasChanges && (
                <IconButton
                  color="error"
                  onClick={() => handleDeleteClick(selectedRecord)}
                  size="small"
                  title="Delete Selected Record"
                >
                  <Delete />
                </IconButton>
              )}
            </Box>
          </Box>
          {viewMode !== 'raw' && (
            <Box sx={{ px: 2, pb: 1 }}>
              <TextField
                fullWidth
                size="small"
                placeholder="Search records..."
                value={searchText}
                onChange={(e) => setSearchText(e.target.value)}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Search />
                    </InputAdornment>
                  ),
                }}
              />
            </Box>
          )}
        </Box>
      </Paper>

      <Box sx={{ flex: 1, overflow: 'hidden' }}>
        {viewMode === 'tree' && (
          <Box
            ref={treeViewRef}
            sx={{
              height: '100%',
              overflow: 'auto',
              scrollBehavior: 'auto', // Use 'auto' for instant but controlled scrolling
            }}
          >
            <JsonTreeView
              records={filteredRecords}
              onSelectRecord={setSelectedRecord}
              selectedRecord={selectedRecord}
              onDeleteRecord={handleDeleteClick}
              onEditRecord={handleRecordEdit}
              editedRecords={editedRecords}
            />
          </Box>
        )}
        {viewMode === 'raw' && (
          <Box
            ref={rawViewRef}
            sx={{
              height: '100%',
              position: 'relative',
              overflow: 'hidden', // Monaco handles its own scrolling
            }}
          >
            <Editor
              ref={editorRef}
              value={rawJson}
              onChange={handleJsonChange}
              readOnly={false}
            />
            {hasChanges && (
              <Box
                sx={{
                  position: 'absolute',
                  top: 10,
                  right: 10,
                  zIndex: 1000,
                  display: 'flex',
                  gap: 1,
                  alignItems: 'center',
                }}
              >
                <Box
                  sx={{
                    bgcolor: 'background.paper',
                    px: 1,
                    py: 0.5,
                    borderRadius: 1,
                    fontSize: '0.75rem',
                    color: 'text.secondary',
                  }}
                >
                  {navigator.platform.includes('Mac') ? '⌘' : 'Ctrl'}+S to save
                </Box>
                <Button
                  variant="contained"
                  onClick={handleSave}
                  startIcon={<Save />}
                  color="primary"
                >
                  Save Changes
                </Button>
              </Box>
            )}
          </Box>
        )}
      </Box>

      {/* Delete Record Dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
      >
        <DialogTitle>Delete Record</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete this record? This action cannot be
            undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={handleDeleteConfirm}
            color="error"
            variant="contained"
          >
            Delete
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete All Records Dialog */}
      <Dialog
        open={deleteAllDialogOpen}
        onClose={() => setDeleteAllDialogOpen(false)}
      >
        <DialogTitle>Delete All Records</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete ALL records in this box? This action
            cannot be undone.
            {records.length > 0 && (
              <strong> This will delete {records.length} record(s).</strong>
            )}
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteAllDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={handleDeleteAllConfirm}
            color="error"
            variant="contained"
          >
            Delete All
          </Button>
        </DialogActions>
      </Dialog>

      {/* Add Record Dialog */}
      <AddRecordDialog
        open={addDialogOpen}
        onClose={() => setAddDialogOpen(false)}
        onSave={handleAddRecord}
        existingKeys={records.map((r) => r.key)}
      />
    </Box>
  );
};

export default DataViewer;
