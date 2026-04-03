# Context Mesh memory (Slote)

## Where it lives

- **Path:** `.context/memory/` (under the repo root).
- **Key files:** `decisions.json` (explicit notes/decisions from `remember` or hand-curated entries), plus optional `tasks.json`, `preferences.json`, `patterns.json`, `sessions.ndjson` when [Context Mesh hooks](https://github.com/contextmesh) are used (e.g. Claude Code).

## Git / sharing policy

- **Default:** the whole `.context/` directory is listed in `.gitignore` (Context Mesh template). That keeps indexes and machine-local memory **out of git**.
- **Rationale:** auto-build rows in `decisions.json` refresh on `context-mesh build`; ignoring avoids noisy commits. Teammates still get fresh seeds when they run build locally.
- **If you want shared team memory:** remove or narrow `.gitignore` for `.context/memory/` only (keep `.context/index.json` ignored if you prefer), or copy important rows into tracked docs (e.g. this file or `components/rich_text/docs/`).

## Quality practices

- Prefer **short, actionable** lines; tag with **module + topic** (e.g. `rich_text`, `appflowy_editor`, `caret`, `integration`) so `recall(query)` ranks them well.
- Long explanations stay in **tracked markdown** (ROADMAP, design docs); memory holds **durable facts** and decisions you want surfaced by search.

## Auto-build vs human entries

- Rows with `"source": "auto-build"` come from the indexer after build. Context Mesh **`recall` deprioritizes** them relative to human/curated rows when both match the same query, so your notes surface first.
