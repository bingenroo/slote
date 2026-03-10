# Tables in the rich text editor

This document describes how tables work end-to-end in the rich_text component: data model, insertion, rendering, editing, and Markdown round-trip.

## 1. What a table is in the document

A table is **not** a special Quill block type. It is implemented as a **single block embed** in the Quill document:

- **In the document**: One "character" (one node) with:
  - **Type**: `EmbeddableTable.tableType` (from the `markdown_quill` package).
  - **Data**: A **string** — the raw Markdown of the table, e.g.  
    `"|   |   |\n|---|---|\n|   |   |"` for a 2×2 empty table.

So the document is a linear sequence of characters and embeds; a table is one of those embeds, and its "content" is that Markdown string. All table structure (rows, cells) exists only inside that string and in the UI that parses it.

## 2. Inserting a table (UI → document)

### 2.1 User action

- The user opens the "More" (⋯) menu in the format toolbar and selects **"Table"** (`format_toolbar.dart`).
- A dialog (`_showTableSizeDialog`) opens: a 7×5 grid of cells; the user taps to choose columns × rows (e.g. 3×4). Tapping "Insert" returns `(selectedCols, selectedRows)`.

### 2.2 Controller: build Markdown and insert embed

- The toolbar calls `controller.insertTableWithSize(cols, rows)`.

In **`RichTextController`** (`rich_text_controller.dart`):

1. **Clamp** columns and rows (e.g. 1–20 columns, 1–30 rows).
2. **Build the initial table Markdown** with `_buildTableMarkdown(cols, rows)`:
   - One header row: `|   |   |   |` (spaces per column).
   - Separator row: `|---|---|---|`.
   - `rows - 1` body rows with the same pattern (spaces).
   So for 3 columns and 4 rows you get 4 lines of Markdown (header + separator + 3 body rows).
3. **Insert position**: `_endOfCurrentBlock(selection.start)` — the next newline after the cursor, or the end of the document. So the table is inserted at the **end of the current paragraph/line**.
4. **Three edits** to the Quill document:
   - Insert `\n` at that offset (new line before the table).
   - Insert the embed `EmbeddableTable(tableMarkdown)` at offset+1 (so the table sits alone on its line).
   - Insert `\n` at offset+2 (new line after the table).
5. **Selection**: The cursor is moved to `offset + 3` (after the table).

After insert, the document looks like: `…current block…\n[TABLE_EMBED]\n` and the caret is right after the table.

## 3. How the table is rendered (Quill → Flutter)

### 3.1 Who builds the widget

- **`RichTextEditor`** is a thin wrapper around `QuillEditor.basic(controller: controller.quillController, config: widget.config)`.
- The config comes from **`richTextEditorConfig(..., controller: controller)`** and includes `embedBuilders: [..., TableEmbedBuilder(onReplaceTable: ...), ...]`.
- When the Quill editor renders the document, it encounters an embed node. It looks up the builder whose `key` equals the embed type. **`TableEmbedBuilder.key`** is `EmbeddableTable.tableType`, so **TableEmbedBuilder** is used for every table embed.

### 3.2 TableEmbedBuilder.build

In **`embed_builders.dart`**, `TableEmbedBuilder.build(context, embedContext)`:

1. **Reads data**: `value = embedContext.node.value`, `data = value.data as String` (or `''`). That is the stored Markdown string.
2. **Parses to rows**: `_parseTableData(data)`:
   - Normalize line endings, split on `\n`, trim, drop empty lines.
   - For each line: split on `|`, trim, drop empty segments → list of cell strings.
   - Skip a line if it looks like a separator (e.g. only `-` and spaces).  
   Result: `List<List<String>>` (rows of cell texts).
3. **Theme**: Border color, header background, body background, and text style from `Theme.of(context)`.
4. **Branch**:
   - **Rows empty**  
     - If editable: show a default 2×2 grid via `_EditableTableContent` with `defaultRows`, using `embedContext.node.documentOffset` so persist knows where to write.  
     - If read-only: show a "Table (no rows)" placeholder.
   - **Rows not empty**  
     - If **editable** (`onReplaceTable != null` and not read-only): build `_EditableTableContent(initialRows: rows, embedOffset: embedContext.node.documentOffset, ..., onReplaceTable: onReplaceTable!)`.  
     - If **read-only**: build `_buildStaticTable(rows, ...)` — a Flutter `Table` with `TableRow`s; first row uses header style (bold, header background), rest use body style; cells are `Text` in padding.
