# Draw + AppFlowy integration roadmap (`components/draw`)

This document is the canonical delivery plan for Slote drawing/ink: engine choice, gesture ownership, data model, and integration with AppFlowy notes.

---

## Direction

| Topic | Decision |
|-------|----------|
| **Architecture** | **Hybrid**: keep Slote viewport/coordinate model, use a drawing library for stroke capture/render/erase. |
| **Drawing model (near term)** | **Global document-space canvas** overlay aligned to note viewport. |
| **Drawing model (later)** | Add **per-block anchors** tied to AppFlowy node IDs when required. |
| **Primary candidate** | [`draw_your_image`](https://pub.dev/packages/draw_your_image) for pressure-aware points, customizable painting, and pixel erase path. |
| **Secondary candidate** | [`scribble`](https://pub.dev/packages/scribble) for mature serialization and line-centric erasing. |
| **AppFlowy role** | AppFlowy remains rich-text/document host; drawing is persisted alongside document JSON. |

---

## Current status (rolling)

| Item | State |
|------|-------|
| **Draw package** | Present in repo as separate component with custom canvas/tooling baseline. |
| **AppFlowy integration** | Rich text is active in `components/rich_text`; draw-to-editor mapping is not yet productized. |
| **Decision status** | Chosen direction: hybrid stack, global-first mapping, library-first for ink engine. |

---

## Phased delivery (high level)

Phases are incremental and intended to ship behind flags where practical.

### Wave A — Spike and library validation

| Step | Scope |
|------|-------|
| **A1 — Candidate spike (`draw_your_image`)** | Run inside current viewport shell and validate pressure input, stroke eraser, pixel eraser, undo/redo, serialization, and PNG/export viability. |
| **A2 — Candidate fallback (`scribble`)** | Validate same matrix to keep a safe fallback if primary candidate fails on gesture or erase semantics. |
| **A3 — Decision gate** | Pick engine based on feature parity, stability, and integration complexity; document tradeoffs in this file. |

### Wave B — Gesture arbitration and interaction modes

| Feature | Notes |
|---------|-------|
| **Single interaction router** | One owner for pointer routing between draw, pan/zoom, and text modes. |
| **Gesture policy** | `1 pointer + draw mode => draw`, `2+ pointers => pan/zoom`, `text mode => editor scroll/selection`. |
| **Conflict handling** | Avoid scattered recognizers; centralize pointer ownership to reduce gesture arena races. |
| **Device policy** | Support stylus-priority option and optional finger-draw mode; touch can remain pan-first by default. |

### Wave C — Data model and persistence

| Feature | Notes |
|---------|-------|
| **DrawingDocument v1** | Versioned payload with strokes, points, pressure, tool metadata, and viewport transform snapshot. |
| **Coordinate contract** | Persist in document/world coordinates so redraw remains stable under zoom and pan changes. |
| **Persistence** | Save/load drawing payload alongside AppFlowy document JSON at note boundary (DB/storage layer). |
| **Round-trip checks** | Verify deterministic restore across app relaunch and device form factors. |

### Wave D — AppFlowy overlay integration (global-first)

| Feature | Notes |
|---------|-------|
| **Overlay composition** | Render drawing canvas in note editor scene with explicit z-order policy. |
| **Mode-aware UX** | In draw mode, prioritize ink interactions; in text mode, avoid accidental stroke input. |
| **Toolbar/actions** | Pen, highlighter, stroke eraser, pixel eraser, clear, undo/redo, pressure toggle. |
| **Export/import hooks** | Keep draw payload in note serialization path with migration-safe schema versioning. |

### Wave E — Precision UX and advanced tools

| Feature | Notes |
|---------|-------|
| **Draw-and-hold straight line** | Snap current stroke preview to line after hold threshold; commit on release. |
| **Pressure toggle** | Runtime toggle with consistent behavior across stylus/touch input classes. |
| **Palm rejection hardening** | Improve stylus + touch coexistence, especially tablet devices. |
| **Selection/move primitives** | Add optional stroke selection and transform tools if required by product scope. |

### Wave F — Per-block anchoring and document semantics

| Feature | Notes |
|---------|-------|
| **Anchor model** | Optional `anchorNodeId` linkage from drawing groups/strokes to AppFlowy blocks. |
| **Block lifecycle behavior** | Define move/delete semantics for anchored drawings (move-with-block vs orphan/soft-delete). |
| **Migration path** | Support transition from global-only drawings to mixed global + anchored data. |
| **Editor commands** | Optional “insert drawing block” / “convert selection to anchored drawing” flows. |

### Wave G — Quality, performance, release

| Area | Notes |
|------|-------|
| **Performance** | Validate 60fps target in representative notes; profile large stroke sets and eraser operations. |
| **Testing** | Unit (schema, transforms, eraser hit-tests), widget (gesture routing), integration (AppFlowy + draw round-trip). |
| **Platforms** | Validate on iOS/Android touch + stylus first; desktop/web parity where relevant. |
| **Rollout** | Feature flag, staged rollout, telemetry for crashes/latency/gesture failure rates. |

---

## Decision checklist (before integration into main note screen)

- [ ] Library engine selected after Wave A comparison
- [ ] Gesture conflict matrix passes (1-finger draw / 2-finger pan)
- [ ] Pressure + dual eraser behavior verified on real devices
- [ ] Drawing payload schema versioned and persisted with notes
- [ ] Global overlay integrated with AppFlowy editor screen
- [ ] Performance and crash baseline captured before rollout

---

## Repo touchpoints

| Area | Path |
|------|------|
| Draw component root | [`components/draw/`](.) |
| Rich-text integration area | [`components/rich_text/`](../rich_text) |
| Rich-text canonical roadmap (style reference) | [`components/rich_text/docs/ROADMAP.md`](../rich_text/docs/ROADMAP.md) |
| App storage integration (main app) | [`lib/src/services/`](../../lib/src/services) |

---

_Roadmap versions with product decisions; update this document whenever architecture or phase boundaries change._
