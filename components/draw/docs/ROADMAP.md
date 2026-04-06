# Draw — end-to-end roadmap (`components/draw`)

This document is the **canonical plan** for Slote’s drawing subsystem: stroke model, rendering, gestures, erasure, coordinate alignment with the note editor, and **undo/redo** for ink (**separate** from AppFlowy `EditorState` history — see [Undo/redo (ink vs editor)](#undoredo-ink-vs-editor)).

**Boundary with rich text:** Ink lives in **`components/draw`**; the note body stays **AppFlowy Document JSON** in [`package:rich_text`](../../rich_text/docs/ROADMAP.md). Product composition (editor + drawing chrome) is a **note-screen** concern — today [`lib/src/views/create_note.dart`](../../../lib/src/views/create_note.dart) owns `DrawController`, `SloteDrawScaffold`, and persistence of `drawingData` on the note model.

---

## Direction

| Topic | Decision |
| ----- | -------- |
| **Rendering primitive** | **[`perfect_freehand`](https://pub.dev/packages/perfect_freehand)** — pure function from sampled points `[x, y, pressure]` to outline polygon vertices. **Do not** build on **high-level drawing packages** that own their own notifier/widget stack: that pattern fights **pixel erasure**, **coordinate transforms**, and **custom gesture routing**; you end up overriding more than you reuse. |
| **Gesture layer** | **`Listener`** / low-level **pointer** events — track **active pointer count** for **stroke capture**. The parent **viewport** (see below) also uses **`Listener`** for pan, pinch, and scroll — the two layers must agree on who owns motion when (**drawing on** vs **navigating**). Read **`PointerDownEvent.pressure`** / **`pressureMax`** where available. Avoid competing **`GestureDetector`** recognizers on the same pointers. |
| **Coordinates** | Store strokes in **document space**. On paint and hit-test, apply the live **`Matrix4`** from the viewport (**`onTransformChanged`** on [`ZoomPanSurface`](../../viewport/lib/src/zoom_pan/zoom_pan_surface.dart), or an equivalent single source of truth) so zoom/pan/scroll **never** mutate stored geometry. |
| **Pressure sensitivity toggle** | At sample time: if enabled, use device pressure; if disabled, use a **constant** pressure (e.g. `0.5`) so width stays uniform — **no** duplicate stroke types in the model. |
| **Draw-and-hold → straight line** | **Speed + dwell** in document space ([`StraightLineHoldConfig`](../lib/src/stroke/straight_line_snap.dart)): while instantaneous speed stays below a cap and the finger remains inside a **hold radius** around the dwell anchor, a **700ms** contiguous timer runs. When it completes, **lock** a two-point segment **first touch → finger at lock time**; **live preview appears only then** and **does not move** until pointer up. **Commit** uses the **same two points** as the preview (uniform ink for that stroke). A **poll timer** advances dwell when the finger is still (no `PointerMove`). |
| **Erasure** | **First:** **stroke erasure** — hit-test stroke bounds (or tighter geometry later) and **remove whole** `Stroke` objects. **Later (optional):** **pixel erasure** — split point lists along the eraser path, or move to raster / **`BlendMode.clear`** if needed for performance. |
| **Pan / zoom / scroll** | **Slote-standard surface:** **[`package:viewport`](../../viewport)** — **`ViewportSurface`** / **`ZoomPanSurface`** — for pinch zoom, **1-finger pan** (when not in drawing-navigation mode), **wheel / trackpad** scroll, boundary clamping, and **`TransformAwareScrollbar`**. **`InteractiveViewer`** is a useful mental model only; **do not** assume it is the long-term note shell. Product wiring is **[Wave G](#wave-g--note-shell-viewport--editor--ink)**. |
| **Transform source of truth** | Authoritative **`Matrix4`** for the note document subtree: **`ZoomPanSurface.onTransformChanged`**. Scrollbar drags apply via **`ZoomPanController.applyTransform`** (same matrix after **`BoundaryManager`**). Draw consumes this matrix for paint and screen ↔ document mapping — **not** a second unsynchronized `TransformationController` unless you deliberately bridge them. |
| **Package layout** | **`lib/`** — public API via [`draw.dart`](../lib/draw.dart) (`DrawController`, `SloteDrawScaffold`, tools, …). **`example/`** — isolated dev loop. Root app depends on **`package:draw`** via path ([`pubspec.yaml`](../../../pubspec.yaml)). **`package:viewport`** is also a path dependency in root **`pubspec.yaml`**; the **note screen** composes both when integrating Wave G (draw stays **viewport-agnostic** if it only accepts **`Matrix4` + flags**). |

### Layer stack (product)

**Target (Wave G):** outer **[`ZoomPanSurface`](../../viewport/lib/src/zoom_pan/zoom_pan_surface.dart)** / **`ViewportSurface`** owns **`Listener`** (pan, pinch, wheel, trackpad), **`Matrix4`**, clip, and scrollbars. **Inside** the single **`Transform`**, child order is effectively:

1. **Editor** — `AppFlowyEditor` / document defines **logical extent** and block layout in **document space** (scroll ownership must be decided — see **double-scroll** note under [Viewport package](#viewport-package-componentsviewport)).
2. **DrawingLayer** — `CustomPaint` (or stack overlay) in the **same** transformed coordinate space as the editor; ink samples stored in **document space**.
3. **Stroke capture** — pointer routing for draw (1-finger stroke, pressure) **coordinated** with viewport flags **`isDrawingMode`** / **`isDrawingActive`** so pan/pinch/scroll and ink do not fight ([`gesture_handler.dart`](../../viewport/lib/src/zoom_pan/gesture_handler.dart)).

### Viewport package (`components/viewport`)

Slote’s zoom/pan/scroll implementation — **not yet** wrapped around the note editor + ink in [`create_note.dart`](../../../lib/src/views/create_note.dart); use **[`components/viewport/example`](../../viewport/example/lib/main.dart)** as the runnable reference.

| Piece | Role for draw / note shell |
| ----- | -------------------------- |
| **`ZoomPanSurface`** | Owns **`Matrix4 _transform`**, applies it with **`Transform`** around measured content. Top-level **`Listener`** for pointer pan, **2-finger pinch**, **`PointerSignalEvent`** (wheel), trackpad **`PointerPanZoomUpdate`**. **`onTransformChanged(Matrix4)`** — feed this into **`DrawCanvas`** / painter for screen ↔ document mapping. |
| **`isDrawingMode` / `isDrawingActive`** | When **`isDrawingMode`** is false, **1-finger drag pans** the surface. When true, that pan arm does not start on pointer down — room for **1-finger draw**. When **`isDrawingActive`** is true, **2-finger zoom** is suppressed so pinch does not fight an in-progress stroke. Wire these from the note UI + **`SloteDrawScaffold`** / stroke lifecycle ([`slote_draw_scaffold.dart`](../lib/src/ui/slote_draw_scaffold.dart) already tracks local drawing activity — must be **connected** to the viewport in Wave G). |
| **`ZoomPanController` + `TransformAwareScrollbar`** | Scrollbar position stays consistent with transform. |
| **`BoundaryManager` + `ContentMeasurer` / `contentHeight`** | Constrain pan/zoom; content extent must match **editor + ink** height when editor and drawing share one transformed subtree. |

**Risk (document explicitly):** AppFlowy’s **internal scroll** vs viewport **transform scroll** can **double-apply** motion if both are active on the same content. Wave G must pick **one owner** for “canvas” motion (usually the viewport wrapping a single document subtree) and document the choice.

```mermaid
flowchart TB
  subgraph noteScreen [NoteScreen target Wave G]
    zps[ZoomPanSurface_Listener]
    transform[Matrix4_onTransformChanged]
    subgraph content [Transformed subtree]
      editor[AppFlowyEditor_docSpace]
      drawLayer[DrawingLayer_CustomPaint]
    end
    strokeListen[Stroke_pointer_router]
    zps --> content
    transform -.->|inject| drawLayer
    strokeListen -.->|isDrawingActive_isDrawingMode| zps
  end
```

### Development workflow

- **Path dependency:** Root [`pubspec.yaml`](../../../pubspec.yaml) lists `draw` with `path: components/draw`. The main app imports **`package:draw`**; edits under `components/draw/lib/` apply on the next analyze, run, or hot restart.
- **Where to run:** Use **`components/draw/example`** for a fast isolated loop; use the **root Slote app** for product flows ([`create_note.dart`](../../../lib/src/views/create_note.dart): drawing toggle, `drawingData` persistence).

---

## Current status (rolling)

| Item | State |
| ---- | ----- |
| **Stroke rendering** | [`StrokeRenderer`](../lib/src/stroke/stroke_renderer.dart) uses **`perfect_freehand`** **`getStroke`** (filled paths). Pen / highlighter only; eraser does not add visible strokes — **Wave D** removes ink via [`eraseStrokesHitByEraserPath`](../lib/src/draw_controller.dart), [`stroke_hit_geometry`](../lib/src/stroke/stroke_hit_geometry.dart), and **D2** split [`stroke_eraser_split`](../lib/src/stroke/stroke_eraser_split.dart). |
| **Stroke model** | [`Stroke`](../lib/src/stroke/stroke.dart): immutable **`StrokeSample`** (`x`, `y`, optional `pressure`), **`pressureEnabled`**; [`DrawController`](../lib/src/draw_controller.dart): **`schemaVersion`** in JSON, legacy `points` decode. |
| **Undo / redo (ink)** | **Wave E** — snapshot stacks on [`DrawController`](../lib/src/draw_controller.dart) (`undo` / `redo`, **`undoRedoListenable`**, **`beginInkUndoGroup`** / **`endInkUndoGroup`** for batched eraser drags); undo/redo buttons in [`SloteDrawScaffold`](../lib/src/ui/slote_draw_scaffold.dart). History is **not** persisted in JSON. |
| **Gestures** | [`DrawCanvas`](../lib/src/draw_canvas.dart): **`Listener`** + **pointer-count** router (**Wave B**): ink only when **`activePointers == 1`**; a second pointer **discards** the in-progress stroke (no commit / no undo step; see Wave B). |
| **Wave B — Gesture router** | **Complete** — same as phased [Wave B](#wave-b--gesture-router-1-draw--2-pan); [`slote_draw_scaffold.dart`](../lib/src/ui/slote_draw_scaffold.dart) **`isDrawingActive`** from **`onStrokeCaptureActiveChanged`**. |
| **Wave A foundation** | **Complete** — `perfect_freehand`, document-space samples + **`Matrix4`**, [`StrokeRenderer`](../lib/src/stroke/stroke_renderer.dart) **`getStroke`**. |
| **Wave C — Pen UX** | **Complete** — pressure **`Switch`** in [`SloteDrawScaffold`](../lib/src/ui/slote_draw_scaffold.dart); straight line via **speed + dwell** (**700 ms** contiguous, **~140 px/s** max speed, **28 px** hold radius, doc space) in [`straight_line_snap.dart`](../lib/src/stroke/straight_line_snap.dart) + [`draw_canvas.dart`](../lib/src/draw_canvas.dart); fixed chord preview after lock; **`StrokeRenderer`** for preview and commit. |
| **Wave D — Stroke eraser** | **Complete** — polyline distance + fixed disc ([`kDefaultEraserDiameterDoc`](../lib/src/stroke/stroke_hit_geometry.dart)); **D2** splits strokes along the eraser footprint ([`stroke_eraser_split.dart`](../lib/src/stroke/stroke_eraser_split.dart)); **`fromJson`** drops legacy eraser entries. |
| **Wave E — Ink undo/redo** | **Complete** — snapshots + eraser gesture grouping ([`draw_controller.dart`](../lib/src/draw_controller.dart), [`draw_canvas.dart`](../lib/src/draw_canvas.dart)); scaffold **`undoRedoListenable`** UI ([`slote_draw_scaffold.dart`](../lib/src/ui/slote_draw_scaffold.dart)); tests in [`draw_ink_undo_test.dart`](../test/draw_ink_undo_test.dart). |
| **Wave F — Integration hooks + JSON** | **Complete** — [`create_note.dart`](../../../lib/src/views/create_note.dart) passes **`documentTransform`** (identity until G) and optional **`onStrokeCaptureActiveChanged`** for viewport **`isDrawingActive`**; [`SloteDrawScaffold`](../lib/src/ui/slote_draw_scaffold.dart) bubbles that callback; [`draw_controller.dart`](../lib/src/draw_controller.dart) **`fromJson`** reads **`schemaVersion`** with forward-compatible default branch; tests in [`stroke_json_test.dart`](../test/stroke_json_test.dart). |
| **Wave G — Viewport + editor + ink** | **In progress** — [`create_note.dart`](../../../lib/src/views/create_note.dart) composes editor + ink under one [`ViewportSurface`](../../viewport/lib/src/viewport/viewport_surface.dart) transform, pipes `onTransformChanged(Matrix4)` into `DrawCanvas.documentTransform`, and wires viewport flags `isDrawingMode` / `isDrawingActive`. Content extent is currently a placeholder constant; measure real document height for tight boundary clamping. |
| **Editor alignment** | **Overlay** — ink renders over the editor (no fixed-height footer). Both sit under the same viewport transform in [`create_note.dart`](../../../lib/src/views/create_note.dart). |
| **Viewport in product** | **Shipped (Wave G)** — [`create_note.dart`](../../../lib/src/views/create_note.dart) imports **`package:viewport`** and mounts `ViewportSurface` for zoom/pan/scroll. |
| **Persistence** | **`Note.drawingData`** JSON via `DrawController.toJson` / `fromJson` in [`create_note.dart`](../../../lib/src/views/create_note.dart); **`schemaVersion: 1`** for new saves; **`fromJson`** honors optional **`schemaVersion`** (defaults to 1, unknown versions best-effort decode); legacy **`points`** strokes and stripping saved **`eraser`** tool strokes remain in [`Stroke.fromJson`](../lib/src/stroke/stroke.dart) / controller. |

## Next (Slote-focused)

1. **Wave G:** End-to-end **viewport + editor + ink** in `create_note` (see table below).
2. **Optional later:** note-level unified undo (chronological typing + ink) — not **Wave E**; requires orchestrator or stroke-in-document model (see [Undo/redo (ink vs editor)](#undoredo-ink-vs-editor)).

---

## Phased delivery (waves)

Waves build on each other. After each major wave, run **`components/draw/example`**, **`flutter test`** under `components/draw`, and the **root app** when persistence or `create_note` integration changes.

### Wave A — Foundation (`perfect_freehand` + document space)

| Step | Scope |
| ---- | ----- |
| **A1 — Dependency** | Add **`perfect_freehand`** to [`pubspec.yaml`](../pubspec.yaml). |
| **A2 — Sample model** | Stroke samples as `(x, y, pressure)` (or library `PointVector` equivalent) + metadata: color, base size, **pressure enabled** flag. Migrate JSON **carefully** (version field or tolerant decode) because [`create_note`](../../../lib/src/views/create_note.dart) already persists strokes. |
| **A3 — Document space + transform** | API for the parent to supply **`Matrix4`** — primary hook: **`ZoomPanSurface.onTransformChanged`** (see [Viewport package](#viewport-package-componentsviewport)). **Store** points in **untransformed** document space; **transform only for painting** (and screen → document hit-testing). |
| **A4 — Render path** | Replace or wrap [`StrokeRenderer`](../lib/src/stroke/stroke_renderer.dart) to build outlines via **`getStroke`** (filled path from polygon), including **`simulatePressure`** when useful for devices without stylus. |

**Status: complete** (A1–A4 implemented in [`pubspec.yaml`](../pubspec.yaml), [`stroke.dart`](../lib/src/stroke/stroke.dart), [`draw_controller.dart`](../lib/src/draw_controller.dart), [`draw_canvas.dart`](../lib/src/draw_canvas.dart), [`stroke_renderer.dart`](../lib/src/stroke/stroke_renderer.dart)).

### Wave B — Gesture router (1 draw / 2 pan)

| Step | Scope |
| ---- | ----- |
| **B1 — Pointer counting** | On down/up/cancel, maintain **`activePointers`**. On move: **only** continue stroke when **`activePointers == 1`**. |
| **B2 — Parent contract** | **Second finger mid-stroke:** **`PointerDown`** when **`activePointers` becomes 2** while a stroke is in progress → **discard** the in-progress stroke (no commit, no undo), clear capture, **`onStrokeCaptureActiveChanged(false)`** so **`isDrawingActive`** is false and [`ZoomPanSurface`](../../viewport/lib/src/zoom_pan/zoom_pan_surface.dart) may apply **2-finger pinch** (`pointerCount == 2 && !isDrawingActive`). **`PointerCancel`** on the drawing pointer → **discard** in-progress ink (no commit). Aligns with [`gesture_handler.dart`](../../viewport/lib/src/zoom_pan/gesture_handler.dart) pointer counting. |
| **B3 — Pressure at source** | Pipe **`PointerEvent.pressure`** into the sample stream when pressure mode is on. |

**Status: complete** — [`DrawCanvas`](../lib/src/draw_canvas.dart) (`Listener`, **`onStrokeCaptureActiveChanged`**); [`SloteDrawScaffold`](../lib/src/ui/slote_draw_scaffold.dart) wires **`isDrawingActive`** from that callback.

### Wave C — Pen UX

| Feature | Notes |
| ------- | ----- |
| **Pressure toggle** | UI + controller: when off, pass **constant** pressure into `perfect_freehand` inputs. |
| **Straight line (draw-and-hold)** | **Speed + dwell** + hold-radius; **700 ms** contiguous; lock fixed **start→end** at lock time; preview only after lock; commit identical to preview. |
| **Live preview** | Freehand polyline until straight lock; after lock, **fixed** two-point chord (same as commit). |

**Status: complete** — [`SloteDrawScaffold`](../lib/src/ui/slote_draw_scaffold.dart) pressure toggle; [`straight_line_snap.dart`](../lib/src/stroke/straight_line_snap.dart) (`StraightLineHoldTracker`) + [`draw_canvas.dart`](../lib/src/draw_canvas.dart) (`Timer` poll for stationary hold).

### Wave D — Erasure

| Slice | Notes |
| ----- | ----- |
| **D1 — Stroke eraser** | Eraser path in doc space + fixed disc; hit-test distance from disc centers to **stroke polyline** (aligned with rendered ink width). Live erase on drag; **`fromJson`** strips legacy eraser tool entries. |
| **D2 — Vector / “pixel” eraser** | Split stroke centerlines along the discrete eraser-disc union (same footprint as hit-test); optional future: denser eraser sampling or raster **`BlendMode.clear`** if needed. |

**Status: complete** — [`stroke_hit_geometry.dart`](../lib/src/stroke/stroke_hit_geometry.dart) (`eraserReachForStroke`, `pointInsideEraserFootprint`, `strokeHitByEraserPath`), [`stroke_eraser_split.dart`](../lib/src/stroke/stroke_eraser_split.dart) (`splitStrokeByEraserPath`), [`draw_controller.dart`](../lib/src/draw_controller.dart) (`eraseStrokesHitByEraserPath`, [`EraserMode`](../lib/src/eraser_mode.dart) **stroke** vs **pixel**), [`slote_draw_scaffold.dart`](../lib/src/ui/slote_draw_scaffold.dart) (erase mode segmented control when eraser is selected), [`draw_canvas.dart`](../lib/src/draw_canvas.dart) (eraser path + preview). Drawing JSON includes optional **`eraserMode`** for persistence.

### Wave E — Undo / redo (ink)

| Item | Notes |
| ---- | ----- |
| **E1 — Draw-local history** | **Undo** / **redo** for **committed** ink operations (strokes; erasures if modeled as mutations). Implementation options: **command list** or **snapshots** of the stroke list — choose by tolerance for memory vs simplicity. |
| **E2 — UI hooks** | Expose something like **`Listenable`** for can-undo / can-redo (mirror the ergonomics of **`RichTextEditorController.undoRedoListenable`** in [`package:rich_text`](../../rich_text/lib/src/appflowy/appflowy_document_controller.dart)) so [`SloteDrawScaffold`](../lib/src/ui/slote_draw_scaffold.dart) or the app bar can enable/disable buttons. |
| **E3 — Non-goal** | Do **not** assume ink can call **`EditorState.undoManager.undo()`** without either **embedding** strokes in the document transaction model or a **note-level orchestrator** (see below). |

**Status: complete** — [`draw_controller.dart`](../lib/src/draw_controller.dart) (snapshot undo/redo, optional **`maxUndoLevels`**, **`undoRedoListenable`**); [`draw_canvas.dart`](../lib/src/draw_canvas.dart) (eraser **`beginInkUndoGroup`** / **`endInkUndoGroup`** pairing); [`slote_draw_scaffold.dart`](../lib/src/ui/slote_draw_scaffold.dart) (undo/redo **`IconButton`**s); [`draw_ink_undo_test.dart`](../test/draw_ink_undo_test.dart).

### Wave F — Integration & persistence

| Item | Notes |
| ---- | ----- |
| **F1 — Transform parity** | With Wave G: drawing layer and editor sit under the **same** **`ZoomPanSurface`** **`Transform`**; ink uses the same **`Matrix4`** as blocks. |
| **F2 — JSON / migration** | Evolve `DrawController.toJson` / `fromJson` with the new stroke sample shape; keep **backward compatibility** for existing `drawingData` in the wild. |
| **F3 — Product wiring** | [`create_note.dart`](../../../lib/src/views/create_note.dart) already wires **`DrawController`**, **`SloteDrawScaffold`**, and **`drawingData`** — extend for transform injection and viewport flags (ink undo/redo ships in **`SloteDrawScaffold`** from Wave E; app bar mirroring is optional). |

**Status: complete (F2, F3)** — [`draw_controller.dart`](../lib/src/draw_controller.dart) (version-aware **`fromJson`**, doc policy); [`slote_draw_scaffold.dart`](../lib/src/ui/slote_draw_scaffold.dart) (**`onStrokeCaptureActiveChanged`** for parents); [`create_note.dart`](../../../lib/src/views/create_note.dart) (**`documentTransform`** + capture callback); [`stroke_json_test.dart`](../test/stroke_json_test.dart).

**F1 — Transform parity:** **API ready** — ink already consumes **`documentTransform`** on [`DrawCanvas`](../lib/src/draw_canvas.dart). **Same live `Matrix4` as the editor** under one **`ZoomPanSurface`** **`Transform`** ships in **Wave G** (see [Wave G](#wave-g--note-shell-viewport--editor--ink)).

### Wave G — Note shell: viewport + editor + ink

End-to-end integration of **zooming, panning, and scrolling** with the note page. **`draw`** can stay **viewport-agnostic** (`Matrix4` + booleans); [`create_note.dart`](../../../lib/src/views/create_note.dart) (or an extracted shell widget) owns composition.

| Step | Scope |
| ---- | ----- |
| **G1 — Compose** | Wrap **one** transformed subtree in **`ViewportSurface`** / **`ZoomPanSurface`**: **AppFlowy editor + drawing overlay** share the same **`Transform`** (single document coordinate space). |
| **G2 — Transform pipe** | Subscribe to **`onTransformChanged`**; pass **`Matrix4`** into `DrawController` / `DrawCanvas` / `StrokeRenderer` for paint and pointer mapping. |
| **G3 — Flags** | Wire **`isDrawingMode`** ↔ note “drawing on/off”; wire **`isDrawingActive`** ↔ stroke-in-progress from draw so **2-finger pinch** does not fight ink (see viewport source). |
| **G4 — Scroll ownership** | Decide **one** owner for vertical motion: viewport wheel/trackpad (`_applyScrollDelta` in `zoom_pan_surface.dart`) vs editor-internal scroll — avoid **double scroll**. Document the choice in code comments. |
| **G5 — Content extent** | Align **`ContentMeasurer` / `contentHeight`** (and **`BoundaryManager`**) with **real document height** (editor + ink). |
| **G6 — QA** | Run **`components/viewport/example`**, **`components/draw/example`**, root app, and **`flutter test`** after shell changes. |

_When verifying Wave G, re-read [`zoom_pan_surface.dart`](../../viewport/lib/src/zoom_pan/zoom_pan_surface.dart) for the exact **`isDrawingMode` / `isDrawingActive`** / pointer-count behavior._

---

## Undo/redo (ink vs editor)

### Rich text (AppFlowy) — unchanged

- Note body undo/redo is **`EditorState.undoManager`** — see [`appflowy_undo_support.dart`](../../rich_text/lib/src/appflowy/appflowy_undo_support.dart) and **[Undo/redo (AppFlowy)](../../rich_text/docs/ROADMAP.md#undoredo-appflowy)** in the rich_text roadmap.
- That stack only understands **document transactions**. It does **not** automatically include **freehand strokes** stored alongside the note.

### In `package:draw`

- **Ink history** lives in **`DrawController`** (snapshot stacks; eraser drags batched via **`beginInkUndoGroup`** / **`endInkUndoGroup`**). The removed standalone **`components/undo_redo`** package is **not** required; reintroducing a generic package is optional only if multiple subsystems need the same abstraction.
- **Erasure** during a pointer gesture is **one** undo step; **`addStroke`**, **`clear`**, and standalone **`eraseStrokesHitByEraserPath`** each record history when not inside a group.

### Rest of repo / product

- **Two independent stacks today:** text history (AppFlowy) and drawing (**Wave E** ink undo in `draw`).
- **Future (optional):** a **note-level facade** could merge **chronological** undo (one Cmd+Z ordering across typing and ink). That is **explicitly deferred** until product requires it — it is **not** “wiring drawing into AppFlowy undo” without either **stroke-as-document-embed** or a coordinator.

---

## Repo touchpoints

| Area | Path |
| ---- | ---- |
| Package exports | [`lib/draw.dart`](../lib/draw.dart) |
| Controller + JSON | [`lib/src/draw_controller.dart`](../lib/src/draw_controller.dart) |
| Canvas / paint | [`lib/src/draw_canvas.dart`](../lib/src/draw_canvas.dart), [`lib/src/stroke/stroke_renderer.dart`](../lib/src/stroke/stroke_renderer.dart) |
| Example (isolated dev) | [`example/`](../example) |
| Main app note + ink | [`lib/src/views/create_note.dart`](../../../lib/src/views/create_note.dart) |
| Zoom/pan/scroll (component) | [`components/viewport/lib/viewport.dart`](../../viewport/lib/viewport.dart), [`zoom_pan_surface.dart`](../../viewport/lib/src/zoom_pan/zoom_pan_surface.dart) |
| Viewport demo | [`components/viewport/example/lib/main.dart`](../../viewport/example/lib/main.dart) |
| Rich text boundary | [`components/rich_text/docs/ROADMAP.md`](../../rich_text/docs/ROADMAP.md) (e.g. Wave F — draw / ink) |

---

## Related Slote docs

- **[`components/rich_text/docs/ROADMAP.md`](../../rich_text/docs/ROADMAP.md)** — editor stack, AppFlowy undo/redo, draw/ink boundary.
- **[`components/viewport/example/README.md`](../../viewport/example/README.md)** — viewport demo app (package root has no README yet).
- **[`PRD.md`](../../../PRD.md)** — product scope and component inventory.
- **[`README.md`](../README.md)** — package overview (link to this file).

---

_Roadmap versions with the product; prefer this file for engineering planning for ink._
