import React, { useRef, useEffect } from 'react';
import Editor from '@monaco-editor/react';
import { Box } from '@mui/material';

interface EditorProps {
  value: string;
  onChange: (value: string | undefined) => void;
  readOnly?: boolean;
}

const JsonEditor: React.FC<EditorProps> = ({ value, onChange, readOnly = false }) => {
  return (
    <Box sx={{ height: '100%', width: '100%' }}>
      <Editor
        height="100%"
        defaultLanguage="json"
        value={value}
        onChange={onChange}
        theme="vs-dark"
        options={{
          readOnly,
          minimap: { enabled: true },
          fontSize: 14,
          wordWrap: 'on',
          formatOnPaste: true,
          formatOnType: true,
          automaticLayout: true,
          scrollBeyondLastLine: false,
          tabSize: 2,
        }}
      />
    </Box>
  );
};

export default JsonEditor;

