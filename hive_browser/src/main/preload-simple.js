// Minimal preload script to test if preload execution works at all
const { contextBridge, ipcRenderer } = require('electron');

console.log('[PRELOAD-SIMPLE] Script is executing!');

// Send ping to main process
try {
  ipcRenderer.invoke('preload:ping').then(() => {
    console.log('[PRELOAD-SIMPLE] Ping successful');
  }).catch((err) => {
    console.error('[PRELOAD-SIMPLE] Ping failed:', err);
  });
} catch (e) {
  console.error('[PRELOAD-SIMPLE] Error sending ping:', e);
}

// Try to expose minimal API
try {
  contextBridge.exposeInMainWorld('electronAPI', {
    test: () => 'test-success'
  });
  console.log('[PRELOAD-SIMPLE] contextBridge.exposeInMainWorld succeeded');
} catch (error) {
  console.error('[PRELOAD-SIMPLE] contextBridge.exposeInMainWorld failed:', error);
}

