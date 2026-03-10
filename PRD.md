# Product Requirements Document (PRD)

## Slote - Cross-Platform Note-Taking Application

### Version: 2.0

### Last Updated: March 2025

---

## 1. Table of Contents

- [2. Technical — What This Codebase Currently Has](#2-technical--what-this-codebase-currently-has)
- [3. Executive Summary](#3-executive-summary)
- [4. Target Platforms](#4-target-platforms)
- [5. Target Audiences](#5-target-audiences)
- [6. MVP Scope & Roadmap](#6-mvp-scope--roadmap)
  - [6.1 One Architecture Decision to Make Now](#61-one-architecture-decision-to-make-now)
  - [6.2 MVP — Prove the Core Loop](#62-mvp--prove-the-core-loop)
  - [6.3 v1.1 — Retention and Trust](#63-v11--retention-and-trust)
  - [6.4 v1.2 — Ecosystem Building](#64-v12--ecosystem-building)
  - [6.5 v2 — Scale and Power Users](#65-v2--scale-and-power-users)
  - [6.6 Ongoing from Day One](#66-ongoing-from-day-one)
- [7. Feature Reference (by Phase)](#7-feature-reference-by-phase)
  - [7.1 Drawing & Typing Integration](#71-drawing--typing-integration)
  - [7.2 Rich Text Formatting](#72-rich-text-formatting)
  - [7.3 Folder Hierarchy](#73-folder-hierarchy)
  - [7.4 Files, Portability & Sync](#74-files-portability--sync)
  - [7.5 Import/Export](#75-importexport)
  - [7.6 Media Insertion](#76-media-insertion)
  - [7.7 Find and Replace](#77-find-and-replace)
  - [7.8 Draft Note / Scratchpad](#78-draft-note--scratchpad)
  - [7.9 Shortcuts & Mobile Panel](#79-shortcuts--mobile-panel)
- [8. Plus Features (v1.1 – v2)](#8-plus-features-v11--v2)
- [9. User Interface](#9-user-interface)
- [10. Technical Requirements](#10-technical-requirements)
  - [10.1 Performance](#101-performance)
  - [10.2 Compatibility](#102-compatibility)
  - [10.3 Data Format](#103-data-format)
  - [10.4 Local Storage (SQLite Database)](#104-local-storage-sqlite-database)
  - [10.5 Development Infrastructure](#105-development-infrastructure)
  - [10.6 Multi-Platform Development (Flutter)](#106-multi-platform-development-flutter)
- [11. Success Metrics](#11-success-metrics)
- [12. Future Considerations](#12-future-considerations)
- [13. Out of Scope (v1.0 / MVP)](#13-out-of-scope-v10--mvp)
- [14. Dependencies & Constraints](#14-dependencies--constraints)
- [Appendix A: Feature Priority by Phase](#appendix-a-feature-priority-by-phase)
- [Appendix B: User Personas](#appendix-b-user-personas)

---

## 2. Technical — What This Codebase Currently Has

This section describes the **current state of the Slote codebase**: which components exist, what each provides, and how the main app is structured.

### 2.1 Repository Layout

- **Root**: Main Flutter app (`lib/`, `pubspec.yaml`), platform folders (`android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/`), and tooling (`cmd.py` for DB/emulator operations).
- **`components/`**: Reusable Flutter packages used by the main app and testable in isolation via `example/` apps.
- **`assets/`**: Animations (e.g. Lottie) and other app assets.

### 2.2 Main Application (`lib/`)

| Area                  | What Exists                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Entry & theme**     | `main.dart` initializes theme (via `ThemeProvider`), runs optional Hive→SQLite migration when enabled, then runs `App`.                                                                                                                                                                                                                                                                                                                                                          |
| **App shell**         | `app.dart`: `MaterialApp` with light/dark theme from `ThemeProvider`, home = `HomeView`.                                                                                                                                                                                                                                                                                                                                                                                         |
| **Home screen**       | `views/home.dart`: List/grid of notes from `LocalDBService`, theme toggle, list/grid toggle, FAB to create note. Selection mode (long-press) for multi-delete with Lottie delete confirmation. Uses `NotesList` / `NotesGrid` and `EmptyView`.                                                                                                                                                                                                                                   |
| **Create/Edit note**  | `views/create_note_zoompan.dart` (primary): Note editor with title + body, **draw vs text mode** toggle, zoom/pan surface (pinch, 1‑finger scroll vs pan), drawing overlay (currently **Scribble**-based with a stub when scribble package is not used), pen/eraser toolbar, pen settings popup (stroke width, colors), undo/redo bar. Auto-save with debounce; load/save note and drawing data via `LocalDBService`. Orientation change scales drawing (width) to fixed height. |
| **Note model**        | `model/note.dart`: `Note` with `id`, `title`, `body`, `drawingData` (JSON string), `lastMod`. `toMap` / `fromMap` for DB.                                                                                                                                                                                                                                                                                                                                                        |
| **Local persistence** | `services/local_db.dart`: SQLite (`notes.db`) via `sqflite`; table `notes` (id, title, body, drawingData, lastMod). Singleton `LocalDBService` with `saveNote`, `getAllNotes`, `getNote`, `deleteNote`, and `listenAllNotes()` stream for reactive UI.                                                                                                                                                                                                                           |
| **Migration**         | `services/hive_to_sqlite_migration.dart`: One-time migration from Hive to SQLite (gated by env flag).                                                                                                                                                                                                                                                                                                                                                                            |
| **Drawing in app**    | Drawing in the note editor is implemented via a **scribble-style API** (ScribbleNotifier, Sketch, Erasing, Scribble widget). The codebase includes a **scribble stub** (`scribble_stub.dart`) so it can compile without the external scribble package; there is a TODO to replace this with **slote_draw** (the `draw` component).                                                                                                                                               |

### 2.3 Component: `draw` (`components/draw`)

Custom drawing for Slote.

| Feature            | Description                                                                                                     |
| ------------------ | --------------------------------------------------------------------------------------------------------------- |
| **DrawController** | Central controller: set color, stroke width, tool (pen/eraser/highlighter/shape).                               |
| **DrawCanvas**     | Canvas widget that uses the controller to render strokes.                                                       |
| **Tools**          | Pen, eraser, highlighter, shape tool.                                                                           |
| **Stroke model**   | Stroke data and `StrokeRenderer` for painting.                                                                  |
| **Stylus**         | `StylusDetector` and `PressureHandler` for stylus-aware input.                                                  |
| **Example app**    | `example/`: pen, eraser, highlighter, color picker (8 colors), stroke width (1–20px), clear, draw vs view mode. |

**Note**: The main app’s note editor does not yet use `draw`; it uses the scribble-based path (or stub). Integration of `draw` into the note screen is planned.

### 2.4 Component: `rich_text` (`components/rich_text`)

Rich text editing (Word-style).

| Feature                | Description                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **RichTextController** | Holds content, selection, and markdown; `loadMarkdown`, debounced `onMarkdownChanged`.                            |
| **RichTextEditor**     | Editable field with formatting applied via controller.                                                            |
| **Format toolbar**     | UI for bold, italic, underline (and formatting actions).                                                          |
| **Formatters**         | `Bold`, `Italic`, `Underline`; `TextFormatter` coordinates formatting.                                            |
| **FormattedText**      | Renders formatted spans.                                                                                          |
| **Example app**        | `example/`: editor with toolbar, bold/italic/underline, clear; shows debounced markdown and character/word stats. |

**Note**: The main app’s create note screen currently uses a plain `TextFormField` for the body, not the `rich_text` component. Integration of `rich_text` into the note editor is for future work.

### 2.5 Component: `viewport` (`components/viewport`)

Zoom and pan for a scrollable content area.

| Feature                     | Description                                                                                |
| --------------------------- | ------------------------------------------------------------------------------------------ |
| **ViewportSurface**         | High-level viewport widget.                                                                |
| **ZoomPanSurface**          | Zoom/pan transform and gesture handling.                                                   |
| **GestureHandler**          | Pointer/gesture logic for pinch and pan.                                                   |
| **BoundaryManager**         | Keeps content within bounds.                                                               |
| **ContentMeasurer**         | Measures content for layout.                                                               |
| **TransformAwareScrollbar** | Scrollbar that respects zoom/pan.                                                          |
| **Example app**             | `example/`: zoom (pinch, limits), pan, scrollbar, boundary behavior, content height/stats. |

**Note**: The main app implements its own zoom/pan in `create_note_zoompan.dart` (`ZoomPanSurface` there), not the `viewport` package. The `viewport` component is available for future unification or reuse.

### 2.6 Component: `undo_redo` (`components/undo_redo`)

Generic undo/redo and text-specific + unified controllers.

| Feature                       | Description                                                                                                                       |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **UndoRedoController\<T\>**   | Generic: `getCurrentState`, `restoreState`, optional `stateEquals`; history (max 50), undo/redo.                                  |
| **TextUndoRedoController**    | Wraps `TextEditingController`; state = text + selection.                                                                          |
| **UnifiedUndoRedoController** | Currently wraps text only; accepts a `scribbleNotifier` parameter for future drawing undo (to be wired when drawing uses `draw`). |
| **UndoRedoState**             | Base and `TextState` for text undo.                                                                                               |
| **Example app**               | `example/`: text field with undo/redo, clear history, state indicators.                                                           |

The main app uses `UnifiedUndoRedoController` in the note screen for text undo/redo; drawing undo is planned when scribble is replaced by `draw`.

### 2.7 Component: `theme` (`components/theme`)

Theming for the app.

| Feature            | Description                                                                                                         |
| ------------------ | ------------------------------------------------------------------------------------------------------------------- |
| **ThemeProvider**  | `ChangeNotifier`; persists light/dark via `shared_preferences`; `initializeTheme()`, `toggleTheme()`, `isDarkMode`. |
| **AppThemeConfig** | Light/dark `ThemeData`, typography (e.g. title/body/small font sizes).                                              |

Used by the main app in `App` and home/note UI for theme mode and styles.

### 2.8 Component: `shared` (`components/shared`)

Shared strings, assets, and widgets.

| Feature     | Description                                          |
| ----------- | ---------------------------------------------------- |
| **Strings** | `AppStrings` (e.g. app name).                        |
| **Assets**  | `AnimationAssets` (e.g. delete Lottie path).         |
| **Widgets** | `AppCheckmark`, `EmptyView` (empty state for lists). |

Used by the main app and by components that need common copy or assets.

### 2.9 Tooling: `cmd.py`

Cross-platform CLI for database and emulator workflows (e.g. pull SQLite DB from Android, open in DB Browser, list/pick device). Not part of the Flutter runtime.

### 2.10 Summary Table

| Layer         | Implemented                                                                                          | Not yet in main app / Planned                                    |
| ------------- | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **App**       | Home, create note, SQLite, theme, zoom/pan in note, text + drawing (scribble/stub), undo/redo (text) | Open existing note from list; folders; .slote format; PDF export |
| **draw**      | Full component + example                                                                             | Wired into note editor (replace scribble)                        |
| **rich_text** | Full component + example                                                                             | Wired into note editor (replace plain TextFormField)             |
| **viewport**  | Full component + example                                                                             | Optional: reuse in note screen instead of custom ZoomPanSurface  |
| **undo_redo** | Text + unified wrapper + example                                                                     | Drawing undo when using `draw`                                   |
| **theme**     | In use                                                                                               | —                                                                |
| **shared**    | In use                                                                                               | —                                                                |

---

## 3. Executive Summary

**Slote** is a lightweight, cross-platform note-taking application that combines **drawing and typing** in a unified interface. The product is built with **Flutter**, so desktop (Windows, Mac, Linux), mobile (iOS, Android), and web ship together or very close together. The MVP’s job is to prove that people will use Slote instead of their current app — the core experience must feel noticeably better, not just different.

### Key Differentiators

- **Draw + Type Integration**: Same note page supports both handwriting and rich text with a clear, non-overlapping mechanism. This is load-bearing for Slote’s identity (students, stylus users) and a moat vs. Notion, Simplenote, Notesnook — but only if shipped with clean layer separation and no overlap bugs.
- **Cross-Platform, Offline-First**: No lock-in to Samsung or Apple ecosystems. Web version allows local save (e.g. to desktop) with **no account required** — a strong hook for adoption.
- **Lightweight**: Fast startup and simple usage vs. Word, Notion, Evernote. Extensions/plugins can add power without weighing down the core app.
- **Folder Hierarchy**: Finder/Explorer mental model (folders, subfolders, notes) — familiar and table stakes for adoption.
- **Custom File Format**: `.slote` format for portability, drag-drop import/export, and future sync. Users are not locked in.

### MVP Goal

A user installs Slote, creates a note that mixes typed text and handwriting, organizes it into folders, and can access it on another device or browser without friction — with no sign-in required.

---

## 4. Target Platforms

**Flutter** enables all platforms in MVP; mobile is not a separate milestone.

### Primary Platforms (MVP)

- **Desktop**: Windows, macOS, Linux
- **Mobile**: iOS, Android
- **Web**: PWA with offline-first; local save to browser/desktop with **no account required**

### Platform-Specific Considerations

- **Desktop**: Full keyboard shortcuts (VS Code-style), mouse/trackpad
- **Mobile**: Touch vs. stylus disambiguation from day one (critical for draw + type); shortcut panel
- **Web**: Local save flow, no sign-in; same .slote portability
- **Widgets** (Android/iOS): Require native bridges; planned for v1.1

---

## 5. Target Audiences

### Brainstorm: Who Might Use Slote

| Audience                                                     | Why Slote Fits                                                                                                                                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Students (high school + university)**                      | Mix handwritten diagrams with typed notes; multi-device (phone in class, laptop at home); price-sensitive → offline-first, no account is a hook. Draw + type is the sweet spot. |
| **People leaving Samsung/Apple Notes**                       | Frustrated by ecosystem lock-in or iCloud cost. Cross-platform + offline-first directly solves their pain. Easiest early acquisition.                                           |
| **Researchers & academics**                                  | Deep folder hierarchies, annotate PDFs, care about not being locked in. LaTeX later (v2 plugin).                                                                                |
| **Creatives (designers, writers, artists)**                  | Drawing for ideation; theming/aesthetics; “publish note to web” later.                                                                                                          |
| **Software developers**                                      | Code blocks, markdown, shortcuts, local-first. Plugin system will attract contributors (v2).                                                                                    |
| **Professionals (consultants, managers, analysts)**          | Meeting notes, tables, doc elements. Lightweight alternative to Notion/OneNote.                                                                                                 |
| **Stylus power users** (iPad + Apple Pencil, Galaxy + S Pen) | Want handwriting + proper text editing. Small but vocal and loyal — good for word of mouth.                                                                                     |

### Recommended Primary Focus for MVP

**Students + People leaving Samsung/Apple Notes.**

- Overlap (e.g. students with Galaxy Tab or iPad) and they feel cross-platform pain most.
- They use draw + type daily.
- Active on social platforms for organic growth.
- More forgiving of rough edges if the core loop works.

**Design every MVP decision around:** a university student with a Galaxy Tab or iPad who bounces between Samsung/Apple Notes on the tablet and has no good option on a Windows laptop.

---

## 6. MVP Scope & Roadmap

### 6.1 One Architecture Decision to Make Now

**Settle file format and data model before ship.** If drawing data, rich text, and metadata all live in the same `.slote` file, define that schema now — it affects import/export, backup, sync, and eventually collaboration. Changing it post-launch with real user data is painful.

### 6.2 MVP — Prove the Core Loop

Goal: User installs Slote, creates a note mixing typed text and handwriting, organizes into folders, accesses on another device or browser without friction.

| Area                    | Scope                                                                                                                                                                                                                                             |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Editing**             | Rich text (bold, italic, underline, H1/H2/H3, highlight, bullet/numbered lists), basic doc elements (dividers, code blocks, blockquotes, tables), Find (Ctrl+F)                                                                                   |
| **Draw + Type**         | Pen, eraser, color picker (5–6 colors), **clean separation** between draw and type layers (no overlap bugs). No shape recognition, pressure tiers, or palm rejection fine-tuning in MVP. On mobile: touch vs. stylus disambiguation from day one. |
| **Organization**        | Folder/subfolder structure (Finder/Explorer model), sort by name and date, drag notes between folders                                                                                                                                             |
| **Files & Portability** | `.slote` format defined and stable, drag-drop import/export of .slote files, PDF export, offline-first with local save (no sign-in)                                                                                                               |
| **Cross-Platform**      | Desktop (Win/Mac/Linux) + Mobile (iOS/Android) + Web — all in MVP (Flutter). Web: local save to browser/desktop, no account                                                                                                                       |
| **Draft/Scratchpad**    | Persistent instant-open scratch note, optional clipboard paste on open                                                                                                                                                                            |
| **Shortcuts**           | Core keyboard shortcuts on desktop, floating shortcut panel on mobile                                                                                                                                                                             |
| **Theming**             | Light, dark, 2–3 preset accent themes                                                                                                                                                                                                             |

### 6.3 v1.1 — Retention and Trust

After real users are in: watch for daily return, folder usage, and missing-feature complaints.

- Find and Replace (Ctrl+H)
- Image insertion with basic compression / lazy loading
- Stylus button mapping (S Pen, Apple Pencil, 3rd party)
- Mobile apps: Android/iOS home screen widgets for draft note (native bridge — plan early)
- Markdown export
- Local .bak backup (export all notes)
- Sticky notes
- Table of contents element with scroll hover preview
- More preset themes

### 6.4 v1.2 — Ecosystem Building

- WiFi local sync (LocalSend-style, same network)
- Local collaboration (WiFi/Bluetooth, guest access)
- Word (.docx) and PNG export
- Sorting and filtering improvements
- Community Discord/forum seeded

### 6.5 v2 — Scale and Power Users

- Cloud sync (opt-in, own infra, cheap tier first)
- Online collaboration with guest access
- Publish note to web
- Plugin system (internal first, then open to community)
- Plugins: LaTeX, grammar/spell check, table formulas
- Draw.io-style diagram blocks
- E2E encryption
- AI integration (summarize, format into templates) — by then user workflows inform what AI should do

### 6.6 Ongoing from Day One

- **Performance**: Monitor startup time (lightweight is a brand promise).
- **File format versioning**: So future imports don’t break.
- **Community**: Simple Discord or forum — seeds plugin ecosystem organically.

---

## 7. Feature Reference (by Phase)

The following sections align with the **Cleaned Up Feature List** and roadmap phases (MVP, v1.1, v1.2, v2). Deferred items are listed with rationale.

**Summary — Cleaned Up Feature List**

- **Core Editing**: Rich text, doc elements (tables, dividers, code blocks, quotes, TOC later), Find & Replace (Find in MVP, Replace in v1.1)
- **Organization**: Folder hierarchy (Finder/Explorer), sorting, drag-and-drop
- **Files & Portability**: .slote format, drag-drop import/export, PDF/Markdown export (Markdown v1.1), local .bak backup (v1.1), offline-first, no account
- **Cross-Platform**: Desktop + Mobile + Web in MVP (Flutter)
- **Productivity**: Keyboard shortcuts, mobile shortcut panel, draft/scratchpad, clipboard paste option, widget (v1.1)
- **Customization**: Preset themes (light/dark + a few accents), settings panel
- **Later**: Sync & collaboration (WiFi sync, cloud, online collab, guest); power features (stylus mapping, images, sticky notes, AI, plugins, E2E, publish to web, LaTeX, diagrams)

---

### 7.1 Drawing & Typing Integration

**MVP:** Pen tool, eraser, 5–6 colors, **clean architectural separation** between draw and type layers so they do not overlap. On mobile: touch vs. stylus disambiguation from day one.

**Post-MVP (v1.1+):** Stylus button mapping (e.g. map button to erase while holding). Pressure sensitivity tiers, palm rejection fine-tuning, shape tools, straight-line detection — validate demand first.

**Deferred:** Shape recognition, high-fidelity pressure tiers. Ship drawing well before adding complexity.

**User Stories**

- As a student, I want to draw diagrams and add text annotations on the same note without bugs.
- As a stylus user, I want touch and stylus to be handled correctly so I don’t draw with my palm.

---

### 7.2 Rich Text Formatting

**MVP:** Bold, italic, underline, headings (H1/H2/H3), highlight, bullet/numbered lists. Basic doc elements: dividers, code blocks, blockquotes, tables. Highlight-to-apply toolbar. Find (Ctrl+F). Not full MS Word — keep it lightweight.

**v1.1:** Find and Replace (Ctrl+H). Table of contents with scroll hover preview.

**User Stories**

- As a writer, I want to format my notes with common formatting and see a toolbar when I select text.
- As a mobile user, I want quick formatting without deep menus.

---

### 7.3 Folder Hierarchy

**MVP:** Folders, subfolders, notes inside. Finder/Explorer mental model. Sorting by name and date. Drag notes between folders.

**v1.2+:** Sorting/filter improvements.

**User Stories**

- As a user, I want to organize notes in a hierarchy I already know from my file manager.
- As a student, I want to sort notes by class and date.

---

### 7.4 Files, Portability & Sync

**MVP:** `.slote` format defined and stable. Drag-drop import/export of .slote files. PDF export. Offline-first; local save with no sign-in (including web). No cloud sync — validate retention via export/import first.

**v1.1:** Markdown export. Local .bak backup (export all notes into one file).

**v1.2:** Word (.docx) and PNG export. WiFi local sync (LocalSend-style, same network).

**v2:** Cloud sync (opt-in, own infra). E2E encryption when handling sensitive data at scale.

**User Stories**

- As a user, I want to open Slote on the web without signing in and save to my desktop.
- As a cautious user, I want to export everything to a .bak file so I’m not locked in.

---

### 7.5 Import/Export

**MVP:** Drag and drop .slote files in/out. PDF export.

**v1.1:** Markdown export.

**v1.2:** Word (.docx), PNG export.

**Later:** Import PDF, Word, Markdown (with separate drawing data); batch import/export.

**User Stories**

- As a user, I want to drag .slote files into the app and onto my desktop to open or save.
- As a student, I want to export a note as PDF for printing.

---

### 7.6 Media Insertion

**v1.1:** Image insertion with compression and lazy loading. Plan for large-file handling in data model from day one even if not shipped in MVP.

**Later:** Video, file attachments. Smart handling of large files.

**User Stories**

- As a user, I want to insert images without making notes heavy.
- As a researcher, I want to add screenshots to notes.

---

### 7.7 Find and Replace

**MVP:** Find (Ctrl+F) within current note; search across notes; case/whole-word options.

**v1.1:** Replace (Ctrl+H), replace all, preview before replace.

**User Stories**

- As a writer, I need to find text quickly in my note.
- As a power user, I want replace-all with preview.

---

### 7.8 Draft Note / Scratchpad

**MVP:** Persistent scratch note that opens instantly. Optional clipboard paste on open. No account needed. No widget in MVP.

**v1.1:** Home screen widgets (Android/iOS) for draft note. Requires native bridge — plan early. Optional “consumable” mode (disable saving if user prefers).

**User Stories**

- As a user, I want a scratch note that’s always one tap away and can paste from clipboard.
- As a mobile user, I want a draft widget on my home screen.

---

### 7.9 Shortcuts & Mobile Panel

**MVP:** Core keyboard shortcuts on desktop (e.g. Ctrl+B, Ctrl+I, duplicate line with Alt+Shift / Option+Shift). Floating shortcut panel on mobile.

**Later:** Full VS Code-style shortcut set, command palette (Ctrl+P / Cmd+P), customizable shortcuts.

**User Stories**

- As a power user, I want keyboard shortcuts for common actions.
- As a mobile user, I want a shortcut panel instead of digging through menus.

---

## 8. Plus Features (v1.1 – v2)

### 8.1 Theming

**MVP:** Light and dark mode, 2–3 preset accent themes. No per-element color customization yet.

**v1.1+:** More preset themes. Telegram-style theming as north star; full customization post-MVP.

**User Stories**

- As a user, I want light/dark and a couple of accent options.
- As a night user, I need a proper dark mode.

---

### 8.2 AI Integration

**Deferred (v2+).** Everyone has it; few do it well in notes. Wait until user workflows are known before defining AI features. Then: summarize, format into templates, optional local AI.

**User Stories**

- As a student, I might want AI to summarize notes (future).
- As a privacy-conscious user, I would prefer local AI (future).

---

### 8.3 Plugin System

**Deferred (v2).** Needs a community first. Build clean architecture from day one, but do not expose a public plugin API until v2+. Then: internal plugins first, then open to community; marketplace, sandboxing, LaTeX/spell-check/table-formula plugins.

**User Stories**

- As a developer, I want to extend Slote with plugins (v2).
- As a user, I want community plugins (v2).

---

### 8.4 LaTeX, Grammar/Spell Check, Table Formulas

**Deferred (v2, as plugins).** LaTeX rendering, grammar/spell check, Excel-like table formulas — deliver via plugin system once it exists.

**User Stories**

- As a student, I need equations in notes (v2 plugin).
- As a writer, I want spell check (v2 plugin).

---

### 8.5 Document Elements (Beyond MVP)

**MVP:** Dividers, code blocks, blockquotes, tables.

**v1.1:** Table of contents with scroll hover preview.

**Later:** Headers/footers, page numbers, footnotes, citations, columns, Draw.io-style diagram blocks (click to edit, render as snippet in note).

**User Stories**

- As a writer, I need clear document structure (TOC, headings).
- As a power user, I want embedded diagrams I can click to edit.

---

### 8.6 End-to-End Encryption

**Deferred (v2).** Important for trust; complex to implement correctly. Promise on roadmap; ship before handling sensitive user data at scale.

**User Stories**

- As a privacy-conscious user, I want encrypted notes (v2).

---

### 8.7 Templates

**Later (v2).** Create templates from notes, apply on note creation, template gallery. Not in MVP.

**User Stories**

- As a student, I want class note templates (v2).
- As a professional, I want meeting note templates (v2).

---

### 8.8 Collaboration

**Deferred (v1.2 local, v2 online).** Local collaboration (same network, guest access) in v1.2. Online collaboration and guest access in v2. Significant architecture impact — defer until core product is validated.

**User Stories**

- As a team, we want to collaborate on notes (v1.2/v2).
- As a teacher, I want to share notes with students (v2).

---

### 8.9 Publish Note to Web

**Deferred (v2).** Export note as static page, optional custom domain. Appeals to creatives and educators.

**User Stories**

- As a blogger, I want to publish a note as a webpage (v2).
- As a teacher, I want to share notes publicly (v2).

---

### 8.10 Sticky Notes

**v1.1.** Floating sticky notes, position on canvas, color coding. Replicate real-world sticky-note feel.

**User Stories**

- As a student, I want to add reminders like sticky notes.
- As a creative, I want visual note-taking with stickies.

---

### 8.11 Todo / Checklist

**Later.** Checkbox lists, todo reordering, shortcuts. Not in MVP scope; add when user feedback asks for it.

---

## 9. User Interface

### 9.1 Main Interface

- **Navigation**: Sidebar with folder tree, top toolbar, status bar
- **Note Editor**: Unified canvas (draw + type), drawing toolbar, format bar for text, zoom controls

### 9.2 Hamburger Menu / Settings

- **Settings** (includes **Themes**): Appearance, light/dark, preset themes
- **Syncing Details**: Sync status and options (when cloud/WiFi sync is available)
- **Folders**: Folder management
- **About**: App info

_(Previously "Themes" was top-level; now under Settings per product decision.)_

### 9.3 Settings Details

- **General**: Language, appearance, behavior
- **Sync**: Cloud/WiFi sync (when available), backup
- **Shortcuts**: Keyboard shortcut customization
- **Plugins**: When plugin system exists (v2)
- **Privacy**: Encryption, data handling (when E2E exists)

---

## 10. Technical Requirements

### 10.1 Performance

- **Lightweight**: < 100MB installation size
- **Fast Startup**: < 2 seconds cold start
- **Smooth Drawing**: 60 FPS drawing performance
- **Efficient Sync**: Minimal bandwidth usage

### 10.2 Compatibility

- **Windows**: Windows 10+ (ARM, x64, x86)
- **macOS**: macOS 11+
- **Linux**: Major distributions (Ubuntu, Fedora, etc.)
- **iOS**: iOS 14+
- **Android**: Android 8+ (API 26+)
- **Web**: Modern browsers (Chrome, Firefox, Safari, Edge)

### 10.3 Data Format

- **Custom Format**: `.slote` binary format
- **Backward Compatibility**: Version migration support
- **Export Compatibility**: Standard formats (PDF, Word, etc.)

### 10.4 Local Storage (SQLite Database)

**Technology**: SQLite - A lightweight, fast, cross-platform SQL database

**Purpose**: Local storage for notes and application data

**Implementation**:

- **Database**: SQLite database with `notes` table
- **Storage Location**: Platform-specific application data directories
- **Data Model**: Note objects with fields (id, title, body, drawingData, lastMod)
- **Database File**: `notes.db` in app documents directory
- **Migration Support**: Version migration and data migration utilities

**Database Browser**:

- Use **DB Browser for SQLite** (free, open-source) to view and edit database files
- Install via Homebrew: `brew install --cask db-browser-for-sqlite`
- Direct file access - no custom tools needed
- Standard SQL queries and table views
- Cross-platform support (Windows, macOS, Linux)

**Benefits**:

- Fast, efficient local storage
- No external database server required
- Cross-platform compatibility
- Easy data inspection and debugging with standard SQLite tools
- Standard format - works with any SQLite browser
- No custom parsing or workarounds needed

**Accessing Database Files**:

To view/edit the database from an Android emulator:

1. Pull the database file using ADB:
   ```bash
   adb exec-out run-as com.example.slote cat app_flutter/notes.db > notes.db
   ```
2. Open in DB Browser for SQLite:
   ```bash
   open -a "DB Browser for SQLite" notes.db
   ```

### 10.5 Development Infrastructure

**Status**: ✅ Implemented (January 2025)

#### Component Test Platforms

To enable faster, decentralized development, each component in `components/` now has a standalone test application in its `example/` directory. This infrastructure allows developers to:

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
cd components/[component_name]/example
flutter pub get
flutter run
```

**Benefits**:

- Decentralized development workflow
- Component-level testing without full app overhead
- Faster iteration and debugging
- Standard Flutter package structure

**Documentation**: See `components/COMPONENT_TEST_PLATFORMS.md` for detailed documentation.

**Note**: Integration testing (e.g., drawing + text overlay) remains in the main app (repo root) where components are combined. Component test platforms focus on individual component functionality only.

### 10.6 Multi-Platform Development (Flutter)

Slote targets Android, iOS, web, and desktop from a single Flutter codebase. The following practices help keep the app portable and avoid platform-only bugs.

**Primary target during development**

- Developing mainly for one platform first (e.g. **Android**) is recommended and is common practice.
- Flutter’s single codebase means most logic and UI are shared; enabling web, desktop, or iOS later is mostly configuration and targeted platform code, not a rewrite.

**When to add platform-specific code**

- **UI/UX branching**: When layout or behavior should differ by platform (e.g. desktop vs mobile). Use `kIsWeb` from `package:flutter/foundation.dart` and `Theme.of(context).platform` (e.g. `TargetPlatform.windows`, `macOS`, `linux`) to branch. Prefer centralizing checks in helpers (e.g. `_isDesktopOrWeb(context)`) rather than scattering conditionals.
- **APIs and plugins**: Some plugins support only mobile; for web/desktop you may need different plugins or conditional usage. Prefer cross-platform packages (e.g. `path_provider`, `file_picker`) over raw `dart:io` so the same code works on web and desktop where possible.
- **Web**: Do not use `dart:io` on web (it is not available). Use conditional imports or `kIsWeb` and cross-platform abstractions. Web may need separate handling for routing/URLs, PWA, and sometimes text selection/editing behavior.
- **Desktop**: Consider window sizing, system menus, keyboard/shortcuts, and accessibility; behavior can differ from mobile.

**Practices for developers**

- **Test on multiple platforms early and often**: Run on web (`flutter run -d chrome`) and desktop when feasible to catch platform issues before they accumulate.
- **Prefer cross-platform abstractions**: Use packages that support all targets (e.g. for file I/O, storage, dialogs) so the same code paths work everywhere.
- **Keep platform conditionals localized**: Put `kIsWeb` and `Theme.of(context).platform` checks in a few well-named helpers or a small platform layer so the rest of the app stays platform-agnostic.

---

## 11. Success Metrics

### 11.1 User Metrics

- User retention (30-day, 90-day)
- Daily active users (DAU)
- Notes created per user
- Sync usage rate

### 11.2 Performance Metrics

- App startup time
- Drawing latency
- Sync speed
- Crash rate

### 11.3 Feature Adoption

- Drawing usage rate
- Rich text formatting usage
- Plugin installation rate
- Collaboration usage

---

## 12. Future Considerations

### 12.1 Potential Features

- Voice notes
- Handwriting recognition
- OCR (text from images)
- Calendar integration
- Reminders and notifications
- Markdown live preview
- Code syntax highlighting
- Mind mapping
- Whiteboard mode

### 12.2 Platform Expansion

- Chrome extension
- Browser bookmarklet
- Command-line interface
- API for third-party integrations

---

## 13. Out of Scope (v1.0 / MVP)

- Real-time collaborative editing (v1.2 local, v2 online)
- Cloud sync (validate retention with export/import first; v2)
- Video editing, audio recording/playback
- Advanced image editing, 3D drawing, VR/AR

---

## 14. Dependencies & Constraints

### 14.1 Technical Constraints

- Flutter framework (cross-platform)
- Local-first architecture
- Privacy-first design
- Offline functionality required

### 14.2 Business Constraints

- Open-source components where possible
- Cost-effective cloud sync solution
- No vendor lock-in

---

## Appendix A: Feature Priority by Phase

| Feature                                                   | Phase                           | Notes                                            |
| --------------------------------------------------------- | ------------------------------- | ------------------------------------------------ |
| Draw + Type (pen, eraser, colors, layer separation)       | MVP                             | Core differentiator; ship clean, no overlap bugs |
| Rich text (bold, italic, headings, lists, highlight)      | MVP                             | Simplified; not full Word                        |
| Doc elements (dividers, code blocks, blockquotes, tables) | MVP                             | Basic set                                        |
| Find (Ctrl+F)                                             | MVP                             | Replace in v1.1                                  |
| Folder hierarchy (Finder/Explorer model)                  | MVP                             | Table stakes                                     |
| .slote format, drag-drop, PDF export                      | MVP                             | Offline-first, no account                        |
| Cross-Platform (Desktop + Mobile + Web)                   | MVP                             | Flutter: all in MVP                              |
| Draft/Scratchpad                                          | MVP                             | Widget in v1.1                                   |
| Shortcuts (desktop + mobile panel)                        | MVP                             |                                                  |
| Theming (light, dark, 2–3 accents)                        | MVP                             |                                                  |
| Find & Replace, Image insert, Stylus mapping              | v1.1                            |                                                  |
| Markdown export, .bak backup, Sticky notes, TOC           | v1.1                            |                                                  |
| Widgets for draft (native bridge)                         | v1.1                            |                                                  |
| WiFi local sync, Local collaboration                      | v1.2                            |                                                  |
| Word/PNG export, Community forum                          | v1.2                            |                                                  |
| Cloud sync, Online collab, Publish to web                 | v2                              |                                                  |
| Plugin system, LaTeX, Spell check, Table formulas         | v2                              |                                                  |
| Draw.io diagrams, E2E encryption, AI                      | v2                              |                                                  |
| Cloud sync                                                | Defer until retention validated | Manual export/import first                       |

---

## Appendix B: User Personas

### Primary Persona: Student (e.g. Sarah)

- **Age**: 18–25
- **Devices**: Galaxy Tab or iPad + Windows/Mac laptop
- **Use Case**: Class notes, diagrams + typed notes, study materials, multi-device access
- **Pain Points**: Samsung/Apple Notes don’t work well on the other OS; wants one app that does draw + type everywhere
- **Goals**: Organize by class/folder, mix handwriting and text without bugs, use on phone in class and laptop at home, no account required

### Primary Persona: Person Leaving Samsung/Apple Notes

- **Context**: Switched device ecosystem or tired of iCloud cost and lock-in
- **Use Case**: Same notes across phone, tablet, laptop; offline-first
- **Pain Points**: Can’t take notes from Samsung Notes to iPhone or Mac; Apple Notes requires iCloud
- **Goals**: Cross-platform, local save, drag-drop .slote files, no vendor lock-in

### Secondary Persona: Professional (e.g. Mike)

- **Use Case**: Meeting notes, project docs, formatting like Word
- **Pain Points**: Notion/OneNote feel heavy and slow
- **Goals**: Lightweight app, good formatting, folders, tables (MVP), collaboration later

### Tertiary Persona: Creative / Stylus Power User (e.g. Alex)

- **Use Case**: Sketching, visual notes, theming
- **Pain Points**: Drawing apps lack good text; text apps lack drawing
- **Goals**: Draw + type, stylus button mapping (v1.1), aesthetics; small but vocal audience for word of mouth

---

_This PRD is a living document and will be updated as the product evolves._
