import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Alert,
} from '@mui/material';
import Editor from './Editor';

interface AddRecordDialogProps {
  open: boolean;
  onClose: () => void;
  onSave: (key: string | number, value: any) => Promise<void>;
  existingKeys: (string | number)[];
}

const AddRecordDialog: React.FC<AddRecordDialogProps> = ({
  open,
  onClose,
  onSave,
  existingKeys,
}) => {
  const [key, setKey] = useState<string>('');
  const [jsonValue, setJsonValue] = useState('{}');
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setError(null);

    // Validate key
    if (!key.trim()) {
      setError('Key is required');
      return;
    }

    // Check if key already exists
    const keyValue = isNaN(Number(key)) ? key : Number(key);
    if (existingKeys.includes(keyValue)) {
      setError('Key already exists');
      return;
    }

    // Validate JSON
    let parsedValue: any;
    try {
      parsedValue = JSON.parse(jsonValue);
    } catch (e) {
      setError('Invalid JSON format');
      return;
    }

    try {
      setSaving(true);
      await onSave(keyValue, parsedValue);
      handleClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save record');
    } finally {
      setSaving(false);
    }
  };

  const handleClose = () => {
    setKey('');
    setJsonValue('{}');
    setError(null);
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>Add New Record</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
          {error && <Alert severity="error">{error}</Alert>}
          
          <TextField
            label="Key"
            value={key}
            onChange={(e) => setKey(e.target.value)}
            fullWidth
            helperText="Enter a unique key (number or string)"
          />

          <Box sx={{ height: 400 }}>
            <Editor
              value={jsonValue}
              onChange={(val) => setJsonValue(val || '{}')}
              readOnly={false}
            />
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose}>Cancel</Button>
        <Button onClick={handleSave} variant="contained" disabled={saving}>
          {saving ? 'Saving...' : 'Save'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default AddRecordDialog;

