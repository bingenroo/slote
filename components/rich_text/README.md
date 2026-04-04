# rich_text

Slote’s **rich text editing** package. The product direction is **AppFlowy Editor** with **Document JSON** as the canonical on-disk/API model (see [docs/ROADMAP.md](docs/ROADMAP.md)).

## Current state

| Layer | Status |
|--------|--------|
| **`lib/`** | **`RichTextEditorController`**, shared chrome (**`SloteRichTextEditorScaffold`**, **`FormatToolbar`**), inline helpers (`applyBiusToggle`, Wave B `slote*` APIs), markdown helpers (`sloteDocumentToMarkdown` / `sloteMarkdownToDocument`), and `standardCommandShortcutsWithSloteInlineHandlers()` (see `lib/rich_text.dart`). |
| **`example/`** | **Isolated spike** — same scaffold and APIs as the main app, plus debounced **document JSON** logging for debugging. |
| **Main Slote app** | **Path dependency** on this package (`pubspec.yaml`: `rich_text: path: components/rich_text`). Note body in [`lib/src/views/create_note.dart`](../../lib/src/views/create_note.dart) imports **`package:rich_text`**; edits under `components/rich_text/lib` apply on the next analyze/run — no copy-paste “wiring” step. |
| **Legacy Quill stack** | **Not in this tree** — design and behavior are preserved in [IMPLEMENTATION.md](IMPLEMENTATION.md) for reference only (historical Quill + markdown pipeline). |

## Quick start (spike app)

```bash
cd components/rich_text/example && flutter pub get && flutter run
```

Entry: `example/lib/main.dart`.

## Development workflow

1. Implement features and fix bugs in **`lib/`** (and tests under `test/`).
2. Optionally validate in **`example/`** first (fast loop, JSON preview).
3. Run or hot-restart the **root Slote app** — it resolves `package:rich_text` from `components/rich_text` automatically.

Shared UI belongs in **`SloteRichTextEditorScaffold`** / **`FormatToolbar`** so the example and `create_note` stay aligned.

## Documentation

| Doc | Purpose |
|-----|---------|
| **[docs/ROADMAP.md](docs/ROADMAP.md)** | End-to-end roadmap: phases, feature waves (inline, blocks, TOC, media, LaTeX, …), listeners, **undo/redo** vs `components/undo_redo`. |
| **[docs/SUPERSCRIPT_SUBSCRIPT.md](docs/SUPERSCRIPT_SUBSCRIPT.md)** | **Slote-only** superscript/subscript on AppFlowy: delta keys, toggles, rendering (`WidgetSpan`), caret/EOT hooks, markdown. |
| **[docs/appflowy-editor-roadmap.md](docs/appflowy-editor-roadmap.md)** | AppFlowy-specific checklist (Phases 1–4 + short deferred list). |
| **[docs/markdown-rendering.md](docs/markdown-rendering.md)** | Markdown rendering notes (**legacy Quill/Markdown; archived**). |
| **[docs/tables.md](docs/tables.md)** | Tables overview (**legacy Quill/Markdown; archived**). |
| **[IMPLEMENTATION.md](IMPLEMENTATION.md)** | Archived record of the former Quill-based implementation. |

## Dependencies

- **`example/`** depends on [`appflowy_editor`](https://pub.dev/packages/appflowy_editor) (see `example/pubspec.yaml`).
- Root **`rich_text/pubspec.yaml`** depends on **`appflowy_editor`** (shared with the example).

## Main Slote app

The root app depends on this package via a **path** entry in [`pubspec.yaml`](../../pubspec.yaml). The note screen uses **`SloteRichTextEditorScaffold`**, **`RichTextEditorController`**, and AppFlowy **Document JSON** persistence (see [`lib/src/services/slote_rich_text_storage.dart`](../../lib/src/services/slote_rich_text_storage.dart) and [docs/ROADMAP.md](docs/ROADMAP.md)). Product envelope and versioning remain per [PRD.md](../../PRD.md).

## Licensing

See [LICENSING.md](LICENSING.md).
