import React, { useState, useEffect } from 'react';
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
  const [title, setTitle] = useState<string>('');
  const [body, setBody] = useState<string>('');
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // Generate a unique ID based on existing keys
  const generateId = (): number => {
    const numericKeys = existingKeys
      .filter(k => typeof k === 'number')
      .map(k => k as number);
    const maxId = numericKeys.length > 0 ? Math.max(...numericKeys) : 0;
    return maxId + 1;
  };

  useEffect(() => {
    if (open) {
      // Reset form when dialog opens
      setTitle('');
      setBody('');
      setError(null);
    }
  }, [open]);

  const handleSave = async () => {
    setError(null);

    // Validate title (can be empty, will be replaced with date if empty)
    const noteId = generateId();
    const now = Date.now();
    
    // Format date as DD/MM for default title if empty
    const date = new Date(now);
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const defaultTitle = title.trim() || `Slote ${day}/${month}`;

    // Create Note object
    const noteValue = {
      id: noteId,
      title: defaultTitle,
      body: body.trim(),
      drawingData: null,
      lastMod: now,
    };

    try {
      setSaving(true);
      await onSave(noteId, noteValue);
      handleClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save record');
    } finally {
      setSaving(false);
    }
  };

  const handleClose = () => {
    setTitle('');
    setBody('');
    setError(null);
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>Add New Note</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
          {error && <Alert severity="error">{error}</Alert>}
          
          <TextField
            label="Title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            fullWidth
            helperText="Leave empty to use date as title (Slote DD/MM)"
            placeholder="Enter note title (optional)"
          />

          <TextField
            label="Description"
            value={body}
            onChange={(e) => setBody(e.target.value)}
            fullWidth
            multiline
            rows={6}
            placeholder="Enter note description"
          />
          
          <Box sx={{ fontSize: '0.875rem', color: 'text.secondary' }}>
            <strong>Note:</strong> ID, drawing data, and last modified date will be automatically set.
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
