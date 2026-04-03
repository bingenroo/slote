# Rich text — end-to-end roadmap (`components/rich_text`)

This document is the **canonical plan** for Slote’s rich-text subsystem: editor stack, features, phases, listeners, and how **undo/redo** fits relative to [`components/undo_redo`](../../undo_redo).

**Implementation detail (AppFlowy):** [appflowy-editor-roadmap.md](appflowy-editor-roadmap.md) tracks AppFlowy-specific milestones (JSON spike, BIUS, controller, shortcuts).

**Vendored editor + licensing:** Slote uses a local fork at [`components/appflowy_editor`](../../appflowy_editor) (see root / package `dependency_overrides`). Dual-license **AGPL-3.0 | MPL-2.0** and what that means for sharing source is summarized in [`components/appflowy_editor/COMPLIANCE.md`](../../appflowy_editor/COMPLIANCE.md).

---

## Direction

| Topic               | Decision                                                                                                                                                                                      |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Source of truth** | **AppFlowy Document JSON** for pixel-accurate round-trip in the app. Use Markdown (or Delta) only for **import/export or migration**, not as the live model.                                  |
| **Editor**          | [`appflowy_editor`](https://pub.dev/packages/appflowy_editor) — compose UI (toolbars, shortcuts) against `EditorState` APIs.                                                                  |
| **Package layout**  | **`lib/`** now exports AppFlowy helpers (`RichTextEditorController`, BIUS entry points, shortcut wiring). The **example** app composes the full editor UI and depends on `package:rich_text`. |
| **Legacy**          | Pre–AppFlowy Quill implementation is **archived in writing only**: [IMPLEMENTATION.md](../IMPLEMENTATION.md) (no longer the active stack).                                                    |

---

## Current status (rolling)

| Item                           | State                                                                                                                                                                   |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Active spike**               | [`example/lib/main.dart`](../example/lib/main.dart) — `EditorState` from JSON, `AppFlowyEditor`, fixed **BIUS** toolbar (`toggleAttribute` + caret-aware active state). |
| **Phase (AppFlowy checklist)** | **Phases 3–4 complete** in `package:rich_text` + example: `RichTextEditorController`, debounced JSON, shared BIUS entry points + command shortcuts.                     |
| **Wave C (structural blocks)** | **C1–C5 delivered** (headings, lists, quote, divider, code block, callout) — see [Wave C](#wave-c--structural-blocks-split) below. **C6–C7** (tables, images) still **not** product/editor milestones; markdown codec tests cover table/image round-trip separately. |
| **Superscript / subscript**    | **Done (Wave B)** — Slote-only extension on AppFlowy (delta keys, `WidgetSpan` renderer, caret/EOT fork hooks, markdown). Implementation guide: [SUPERSCRIPT_SUBSCRIPT.md](SUPERSCRIPT_SUBSCRIPT.md). |
| **Main Slote app**             | Note body still uses plain text / Quill at root; **integration** of this editor is a separate milestone (see PRD).                                                      |

---

## Phased delivery (high level)

Phases build on each other; run the example app and tests after each major phase.

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
| **Superscript / subscript** | **Done** — See [SUPERSCRIPT_SUBSCRIPT.md](SUPERSCRIPT_SUBSCRIPT.md) for architecture (attributes, toggles, `toggledStyle` sync, `WidgetSpan` layout, caret metrics, markdown). Example wires `EditorStyle.copyWith(textSpanDecorator: …, caretMetrics: …, endOfParagraphCaretHeight: …)`.                                                                                                        |
| **Links**                   | Inline `href` (or package equivalent); dialog or paste handler. **Current behavior:** quick tap opens the URL in the system default browser; long-press opens the link format drawer.                                                                                                                                                                                                                                                                                                                     |
| **Font size, font family**  | **Implemented (Phase 1)**: selection helpers apply AppFlowy inline attributes `font_size` / `font_family` (`sloteApplyFontSize` / `sloteApplyFontFamily`). Markdown export/import supported via `<span font_size=\"...\" font_family='\"...\"'>...` wrapper from `sloteDocumentToMarkdown`.                                                                                                                                                                                                               |
| **Text color, highlight**   | Use / extend built-in color attributes where available. **Near-term focus — picker UX:** match **Google Docs–style mobile** behavior: a **bottom sheet** (slide-up formatting panel from the bottom; often described informally as a mobile “formatting drawer”) with swatches/options—not separate modal dialogues for raw hex input; desktop can use compact menus or the same sheet for parity. **Touchpoint:** [`example/lib/editor/format_toolbar.dart`](../example/lib/editor/format_toolbar.dart). |
| **Alignment**               | **Implemented (Phase 1, example toolbar)**: block-level `align` via `blockComponentAlign` with `left` / `center` / `right` / `justify` (`justify` uses `TextAlign.justify` on text blocks in vendored `appflowy_editor`). Slote example toolbar exposes all four. Main app wiring is deferred.                                                                                                                                                                                                            |
| **Clear formatting**        | Single command stripping partial styles on selection; respects `EditorState` history.                                                                                                                                                                                                                                                                                                                                                                                                                     |

<a id="sup-sub-known-limitations"></a>

#### Superscript / subscript — remaining limitations

Details and diagrams of the implementation live in [SUPERSCRIPT_SUBSCRIPT.md](SUPERSCRIPT_SUBSCRIPT.md). The items below are the **current** product/technical boundaries (not an old punch-list).

1. **No nested superscript or subscript** — The model keeps at most one script level; sup/sup, sub/sub, and sup-inside-sub are out of scope.
2. **Link + script** — A hyperlink with superscript/subscript uses **one** `WidgetSpan` for the whole run (gesture handling for links). Per-character caret stepping matches **plain** script runs (one placeholder per UTF-16 unit) but not all **link+script** multi-character cases.
3. **Residual editor/fork edge cases** — Caret height at paragraph end, mixed script/body lines, and IME-specific behavior are mitigated by `sloteCaretMetrics` / `sloteEndOfParagraphCaretHeight` on the Slote fork; corner cases may still appear.

**Primary code:** [`slote_inline_attributes.dart`](../lib/src/appflowy/slote_inline_attributes.dart), [`appflowy_editor_support.dart`](../lib/src/appflowy/appflowy_editor_support.dart) (`sloteToggleSuperscript` / `sloteToggleSubscript`), [`appflowy_document_controller.dart`](../lib/src/appflowy/appflowy_document_controller.dart) (`_syncCaretSupSubTypingStyle`), [`slote_text_span_decorator.dart`](../lib/src/appflowy/slote_text_span_decorator.dart), [`slote_sup_sub_metrics.dart`](../lib/src/appflowy/slote_sup_sub_metrics.dart), [`slote_caret_metrics.dart`](../lib/src/appflowy/slote_caret_metrics.dart), [`slote_end_of_paragraph_caret_height.dart`](../lib/src/appflowy/slote_end_of_paragraph_caret_height.dart), [`slote_markdown_codec.dart`](../lib/src/appflowy/slote_markdown_codec.dart).

### Wave C — Structural blocks (split)

Wave C is implemented in small, shippable slices. Order maximizes reuse (headings/lists unlock TOC + most note-taking docs) and defers “hard storage” decisions (images/tables as dedicated milestones).

#### Wave C — delivered (C1–C5)

These slices are **in place** today: example toolbar wiring, AppFlowy block components, and (where noted) `package:rich_text` APIs or markdown codec coverage.

| Slice | Feature | Notes |
| ----- | ------- | ----- |
| **C1** | **Headings H1–H5** | Block heading levels up to **H5**. APIs and menu: [`slote_heading_support.dart`](../lib/src/appflowy/slote_heading_support.dart) (`sloteToggleHeadingLevel`, `SloteHeadingStyleToolbarMenu`); example: [`format_toolbar.dart`](../example/lib/editor/format_toolbar.dart). Tests: `slote_heading_support_test.dart`, `slote_markdown_heading_levels_test.dart`. |
| **C2** | **Bullet, numbered, checkbox lists** | Toolbar actions use AppFlowy `insertBulletedListAfterSelection` / `insertNumberedListAfterSelection` / `insertCheckboxAfterSelection` (indent/outdent, new item, split/merge follow **AppFlowy defaults**). Tests: [`slote_list_insertion_test.dart`](../test/slote_list_insertion_test.dart). |
| **C3** | **Quote + horizontal rule** | Quote: `insertQuoteAfterSelection`. Divider: `dividerNode()` + `insertNodeAfterSelection` (see [`slote_list_insertion_test.dart`](../test/slote_list_insertion_test.dart)). |
| **C4** | **Code blocks (plain first)** | Fenced-style plain code block via `insertCodeBlockAfterSelection` in the example toolbar. Markdown round-trip: [`slote_markdown_codec.dart`](../lib/src/appflowy/slote_markdown_codec.dart); tests: `slote_markdown_code_block_test.dart`. Optional syntax highlight is **Wave E**. |
| **C5** | **Callouts** | Custom callout block + insert from toolbar (`insertCalloutAfterSelection`). Markdown: [`slote_callout_markdown.dart`](../lib/src/appflowy/slote_callout_markdown.dart); tests: `slote_markdown_callout_test.dart`. |

#### Wave C — not yet (C6–C7)

These remain **out of scope** for the current editor/product slice: no dedicated Slote toolbar or app-level storage story yet, even though **markdown import/export** for table and image nodes is covered by codec tests (`slote_markdown_table_test.dart`, `slote_markdown_image_test.dart`) for migration and interchange.

| Slice | Feature | Notes |
| ----- | ------- | ----- |
| **C6** | **Tables** | Full **editing UX** (insert from chrome, complex manipulation) and any Slote-specific table behavior — schedule after the delivered block set. Higher complexity than quote/hr/code. |
| **C7** | **Images** | Embed block **in product**: storage policy at app boundary (paths, blobs, encryption), picker UX, and main-app wiring — not just codec round-trip. |

### Wave D — Advanced content

| Feature             | Notes                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Formula (LaTeX)** | Inline or block embed; renderer + editing UX.                                                                                         |
| **Outline / TOC**   | **Chrome**, not a single delta: walk document (on debounced `transactionStream` or equivalent), show headings hierarchy, jump on tap. |

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
| **Undo / redo buttons (editor)**     | **`sloteEditorCanUndo` / `sloteEditorCanRedo`** + **`sloteEditorUndo` / `sloteEditorRedo`** on **`EditorState.undoManager`**, and **`RichTextEditorController.undoRedoListenable`** (notifies when the can-undo/can-redo pair changes; microtask-deferred so it matches AppFlowy’s post-`apply` history). Not the generic `undo_redo` package (see below). |

---

## Undo/redo: `undo_redo` vs AppFlowy

### In `package:rich_text` (today)

- **AppFlowy-only API**: [`appflowy_undo_support.dart`](../lib/src/appflowy/appflowy_undo_support.dart) exports **`sloteEditorCanUndo`**, **`sloteEditorCanRedo`**, **`sloteEditorUndo`**, **`sloteEditorRedo`** — thin wrappers over **`EditorState.undoManager`** (same stack as AppFlowy’s standard undo/redo shortcuts).
- **`RichTextEditorController`**: optional **`maxHistoryItemSize`** / **`minHistoryItemDuration`** forwarded to **`EditorState`**; **`undoRedoListenable`** (a Flutter `Listenable`) rebuilds toolbar enablement when undo/redo availability changes.
- **Example**: undo/redo icons on [`format_toolbar.dart`](../example/lib/editor/format_toolbar.dart) merged with selection/toggled-style listenables in [`rich_text_editor_screen.dart`](../example/lib/editor/rich_text_editor_screen.dart).

### Today (rest of repo)

- **`components/undo_redo`**: Generic stack + **`TextUndoRedoController` / `UnifiedUndoRedoController`** used by the **main app** for **plain `TextFormField`-style** body text (`create_note*.dart`).
- **AppFlowy `EditorState`**: Own **transaction history**; undo/redo replays edits made through the editor. **All rich-text actions** (BIUS, blocks, links, …) should go through **transactions** so **one** history stack covers them.

### Recommendation

1. **Do not duplicate** document undo inside `undo_redo` when the note body is AppFlowy-driven. Wire **Undo/Redo** toolbar actions to **`EditorState`** / the **`sloteEditor*`** helpers above (same stack as typing).
2. **After** the note body uses AppFlowy end-to-end, **remove** `UnifiedUndoRedoController` (and `undo_redo` imports) from note screens for that field.
3. **Deprecate `components/undo_redo`** when nothing in the repo imports it:
   - Either **delete** the package and drop the path dependency from root `pubspec.yaml`, **or**
   - **Move** a tiny generic helper into `rich_text/lib/src/` if a non-editor widget still needs stack-based undo (unlikely for v1).
4. **Drawing undo** remains owned by **`draw`** / stroke model until a product decision unifies stacks; not blocked on `undo_redo`.

### Planned removal checklist (execute when integrating rich_text into the app)

- [ ] Note body uses `EditorState` / `AppFlowyEditor` from `rich_text`.
- [ ] Undo/redo UI calls editor history, verified across BIUS + blocks.
- [ ] Remove `package:undo_redo/undo_redo.dart` from `create_note*.dart` (and any other callers).
- [ ] Remove `undo_redo` from root `pubspec.yaml` if unused.
- [ ] Delete or archive `components/undo_redo` and update [PRD.md](../../../PRD.md), [components/README.md](../../README.md), and [COMPONENT_TEST_PLATFORMS.md](../../COMPONENT_TEST_PLATFORMS.md).

---

## Repo touchpoints

| Area                     | Path                                                     |
| ------------------------ | -------------------------------------------------------- |
| Spike / daily dev        | [`example/`](../example)                                 |
| Future public API        | [`lib/rich_text.dart`](../lib/rich_text.dart)            |
| AppFlowy phase checklist | [appflowy-editor-roadmap.md](appflowy-editor-roadmap.md) |
| Legacy Quill record      | [IMPLEMENTATION.md](../IMPLEMENTATION.md)                |

---

## Related Slote docs

- **[SUPERSCRIPT_SUBSCRIPT.md](SUPERSCRIPT_SUBSCRIPT.md)** — superscript/subscript (Slote extension on AppFlowy).
- **[PRD.md](../../../PRD.md)** — product scope, component inventory, MVP alignment.
- **[README.md](../README.md)** — package overview and links.

---

_Roadmap versions with the product; prefer this file and the AppFlowy checklist for engineering planning._
