# Rich Text Implementation Record

**Current direction:** AppFlowy Editor + Document JSON — see **[docs/ROADMAP.md](docs/ROADMAP.md)**.

This document preserves what was implemented before the full dependency gutting (legacy Quill stack).

## Architecture

The component was layered as:

- `RichTextController`: state, formatting actions, selection style inspection, markdown import/export, debounced persistence
- `RichTextEditor`: WYSIWYG editor widget wrapper
- `richTextEditorConfig()`: style and embed configuration
- `FormatToolbar`: formatting controls and insertion actions
- Embed/rendering files: `embed_builders.dart`, `syntax_code_block.dart`, `fenced_code_embed_syntax.dart`
- Utility files: `text_formatter.dart`, `formatted_text.dart`, `formatting/*`

## Core Controller Design

`RichTextController` wrapped Quill and exposed:

- `markdown` getter and `loadMarkdown(String)` for DB-ready serialization round trips
- Debounced callback `onMarkdownChanged` (default 200ms)
- Selection state projection via `selectionStyle` and `selectionStyleListenable`
- Formatting methods for:
  - inline: bold, italic, underline, strikethrough, inline code, subscript, superscript
  - block: headers H1-H3, block quote, code block
  - lists: bullet, ordered, checklist
  - document actions: alignment, size, links, clear formatting, line break, indent/outdent
  - embeds: insert/replace horizontal rule, code block, and table

`SelectionStyleState` tracked flags and values:

- `isBold`, `isItalic`, `isUnderline`, `isStrikethrough`, `isInlineCode`
- `isSubscript`, `isSuperscript`
- `headerLevel`, `isBlockQuote`, `isCodeBlock`
- `listType`, `sizeLabel`, `alignment`, `indentLevel`

`EditorFocusRequester` provided a bridge from embeds back to editor focus so keyboard transitions used one active cursor.

## Markdown Conversion Pipeline

Implemented conversion used `DeltaToMarkdown` and `MarkdownToDelta` with custom handlers.

Key behavior:

- Underline exported with custom text attr wrapper: `__content__`
- Custom embed handlers:
  - table via `EmbeddableTable`
  - syntax code block via custom serializer
- Markdown parser config used custom block syntaxes:
  - `FencedCodeToEmbedSyntax`
  - `EmbeddableTableSyntax`

Code-block data contract encoded embed payload as:

```text
language\ncode
```

and converted to markdown fenced blocks:

```text
```lang
...code...
```
```

## Custom Embeds

### Horizontal Rule (`divider`)

- Rendered as fixed 1.5px border line
- Stable visual thickness independent of position

### Syntax Code Block (`syntax_code_block`)

- Editable block widget with footer controls
- Footer included language dropdown and Copy action
- Highlight theme colors approximated VS Code dark tokens:
  - keyword `#C586C0`
  - number `#DCDCAA`
  - string `#CE9178`
  - comment `#6A9955`
- Supported language list included common IDs (`plaintext`, `cpp`, `dart`, `java`, `javascript`, `typescript`, `python`, `go`, `rust`, `sql`, etc.)
- Arrow-key exit behavior:
  - Up on first line requested focus above block
  - Down on last line requested focus below block
- Focus synchronization done with `_CodeBlockFocusSync`

### Editable Table (`embeddable_table`)

- Parsed markdown table rows to editable cell grid
- Serialized edited rows back to markdown with header + separator
- Included insert-size dialog (up to 7 columns x 5 rows)
- Focus handoff and selection safety handled by `_TableFocusSync`

## Editor Styling and Config

`richTextEditorConfig()` set:

- Telegram-style code block visuals
  - dark background (`#1E1E1E` or `#2D2D2D` depending theme)
  - accent left border
  - monospace text
- Inline code chip style (rounded background, muted code text)
- Distinct headings:
  - H1: 28px
  - H2: 22px
  - H3: 18px
- Attribute-oriented inline text styles to preserve merge behavior
- Custom list/paragraph/link styles
- Embed builders for divider, code block, and table

## Toolbar Behavior

`FormatToolbar` provided:

- Inline controls: bold, underline, italic
- More menu: strikethrough, inline code, subscript, superscript
- Font size dropdown: small/normal/large/huge
- Heading dropdown: paragraph + H1/H2/H3
- List controls: checklist, bullet, ordered
- Link insertion dialog
- Alignment buttons: left/center/right
- Clear formatting
- Indent/outdent
- Insert menu: code block, horizontal line, table

## Fenced Code Syntax Parser

`FencedCodeToEmbedSyntax` was a custom markdown `BlockSyntax` that:

- Matched triple-backtick and triple-tilde fences
- Extracted language from info string
- Captured body preserving line layout
- Produced element tagged with embed type and attrs (`language`, `data`)

## Debounced Persistence

The controller listener delayed markdown emission by a timer to avoid recomputing on every keystroke.

- Default delay: 200ms
- Deduped emissions by comparing with last emitted markdown string

## Utility Formatting Files

Implemented utilities also included:

- `TextFormatter`: wraps selected plain text with markdown markers (`**`, `*`, `__`)
- `FormattedText`: parses marker syntax into styled `TextSpan` output
- `formatting/bold.dart`, `italic.dart`, `underline.dart`: formatter helpers

## Representative Snippets

Focus handoff intent:

```dart
editorFocusRequester.requestFocus();
controller.moveSelectionTo(offset);
```

Code block payload contract:

```dart
final data = language.isEmpty ? code : '$language\n$code';
```

Table markdown serialization shape:

```text
|h1|h2|
|---|---|
|c1|c2|
```

## Notes

This file is intentionally retained after source removal so implementation decisions, behavior, and integration assumptions remain documented.
