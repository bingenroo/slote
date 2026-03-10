# Flutter Quill ↔ Markdown rendering

This doc explains how the rich_text component uses **Flutter Quill** with **Markdown** as the storage format: editing in Quill, persisting and loading as Markdown.

## What “Markdown rendering” means here

- **Edit** in a WYSIWYG editor (Quill) — no visible `*` / `**` markers.
- **Store / send** as **Markdown** (not Quill Delta/JSON) so you can persist to a DB or send to a backend.
- **Load** from Markdown when opening a note (e.g. from DB).

So “rendering” here is: **Quill document ↔ Markdown string** — conversion both ways — plus how you use that string (persist, preview, etc.).

## Where it lives

All conversion and APIs live in **`RichTextController`** (`lib/src/rich_text_controller.dart`). It:

- Holds a **QuillController** (in-memory document).
- Uses **`markdown_quill`** to convert **Delta → Markdown** and **Markdown → Delta**.
- Exposes **`markdown`** (getter) and **`loadMarkdown(String)`** for export/import.
- Optionally notifies you when the Markdown string changes (**`onMarkdownChanged`**), **debounced**.

You don’t touch Delta or conversion directly; you use the controller’s Markdown API.

## The pieces

### Packages

From `pubspec.yaml`:

- **`flutter_quill`** – editor and Quill document/Delta.
- **`markdown`** – parsing Markdown (used by `markdown_quill`).
- **`markdown_quill`** – **DeltaToMarkdown** and **MarkdownToDelta**.

The “rendering” to/from Markdown is done by **`markdown_quill`**; the controller just calls it and uses the string.

### Export: Quill → Markdown

When you need the current document as Markdown:

1. Get the Quill **Delta** from the document.
2. Run it through **DeltaToMarkdown**.
3. The result is the Markdown string you persist or show.

In the controller this is the **`markdown`** getter:

```dart
String get markdown {
  final delta = _quillController.document.toDelta();
  return _deltaToMarkdown.convert(delta);
}
```

**Rule:** Call `controller.markdown` only when you need the string (e.g. on save or in a debounced callback), not on every frame or inside `build()`.

### Import: Markdown → Quill

When you load from DB (or set initial content):

1. Take the stored Markdown string.
2. Convert it to a Delta with **MarkdownToDelta**.
3. Build a Quill **Document** from that Delta and assign it to the controller.

In the controller:

```dart
void loadMarkdown(String markdown) {
  final delta = _markdownToDelta.convert(markdown);
  final doc = Document.fromDelta(delta);
  _quillController.document = doc;
  _quillController.updateSelection(
    TextSelection.collapsed(offset: 0),
    ChangeSource.local,
  );
  notifyListeners();
}
```

Use **`loadMarkdown(yourMarkdownString)`** when loading a note (e.g. from DB).

### Customizing what gets written as Markdown

**DeltaToMarkdown** can be configured so certain Quill attributes or embeds become specific Markdown syntax via **custom handlers**.

Example: **underline** is not standard Markdown, so we map it to `__...__`:

```dart
static final DeltaToMarkdown _deltaToMarkdown = DeltaToMarkdown(
  customTextAttrsHandlers: {
    Attribute.underline.key: CustomAttributeHandler(
      beforeContent: (attr, node, out) => out.write('__'),
      afterContent: (attr, node, out) => out.write('__'),
    ),
  },
  customEmbedHandlers: {
    EmbeddableTable.tableType: EmbeddableTable.toMdSyntax,
  },
);
```

- **customTextAttrsHandlers** – “when this attribute is present, write this before/after the text” (controls how that format “renders” to Markdown).
- **customEmbedHandlers** – “when this embed type is present, write this Markdown” (e.g. table → `| ... |`).

To support another custom format in export, add or adjust handlers here.

### Markdown → Delta (parsing)

We use **MarkdownToDelta** with a markdown document that includes table parsing, so that table syntax in markdown is turned into table embeds:

