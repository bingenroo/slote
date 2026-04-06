# Rich text — end-to-end roadmap (`components/rich_text`)

This document is the **canonical plan** for Slote’s rich-text subsystem: editor stack, features, phases, listeners, and **undo/redo** (AppFlowy `EditorState` history only — the former standalone `components/undo_redo` package was removed).

**Implementation detail (AppFlowy):** [appflowy-editor-roadmap.md](appflowy-editor-roadmap.md) tracks AppFlowy-specific milestones (JSON spike, BIUS, controller, shortcuts).

**Vendored editor + licensing:** Slote uses a local fork at [`components/appflowy_editor`](../../appflowy_editor) (see root / package `dependency_overrides`). Dual-license **AGPL-3.0 | MPL-2.0** and what that means for sharing source is summarized in [`components/appflowy_editor/COMPLIANCE.md`](../../appflowy_editor/COMPLIANCE.md).

---

## Direction

| Topic               | Decision                                                                                                                                                                                      |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Source of truth** | **AppFlowy Document JSON** for pixel-accurate round-trip in the app. Use Markdown (or Delta) only for **import/export or migration**, not as the live model.                                  |
| **Editor**          | [`appflowy_editor`](https://pub.dev/packages/appflowy_editor) — compose UI (toolbars, shortcuts) against `EditorState` APIs.                                                                  |
| **Package layout**  | **`lib/`** exports AppFlowy helpers plus shared editor chrome: [`FormatToolbar`](../lib/src/ui/slote_default_format_toolbar.dart), [`SloteRichTextEditorScaffold`](../lib/src/ui/slote_rich_text_editor_scaffold.dart). The **example** app and **main app** (`create_note`) use the same scaffold; the example adds JSON logging only. |
| **Legacy**          | Pre–AppFlowy Quill implementation is **archived in writing only**: [IMPLEMENTATION.md](../IMPLEMENTATION.md) (no longer the active stack).                                                    |

### Development workflow

- **Path dependency:** Root [`pubspec.yaml`](../../../pubspec.yaml) lists `rich_text` with `path: components/rich_text`. The main app imports **`package:rich_text`**; edits under `components/rich_text/lib/` are reflected on the next analyze, run, or hot restart — no manual “wire into Slote” step beyond using the public API.
- **Shared chrome:** Editor shell (**[`SloteRichTextEditorScaffold`](../lib/src/ui/slote_rich_text_editor_scaffold.dart)**, **[`FormatToolbar`](../lib/src/ui/slote_default_format_toolbar.dart)**) lives in this package so **[`create_note.dart`](../../../lib/src/views/create_note.dart)** and the **[example](../example)** stay aligned. Prefer extending the package when adding toolbar, outline, or scaffold behavior.
- **Where to run:** Use **`components/rich_text/example`** for a fast isolated loop and debounced JSON logging; use the **root Slote app** for product flows (navigation, storage, theme).

---

## Current status (rolling)

| Item                           | State                                                                                                                                                                   |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Active spike**               | [`example/lib/main.dart`](../example/lib/main.dart) — `EditorState` from JSON, `AppFlowyEditor`, fixed **BIUS** toolbar (`toggleAttribute` + caret-aware active state). |
| **Phase (AppFlowy checklist)** | **Phases 3–4 complete** in `package:rich_text` + example: `RichTextEditorController`, debounced JSON, shared BIUS entry points + command shortcuts.                     |
| **Wave C (structural blocks)** | **C1–C5 delivered** (headings, lists, quote, divider, code block, callout) — see [Wave C](#wave-c--structural-blocks-split) below. **C6–C7** (tables, images): basic insert actions exist in [`FormatToolbar`](../lib/src/ui/slote_default_format_toolbar.dart), but full product/editor UX and app-boundary storage/picker story are still deferred (codec round-trip is covered by tests). |
| **Superscript / subscript**    | **Feature done (Wave B)** — Slote-only extension on AppFlowy (delta keys, `WidgetSpan` renderer, fork **caret metrics** / **EOT** hooks, markdown): [SUPERSCRIPT_SUBSCRIPT.md](SUPERSCRIPT_SUBSCRIPT.md). **Caret polish (Apr 2026):** end-of-paragraph vs body height largely fixed; **subscript** still has open edge cases — caret **too tall** when re-entering a sub run from the body, **clipping** while typing — see [§ Sup/sub — remaining limitations](#sup-sub-known-limitations). |
| **Main Slote app**             | **Note body integrated** — [`lib/src/views/create_note.dart`](../../../lib/src/views/create_note.dart): [`SloteRichTextEditorScaffold`](../lib/src/ui/slote_rich_text_editor_scaffold.dart) + `RichTextEditorController`, AppFlowy Document JSON via [`lib/src/services/slote_rich_text_storage.dart`](../../../lib/src/services/slote_rich_text_storage.dart). Legacy/non-JSON bodies normalize or fall back to empty doc. |
| **Outline / TOC (Wave D)**     | **Done** — [`slote_outline.dart`](../lib/src/appflowy/slote_outline.dart) (`sloteCollectOutlineEntries`); [`RichTextEditorController`](../lib/src/appflowy/appflowy_document_controller.dart) `onDebouncedDocumentChanged` (same debounce as JSON); outline UI lives in [`SloteRichTextEditorScaffold`](../lib/src/ui/slote_rich_text_editor_scaffold.dart) (modal sheet &lt;600dp / `endDrawer` ≥600dp, scroll + selection jump). |

## Next (Slote-focused “what’s next”)

1. Wave E: finish editor polish for product quality (theme bridge, mobile/desktop toolbar behavior, and performance/debounce for large docs).
2. Tables/images (C6–C7): define the next product slice beyond basic insert (editing UX + app-level storage/picker wiring). Markdown codec interchange is already in place.

---

## Phased delivery (high level)

Phases build on each other; after each major phase run **`components/rich_text/example`**, **`flutter test`** in `components/rich_text`, and (when UI or persistence changes) the **root Slote app** — it already depends on this package via path.

### Wave A — Foundation (AppFlowy Phases 1–4)

| Step                                   | Scope                                                                                                                                          |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **A1 — Document JSON confidence**      | Load/save `Document.fromJson` / `toJson`, observe deltas per keystroke, validate undo with built-in history. _(Aligns with AppFlowy Phase 1.)_ |
| **A2 — Inline BIUS**                   | Toolbar + parity shortcuts for Bold, Italic, Underline, Strikethrough. _(AppFlowy Phase 2–4.)_                                                 |
| **A3 — Controller + persistence hook** | One owner of `EditorState`; debounced emission of canonical JSON for DB/API/logging; subscription cleanup. _(AppFlowy Phase 3.)_               |
| **A4 — Keyboard parity**               | BIUS (and later shared) commands: toolbar and shortcuts call the **same** `EditorState` entry points. _(AppFlowy Phase 4.)_                    |

### Wave B — Extended inline & typography

| Feature                     | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Superscript / subscript** | **Done (feature)** — See [SUPERSCRIPT_SUBSCRIPT.md](SUPERSCRIPT_SUBSCRIPT.md). Example wires `EditorStyle.copyWith(textSpanDecorator: …, caretMetrics: …, endOfParagraphCaretHeight: …, endOfParagraphCaretMetrics: …)`. **Ongoing:** subscript caret height when **moving from body** back into a sub run; **clipped** caret while **typing** subscript — mitigated by `sloteCaretMetrics` / `sloteEndOfParagraphCaretHeight` but not fully closed; use example `DBG-CARET` logs when reproducing.                                                                                                        |
| **Links**                   | Inline `href` with the Slote UI flow: quick tap opens the URL; long-press (or toolbar action) opens the **link format drawer** implemented as a bottom sheet (`showModalBottomSheet`) in `slote_format_drawers.dart`.                                                                                                                                                                                                                                                                                                                     |
| **Font size, font family**  | **Implemented (Phase 1)**: selection helpers apply AppFlowy inline attributes `font_size` / `font_family` (`sloteApplyFontSize` / `sloteApplyFontFamily`). Markdown export/import supported via `<span font_size=\"...\" font_family='\"...\"'>...` wrapper from `sloteDocumentToMarkdown`.                                                                                                                                                                                                               |
| **Text color, highlight**   | **Implemented (Phase 1):** color + highlight picker as a bottom sheet with preset swatches, applying attributes to the current selection (`showSloteColorFormatDrawer` in `slote_format_drawers.dart`). **Touchpoint:** [`FormatToolbar`](../lib/src/ui/slote_default_format_toolbar.dart).                                                                                                                                                                                                                                                                                                                     |
| **Alignment**               | **Implemented (Phase 1):** block-level `align` via `blockComponentAlign` with `left` / `center` / `right` / `justify` (`justify` uses `TextAlign.justify` on text blocks in vendored `appflowy_editor`). [`FormatToolbar`](../lib/src/ui/slote_default_format_toolbar.dart) exposes all four (example + main app).                                                                                                                                                                                                            |
| **Clear formatting**        | **Implemented (Phase 1):** single command stripping partial inline styles on selection; respects `EditorState` history.                                                                                                                                                                                                                                                                                                                                                                                                                     |

<a id="sup-sub-known-limitations"></a>

#### Superscript / subscript — remaining limitations

Details and diagrams of the implementation live in [SUPERSCRIPT_SUBSCRIPT.md](SUPERSCRIPT_SUBSCRIPT.md). The items below are the **current** product/technical boundaries (not an old punch-list).

1. **No nested superscript or subscript** — The model keeps at most one script level; sup/sup, sub/sub, and sup-inside-sub are out of scope.
2. **Link + script** — A hyperlink with superscript/subscript uses **one** `WidgetSpan` for the whole run (gesture handling for links). Per-character caret stepping matches **plain** script runs (one placeholder per UTF-16 unit) but not all **link+script** multi-character cases.
3. **Residual editor/fork edge cases** — **EOT vs body:** paragraph-end caret using baseline run metrics is largely addressed (Apr 2026 sessions). **Subscript-specific (still open):** when the caret **moves back** from normal text into an existing subscript run, the caret can appear **taller than the subscript glyphs**; while **actively typing** new subscript, the caret can look **clipped** (two code paths in `sloteCaretMetrics` vs EOT helpers — see terminal `DBG-CARET height=… rect=… sup=… sub=…`). IME and mixed script/body lines can still surface minor glitches.

**Primary code:** [`slote_inline_attributes.dart`](../lib/src/appflowy/slote_inline_attributes.dart), [`appflowy_editor_support.dart`](../lib/src/appflowy/appflowy_editor_support.dart) (`sloteToggleSuperscript` / `sloteToggleSubscript`), [`appflowy_document_controller.dart`](../lib/src/appflowy/appflowy_document_controller.dart) (`_syncCaretSupSubTypingStyle`), [`slote_text_span_decorator.dart`](../lib/src/appflowy/slote_text_span_decorator.dart), [`slote_sup_sub_metrics.dart`](../lib/src/appflowy/slote_sup_sub_metrics.dart), [`slote_caret_metrics.dart`](../lib/src/appflowy/slote_caret_metrics.dart), [`slote_end_of_paragraph_caret_height.dart`](../lib/src/appflowy/slote_end_of_paragraph_caret_height.dart), [`slote_markdown_codec.dart`](../lib/src/appflowy/slote_markdown_codec.dart).

### Wave C — Structural blocks (split)

Wave C is implemented in small, shippable slices. Order maximizes reuse (headings/lists unlock TOC + most note-taking docs) and defers “hard storage” decisions (images/tables as dedicated milestones).

#### Wave C — delivered (C1–C5)

These slices are **in place** today: example toolbar wiring, AppFlowy block components, and (where noted) `package:rich_text` APIs or markdown codec coverage.

| Slice | Feature | Notes |
| ----- | ------- | ----- |
| **C1** | **Headings H1–H5** | Block heading levels up to **H5**. APIs and menu: [`slote_heading_support.dart`](../lib/src/appflowy/slote_heading_support.dart) (`sloteToggleHeadingLevel`, `SloteHeadingStyleToolbarMenu`); toolbar: [`FormatToolbar`](../lib/src/ui/slote_default_format_toolbar.dart). Tests: `slote_heading_support_test.dart`, `slote_markdown_heading_levels_test.dart`. |
| **C2** | **Bullet, numbered, checkbox lists** | Toolbar actions use AppFlowy `insertBulletedListAfterSelection` / `insertNumberedListAfterSelection` / `insertCheckboxAfterSelection` (indent/outdent, new item, split/merge follow **AppFlowy defaults**). Tests: [`slote_list_insertion_test.dart`](../test/slote_list_insertion_test.dart). |
| **C3** | **Quote + horizontal rule** | Quote: `insertQuoteAfterSelection`. Divider: `dividerNode()` + `insertNodeAfterSelection` (see [`slote_list_insertion_test.dart`](../test/slote_list_insertion_test.dart)). |
| **C4** | **Code blocks (plain first)** | Fenced-style plain code block via `insertCodeBlockAfterSelection` in [`FormatToolbar`](../lib/src/ui/slote_default_format_toolbar.dart). Markdown round-trip: [`slote_markdown_codec.dart`](../lib/src/appflowy/slote_markdown_codec.dart); tests: `slote_markdown_code_block_test.dart`. Optional syntax highlight is **Wave E**. |
| **C5** | **Callouts** | Custom callout block + insert from toolbar (`insertCalloutAfterSelection`). Markdown: [`slote_callout_markdown.dart`](../lib/src/appflowy/slote_callout_markdown.dart); tests: `slote_markdown_callout_test.dart`. |

#### Wave C — not yet (C6–C7)

These remain **out of scope** for the current editor/product slice: no dedicated Slote toolbar or app-level storage story yet, even though **markdown import/export** for table and image nodes is covered by codec tests (`slote_markdown_table_test.dart`, `slote_markdown_image_test.dart`) for migration and interchange.

| Slice | Feature | Notes |
| ----- | ------- | ----- |
| **C6** | **Tables** | Basic insert (e.g. 2×2) exists in [`FormatToolbar`](../lib/src/ui/slote_default_format_toolbar.dart), but full **editing UX** (insert chrome, complex manipulation) and any Slote-specific table behavior are deferred. Higher complexity than quote/hr/code. |
| **C7** | **Images** | Basic insert (URL) exists in [`FormatToolbar`](../lib/src/ui/slote_default_format_toolbar.dart) (optional `onInsertImageUrl` override); product embedding is deferred: app-boundary storage policy (paths/blobs/encryption), picker UX — not just codec round-trip. |

### Wave D — Advanced content

| Feature             | Notes                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Formula (LaTeX)** | Inline or block embed; renderer + editing UX.                                                                                         |
| **Outline / TOC**   | **Done** — debounced outline refresh (`onDebouncedDocumentChanged` + [`sloteCollectOutlineEntries`](../lib/src/appflowy/slote_outline.dart)); hierarchy UI + tap-to-jump in [`SloteRichTextEditorScaffold`](../lib/src/ui/slote_rich_text_editor_scaffold.dart) (used by [`create_note.dart`](../../../lib/src/views/create_note.dart)). |

### Wave E — Editor polish & theming

| Item                  | Notes                                                                                                   |
| --------------------- | ------------------------------------------------------------------------------------------------------- |
| **Theming bridge**    | `EditorStyle` / `BlockComponentConfiguration` ↔ Slote `theme` component.                                |
| **Mobile vs desktop** | `EditorStyle.mobile()` vs desktop, floating toolbars, safe areas.                                       |
| **Performance**       | Large docs: avoid rebuilding full chrome on every keystroke; debounce heavy readers (TOC, JSON export). |

### Wave F — Cross-cutting (from PRD / security)

| Item           | Notes                                                                                                                      |
| -------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Encryption** | Lives **outside** rich_text core; operate on serialized JSON at app boundary ([roadmap note](appflowy-editor-roadmap.md)). |
| **Draw / ink** | Stays in **`components/draw`**; overlay or attachment model at note level — not inside rich_text core.                     |

---

## Listeners: what uses what

Use **narrow** signals for interactive toolbars; **one debounced pipe** for expensive work.

| UI / concern                         | Typical signals                                                                                                                                                                                                                                                                                                                                            |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Inline toolbar (BIUS, colors, …)** | `selectionNotifier`, `toggledStyleNotifier`, plus **derived state** from node at caret (e.g. `delta.sliceAttributes`). Add `transactionStream` only if you observe staleness.                                                                                                                                                                              |
| **Persistence / preview / TOC**      | **`transactionStream`** (debounced ~200 ms) → emit JSON, refresh outline.                                                                                                                                                                                                                                                                                  |
| **Undo / redo buttons (editor)**     | **`sloteEditorCanUndo` / `sloteEditorCanRedo`** + **`sloteEditorUndo` / `sloteEditorRedo`** on **`EditorState.undoManager`**, and **`RichTextEditorController.undoRedoListenable`** (notifies when the can-undo/can-redo pair changes; microtask-deferred so it matches AppFlowy’s post-`apply` history). |

---

## Undo/redo (AppFlowy)

### In `package:rich_text`

- **AppFlowy-only API**: [`appflowy_undo_support.dart`](../lib/src/appflowy/appflowy_undo_support.dart) exports **`sloteEditorCanUndo`**, **`sloteEditorCanRedo`**, **`sloteEditorUndo`**, **`sloteEditorRedo`** — thin wrappers over **`EditorState.undoManager`** (same stack as AppFlowy’s standard undo/redo shortcuts).
- **`RichTextEditorController`**: optional **`maxHistoryItemSize`** / **`minHistoryItemDuration`** forwarded to **`EditorState`**; **`undoRedoListenable`** (a Flutter `Listenable`) rebuilds toolbar enablement when undo/redo availability changes.
- **Toolbar + example**: undo/redo on [`FormatToolbar`](../lib/src/ui/slote_default_format_toolbar.dart); [`SloteRichTextEditorScaffold`](../lib/src/ui/slote_rich_text_editor_scaffold.dart) merges selection, toggled-style, and `undoRedoListenable`. [`rich_text_editor_screen.dart`](../example/lib/editor/rich_text_editor_screen.dart) is a thin shell + JSON log.

### Rest of repo

- **Main app note body:** Uses **AppFlowy** only (`CreateNoteView` in [`lib/src/views/create_note.dart`](../../../lib/src/views/create_note.dart)).
- **AppFlowy `EditorState`**: Own **transaction history**; undo/redo replays edits made through the editor. **All rich-text actions** (BIUS, blocks, links, …) go through **transactions** so **one** history stack covers them.
- **Former `components/undo_redo` package:** Removed from the repo (it was only a generic/plain-text demo; nothing in the root app depended on it). **Drawing undo** will live in **`draw`** / stroke model when implemented; a future **note-level** unified Cmd+Z would orchestrate editor + draw stacks if product requires it.

### Checklist (historical)

- [x] Note body uses `EditorState` / `AppFlowyEditor` from `rich_text`.
- [x] Undo/redo UI calls editor history, verified across BIUS + blocks.
- [x] Remove `package:undo_redo/undo_redo.dart` from note screens (no remaining callers).
- [x] Remove `undo_redo` from root `pubspec.yaml` (already absent).
- [x] Delete `components/undo_redo`; update PRD, `components/README.md`, `COMPONENT_TEST_PLATFORMS.md`, CI, and `cmd.py`.

---

## Repo touchpoints

| Area                     | Path                                                     |
| ------------------------ | -------------------------------------------------------- |
| Example (isolated dev)   | [`example/`](../example) — same `package:rich_text` APIs as the app; JSON preview for debugging |
| Main app note editor     | [`lib/src/views/create_note.dart`](../../../lib/src/views/create_note.dart) — imports **`package:rich_text`** (path-resolved) |
| Public exports           | [`lib/rich_text.dart`](../lib/rich_text.dart)            |
| AppFlowy phase checklist | [appflowy-editor-roadmap.md](appflowy-editor-roadmap.md) |
| Legacy Quill record      | [IMPLEMENTATION.md](../IMPLEMENTATION.md)                |

---

## Related Slote docs

- **[SUPERSCRIPT_SUBSCRIPT.md](SUPERSCRIPT_SUBSCRIPT.md)** — superscript/subscript (Slote extension on AppFlowy).
- **[PRD.md](../../../PRD.md)** — product scope, component inventory, MVP alignment.
- **[README.md](../README.md)** — package overview and links.

---

_Roadmap versions with the product; prefer this file and the AppFlowy checklist for engineering planning._
