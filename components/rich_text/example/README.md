# Rich text example

Runnable **AppFlowy Editor** spike for `components/rich_text` — no full Slote app required.

## Purpose

- `EditorState` loaded from **Document JSON**
- **`AppFlowyEditor`** (mobile editor style in the spike)
- **BIUS toolbar** (Bold, Italic, Underline, Strikethrough) wired to `EditorState.toggleAttribute`
- Toggle buttons reflect **range selection** and **caret** position (including text already formatted in the document)

## Run

```bash
cd components/rich_text/example
flutter pub get
flutter run
```

## Docs

- End-to-end roadmap: [../docs/ROADMAP.md](../docs/ROADMAP.md)
- AppFlowy phase checklist: [../docs/appflowy-editor-roadmap.md](../docs/appflowy-editor-roadmap.md)

## Note

This example does **not** use the legacy Quill / markdown pipeline described in older docs. Canonical persistence for the product is **AppFlowy Document JSON** (see ROADMAP).
