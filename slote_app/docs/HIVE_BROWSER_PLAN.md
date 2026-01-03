# Hive Database Browser - Development Plan

## Overview

Create a standalone, web-based Hive database browser tool for viewing, editing, and debugging Hive databases. The tool should provide a modern, mobile-responsive interface with advanced code editing capabilities, CRUD operations, and debugging features.

## Requirements

### Core Features
- **Database Connection**: Open and read Hive database files (`.hive` files)
- **JSON Viewing**: Display Hive data in JSON format with syntax highlighting
- **CRUD Operations**: Create, Read, Update, Delete records
- **Code Editor**: VSCode-like editor with:
  - Syntax highlighting
  - Auto-completion
  - Keyboard shortcuts (duplicate line, etc.)
  - Multi-cursor support
  - Find and replace
- **Mobile Responsive**: Works on desktop, tablet, and mobile
- **Modern UI**: Clean, intuitive interface
- **Standalone**: No localhost, Docker, or XAMPP required

### Advanced Features
- **Console/Debugging**: 
  - Query console
  - Log viewer
  - Performance metrics
  - Database statistics
- **Data Visualization**:
  - Table view
  - Tree view
  - JSON tree explorer
- **Search & Filter**: 
  - Full-text search
  - Filter by field
  - Sort capabilities
- **Export/Import**:
  - Export to JSON, CSV
  - Import from JSON
  - Backup/restore

## Technical Architecture

### Option A: Electron App (Recommended)
**Pros:**
- Standalone executable (no server needed)
- Full file system access
- Can use existing Hive libraries
- Cross-platform (Windows, Mac, Linux)
- Modern web UI (React/Vue)

**Cons:**
- Larger file size
- Requires packaging

**Tech Stack:**
- Electron
- React/Vue for UI
- Monaco Editor (VSCode editor)
- Hive parser library (or custom parser)

### Option B: Flutter Web App
**Pros:**
- Consistent with main app stack
- Can reuse code
- Good mobile support

**Cons:**
- Limited file system access in browser
- Would need file picker API
- Hive library may not work in web

**Tech Stack:**
- Flutter Web
- CodeMirror or Monaco Editor (via webview)
- Custom Hive parser

### Option C: Progressive Web App (PWA)
**Pros:**
- No installation needed
- Works on all platforms
- Can be hosted or run offline

**Cons:**
- File system limitations
- Requires file picker API

**Recommendation: Option A (Electron App)**

## Implementation Plan

### Phase 1: Core Infrastructure

#### 1.1 Project Setup
- Initialize Electron project
- Set up build configuration
- Configure development environment
- Set up UI framework (React/Vue)

#### 1.2 Hive File Parser
- Research Hive file format specification
- Implement Hive file reader
- Parse Hive boxes and keys
- Handle Hive adapters (typeId mapping)
- Support multiple boxes in one file

#### 1.3 Database Connection
- File picker for selecting `.hive` files
- Recent files list
- Database metadata display
- Box listing and selection

### Phase 2: UI Components

#### 2.1 Main Layout
- Sidebar (boxes list, navigation)
- Main content area (data viewer)
- Toolbar (actions, search)
- Status bar (database info, stats)

#### 2.2 Code Editor Integration
- Integrate Monaco Editor
- Configure JSON syntax highlighting
- Set up auto-completion
- Implement keyboard shortcuts:
  - `Ctrl+D` / `Cmd+D`: Duplicate line
  - `Ctrl+Shift+K` / `Cmd+Shift+K`: Delete line
  - `Alt+Up/Down`: Move line
  - `Ctrl+/` / `Cmd+/`: Toggle comment
  - `Ctrl+F` / `Cmd+F`: Find
  - `Ctrl+H` / `Cmd+H`: Replace
  - `Ctrl+G` / `Cmd+G`: Go to line
  - Multi-cursor: `Ctrl+Alt+Up/Down`
- Theme support (light/dark)

#### 2.3 Data Display
- JSON tree view (collapsible)
- Table view (for structured data)
- Raw JSON view (with editor)
- Pretty print / Minify toggle

### Phase 3: CRUD Operations

#### 3.1 Read Operations
- List all records in a box
- View individual record
- Search records
- Filter records

#### 3.2 Create Operations
- Add new record dialog
- JSON editor for new record
- Key generation (auto-increment or manual)
- Validation

#### 3.3 Update Operations
- Edit record in JSON editor
- Validate JSON before save
- Save changes
- Undo/redo support

#### 3.4 Delete Operations
- Delete single record
- Delete multiple records (bulk)
- Confirmation dialog
- Soft delete option (mark as deleted)

