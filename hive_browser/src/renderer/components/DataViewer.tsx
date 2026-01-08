import React, { useState, useEffect } from 'react';
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
import { Delete, Add, Search } from '@mui/icons-material';
import JsonTreeView from './JsonTreeView';
import TableView from './TableView';
import Editor from './Editor';
import AddRecordDialog from './AddRecordDialog';
import { HiveRecord } from '../../shared/types';
import { DatabaseService } from '../services/database-service';

interface DataViewerProps {
  boxName: string;
}

type ViewMode = 'tree' | 'table' | 'raw';

const DataViewer: React.FC<DataViewerProps> = ({ boxName }) => {
  const [records, setRecords] = useState<HiveRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<ViewMode>('tree');
  const [selectedRecord, setSelectedRecord] = useState<HiveRecord | null>(null);
  const [rawJson, setRawJson] = useState('');
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [recordToDelete, setRecordToDelete] = useState<HiveRecord | null>(null);
  const [searchText, setSearchText] = useState('');
  const [filteredRecords, setFilteredRecords] = useState<HiveRecord[]>([]);

  useEffect(() => {
    loadRecords();
  }, [boxName]);

  // Listen for database updates to reload records
  useEffect(() => {
    if (!window.electronAPI || !window.electronAPI.onDatabaseUpdated) {
      return;
    }
    const removeListener = window.electronAPI.onDatabaseUpdated(() => {
      // Reload records when database is updated
      loadRecords();
    });
    return () => {
      removeListener();
    };
  }, [boxName]);

  useEffect(() => {
    if (selectedRecord) {
      // For selected record, show transformed format
      const transformed = DatabaseService.transformToNoteFormat([
        selectedRecord,
      ]);
      setRawJson(JSON.stringify(transformed[0], null, 2));
    } else {
      // For all records, show transformed format
      const transformed = DatabaseService.transformToNoteFormat(records);
      setRawJson(JSON.stringify(transformed, null, 2));
    }
  }, [selectedRecord, records]);

  useEffect(() => {
    if (searchText.trim()) {
      const filtered = DatabaseService.searchRecords(records, searchText);
      setFilteredRecords(filtered);
    } else {
      setFilteredRecords(records);
    }
  }, [searchText, records]);

  const loadRecords = async () => {
    if (!window.electronAPI) {
      console.error('Electron API is not available');
      setLoading(false);
      return;
    }
    try {
      setLoading(true);
      const data = await window.electronAPI.getRecords(boxName);
      setRecords(data);
    } catch (error) {
      console.error('Failed to load records:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleJsonChange = (value: string | undefined) => {
    if (value && selectedRecord) {
      try {
        const parsed = JSON.parse(value);
        setSelectedRecord({ ...selectedRecord, value: parsed });
      } catch (e) {
        // Invalid JSON, ignore
      }
    }
  };

  const handleSave = async () => {
    if (!window.electronAPI) {
      alert('Electron API is not available');
      return;
    }
    if (selectedRecord) {
      try {
        setLoading(true);
        await window.electronAPI.updateRecord(
          boxName,
          selectedRecord.key,
          selectedRecord.value
        );
        await loadRecords();
        alert('Record saved successfully');
      } catch (error) {
        console.error('Failed to save record:', error);
        alert(
          `Failed to save record: ${error instanceof Error ? error.message : 'Unknown error'}`
        );
      } finally {
        setLoading(false);
      }
    }
  };

  const handleAddRecord = async (key: string | number, value: any) => {
    if (!window.electronAPI) {
      alert('Electron API is not available');
      return;
    }
    try {
      setLoading(true);
      await window.electronAPI.addRecord(boxName, key, value);
      await loadRecords();
      setAddDialogOpen(false);
    } catch (error) {
      console.error('Failed to add record:', error);
      alert(
        `Failed to add record: ${error instanceof Error ? error.message : 'Unknown error'}`
      );
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
              onChange={(_, newValue) => setViewMode(newValue)}
              sx={{ borderBottom: 1, borderColor: 'divider', flex: 1 }}
            >
              <Tab label="Tree View" value="tree" />
              <Tab label="Table View" value="table" />
              <Tab label="Raw JSON" value="raw" />
            </Tabs>
            <Box sx={{ pr: 2, display: 'flex', gap: 1 }}>
              <Button
                variant="contained"
                startIcon={<Add />}
                onClick={() => setAddDialogOpen(true)}
                size="small"
              >
                Add Record
              </Button>
              {selectedRecord && (
                <IconButton
                  color="error"
                  onClick={() => handleDeleteClick(selectedRecord)}
                  size="small"
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
          <JsonTreeView
            records={filteredRecords}
            onSelectRecord={setSelectedRecord}
            selectedRecord={selectedRecord}
            onDeleteRecord={handleDeleteClick}
          />
        )}
        {viewMode === 'table' && (
          <TableView
            records={filteredRecords}
            onSelectRecord={setSelectedRecord}
            selectedRecord={selectedRecord}
          />
        )}
        {viewMode === 'raw' && (
          <Box sx={{ height: '100%', position: 'relative' }}>
            <Editor
              value={rawJson}
              onChange={handleJsonChange}
              readOnly={!selectedRecord}
            />
            {selectedRecord && (
              <Box
                sx={{ position: 'absolute', top: 10, right: 10, zIndex: 1000 }}
              >
                <button onClick={handleSave}>Save Changes</button>
              </Box>
            )}
          </Box>
        )}
      </Box>
    </Box>
  );
};

export default DataViewer;