5. **Wrapper**: The table is placed in a horizontal `SingleChildScrollView`, `ConstrainedBox` (min height/width), and for block embeds, `SizedBox(width: double.infinity)`. A `Listener` with `HitTestBehavior.opaque` ensures the table doesn't steal focus in surprising ways.

So: **one embed in the document → one call to `TableEmbedBuilder.build` → one Table (static or editable) on screen.** The only "state" in the document is that single embed and its Markdown string.

## 4. Editing cells and writing back

### 4.1 Editable table state

When the builder chooses **`_EditableTableContent`**:

- It is a `StatefulWidget` that receives `initialRows` (from the parsed Markdown), `embedOffset` (document offset of the embed), and `onReplaceTable`.
- In `initState`, it creates a `TextEditingController` and `FocusNode` per cell, initializing each controller with the cell text from `initialRows`.

### 4.2 User edits

- Each cell is a `TextField` (no border, dense). The user types; only the local controllers change; the Quill document is **not** updated on every keystroke.

### 4.3 Persisting into the document

- When the user leaves the table (tap outside) or submits (e.g. Enter), the field calls `onTapOutside` / `onSubmitted` → `_persistTable()`.
- **`_persistTable()`**:
  - Builds `rows` from all controllers: `row.map((c) => c.text).toList()` per row.
  - Converts to Markdown with **`TableEmbedBuilder.rowsToMarkdown(rows)`**:
    - First row → `| cell1 | cell2 | ... |`
    - Second line → `|---|...|`
    - Remaining rows → same pipe format; short rows padded with spaces.
  - Calls **`widget.onReplaceTable(widget.embedOffset, markdownString)`**.

### 4.4 Config and controller

- In **`rich_text_editor_config.dart`**, `TableEmbedBuilder` is given  
  `onReplaceTable: controller != null ? (offset, newMarkdown) => controller!.replaceTableEmbedAt(offset, newMarkdown) : null`.
- So the callback calls **`RichTextController.replaceTableEmbedAt(offset, newMarkdown)`**, which does:
  - `_quillController.replaceText(offset, 1, EmbeddableTable(newMarkdown), null)`  
  i.e. replace the **one** character (the table embed) at that offset with a new embed whose data is the updated Markdown. The document now stores the new table content; the next build will parse the new string and show the new text.

Flow: **edit in UI → _persistTable → rowsToMarkdown → onReplaceTable(embedOffset, newMarkdown) → replaceTableEmbedAt → replaceText(offset, 1, EmbeddableTable(newMarkdown))** — a single replace of the embed at a known offset.

## 5. Saving: document → Markdown string

When the app saves (e.g. debounced `onMarkdownChanged` or an explicit read):

- The controller's **`markdown`** getter runs: `_quillController.document.toDelta()` then `_deltaToMarkdown.convert(delta)`.
- **`_deltaToMarkdown`** is a `DeltaToMarkdown` from `markdown_quill` with  
  `customEmbedHandlers: { EmbeddableTable.tableType: EmbeddableTable.toMdSyntax }`.
- When the converter hits an embed with type `EmbeddableTable.tableType`, it calls **`EmbeddableTable.toMdSyntax`** (from `markdown_quill`), which takes the embed's data string (the table Markdown) and writes it into the output Markdown stream. So the table appears in the saved string as normal Markdown lines (e.g. `| a | b |\n|---|---|\n| c | d |`).

So: **Quill document (with table embed) → Delta → DeltaToMarkdown + customEmbedHandlers → Markdown string with table syntax.** The table is stored as Markdown, not as a custom JSON structure.

## 6. Loading: Markdown string → document

When loading a note (e.g. from DB):

- The app calls **`controller.loadMarkdown(savedMarkdown)`**.
- The controller does: `delta = _markdownToDelta.convert(markdown)`, then `Document.fromDelta(delta)`, then assigns that document to `_quillController.document` and resets selection.

**How tables get into the Delta**