### Phase 4: Advanced Features

#### 4.1 Console/Debugging
- Query console:
  - Execute custom queries
  - Filter expressions
  - Sort expressions
- Log viewer:
  - Operation logs
  - Error logs
  - Performance logs
- Performance metrics:
  - Query execution time
  - File size
  - Record count
  - Memory usage
- Database statistics:
  - Box statistics
  - Key distribution
  - Data type analysis

#### 4.2 Search & Filter
- Full-text search across all fields
- Field-specific search
- Advanced filters:
  - Date range
  - Numeric range
  - Regex matching
- Save filter presets

#### 4.3 Export/Import
- Export to JSON (pretty/minified)
- Export to CSV
- Import from JSON
- Backup entire database
- Restore from backup
- Compare databases (diff view)

#### 4.4 Data Visualization
- Record count charts
- Data type distribution
- Timeline view (for date fields)
- Relationship viewer (if applicable)

### Phase 5: Mobile Responsiveness

#### 5.1 Responsive Layout
- Mobile-first design
- Breakpoints for tablet/desktop
- Collapsible sidebar
- Touch-friendly controls
- Swipe gestures

#### 5.2 Mobile Optimizations
- Simplified navigation
- Bottom sheet for actions
- Optimized editor for mobile
- Virtual keyboard handling

### Phase 6: Polish & Testing

#### 6.1 UI/UX Polish
- Modern design system
- Smooth animations
- Loading states
- Error handling
- Success feedback
- Help tooltips

#### 6.2 Testing
- Unit tests for parser
- Integration tests for CRUD
- UI tests
- Cross-platform testing
- Performance testing

#### 6.3 Documentation
- User guide
- Developer documentation
- API documentation (if applicable)

## Technical Details

### Hive File Format
Hive stores data in binary format. Key considerations:
- Box structure (named containers)
- Key-value pairs
- Type adapters (typeId mapping)
- File format version
- Compression support

**Implementation Approach:**
1. Use existing Hive libraries if available for Node.js/Electron
2. Or implement custom parser based on Hive specification
3. Handle different Hive versions
4. Support encrypted boxes (if applicable)

### Code Editor (Monaco Editor)
Monaco Editor provides:
- Full VSCode editing experience
- JSON language support
- Auto-completion
- Syntax validation
- Multi-cursor editing
- Find and replace
- Code folding
- Bracket matching

**Configuration:**
```javascript
monaco.editor.create(container, {
  value: jsonString,
  language: 'json',
  theme: 'vs-dark',
  automaticLayout: true,
  minimap: { enabled: true },
  formatOnPaste: true,
  formatOnType: true,
  // ... more options
});
```

### Data Structure
```typescript
interface HiveBox {
  name: string;
  keys: string[];
  recordCount: number;
  metadata: BoxMetadata;
}

interface HiveRecord {
  key: string | number;
  value: any;
  typeId?: number;
  timestamp?: number;
}

interface DatabaseInfo {
  path: string;
  boxes: HiveBox[];
  fileSize: number;
  lastModified: Date;
  version: string;
}
```

## File Structure

```
hive-browser/
├── src/
│   ├── main/                    # Electron main process
│   │   ├── main.ts
│   │   ├── file-handler.ts     # File operations
│   │   └── hive-parser.ts      # Hive file parser
│   ├── renderer/                # UI (React/Vue)
│   │   ├── components/
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Editor.tsx
│   │   │   ├── TableView.tsx
│   │   │   ├── Console.tsx
│   │   │   └── ...
│   │   ├── hooks/
│   │   ├── services/
│   │   │   ├── database-service.ts
│   │   │   └── crud-service.ts
│   │   └── App.tsx
│   └── shared/                  # Shared types/utils
│       ├── types.ts
│       └── utils.ts
├── public/
│   └── assets/
├── package.json
├── electron-builder.json
└── README.md
```

## Dependencies

### Core
- `electron`: ^latest
- `react` / `vue`: ^latest
- `monaco-editor`: ^latest
- `react-router` / `vue-router`: ^latest

### UI Components
- `@mui/material` or `antd`: UI component library
- `react-json-view` or `vue-json-pretty`: JSON viewer
- `react-table` or `vue-table`: Table component

### Utilities
- `lodash`: Utility functions
- `date-fns`: Date formatting
- `file-saver`: File download
- `papaparse`: CSV parsing

### Development
- `typescript`: Type safety
- `eslint`: Linting
- `prettier`: Code formatting
- `jest`: Testing
- `electron-builder`: Packaging

## User Interface Mockup

