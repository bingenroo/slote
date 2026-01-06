import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Alert,
  TextField,
} from '@mui/material';
import Editor from './Editor';

interface ImportDialogProps {
  open: boolean;
  onClose: () => void;
  onImport: (data: any[]) => Promise<void>;
}

const ImportDialog: React.FC<ImportDialogProps> = ({ open, onClose, onImport }) => {
  const [jsonData, setJsonData] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [importing, setImporting] = useState(false);

  const handleImport = async () => {
    setError(null);

    try {
      const parsed = JSON.parse(jsonData);
      let records: any[] = [];

      if (Array.isArray(parsed)) {
        records = parsed;
      } else if (parsed.boxes && typeof parsed.boxes === 'object') {
        // Handle exported format
        for (const [boxName, boxData] of Object.entries(parsed.boxes)) {
          if (Array.isArray(boxData)) {
            records = records.concat(boxData);
          } else if (boxData && typeof boxData === 'object' && 'records' in boxData) {
            records = records.concat((boxData as any).records);
          }
        }
      } else {
        throw new Error('Invalid JSON format. Expected array or object with boxes.');
      }

      if (records.length === 0) {
        throw new Error('No records found in JSON data');
      }

      setImporting(true);
      await onImport(records);
      handleClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Invalid JSON format');
    } finally {
      setImporting(false);
    }
  };

  const handleClose = () => {
    setJsonData('');
    setError(null);
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>Import Records from JSON</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
          {error && <Alert severity="error">{error}</Alert>}
          
          <Box sx={{ height: 400 }}>
            <Editor
              value={jsonData}
              onChange={(val) => setJsonData(val || '')}
              readOnly={false}
            />
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose}>Cancel</Button>
        <Button onClick={handleImport} variant="contained" disabled={importing || !jsonData.trim()}>
          {importing ? 'Importing...' : 'Import'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ImportDialog;

