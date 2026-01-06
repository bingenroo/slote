import React, { useState } from 'react';
import {
  Box,
  TextField,
  InputAdornment,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Paper,
} from '@mui/material';
import { Search, Sort } from '@mui/icons-material';
import { HiveRecord } from '../../shared/types';
import { DatabaseService } from '../services/database-service';

interface RecordListProps {
  records: HiveRecord[];
  onSelectRecord: (record: HiveRecord) => void;
  selectedRecord: HiveRecord | null;
}

const RecordList: React.FC<RecordListProps> = ({
  records,
  onSelectRecord,
  selectedRecord,
}) => {
  const [searchText, setSearchText] = useState('');
  const [sortField, setSortField] = useState<string>('key');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc');

  const filteredRecords = DatabaseService.searchRecords(records, searchText);
  const sortedRecords = DatabaseService.sortRecords(filteredRecords, sortField, sortDirection);

  // Extract available fields for sorting
  const availableFields = records.length > 0 && records[0].value && typeof records[0].value === 'object'
    ? ['key', ...Object.keys(records[0].value)]
    : ['key'];

  return (
    <Box sx={{ p: 2 }}>
      <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
        <TextField
          fullWidth
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
        <FormControl sx={{ minWidth: 150 }}>
          <InputLabel>Sort By</InputLabel>
          <Select
            value={sortField}
            label="Sort By"
            onChange={(e) => setSortField(e.target.value)}
          >
            {availableFields.map((field) => (
              <MenuItem key={field} value={field}>
                {field}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
        <FormControl sx={{ minWidth: 120 }}>
          <InputLabel>Direction</InputLabel>
          <Select
            value={sortDirection}
            label="Direction"
            onChange={(e) => setSortDirection(e.target.value as 'asc' | 'desc')}
          >
            <MenuItem value="asc">Ascending</MenuItem>
            <MenuItem value="desc">Descending</MenuItem>
          </Select>
        </FormControl>
      </Box>

      <Paper sx={{ p: 2 }}>
        <Box sx={{ mb: 1, color: 'text.secondary' }}>
          Showing {sortedRecords.length} of {records.length} records
        </Box>
        {sortedRecords.map((record) => (
          <Box
            key={String(record.key)}
            onClick={() => onSelectRecord(record)}
            sx={{
              p: 1,
              mb: 1,
              cursor: 'pointer',
              borderRadius: 1,
              bgcolor: selectedRecord?.key === record.key ? 'action.selected' : 'transparent',
              '&:hover': {
                bgcolor: 'action.hover',
              },
            }}
          >
            <Box sx={{ fontWeight: 'bold' }}>Key: {String(record.key)}</Box>
            <Box sx={{ fontSize: '0.875rem', color: 'text.secondary' }}>
              {JSON.stringify(record.value).substring(0, 100)}
              {JSON.stringify(record.value).length > 100 ? '...' : ''}
            </Box>
          </Box>
        ))}
      </Paper>
    </Box>
  );
};

export default RecordList;

