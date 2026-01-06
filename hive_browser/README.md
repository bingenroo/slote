# Hive Browser

A standalone Electron desktop application for browsing, viewing, and editing Hive database files.

## Features

- Open and view `.hive` database files (JSON format for MVP)
- JSON editor with syntax highlighting (Monaco Editor)
- CRUD operations (Create, Read, Update, Delete)
- Search and filter records
- Export to JSON
- Import from JSON
- Modern, responsive UI with Material-UI

## Development

```bash
# Install dependencies
npm install --legacy-peer-deps

# Run in development mode
npm run dev

# Build for production
npm run build

# Package for distribution
npm run package
```

## Project Structure

```
hive_browser/
├── src/
│   ├── main/           # Electron main process
│   ├── renderer/        # React UI
│   └── shared/          # Shared types and utilities
├── public/              # Static assets
└── dist/                # Build output
```

## Usage

1. **Open a Database**: Click "Open" to select a Hive database file (currently supports JSON format)
2. **View Records**: Select a box from the sidebar to view its records
3. **Edit Records**: Click on a record to edit it in the Raw JSON view
4. **Add Records**: Click "Add Record" to create a new record
5. **Delete Records**: Click the delete icon on a record to remove it
6. **Save Changes**: Click "Save" to persist changes to the database file
7. **Export/Import**: Use Export to save database as JSON, or Import to load records from JSON

## Note

This MVP version works with JSON-exported Hive databases. For full binary Hive file support, a custom parser needs to be implemented based on the Hive file format specification.
