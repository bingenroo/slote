import React from 'react';
import { Box, AppBar, Toolbar, Typography, Button, Alert } from '@mui/material';
import { FolderOpen, Save, FileDownload, FileUpload } from '@mui/icons-material';
import Sidebar from './Sidebar';
import DataViewer from './DataViewer';
import ImportDialog from './ImportDialog';
import { DatabaseInfo } from '../../shared/types';

interface LayoutProps {
  database: DatabaseInfo | null;
  loading: boolean;
  error: string | null;
  onOpenFile: () => void;
  onSave: () => void;
  onExport: () => void;
  onImport?: (data: any[]) => Promise<void>;
}

const Layout: React.FC<LayoutProps> = ({
  database,
  loading,
  error,
  onOpenFile,
  onSave,
  onExport,
  onImport,
}) => {
  const [selectedBox, setSelectedBox] = React.useState<string | null>(null);
  const [importDialogOpen, setImportDialogOpen] = React.useState(false);

  React.useEffect(() => {
    if (database && database.boxes.length > 0 && !selectedBox) {
      setSelectedBox(database.boxes[0].name);
    }
  }, [database, selectedBox]);

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100vh' }}>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Hive Browser
          </Typography>
          <Button
            color="inherit"
            startIcon={<FolderOpen />}
            onClick={onOpenFile}
            disabled={loading}
          >
            Open
          </Button>
          <Button
            color="inherit"
            startIcon={<Save />}
            onClick={onSave}
            disabled={loading || !database}
          >
            Save
          </Button>
          <Button
            color="inherit"
            startIcon={<FileDownload />}
            onClick={onExport}
            disabled={loading || !database}
          >
            Export
          </Button>
          {onImport && (
            <Button
              color="inherit"
              startIcon={<FileUpload />}
              onClick={() => setImportDialogOpen(true)}
              disabled={loading || !database}
            >
              Import
            </Button>
          )}
        </Toolbar>
      </AppBar>

      {error && (
        <Alert severity="error" sx={{ m: 1 }}>
          {error}
        </Alert>
      )}

      <Box sx={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        <Sidebar
          database={database}
          selectedBox={selectedBox}
          onSelectBox={setSelectedBox}
        />
        <Box sx={{ flex: 1, overflow: 'auto' }}>
          {database && selectedBox ? (
            <DataViewer boxName={selectedBox} />
          ) : (
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                height: '100%',
              }}
            >
              <Typography variant="h6" color="text.secondary">
                {database ? 'Select a box to view data' : 'Open a Hive database file to get started'}
              </Typography>
            </Box>
          )}
        </Box>
      </Box>

      {onImport && (
        <ImportDialog
          open={importDialogOpen}
          onClose={() => setImportDialogOpen(false)}
          onImport={onImport}
        />
      )}
    </Box>
  );
};

export default Layout;

