# Product Requirements Document (PRD)

## Slote - Cross-Platform Note-Taking Application

### Version: 1.0

### Last Updated: January 2025

---

## 1. Executive Summary

**Slote** is a lightweight, cross-platform note-taking application that combines drawing and typing capabilities in a unified interface. Unlike existing solutions that separate drawing and text, Slote provides seamless integration of both modalities, making it ideal for students, professionals, and creative users who need flexible note-taking across all their devices.

### Key Differentiators

- **Draw + Type Integration**: Seamless combination of drawing and text editing (unlike apps that only format text)
- **Cross-Platform**: Native support for Windows (ARM/x64/x86), macOS, iOS, Android, Web, and Linux
- **Lightweight**: Optimized performance compared to heavy alternatives (Word, Notion, Evernote)
- **Custom File Format**: Proprietary format with efficient cloud sync
- **Open Ecosystem**: Plugin support and open-source components

---

## 2. Target Platforms

### Primary Platforms

- **Desktop**: Windows (ARM, x64, x86), macOS, Linux
- **Mobile**: iOS, Android
- **Web**: Progressive Web App (PWA) support

### Platform-Specific Features

- **Desktop**: Full keyboard shortcuts (VS Code-style), mouse/trackpad support
- **Mobile**: Touch gestures, stylus support, haptic feedback
- **Web**: Offline-first architecture, cloud sync

---

## 3. Core Features

### 3.1 Drawing & Typing Integration

**Priority: P0 (Critical)**

- **Unified Canvas**: Single surface where users can both draw and type
- **Layer Management**: Drawings and text can coexist and be repositioned
- **Stylus Support**:
  - Pressure sensitivity
  - Palm rejection
  - Stylus button support (eraser, secondary functions)
- **Drawing Tools**:
  - Pen/Pencil with adjustable width and color
  - Highlighter (semi-transparent)
  - Eraser (pixel-perfect and stroke-based)
  - Shape tools (lines, circles, rectangles)
  - Straight line detection (hold to convert)
- **Text Input**:
  - Multi-line text fields
  - Inline text editing
  - Text positioning relative to drawings

**User Stories**:

- As a student, I want to draw diagrams and add text annotations simultaneously
- As a designer, I want to sketch ideas and add notes without switching modes

---

### 3.2 Rich Text Formatting

**Priority: P0 (Critical)**

- **Word-Style Formatting**: Highlight text to apply formatting (like Microsoft Word)
- **Format Options**:
  - Bold, Italic, Underline, Strikethrough
  - Font family, size, color
  - Text alignment (left, center, right, justify)
  - Bullet points and numbered lists
  - Headings (H1-H6)
  - Text highlights/background colors
- **Format Bar**: Contextual toolbar appears when text is selected
- **Keyboard Shortcuts**: Standard shortcuts (Ctrl+B, Ctrl+I, etc.)
- **Mobile Gestures**: Swipe gestures for common formatting

**User Stories**:

- As a writer, I want to format my notes like I do in Word
- As a mobile user, I want quick formatting without opening menus

---

### 3.3 Folder Hierarchy

**Priority: P0 (Critical)**

- **Nested Folders**: Unlimited depth folder structure
- **Folder Management**:
  - Create, rename, delete folders
  - Move notes/folders via drag-and-drop
  - Folder icons/colors (customization)
- **Sorting Options**:
  - By name (A-Z, Z-A)
  - By date created/modified
  - By size
  - Custom order (manual reordering)
- **Views**:
  - Grid view
  - List view
  - Compact view
- **Search**: Full-text search across folders and notes

**User Stories**:

- As a project manager, I want to organize notes in a hierarchical structure
- As a student, I want to sort notes by class and date

---

### 3.4 Cross-Platform Synchronization

**Priority: P0 (Critical)**

- **Cloud Sync**:
  - Automatic background sync
  - Conflict resolution (last-write-wins with manual merge option)
  - Sync status indicator
- **Custom File Format**:
  - Efficient binary format (`.slote`)
  - Compression support
  - Version metadata
