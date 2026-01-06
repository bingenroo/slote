import React from 'react';
import {
  Box,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  Typography,
  Paper,
} from '@mui/material';
import { DatabaseInfo } from '../../shared/types';

interface SidebarProps {
  database: DatabaseInfo | null;
  selectedBox: string | null;
  onSelectBox: (boxName: string) => void;
}

const Sidebar: React.FC<SidebarProps> = ({ database, selectedBox, onSelectBox }) => {
  if (!database) {
    return (
      <Paper
        sx={{
          width: 250,
          height: '100%',
          p: 2,
          borderRadius: 0,
        }}
      >
        <Typography variant="body2" color="text.secondary">
          No database open
        </Typography>
      </Paper>
    );
  }

  return (
    <Paper
      sx={{
        width: 250,
        height: '100%',
        borderRadius: 0,
        overflow: 'auto',
      }}
    >
      <Box sx={{ p: 2 }}>
        <Typography variant="h6" gutterBottom>
          Boxes
        </Typography>
        <Typography variant="caption" color="text.secondary">
          {database.path.split(/[/\\]/).pop()}
        </Typography>
      </Box>
      <List>
        {database.boxes.map((box) => (
          <ListItem key={box.name} disablePadding>
            <ListItemButton
              selected={selectedBox === box.name}
              onClick={() => onSelectBox(box.name)}
            >
              <ListItemText
                primary={box.name}
                secondary={`${box.recordCount} records`}
              />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
    </Paper>
  );
};

export default Sidebar;

