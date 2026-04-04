# Superscript & subscript (Slote extension)

AppFlowy Editor does **not** ship first-class superscript/subscript for rich text. Slote adds them as **custom delta attributes**, **custom rendering** (via the editor’s text-span decorator hook), **caret helpers** on a small **fork** of `appflowy_editor`, and **markdown import/export** in `package:rich_text`.

For product planning and waves, see [ROADMAP.md](ROADMAP.md). For fork-level caret/EOT behavior, see [appflowy-editor-roadmap.md](appflowy-editor-roadmap.md) § “Slote fork: caret height at EOT & sup/sub layout”.

---

## 1. Mental model

| Piece | Role |
|--------|------|
| **Document** | Still AppFlowy **Document JSON**; extra keys live on text inserts’ `attributes`. |
| **Slote-only keys** | `slote_superscript` and `slote_subscript` (see [`slote_inline_attributes.dart`](../lib/src/appflowy/slote_inline_attributes.dart)). Value is **`true`** when on, **absent** / cleared when off. The two are **mutually exclusive**; if both appear, **superscript wins**. |
| **Typing style** | AppFlowy merges **paragraph slice attributes** with **`EditorState.toggledStyle`** on each insert. Slote registers its keys on `AppFlowyRichTextKeys.supportToggled` / `supportSliced` so IME/debug paths accept them. |
| **Rendering** | Not plain `TextStyle.baselineShift` (unreliable in the Flutter version this was built against). Slote uses **`WidgetSpan`** + **`PlaceholderAlignment.aboveBaseline` / `belowBaseline`** + scaled font + padding. |
| **Caret** | **`EditorStyle.caretMetrics`** (`sloteCaretMetrics`) aligns the caret with script-sized text; **`endOfParagraphCaretHeight` / `endOfParagraphCaretMetrics`** fix tall/small cursors at paragraph end when the next insertion might be body vs script. |

---

## 2. Attribute keys & registration

Constants: `kSloteSuperscriptAttribute` (`'slote_superscript'`), `kSloteSubscriptAttribute` (`'slote_subscript'`).

**`ensureSloteAppFlowyRichTextKeysRegistered()`** adds those keys to AppFlowy’s internal allow-lists once (idempotent). Without this, debug builds can assert when `toggledStyle` contains unknown keys. It is invoked from the toggle helpers, `RichTextEditorController`, and should run before editing if you construct `EditorState` yourself.

---

## 3. Toggles and continued typing

**APIs:** `sloteToggleSuperscript` / `sloteToggleSubscript` in [`appflowy_editor_support.dart`](../lib/src/appflowy/appflowy_editor_support.dart).

Behavior (summary):

- **Collapsed caret:** `toggleAttribute` plus explicit **`updateToggledStyle`** on the **opposite** script (`false` while the active one is on, `null` when turning off) so sub/sup stay exclusive and the slice does not keep stale flags.
- **Range selection:** `formatDelta` sets or clears the attribute on the range, clears the opposite key, then **collapses the selection to the end** so the following keystrokes inherit the script from the delta slice (same idea as a word processor “end of formatted run”).

**`RichTextEditorController`** ([`appflowy_document_controller.dart`](../lib/src/appflowy/appflowy_document_controller.dart)) runs **`_syncCaretSupSubTypingStyle`** on selection changes: after AppFlowy clears `toggledStyle` post-transaction, it restores superscript/subscript from **`delta.sliceAttributes`** at the caret (preferring the **character after** the caret for a collapsed position). It avoids `toggleAttribute` in that path so a stray `false` does not strip script on the next character (see comments in-file).

Toolbar “active” state uses **`sloteIsFormatKeyActive`** with the same mutual-exclusion rules as rendering ([`slote_format_toolbar_state.dart`](../lib/src/appflowy/slote_format_toolbar_state.dart)).

---

## 4. Rendering (`sloteTextSpanDecoratorForAttribute`)

