import React, { useRef, useImperativeHandle, forwardRef } from 'react';
import Editor from '@monaco-editor/react';
import { Box } from '@mui/material';
import type { editor } from 'monaco-editor';

interface EditorProps {
  value: string;
  onChange: (value: string | undefined) => void;
  readOnly?: boolean;
}

export interface EditorRef {
  getScrollTop: () => number;
  setScrollTop: (scrollTop: number) => void;
}

const JsonEditor = forwardRef<EditorRef, EditorProps>(
  ({ value, onChange, readOnly = false }, ref) => {
    const editorRef = useRef<editor.IStandaloneCodeEditor | null>(null);

    useImperativeHandle(ref, () => ({
      getScrollTop: () => {
        if (editorRef.current) {
          return editorRef.current.getScrollTop();
        }
        return 0;
      },
      setScrollTop: (scrollTop: number) => {
        if (editorRef.current) {
          editorRef.current.setScrollTop(scrollTop);
        }
      },
    }));

    const handleEditorDidMount = (editor: editor.IStandaloneCodeEditor) => {
      editorRef.current = editor;
    };

    return (
      <Box sx={{ height: '100%', width: '100%' }}>
        <Editor
          height="100%"
          defaultLanguage="json"
          value={value}
          onChange={onChange}
          onMount={handleEditorDidMount}
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
  }
);

JsonEditor.displayName = 'JsonEditor';

export default JsonEditor;