- **Cheap Sync Method**:
  - Initial implementation: Local network sync (WiFi/LAN)
  - Optional cloud storage integration
- **Local Backup**:
  - Automatic local backups
  - Backup scheduling
  - Restore from backup
  - Backup location configuration

**User Stories**:

- As a user, I want my notes to sync across all my devices automatically
- As a privacy-conscious user, I want local backup options

---

### 3.5 Import/Export

**Priority: P1 (High)**

- **Import Formats**:
  - PDF (text extraction, preserve layout where possible)
  - Microsoft Word (.docx)
  - Plain text (.txt)
  - Markdown (.md)
- **Export Formats**:
  - PDF (with drawings and formatting)
  - Microsoft Word (.docx)
  - Plain text (.txt)
  - Markdown (.md)
  - Images (PNG, JPEG) - for drawings
- **Batch Operations**: Import/export multiple files

**User Stories**:

- As a professional, I need to import documents from Word
- As a student, I want to export my notes as PDF for printing

---

### 3.6 Media Insertion

**Priority: P1 (High)**

- **Image Support**:
  - Insert from gallery/camera
  - Drag-and-drop images
  - Image resizing and positioning
  - Inline and floating images
- **Video Support**:
  - Embed videos (local files)
  - Video thumbnails
  - Playback controls
- **File Attachments**:
  - Attach any file type
  - File preview where possible
  - Download/open attachments

**User Stories**:

- As a researcher, I want to insert screenshots and diagrams
- As a student, I want to attach lecture recordings

---

### 3.7 Find and Replace

**Priority: P1 (High)**

- **Find (Ctrl+F)**:
  - Search within current note
  - Search across all notes
  - Case-sensitive/insensitive toggle
  - Whole word matching
  - Regex support (advanced)
- **Replace (Ctrl+H)**:
  - Find and replace in current note
  - Replace all occurrences
  - Preview before replace
  - Undo replace operations

**User Stories**:

- As a writer, I need to find and replace text quickly
- As a developer, I want regex search support

---

### 3.8 Draft Notes

**Priority: P1 (High)**

- **Auto-Save**: Automatic saving of drafts
- **Draft Indicator**: Visual indicator for unsaved changes
- **Recovery**: Recover unsaved drafts after app crash
- **Draft Cleanup**: Automatic cleanup of old drafts

**User Stories**:

- As a user, I never want to lose my work due to a crash
- As a mobile user, I want my notes saved even if I close the app accidentally

---

### 3.9 Desktop Shortcuts & Mobile Gestures

**Priority: P1 (High)**

- **Desktop Shortcuts** (VS Code-style):
  - Customizable keyboard shortcuts
  - Command palette (Ctrl+P / Cmd+P)
  - Shortcut conflicts detection
  - Platform-specific shortcuts (Windows/Mac/Linux)
- **Mobile Gestures**:
  - Swipe to undo/redo
  - Pinch to zoom
  - Long-press for context menu
  - Three-finger gestures
- **Consistency**: Same actions available on both desktop and mobile (where applicable)

**User Stories**:

- As a power user, I want keyboard shortcuts for everything
- As a mobile user, I want gestures that match desktop functionality

---

## 4. Plus Features

### 4.1 Advanced Theming

**Priority: P2 (Medium)**

- **Telegram-Style Theming**:
  - Simple theme: Pre-built color schemes
  - Advanced theme: Custom colors for all UI elements
  - Theme marketplace (community themes)
- **Theme Options**:
  - Light/Dark mode
  - Accent colors
  - Background patterns/textures
  - Font customization
- **Per-Note Themes**: Optional per-note color coding

**User Stories**:

- As a user, I want my app to match my aesthetic preferences
- As a night owl, I need a true dark mode

---

### 4.2 AI Integration

**Priority: P2 (Medium)**

- **Local AI (Primary)**:
  - On-device processing (privacy-first)
  - Optional cloud AI (user choice)
- **AI Features**:
  - **Summary**: Generate note summaries
  - **Reword**: Paraphrase text
  - **Format**: Apply formatting templates
  - **Templates**: Create and use format templates