```dart
static final md.Document _markdownDocument = md.Document(
  blockSyntaxes: [
    const EmbeddableTableSyntax(),
  ],
);

static final MarkdownToDelta _markdownToDelta = MarkdownToDelta(
  markdownDocument: _markdownDocument,
  customElementToEmbeddable: {
    EmbeddableTable.tableType: EmbeddableTable.fromMdSyntax,
  },
);
```

So when you load (or paste) markdown that contains a table like `| a | b |\n|---|---|\n| c | d |`, it is parsed into a table embed and rendered as a table in the editor. Other markdown (headings, lists, code, etc.) is handled by the default block syntaxes.

### Initial content from Markdown

When creating the controller, you pass **initial Markdown**; the first document is built from it:

```dart
static QuillController _createController(String initialMarkdown) {
  Delta delta;
  if (initialMarkdown.trim().isEmpty) {
    delta = Delta()..insert('\n');
  } else {
    delta = _markdownToDelta.convert(initialMarkdown);
    if (delta.isEmpty) delta = Delta()..insert('\n');
  }
  final document = Document.fromDelta(delta);
  // ...
}
```

So for the first paint you pass **`initialMarkdown`** into `RichTextController(initialMarkdown: ...)`.

### Persistence without lag (debounced “render” to Markdown)

Converting the whole document to Markdown on every keystroke would be expensive. So we don’t call `markdown` on every change; we use **onMarkdownChanged** and only run conversion after the user pauses:

```dart
void _onQuillChanged() {
  if (_onMarkdownChanged == null) return;
  _markdownDebounce?.cancel();
  _markdownDebounce = Timer(debounceMarkdownDuration, () {
    final current = markdown;
    if (current != _lastEmittedMarkdown) {
      _lastEmittedMarkdown = current;
      _onMarkdownChanged!(current);
    }
  });
}
```

For live persistence, pass **`onMarkdownChanged: (markdown) { ... }`** and save `markdown` there; the controller only runs Delta→Markdown when the debounce timer fires.

## End-to-end flow

1. **Create controller** (optionally with initial Markdown and a persistence callback):
   - `RichTextController(initialMarkdown: savedString, onMarkdownChanged: (md) => save(md))`
2. **Editing**: User types in `RichTextEditor`; Quill holds the document.
3. **Saving**: After a short pause, `onMarkdownChanged` is called with the current Markdown string; you persist that.
4. **Loading**: When opening a note, call **`controller.loadMarkdown(savedString)`**.

So “Flutter Quill Markdown rendering” in this package is: **use `RichTextController.markdown` and `loadMarkdown`**, plus optional **`onMarkdownChanged`** for debounced persistence. The conversion and “rendering” to/from Markdown are inside the controller and `markdown_quill`.

## Read-only Markdown preview (optional)

If you want a **read-only** preview of the same content (e.g. a side panel):

- Take the string from **`controller.markdown`** (or from **`onMarkdownChanged`**).
- Pass it to a Markdown widget (e.g. `flutter_markdown`’s `MarkdownBody`) for display.

The package does not include that widget; you add it in your app using the same Markdown string the controller already produces.

## Quick reference

| Goal | How to do it |
|------|-------------------------------|
| Get current content as Markdown | `controller.markdown` (use sparingly, e.g. in debounced callback). |
| Load from DB / set content | `controller.loadMarkdown(markdownString)`. |
| Persist on change | `RichTextController(onMarkdownChanged: (md) => save(md))` — conversion is debounced. |
| Custom export syntax (e.g. underline → `__`) | Configure `DeltaToMarkdown` with `customTextAttrsHandlers` / `customEmbedHandlers` in `rich_text_controller.dart`. |
| Initial content | `RichTextController(initialMarkdown: '...')`. |

## See also

- [tables.md](tables.md) – End-to-end how tables work (embed model, insert, render, edit, Markdown round-trip).
- [README](../README.md) – Usage, supported Markdown, performance, API summary.
- [example/](../example/) – Runnable app with toolbar, editor, and debounced Markdown preview.
