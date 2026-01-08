import React from 'react';
import { Box, Paper, IconButton, Typography, TextField } from '@mui/material';
import { Delete } from '@mui/icons-material';
import { HiveRecord } from '../../shared/types';
import { DatabaseService } from '../services/database-service';

interface JsonTreeViewProps {
  records: HiveRecord[];
  onSelectRecord: (record: HiveRecord) => void;
  selectedRecord: HiveRecord | null;
  onDeleteRecord?: (record: HiveRecord) => void;
  onEditRecord?: (record: HiveRecord, field: string, value: any) => void;
  editedRecords?: Map<string | number, HiveRecord>;
}

const JsonTreeView: React.FC<JsonTreeViewProps> = ({
  records,
  onSelectRecord,
  selectedRecord,
  onDeleteRecord,
  onEditRecord,
  editedRecords = new Map(),
}) => {
  const getRecordForDisplay = (record: HiveRecord): HiveRecord => {
    return editedRecords.get(record.key) || record;
  };

  const getNoteFields = (record: HiveRecord) => {
    const displayRecord = getRecordForDisplay(record);
    const value = displayRecord.value;
    
    // Check if it's a Note object
    if (value && typeof value === 'object' && ('id' in value || 'title' in value || 'body' in value)) {
      return {
        id: value.id,
        title: value.title || '',
        body: value.body || '',
        drawingData: value.drawingData || null,
        lastMod: value.lastMod || Date.now(),
      };
    }
    
    // Try to extract from transformed format
    const transformed = DatabaseService.transformToNoteFormat([record]);
    if (transformed.length > 0) {
      const noteTitle = Object.keys(transformed[0])[0];
      const noteDescription = transformed[0][noteTitle];
      return {
        id: record.key,
        title: noteTitle,
        body: Array.isArray(noteDescription) ? noteDescription.join('\n') : String(noteDescription),
        drawingData: null,
        lastMod: Date.now(),
      };
    }
    
    return null;
  };

  const formatDate = (timestamp: number | Date): string => {
    const date = typeof timestamp === 'number' ? new Date(timestamp) : timestamp;
    return date.toLocaleString();
  };

  return (
    <Box sx={{ p: 2 }}>
      {records.length === 0 ? (
        <Paper sx={{ p: 3, textAlign: 'center' }}>
          No records in this box
        </Paper>
      ) : (
        records.map((record) => {
          const displayRecord = getRecordForDisplay(record);
          const noteFields = getNoteFields(displayRecord);
          const isEdited = editedRecords.has(record.key);
          
          return (
            <Paper
              key={String(record.key)}
              sx={{
                p: 2,
                mb: 2,
                cursor: 'pointer',
                border: selectedRecord?.key === record.key ? 2 : 1,
                borderColor: selectedRecord?.key === record.key 
                  ? 'primary.main' 
                  : isEdited 
                    ? 'warning.main' 
                    : 'divider',
                transition: 'border-color 0.3s ease, border-width 0.2s ease, background-color 0.2s ease',
              }}
              onClick={() => onSelectRecord(displayRecord)}
            >
              <Box sx={{ mb: 1, fontWeight: 'bold', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span>Key: {String(record.key)}</span>
                {onDeleteRecord && (
                  <IconButton
                    size="small"
                    color="error"
                    onClick={(e) => {
                      e.stopPropagation();
                      onDeleteRecord(record);
                    }}
                  >
                    <Delete fontSize="small" />
                  </IconButton>
                )}
              </Box>
              
              {noteFields && onEditRecord ? (
                <Box 
                  sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}
                  onFocus={(e) => {
                    // Prevent scroll jump when focusing on input
                    e.stopPropagation();
                  }}
                >
                  <TextField
                    label="ID"
                    value={noteFields.id}
                    disabled
                    fullWidth
                    size="small"
                    helperText="ID cannot be changed"
                    onFocus={(e) => e.stopPropagation()}
                  />
                  <TextField
                    label="Title"
                    value={noteFields.title}
                    onChange={(e) => {
                      e.stopPropagation();
                      onEditRecord(displayRecord, 'title', e.target.value);
                    }}
                    onClick={(e) => e.stopPropagation()}
                    onFocus={(e) => e.stopPropagation()}
                    fullWidth
                    size="small"
                  />
                  <TextField
                    label="Description"
                    value={noteFields.body}
                    onChange={(e) => {
                      e.stopPropagation();
                      onEditRecord(displayRecord, 'body', e.target.value);
                    }}
                    onClick={(e) => e.stopPropagation()}
                    onFocus={(e) => e.stopPropagation()}
                    fullWidth
                    multiline
                    rows={4}
                    size="small"
                  />
                  <TextField
                    label="Drawing Data"
                    value={noteFields.drawingData || ''}
                    onChange={(e) => {
                      e.stopPropagation();
                      onEditRecord(displayRecord, 'drawingData', e.target.value || null);
                    }}
                    onClick={(e) => e.stopPropagation()}
                    onFocus={(e) => e.stopPropagation()}
                    fullWidth
                    multiline
                    rows={2}
                    size="small"
                    helperText="Drawing data (JSON string or null)"
                  />
                  <TextField
                    label="Last Modified"
                    value={formatDate(noteFields.lastMod)}
                    disabled
                    fullWidth
                    size="small"
                    helperText="Last modified timestamp (auto-updated when title/body changes)"
                    onFocus={(e) => e.stopPropagation()}
                  />
                </Box>
              ) : (
                <Box
                  sx={{
                    fontFamily: 'monospace',
                    fontSize: '0.875rem',
                    whiteSpace: 'pre-wrap',
                    wordBreak: 'break-word',
                    bgcolor: 'rgba(0, 0, 0, 0.1)',
                    p: 1,
                    borderRadius: 1,
                    maxHeight: 400,
                    overflow: 'auto',
                  }}
                >
                  <Typography component="pre" sx={{ m: 0, fontFamily: 'inherit' }}>
                    {JSON.stringify(displayRecord.value, null, 2)}
                  </Typography>
                </Box>
              )}
            </Paper>
          );
        })
      )}
    </Box>
  );
};

export default JsonTreeView;