- **AI Models**: Support for local models (e.g., Ollama, local LLMs)

**User Stories**:

- As a student, I want AI to summarize my lecture notes
- As a privacy-conscious user, I want local AI processing

---

### 4.3 Plugin System

**Priority: P2 (Medium)**

- **Plugin Architecture**:
  - Open-source plugin API
  - Plugin marketplace
  - Plugin sandboxing (security)
- **Plugin Types**:
  - UI plugins (custom toolbars)
  - Processing plugins (text transformers)
  - Export plugins (custom formats)
  - Integration plugins (third-party services)
- **Plugin Management**:
  - Install/uninstall plugins
  - Plugin settings
  - Plugin updates

**User Stories**:

- As a developer, I want to create custom plugins
- As a user, I want to extend functionality with plugins

---

### 4.4 LaTeX Support

**Priority: P2 (Medium)**

- **LaTeX Rendering**: Inline and block LaTeX equations
- **LaTeX Editor**: Syntax highlighting, auto-completion
- **Math Mode**: Toggle math input mode
- **Export**: LaTeX export for academic documents

**User Stories**:

- As a student, I need to write mathematical equations
- As a researcher, I want LaTeX support for papers

---

### 4.5 Grammar & Spell Check

**Priority: P2 (Medium)**

- **Spell Check**:
  - Real-time spell checking
  - Multiple language support
  - Custom dictionaries
- **Grammar Check**:
  - Grammar suggestions
  - Style recommendations
  - Optional (can be disabled)

**User Stories**:

- As a writer, I want grammar checking
- As a multilingual user, I need multi-language support

---

### 4.6 Table Support with Excel Formulas

**Priority: P2 (Medium)**

- **Tables**:
  - Create and edit tables
  - Resize columns/rows
  - Table formatting
- **Excel Formulas**:
  - Basic formulas (SUM, AVERAGE, etc.)
  - Cell references
  - Formula autocomplete
  - Formula error detection

**User Stories**:

- As a business user, I need tables with calculations
- As a student, I want to track expenses in notes

---

### 4.7 Document Elements

**Priority: P2 (Medium)**

- **Elements**:
  - Headers and footers
  - Page numbers
  - Table of contents (auto-generated)
  - Footnotes
  - Citations
- **Layout**:
  - Page breaks
  - Columns
  - Margins

**User Stories**:

- As a writer, I need document elements for formal documents
- As a student, I want to create formatted reports

---

### 4.8 End-to-End Encryption

**Priority: P2 (Medium)**

- **Encryption**:
  - E2E encryption for cloud sync
  - Local encryption for sensitive notes
  - Key management
- **Security**:
  - Optional password protection per note
  - Biometric authentication
  - Secure key storage

**User Stories**:

- As a privacy-conscious user, I want encrypted notes
- As a professional, I need to protect sensitive information

---

### 4.9 Templates

**Priority: P2 (Medium)**

- **Template System**:
  - Create templates from existing notes
  - Template gallery
  - Template categories
- **Template Features**:
  - Placeholder fields
  - Template variables
  - Apply template on note creation

**User Stories**:

- As a student, I want class note templates
- As a professional, I want meeting note templates

---

### 4.10 Collaboration

**Priority: P2 (Medium)**

- **Collaboration Modes**:
  - **Local**: Share notes on same network (WiFi/LAN)
  - **Online**: Cloud-based collaboration
- **Guest Mode**:
  - Guest access (read-only or limited edit)
  - Guest permissions management
- **Real-time Sync**: Live collaboration (optional, future)
- **Version History**: Track changes and revert

**User Stories**:

- As a team, we want to collaborate on notes
- As a teacher, I want to share notes with students (read-only)

---

### 4.11 Publish as Website

**Priority: P2 (Medium)**

- **Publishing**:
  - Export note as static website
  - Custom domain support
  - Public/private publishing
- **Features**:
  - Responsive design
  - SEO optimization
  - Analytics integration

**User Stories**:

- As a blogger, I want to publish notes as a website
- As a teacher, I want to share notes publicly

---

### 4.12 Todo Management

**Priority: P2 (Medium)**

