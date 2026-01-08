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
} from '@mui/material';
import { HiveRecord } from '../../shared/types';
import { DatabaseService } from '../services/database-service';

interface TableViewProps {
  records: HiveRecord[];
  onSelectRecord: (record: HiveRecord) => void;
  selectedRecord: HiveRecord | null;
}

const TableView: React.FC<TableViewProps> = ({
  records,
  onSelectRecord,
  selectedRecord,
}) => {
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
    <Box sx={{ p: 2, height: '100%', overflow: 'auto' }}>
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
              const noteTitle = Object.keys(transformedRecord)[0];
              const noteDescription = transformedRecord[noteTitle];
              const originalRecord = records[index];
              
              return (
                <TableRow
                  key={String(originalRecord.key)}
                  hover
                  selected={selectedRecord?.key === originalRecord.key}
                  onClick={() => onSelectRecord(originalRecord)}
                  sx={{ cursor: 'pointer' }}
                >
                  <TableCell>
                    <Chip label={noteTitle} size="small" color="primary" />
                  </TableCell>
                  <TableCell>
                    {noteDescription.length > 0 ? (
                      <Box sx={{ maxWidth: 500 }}>
                        {noteDescription.map((line, i) => (
                          <Box key={i} sx={{ mb: 0.5 }}>
                            {line}
                          </Box>
                        ))}
                      </Box>
                    ) : (
                      <Box sx={{ color: 'text.secondary', fontStyle: 'italic' }}>
                        (no description)
                      </Box>
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