- **`_markdownToDelta`** uses a custom **Markdown document**: `md.Document(blockSyntaxes: [..., const EmbeddableTableSyntax()])`. So the Markdown parser recognizes table blocks (lines like `| a | b |`, `|---|---|`, etc.).
- When the parser sees a table, it produces an element that is then turned into an embed via  
  `customElementToEmbeddable: { EmbeddableTable.tableType: EmbeddableTable.fromMdSyntax }`.  
  **`EmbeddableTable.fromMdSyntax`** (from `markdown_quill`) turns that element into an `EmbeddableTable` whose data is the table's Markdown string. So the Delta gets an insert of one embed (type + data string).
- That Delta is what builds the Document. So when the editor later renders, it sees a table embed and uses `TableEmbedBuilder` as in section 3.

So: **Markdown string → MarkdownToDelta (with EmbeddableTableSyntax + fromMdSyntax) → Delta with table embed → Document → QuillEditor → TableEmbedBuilder → Table on screen.**

## 7. Read-only mode

- If **`TableEmbedBuilder`** is created with **`onReplaceTable: null`** (e.g. config built without a controller), or if **`embedContext.readOnly`** is true, the builder never builds `_EditableTableContent`. It only builds `_buildStaticTable(...)` or the "Table (no rows)" placeholder. So no TextFields, no callbacks; the table is display-only and still driven by the same embed data string.

## 8. Summary diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  USER                                                                        │
└─────────────────────────────────────────────────────────────────────────────┘
  │ Insert table (toolbar)     Edit cells (tap outside/Enter)    Save / Load
  ▼                            ▼                                 ▼
┌──────────────────────┐  ┌─────────────────────────────┐  ┌─────────────────────┐
│ RichTextController   │  │ _EditableTableContent       │  │ RichTextController  │
│ insertTableWithSize  │  │ _persistTable()             │  │ markdown /          │
│ • _buildTableMarkdown│  │ → rowsToMarkdown(rows)      │  │ loadMarkdown()      │
│ • replaceText(embed) │  │ → onReplaceTable(offset,md) │  │ • DeltaToMarkdown   │
│ • replaceText(\n)    │  │   → replaceTableEmbedAt     │  │   (toMdSyntax)      │
└──────────┬───────────┘  └──────────────┬──────────────┘  │ • MarkdownToDelta   │
           │                             │                 │   (EmbeddableTable  │
           │                             │                 │    Syntax +         │
           ▼                             ▼                 │    fromMdSyntax)    │
┌──────────────────────────────────────────────────────────┴─────────────────────┐
│  QUILL DOCUMENT                                                                 │
│  …text… \n [EMBED type=EmbeddableTable.tableType data="|   |   |\n|---|---|\n…"] \n │
└──────────┬──────────────────────────────────────────────────────────────────────┘
           │ QuillEditor renders embeds
           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│  QuillEditorConfig.embedBuilders → key == EmbeddableTable.tableType               │
│  → TableEmbedBuilder.build(embedContext)                                          │
│     • value.data → markdown string → _parseTableData → List<List<String>>         │
│     • editable? _EditableTableContent(initialRows, embedOffset, onReplaceTable)   │
│       else _buildStaticTable(rows)                                                │
│     → Flutter Table (or 2×2 default) inside ScrollView + ConstrainedBox           │
└──────────────────────────────────────────────────────────────────────────────────┘
```

## 9. File reference

| File | Responsibility |
|------|----------------|
| **format_toolbar.dart** | "Table" menu → size dialog → `controller.insertTableWithSize(cols, rows)`. |
| **rich_text_controller.dart** | Insert (Markdown + embed at end of block), replace (`replaceTableEmbedAt`), Delta↔Markdown (customEmbedHandlers, EmbeddableTableSyntax, fromMdSyntax/toMdSyntax). |
| **embed_builders.dart** | Turn one table embed into one Table widget: parse data string, static vs editable, `rowsToMarkdown` for persist. |
| **rich_text_editor_config.dart** | Registers `TableEmbedBuilder` and wires `onReplaceTable` → `controller.replaceTableEmbedAt`. |
| **markdown_quill** (package) | `EmbeddableTable`, `EmbeddableTableSyntax`, `fromMdSyntax`, `toMdSyntax` — type, data shape, and Markdown ↔ Delta for tables. |

## See also

- [markdown-rendering.md](markdown-rendering.md) — How the editor converts between Quill and Markdown in general.
- [README](../README.md) — Usage and API overview.