### Desktop Layout
```
┌─────────────────────────────────────────────────┐
│ [Menu] Hive Browser          [Search] [Settings]│
├──────────┬──────────────────────────────────────┤
│          │                                      │
│ Boxes    │  JSON Editor / Table View            │
│ - notes  │  ┌──────────────────────────────┐  │
│ - users  │  │ {                            │  │
│          │  │   "id": 1,                    │  │
│ [New]    │  │   "title": "Note 1",         │  │
│          │  │   "body": "Content..."       │  │
│ Console  │  │ }                            │  │
│ ┌──────┐ │  └──────────────────────────────┘  │
│ │Query │ │                                      │
│ │      │ │  [Save] [Delete] [Refresh]          │
│ └──────┘ │                                      │
│          │                                      │
│ Stats    │  Status: Connected | Records: 42    │
└──────────┴──────────────────────────────────────┘
```

### Mobile Layout
```
┌─────────────────────┐
│ [☰] Hive Browser    │
├─────────────────────┤
│                     │
│ [Boxes ▼]           │
│                     │
│ JSON Editor         │
│ ┌─────────────────┐ │
│ │ {              │ │
│ │   "id": 1,     │ │
│ │   ...          │ │
│ │ }              │ │
│ └─────────────────┘ │
│                     │
│ [Save] [Delete]     │
│                     │
│ [Console] [Stats]   │
└─────────────────────┘
```

## Keyboard Shortcuts

### Editor Shortcuts
- `Ctrl+D` / `Cmd+D`: Duplicate line
- `Ctrl+Shift+K` / `Cmd+Shift+K`: Delete line
- `Alt+Up/Down`: Move line up/down
- `Ctrl+/` / `Cmd+/`: Toggle comment
- `Ctrl+F` / `Cmd+F`: Find
- `Ctrl+H` / `Cmd+H`: Replace
- `Ctrl+G` / `Cmd+G`: Go to line
- `Ctrl+Alt+Up/Down`: Multi-cursor
- `Ctrl+Space`: Trigger autocomplete
- `Ctrl+S` / `Cmd+S`: Save
- `Ctrl+Z` / `Cmd+Z`: Undo
- `Ctrl+Shift+Z` / `Cmd+Shift+Z`: Redo

### Application Shortcuts
- `Ctrl+O` / `Cmd+O`: Open database
- `Ctrl+N` / `Cmd+N`: New record
- `Ctrl+R` / `Cmd+R`: Refresh
- `Ctrl+E` / `Cmd+E`: Export
- `Ctrl+I` / `Cmd+I`: Import
- `Ctrl+,` / `Cmd+,`: Settings

## Console Features

### Query Console
- Execute filter queries: `filter(record => record.id > 10)`
- Sort queries: `sort('lastMod', 'desc')`
- Aggregate queries: `count()`, `sum('field')`, `avg('field')`
- Custom JavaScript execution (sandboxed)

### Log Viewer
- Operation logs (create, update, delete)
- Error logs with stack traces
- Performance logs (query times)
- Filter logs by type/date
- Export logs

### Debugging Tools
- Breakpoint support (pause on operations)
- Variable inspector
- Call stack viewer
- Performance profiler
- Memory usage monitor

## Security Considerations

- Sandbox file operations
- Validate JSON before saving
- Backup before destructive operations
- Read-only mode option
- Encryption support (if Hive uses encryption)

## Future Enhancements

- Real-time sync (watch for file changes)
- Multiple database connections
- Database comparison tool
- Schema viewer/editor
- Migration tool
- Query builder (GUI)
- Data validation rules
- Custom themes
- Plugin system
- Command palette (VSCode style)

## Success Criteria

- ✅ Can open and view Hive database files
- ✅ Display data in JSON format with syntax highlighting
- ✅ Perform CRUD operations
- ✅ Code editor with VSCode-like shortcuts
- ✅ Mobile responsive design
- ✅ Modern, intuitive UI
- ✅ Console and debugging features
- ✅ No server/localhost required
- ✅ Cross-platform support

## Timeline Estimate

- **Phase 1**: 2-3 weeks (Core infrastructure)
- **Phase 2**: 2 weeks (UI components)
- **Phase 3**: 1-2 weeks (CRUD operations)
- **Phase 4**: 2-3 weeks (Advanced features)
- **Phase 5**: 1 week (Mobile responsiveness)
- **Phase 6**: 1-2 weeks (Polish & testing)

**Total**: 9-13 weeks

---

*This tool will significantly improve development workflow by providing easy access to Hive database contents and debugging capabilities.*

