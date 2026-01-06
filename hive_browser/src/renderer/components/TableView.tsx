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

  // Extract columns from first record (assuming all records have similar structure)
  const firstRecord = records[0];
  const columns = firstRecord.value && typeof firstRecord.value === 'object'
    ? Object.keys(firstRecord.value)
    : ['value'];

  return (
    <Box sx={{ p: 2, height: '100%', overflow: 'auto' }}>
      <TableContainer component={Paper}>
        <Table stickyHeader>
          <TableHead>
            <TableRow>
              <TableCell>Key</TableCell>
              {columns.map((col) => (
                <TableCell key={col}>{col}</TableCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {records.map((record) => (
              <TableRow
                key={String(record.key)}
                hover
                selected={selectedRecord?.key === record.key}
                onClick={() => onSelectRecord(record)}
                sx={{ cursor: 'pointer' }}
              >
                <TableCell>
                  <Chip label={String(record.key)} size="small" />
                </TableCell>
                {columns.map((col) => {
                  const value = record.value && typeof record.value === 'object'
                    ? record.value[col]
                    : record.value;
                  return (
                    <TableCell key={col}>
                      {typeof value === 'object'
                        ? JSON.stringify(value)
                        : String(value ?? '')}
                    </TableCell>
                  );
                })}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default TableView;

