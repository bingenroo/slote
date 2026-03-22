# rich_text

WYSIWYG rich text editor for Slote with **full Markdown** import/export. Editing is styled inline (no visible `*`/`**` markers); content is serialized to standard Markdown for storage or API use.

## Features

- **WYSIWYG editing**: Bold, italic, underline, and more render as formatted text, not markdown syntax.
- **Full Markdown**: Import and export use common Markdown (GFM-style) so you can persist or send to a backend without losing structure.

### Supported Markdown (import & export)

| Kind | Syntax / notes |
|------|----------------|
| **Bold** | `**text**` |
| *Italic* | `*text*` or `_text_` |
| <u>Underline</u> | `__text__` (export only; standard MD has no underline) |
| ~~Strikethrough~~ | `~~text~~` |
| `Inline code` | `` `code` `` |
| [Links](url) | `[text](url)` |
| Headings | `# ` … `### ` |
| Blockquote | `> quote` |
| Bullet list | `- item` |
| Ordered list | `1. item` |
| Task list | `- [ ]` / `- [x]` |
| Fenced code block | ` ```lang … ``` ` |
| Image | `![alt](url)` |
| Horizontal rule | `---` (as `- - -` in export) |

Rounds trips (load markdown → edit → export) preserve these; underline is editor-only and exports as `__text__`.

## Usage

```dart
import 'package:rich_text/rich_text.dart';

// 1. Create controller (optional: initial markdown + callback for persistence)
final controller = RichTextController(
  initialMarkdown: '# Hello\n\n**Bold** and *italic*.',
  debounceMarkdownDuration: const Duration(milliseconds: 200),
  onMarkdownChanged: (markdown) {
    // Persist to DB or API; only called after typing pauses (debounced).
    saveToBackend(markdown);
  },
);

// 2. Toolbar (bold/italic/underline; reflects selection, toggles on second tap)
FormatToolbar(controller: controller)

// 3. Editor
RichTextEditor(controller: controller)

// Later: load from DB
controller.loadMarkdown(savedMarkdown);
```

### API summary

- **RichTextController**
  - `markdown` – current document as Markdown (lazy; see Performance).
  - `loadMarkdown(String)` – replace content from Markdown (e.g. from DB).
  - `selectionStyle` / `selectionStyleListenable` – for toolbar state (bold/italic/underline).
  - `toggleBold()`, `toggleItalic()`, `toggleUnderline()` – toggle format at selection/caret.
  - `quillController` – underlying Quill controller for advanced use.
- **RichTextEditor** – WYSIWYG editor widget; pass `controller`.
- **FormatToolbar** – toolbar that uses `controller` for state and actions.

## Performance (no bottleneck)

The editor is designed so that **typing and selection stay smooth** even with large documents:

1. **No work on every keystroke**
   - The editor uses Quill’s in-memory document; no markdown parsing or serialization on key press.
   - Markdown conversion runs only when:
     - You read `controller.markdown`, or
     - The **debounced** `onMarkdownChanged` fires (after typing stops for `debounceMarkdownDuration`).

2. **Debounced export**
   - Use `onMarkdownChanged` for persistence (DB, API). It is invoked only after a short idle (default 200 ms), so rapid typing does not trigger repeated conversion.
   - You can increase `debounceMarkdownDuration` (e.g. 300–500 ms) for very large documents if needed.

3. **Avoid calling `markdown` in build**
   - Do not call `controller.markdown` inside `build()` or on every frame. Use it only when saving, or rely on the debounced callback. The example uses the callback to update a preview string; that update is debounced.

4. **Load once**
   - `loadMarkdown()` is for initial load or full replace (e.g. from DB). It parses markdown once and replaces the document; no continuous parsing.

With this, the app does not bottleneck on markdown: editing stays responsive, and export is deferred and optional.

## Integration (main app / DB)

- **Persistence**: Pass `onMarkdownChanged` and persist the string (e.g. to SQLite, REST). Use the same string later with `loadMarkdown()` to restore.
- **Format**: Store and transmit **Markdown**; no need to store Quill deltas unless you want editor-specific features beyond markdown.

## Dependencies

- `flutter_quill` – WYSIWYG editor.
- `markdown_quill` – Delta ↔ Markdown (full markdown).
- `markdown` – Parser for Markdown → Delta.

## Docs

- **[Flutter Quill ↔ Markdown rendering](docs/markdown-rendering.md)** – How Quill document ↔ Markdown conversion works, where it lives (`RichTextController`), custom handlers, debouncing, and end-to-end flow.
- **[AppFlowy Editor integration roadmap](docs/appflowy-editor-roadmap.md)** – Phased plan for Document JSON, BIUS toolbar, debounced controller, shortcuts, and deferred features (blocks, crypto, draw, theming).

## Example

See `example/` for a runnable app: toolbar, WYSIWYG editor, and debounced Markdown preview.

```bash
cd example && flutter pub get && flutter run
```

## Legacy / optional

- `FormattedText` – widget that renders a string with `**`/`*`/`__` as styled text (read-only). Useful for simple previews outside the editor.
- `TextFormatter` – legacy helpers that wrap selection in markdown markers; not used by the WYSIWYG path.
