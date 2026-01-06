import React from 'react';
import { Box, Paper, IconButton, Typography } from '@mui/material';
import { Delete } from '@mui/icons-material';
import { HiveRecord } from '../../shared/types';

interface JsonTreeViewProps {
  records: HiveRecord[];
  onSelectRecord: (record: HiveRecord) => void;
  selectedRecord: HiveRecord | null;
  onDeleteRecord?: (record: HiveRecord) => void;
}

const JsonTreeView: React.FC<JsonTreeViewProps> = ({
  records,
  onSelectRecord,
  selectedRecord,
  onDeleteRecord,
}) => {
  return (
    <Box sx={{ p: 2, height: '100%', overflow: 'auto' }}>
      {records.length === 0 ? (
        <Paper sx={{ p: 3, textAlign: 'center' }}>
          No records in this box
        </Paper>
      ) : (
        records.map((record) => (
          <Paper
            key={String(record.key)}
            sx={{
              p: 2,
              mb: 2,
              cursor: 'pointer',
              border: selectedRecord?.key === record.key ? 2 : 1,
              borderColor: selectedRecord?.key === record.key ? 'primary.main' : 'divider',
            }}
            onClick={() => onSelectRecord(record)}
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
                {JSON.stringify(record.value, null, 2)}
              </Typography>
            </Box>
          </Paper>
        ))
      )}
    </Box>
  );
};

export default JsonTreeView;