Defined in [`slote_text_span_decorator.dart`](../lib/src/appflowy/slote_text_span_decorator.dart). This is the value passed to **`EditorStyle.textSpanDecorator`** (see example below).

- **Plain script (no link):** one **`WidgetSpan` per UTF-16 code unit**, each wrapping a single-character `Text` widget. That keeps **selection offsets** aligned with layout (one placeholder per index).
- **Script + link:** one **`WidgetSpan`** for the whole run with the same link gesture behavior (tap vs long-press). **Trade-off:** the editor may not place a per-character caret inside a multi-character **link+script** run the way it does for plain script.
- **Typography:** [`SloteSupSubMetrics`](../lib/src/appflowy/slote_sup_sub_metrics.dart) supplies **font scale** (~0.7×) and **vertical translation** in logical px (respects **`TextScaler`**). OpenType superscript/subscript **font features are intentionally disabled** so positioning stays consistent with the scaled, shifted glyphs.

---

## 5. Caret metrics

- **General positions:** [`slote_caret_metrics.dart`](../lib/src/appflowy/slote_caret_metrics.dart) — script-sized caret height, padding, and **y** nudges tuned for sup vs sub and for toggled vs slice state.
- **End of paragraph:** [`slote_end_of_paragraph_caret_height.dart`](../lib/src/appflowy/slote_end_of_paragraph_caret_height.dart) — coordinates with **`EditorState.toggledStyle`** and paragraph tail attributes so the EOT caret height matches **what the next typed character will be** (body vs superscript vs subscript).

Unit coverage: `slote_caret_metrics_test.dart`, `slote_sup_sub_metrics_test.dart`, `appflowy_editor_support_test.dart`.

---

## 6. Markdown interchange

In [`slote_markdown_codec.dart`](../lib/src/appflowy/slote_markdown_codec.dart):

- **Export:** text runs serialize as  
  `<sup slote_superscript="true">…</sup>` / `<sub slote_subscript="true">…</sub>` (HTML-shaped segments that survive AppFlowy’s markdown pipeline).
- **Import:** `sloteMarkdownToDocument` — relies on AppFlowy’s markdown decoder understanding HTML-ish tags; custom inline handling is aligned with the same attribute names.

---

## 7. Wiring in an app (example + main app)

**[`SloteRichTextEditorScaffold`](../lib/src/ui/slote_rich_text_editor_scaffold.dart)** applies the same `EditorStyle` hooks for both the **[example](../example)** screen and the main app’s **[`create_note.dart`](../../../lib/src/views/create_note.dart)** (path `package:rich_text`). The example also shows the pattern explicitly:

```dart
final editorStyle =
    (useDesktopChrome ? EditorStyle.desktop() : EditorStyle.mobile())
        .copyWith(
  textSpanDecorator: sloteTextSpanDecoratorForAttribute,
  caretMetrics: sloteCaretMetrics,
  endOfParagraphCaretHeight: sloteEndOfParagraphCaretHeight,
  endOfParagraphCaretMetrics: sloteEndOfParagraphCaretMetrics,
);
```

Reference: [`example/lib/editor/rich_text_editor_screen.dart`](../example/lib/editor/rich_text_editor_screen.dart) (thin wrapper around the scaffold).

Use **`standardCommandShortcutsWithSloteInlineHandlers`** (or your own) so keyboard shortcuts hit the same toggle APIs as the toolbar.

---

## 8. Known limitations

1. **No nested script** — You cannot stack superscript on superscript, subscript on subscript, or mix sup inside sub in the model/UI.
2. **Link + script** — Multi-character hyperlink runs with script use **one** `WidgetSpan`; fine-grained caret behavior may differ from **plain** script runs (by design).
3. **Residual edge cases** — Mixed line layouts, platform IMEs, and placeholder merging can still surface minor glitches; fork hooks above exist specifically to mitigate the worst caret-height issues at EOT.

---

_This document reflects the `components/rich_text` implementation; behavior depends on the vendored [`components/appflowy_editor`](../../appflowy_editor) revision in the repo._
