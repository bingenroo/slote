# Troubleshooting Guide

## Issue: Electron Window Not Showing / electronAPI Undefined

### Symptoms
- Electron app starts but window is not visible
- `TypeError: Cannot read properties of undefined (reading 'getDatabaseInfo')` in renderer
- `window.electronAPI` is undefined in React components
- Preload script appears to execute (logs show ping received) but API is not accessible

### Root Cause

The development mode check in `main.ts` was using a strict equality check:
```typescript
if (process.env.NODE_ENV === 'development') {
  // Load from Vite dev server
}
```

However, `NODE_ENV` was not being set in the npm scripts, so it was `undefined`. This caused the condition to fail, preventing the app from loading the React app from the Vite dev server (`http://localhost:3000`). As a result:
1. The window was created but never shown (it was set to `show: false` and only shown on `dom-ready`, which never fired)
2. The preload script executed successfully, but the renderer never loaded, so `window.electronAPI` was never accessible

### Solution

Changed the environment check to default to development mode when `NODE_ENV` is not explicitly set to `'production'`:

```typescript
// Before (broken)
if (process.env.NODE_ENV === 'development') {
  // ...
}

// After (fixed)
const isDevelopment = process.env.NODE_ENV !== 'production';
if (isDevelopment) {
  // ...
}
```

This ensures that:
- The app loads from `http://localhost:3000` in development (when `NODE_ENV` is unset or set to `'development'`)
- The window is shown when `dom-ready` fires
- A fallback timeout (2 seconds) shows the window if `dom-ready` doesn't fire
- The preload script successfully exposes `window.electronAPI` to the renderer

### Additional Improvements

1. **Fallback Window Display**: Added a 2-second timeout to show the window if `dom-ready` doesn't fire, preventing the window from staying hidden
2. **Preload Script Confirmation**: Kept IPC handlers (`preload:ping`, `preload:expose-complete`, `preload:expose-error`) to confirm preload script execution
3. **Better Error Handling**: Improved error messages and console logging for debugging

### Verification

After the fix:
- ✅ Window appears when Electron app starts
- ✅ `window.electronAPI` is available in React components
- ✅ Preload script executes and exposes API successfully
- ✅ App loads from Vite dev server in development mode

### Prevention

To prevent this issue in the future:
1. **Set NODE_ENV explicitly** in package.json scripts if needed:
   ```json
   "dev:main": "NODE_ENV=development tsc -p tsconfig.main.json && tsc -p tsconfig.preload.json && electron ."
   ```
2. **Use the default-to-development pattern** (as implemented) which is more robust
3. **Test window visibility** in development mode to catch similar issues early

### Related Files

- `src/main/main.ts` - Main Electron process, contains window creation and URL loading logic
- `src/main/preload.ts` - Preload script that exposes `window.electronAPI`
- `src/renderer/components/App.tsx` - React component that uses `window.electronAPI`