- **Todo Features**:
  - Checkbox lists
  - Todo reordering (drag-and-drop)
  - Keyboard shortcuts for todos
  - Mobile gestures for todos
- **Todo States**:
  - Pending
  - In Progress
  - Completed
  - Cancelled

**User Stories**:

- As a project manager, I need todo lists in my notes
- As a mobile user, I want to reorder todos easily

---

### 4.13 Sticky Notes

**Priority: P2 (Medium)**

- **Sticky Note Feature**:
  - Create floating sticky notes
  - Position anywhere on canvas
  - Color coding
  - Resize and reposition
- **Real-World Replication**: Mimic physical sticky notes as much as possible

**User Stories**:

- As a student, I want to add reminders like sticky notes
- As a creative, I want visual note-taking with stickies

---

## 5. User Interface

### 5.1 Main Interface

- **Navigation**:
  - Sidebar with folder tree
  - Top toolbar with actions
  - Bottom status bar
- **Note Editor**:
  - Unified canvas (draw + type)
  - Toolbar for drawing tools
  - Format bar for text
  - Zoom controls

### 5.2 Hamburger Menu

- **Sections**:
  - Themes
  - Settings
  - Folders
  - Syncing Details
  - About

### 5.3 Settings

- **General**: Language, appearance, behavior
- **Sync**: Cloud sync settings, backup configuration
- **Shortcuts**: Keyboard shortcut customization
- **Plugins**: Plugin management
- **Privacy**: Encryption, data handling

---

## 6. Technical Requirements

### 6.1 Performance

- **Lightweight**: < 100MB installation size
- **Fast Startup**: < 2 seconds cold start
- **Smooth Drawing**: 60 FPS drawing performance
- **Efficient Sync**: Minimal bandwidth usage

### 6.2 Compatibility

- **Windows**: Windows 10+ (ARM, x64, x86)
- **macOS**: macOS 11+
- **Linux**: Major distributions (Ubuntu, Fedora, etc.)
- **iOS**: iOS 14+
- **Android**: Android 8+ (API 26+)
- **Web**: Modern browsers (Chrome, Firefox, Safari, Edge)

### 6.3 Data Format

- **Custom Format**: `.slote` binary format
- **Backward Compatibility**: Version migration support
- **Export Compatibility**: Standard formats (PDF, Word, etc.)

### 6.4 Local Storage (Hive Database)

**Technology**: Hive - A lightweight, fast key-value database for Flutter

**Purpose**: Local storage for notes and application data

**Implementation**:

- **Database**: Hive boxes for storing Note objects
- **Storage Location**: Platform-specific application data directories
- **Data Model**: Note objects with fields (id, title, body, drawingData, lastMod)
- **Auto-Export**: Automatic JSON export for Hive Browser synchronization
- **Migration Support**: Version migration and data migration utilities

**Hive Browser Tool**:

- Standalone Electron desktop application (`hive_browser/`)
- View, edit, and manage Hive database files
- CRUD operations on database records
- JSON editor with syntax highlighting
- Search, filter, and export capabilities
- Cross-platform support (Windows, macOS, Linux)

**Benefits**:

- Fast, efficient local storage
- No external database server required
- Cross-platform compatibility
- Easy data inspection and debugging via Hive Browser
- Automatic synchronization with Hive Browser tool

**Documentation**: See `hive_browser/README.md` and `slote_app/docs/HIVE_BROWSER_IMPLEMENTATION.md` for details.

### 6.5 Development Infrastructure

**Status**: ✅ Implemented (January 2025)

#### Component Test Platforms

To enable faster, decentralized development, each component in `slote_components/` now has a standalone test application in its `example/` directory. This infrastructure allows developers to:

- **Test Components Independently**: Each component can be tested in isolation without running the full Slote app
- **Faster Development Cycles**: Reduced startup time and focused debugging environments
- **Standard Flutter Pattern**: Follows Flutter package conventions with `example/` directories
- **Easy Onboarding**: New developers can test components without understanding the entire app architecture

**Implemented Test Platforms**:

