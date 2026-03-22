# AppFlowy Editor integration roadmap (rich_text)

This document records the divide-and-conquer plan for integrating [appflowy_editor](https://pub.dev/packages/appflowy_editor) in `components/rich_text`. It supersedes ad-hoc notes for phases, deferred work, and repo touchpoints.

**Canonical direction:** Prefer **AppFlowy Document JSON** as the eventual source of truth for pixel-perfect round-trip. Use Markdown or Delta only for migration when needed ([importing.md](https://raw.githubusercontent.com/AppFlowy-IO/appflowy-editor/main/documentation/importing.md)).

---

## Execution model (divide and conquer)

- **Phase 1:** Work alone on AppFlowy JSON (load, edit, export, debug). No bulk assistant implementation until Phase 1 is done.
- **Phases 2–4:** Implement incrementally with review; after each phase, run the example app and tests before the next.

---

## Phase 1 — AppFlowy JSON (solo)

- Use `components/rich_text/example` (or a scratch screen): `EditorState(document: Document.fromJson(...))`, then serialize back after edits.
- Goals:
  - Confidence in JSON shape and undo behavior.
  - Understand what changes in the document on each keystroke (deltas in nodes).
  - Validate that edits persist correctly through a load/save round-trip.

---

## Phase 2 — BIUS toolbar

- Build a **fixed** row (e.g. under the editor) or reuse **MobileFloatingToolbar** / desktop patterns from `appflowy_editor`. The package provides **building blocks**; you **compose** the screen ([pub.dev overview](https://pub.dev/packages/appflowy_editor)).
- Toolbar scope: four actions only — **Bold**, **Italic**, **Underline**, **Strikethrough** (BIUS).
- Note: `AppFlowyEditor` alone does not ship a complete toolbar; expect to wire UI to editor APIs yourself (same idea as floating-toolbar examples in the package).

---

## Phase 3 — Controller + listener + debounce

- Single owner of `EditorState` (e.g. `RichTextController` or equivalent).
- Subscribe to `editorState.transactionStream` (or the equivalent change signal), **debounce** (~200 ms), then emit canonical Document JSON (string or `Map`) for persistence, preview, or logging.
- `dispose()`: cancel the subscription and dispose `EditorState` cleanly.

### Data flow (Phases 3–4)

```mermaid
flowchart LR
  subgraph phase3 [Phase 3]
    ES[EditorState]
    TS[transactionStream]
    DB[debounce]
    OUT[onDocumentJsonChanged]
    ES --> TS --> DB --> OUT
  end
  subgraph phase4 [Phase 4]
    TB[BIUS toolbar]
    SC[characterShortcutEvents]
    TB --> ES
    SC --> ES
  end
```

---

## Phase 4 — BIUS via shortcuts + parity with toolbar

- Use [Customizing Editor Features — shortcut event](https://github.com/AppFlowy-IO/appflowy-editor/blob/main/documentation/customizing.md#customizing-a-shortcut-event) as reference: `CharacterShortcutEvent`, injected via `AppFlowyEditor.custom` / `characterShortcutEvents`, and format commands as needed.
- Pub.dev examples also cover **BIUS** shortcuts ([appflowy_editor](https://pub.dev/packages/appflowy_editor)).
- **Selection:** formatting applies to the current selection; with a **collapsed** caret, behavior should match the editor (e.g. format applies to the **next** typed run).
- **Parity:** toolbar buttons and shortcuts must call the **same** formatting entry points on `EditorState`.

---

## Future roadmap (out of current scope)

Implement later; no requirement in the initial AppFlowy pass.

1. **Block components** — tables, checklist, numbered/bullet lists, quote, code blocks, etc. (extend `blockComponentBuilders` / custom blocks per AppFlowy docs).
2. **Encryption / decryption** — logic lives in another component; integrate at the app boundary with the debounced JSON payload, not inside `rich_text` core.
3. **Draw / ink** — separate component/folder; integrate with document or overlay per broader architecture notes.
4. **Theming** — `appflowy_editor` uses `EditorStyle` / `BlockComponentConfiguration` ([customizing.md — theme](https://github.com/AppFlowy-IO/appflowy-editor/blob/main/documentation/customizing.md#customizing-a-theme)); bridge to Slote `components` theme so Material/app theme and editor styling stay consistent (bridge layer TBD).

---

## Repo touchpoints (when implementing)

| Area | Path |
|------|------|
| Dependency | [`pubspec.yaml`](../pubspec.yaml) — add `appflowy_editor` if the editor lives in `lib/`, not only the example. |
| Public API | [`lib/rich_text.dart`](../lib/rich_text.dart) — export controller/widget when added. |
| Spike / evolution | [`example/lib/main.dart`](../example/lib/main.dart) — evolve through phases. |

---

## Phase checklist (tracking)

Use this list to track progress locally (e.g. in PRs or issues).

- [ ] **Phase 1 (solo):** JSON round-trip, delta inspection, persistence validation in the example app.
- [ ] **Phase 2:** Minimal BIUS toolbar wired to editor APIs.
- [ ] **Phase 3:** Controller + `transactionStream` + debounced JSON callback + clean dispose.
- [ ] **Phase 4:** BIUS shortcuts/commands aligned with toolbar behavior.
- [ ] **Deferred:** Future roadmap items only after the above are stable.
