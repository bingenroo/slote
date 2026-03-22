# rich_text

Slote’s **rich text editing** package. The product direction is **AppFlowy Editor** with **Document JSON** as the canonical on-disk/API model (see [docs/ROADMAP.md](docs/ROADMAP.md)).

## Current state

| Layer | Status |
|--------|--------|
| **`lib/`** | **Placeholder** — exports a package name constant only; APIs will land as the AppFlowy integration is promoted out of the example. |
| **`example/`** | **Active development** — runnable spike: `EditorState` from JSON, `AppFlowyEditor`, BIUS toolbar wired to `EditorState.toggleAttribute`, caret-aware toggle state. |
| **Legacy Quill stack** | **Not in this tree** — design and behavior are preserved in [IMPLEMENTATION.md](IMPLEMENTATION.md) for reference only (historical Quill + markdown pipeline). |

## Quick start (spike app)

```bash
cd components/rich_text/example && flutter pub get && flutter run
```

Entry: `example/lib/main.dart`.

## Documentation

| Doc | Purpose |
|-----|---------|
| **[docs/ROADMAP.md](docs/ROADMAP.md)** | End-to-end roadmap: phases, feature waves (inline, blocks, TOC, media, LaTeX, …), listeners, **undo/redo** vs `components/undo_redo`. |
| **[docs/appflowy-editor-roadmap.md](docs/appflowy-editor-roadmap.md)** | AppFlowy-specific checklist (Phases 1–4 + short deferred list). |
| **[docs/markdown-rendering.md](docs/markdown-rendering.md)** | Markdown rendering notes (historical / migration context). |
| **[IMPLEMENTATION.md](IMPLEMENTATION.md)** | Archived record of the former Quill-based implementation. |

## Dependencies

- **`example/`** depends on [`appflowy_editor`](https://pub.dev/packages/appflowy_editor) (see `example/pubspec.yaml`).
- Root **`rich_text/pubspec.yaml`** remains minimal until `lib/` is implemented.

## Integration (main Slote app)

Not wired yet: the app still uses its own text path for note bodies. After `RichTextController` (or equivalent) wraps `EditorState` and debounced JSON export, the root app should depend on this package and persist **Document JSON** (or a versioned `.slote` envelope) per [PRD.md](../../PRD.md).

## Licensing

See [LICENSING.md](LICENSING.md).
