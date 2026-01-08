import React from 'react';
import {
  Box,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  TextField,
} from '@mui/material';
import { HiveRecord } from '../../shared/types';
import { DatabaseService } from '../services/database-service';

interface TableViewProps {
  records: HiveRecord[];
  onSelectRecord: (record: HiveRecord) => void;
  selectedRecord: HiveRecord | null;
  onEditRecord?: (record: HiveRecord, field: string, value: any) => void;
  editedRecords?: Map<string | number, HiveRecord>;
}

const TableView: React.FC<TableViewProps> = ({
  records,
  onSelectRecord,
  selectedRecord,
  onEditRecord,
  editedRecords = new Map(),
}) => {
  const getRecordForDisplay = (record: HiveRecord): HiveRecord => {
    return editedRecords.get(record.key) || record;
  };

  if (records.length === 0) {
    return (
      <Box sx={{ p: 3, textAlign: 'center' }}>
        <Paper sx={{ p: 3 }}>No records in this box</Paper>
      </Box>
    );
  }

  // Transform records to note format
  const transformedRecords = DatabaseService.transformToNoteFormat(records);

  return (
    <Box sx={{ p: 2 }}>
      <TableContainer component={Paper}>
        <Table stickyHeader>
          <TableHead>
            <TableRow>
              <TableCell>Note Title</TableCell>
              <TableCell>Note Description</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {transformedRecords.map((transformedRecord, index) => {
              const originalRecord = records[index];
              const displayRecord = getRecordForDisplay(originalRecord);
              const isEdited = editedRecords.has(originalRecord.key);
              
              // Get note fields from the display record
              const noteValue = displayRecord.value;
              let noteTitle = '';
              let noteBody = '';
              
              if (noteValue && typeof noteValue === 'object') {
                if ('title' in noteValue) {
                  noteTitle = String(noteValue.title || '');
                } else {
                  noteTitle = Object.keys(transformedRecord)[0];
                }
                
                if ('body' in noteValue) {
                  noteBody = String(noteValue.body || '');
                } else {
                  const description = transformedRecord[noteTitle];
                  noteBody = Array.isArray(description) ? description.join('\n') : String(description || '');
                }
              } else {
                noteTitle = Object.keys(transformedRecord)[0];
                const description = transformedRecord[noteTitle];
                noteBody = Array.isArray(description) ? description.join('\n') : String(description || '');
              }
              
              return (
                <TableRow
                  key={String(originalRecord.key)}
                  hover
                  selected={selectedRecord?.key === originalRecord.key}
                  onClick={() => onSelectRecord(displayRecord)}
                  sx={{ 
                    cursor: 'pointer',
                    backgroundColor: isEdited ? 'action.selected' : undefined,
                  }}
                >
                  <TableCell>
                    {onEditRecord ? (
                      <TextField
                        value={noteTitle}
                        onChange={(e) => {
                          e.stopPropagation();
                          onEditRecord(displayRecord, 'title', e.target.value);
                        }}
                        onClick={(e) => e.stopPropagation()}
                        size="small"
                        fullWidth
                        variant="outlined"
                        sx={{ minWidth: 200 }}
                      />
                    ) : (
                      <Chip label={noteTitle} size="small" color="primary" />
                    )}
                  </TableCell>
                  <TableCell>
                    {onEditRecord ? (
                      <TextField
                        value={noteBody}
                        onChange={(e) => {
                          e.stopPropagation();
                          onEditRecord(displayRecord, 'body', e.target.value);
                        }}
                        onClick={(e) => e.stopPropagation()}
                        size="small"
                        fullWidth
                        multiline
                        rows={3}
                        variant="outlined"
                      />
                    ) : (
                      noteBody.length > 0 ? (
                        <Box sx={{ maxWidth: 500 }}>
                          {noteBody.split('\n').map((line, i) => (
                            <Box key={i} sx={{ mb: 0.5 }}>
                              {line}
                            </Box>
                          ))}
                        </Box>
                      ) : (
                        <Box sx={{ color: 'text.secondary', fontStyle: 'italic' }}>
                          (no description)
                        </Box>
                      )
                    )}
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default TableView;
