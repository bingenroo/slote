# Rich text example

Example app for the `rich_text` component: WYSIWYG editor with **full Markdown** and a debounced export preview.

## Purpose

Run and debug rich text editing without the full Slote app:

- WYSIWYG input (no visible `*` / `**` / `__` while typing)
- Format toolbar: bold, italic, underline (reflects selection; second tap removes format)
- Debounced Markdown output (DB-ready string)
- Character/word count and selection info

## Run

```bash
cd components/rich_text/example
flutter pub get
flutter run
```

Pick a device (e.g. `chrome`, `macos`) when prompted.

## Full Markdown

The editor uses full Markdown for import/export. You can paste or type:

- **Headings**: `# H1`, `## H2`, `### H3`
- **Lists**: `- item`, `1. item`, `- [ ]` / `- [x]`
- **Blockquote**: `> quote`
- **Code**: `` `inline` `` and fenced ` ``` … ``` `
- **Links**: `[text](url)` and images `![alt](url)`
- **Bold / italic / underline** via toolbar or markdown in initial content

The “Markdown output (debounced, DB-ready)” section shows the serialized string after a short pause in typing. Use that string to save to a DB and later pass it to `controller.loadMarkdown(...)`.

## Performance

- Markdown is **not** recomputed on every keystroke. The preview updates only after typing stops for ~200 ms (debounce).
- To avoid lag in your app: persist via `onMarkdownChanged` (debounced) and do not read `controller.markdown` inside `build()` or on every frame.

## Features

- **RichTextController**: `initialMarkdown`, `onMarkdownChanged`, `debounceMarkdownDuration`
- **RichTextEditor**: WYSIWYG editing with the controller
- **FormatToolbar**: Bold, italic, underline; state follows selection/caret; toggle on/off without stacking markers
- **Clear** and stats bar (characters, words, selection)

## Tips

1. Place cursor and tap **Bold** to type in bold (no selection needed).
2. Select text and tap a format to apply; tap again to remove.
3. Paste Markdown into the editor; it is parsed and rendered.
4. Use the debounced Markdown panel to copy the string for storage or API.
