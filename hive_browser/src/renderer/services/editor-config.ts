// Editor configuration constants
export const EDITOR_THEMES = {
  DARK: 'vs-dark',
  LIGHT: 'vs',
} as const;

export const EDITOR_OPTIONS = {
  minimap: { enabled: true },
  fontSize: 14,
  wordWrap: 'on' as const,
  formatOnPaste: true,
  formatOnType: true,
  automaticLayout: true,
  scrollBeyondLastLine: false,
  tabSize: 2,
  lineNumbers: 'on' as const,
  folding: true,
  bracketPairColorization: {
    enabled: true,
  },
};