1. **slote_draw/example/** - Drawing functionality testing (pen, eraser, highlighter, color selection, stroke width)
2. **slote_rich_text/example/** - Text editing and formatting testing (bold, italic, underline, format toolbar)
3. **slote_viewport/example/** - Zoom/pan/viewport testing (zoom controls, content height, boundary constraints)
4. **slote_undo_redo/example/** - Undo/redo system testing (state management, history tracking)

**Usage**:

```bash
cd slote_components/[component_name]/example
flutter pub get
flutter run
```

**Benefits**:

- Decentralized development workflow
- Component-level testing without full app overhead
- Faster iteration and debugging
- Standard Flutter package structure

**Documentation**: See `slote_components/COMPONENT_TEST_PLATFORMS.md` for detailed documentation.

**Note**: Integration testing (e.g., drawing + text overlay) remains in `slote_app/` where components are combined. Component test platforms focus on individual component functionality only.

---

## 7. Success Metrics

### 7.1 User Metrics

- User retention (30-day, 90-day)
- Daily active users (DAU)
- Notes created per user
- Sync usage rate

### 7.2 Performance Metrics

- App startup time
- Drawing latency
- Sync speed
- Crash rate

### 7.3 Feature Adoption

- Drawing usage rate
- Rich text formatting usage
- Plugin installation rate
- Collaboration usage

---

## 8. Future Considerations

### 8.1 Potential Features

- Voice notes
- Handwriting recognition
- OCR (text from images)
- Calendar integration
- Reminders and notifications
- Markdown live preview
- Code syntax highlighting
- Mind mapping
- Whiteboard mode

### 8.2 Platform Expansion

- Chrome extension
- Browser bookmarklet
- Command-line interface
- API for third-party integrations

---

## 9. Out of Scope (v1.0)

- Real-time collaborative editing (future)
- Video editing
- Audio recording/playback
- Advanced image editing
- 3D drawing
- VR/AR support

---

## 10. Dependencies & Constraints

### 10.1 Technical Constraints

- Flutter framework (cross-platform)
- Local-first architecture
- Privacy-first design
- Offline functionality required

### 10.2 Business Constraints

- Open-source components where possible
- Cost-effective cloud sync solution
- No vendor lock-in

---

## Appendix A: Feature Priority Matrix

| Feature            | Priority | Complexity | Impact   |
| ------------------ | -------- | ---------- | -------- |
| Draw + Type        | P0       | High       | Critical |
| Rich Text          | P0       | Medium     | Critical |
| Folder Hierarchy   | P0       | Low        | Critical |
| Cross-Platform     | P0       | High       | Critical |
| Cloud Sync         | P0       | High       | Critical |
| Import/Export      | P1       | Medium     | High     |
| Media Insertion    | P1       | Medium     | High     |
| Find/Replace       | P1       | Low        | High     |
| Draft Notes        | P1       | Low        | High     |
| Shortcuts/Gestures | P1       | Medium     | High     |
| Theming            | P2       | Low        | Medium   |
| AI Integration     | P2       | High       | Medium   |
| Plugins            | P2       | High       | Medium   |
| LaTeX              | P2       | Medium     | Medium   |
| Collaboration      | P2       | High       | Medium   |

---

## Appendix B: User Personas

### Primary Persona: Student (Sarah)

- **Age**: 20-25
- **Use Case**: Class notes, study materials, assignments
- **Pain Points**: Can't draw diagrams in text-only apps, needs cross-platform sync
- **Goals**: Organize notes by class, combine drawing and text, access on all devices

### Secondary Persona: Professional (Mike)

- **Age**: 30-45
- **Use Case**: Meeting notes, project planning, documentation
- **Pain Points**: Heavy apps are slow, need formatting like Word
- **Goals**: Fast note-taking, professional formatting, collaboration

### Tertiary Persona: Creative (Alex)

- **Age**: 25-35
- **Use Case**: Sketching ideas, visual notes, creative projects
- **Pain Points**: Drawing apps don't have good text, text apps don't have drawing
- **Goals**: Seamless draw+type, visual organization, export options

---

_This PRD is a living document and will be updated as the product evolves._
