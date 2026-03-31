# AppFlowy Editor fork — licensing (Slote)

Slote vendors this package from **AppFlowy Editor** under the `LICENSE` in this directory. It is **dual-licensed**:

1. **GNU Affero General Public License v3** (AGPL-3.0)  
2. **Mozilla Public License v2.0** (MPL-2.0)

See [`LICENSE`](LICENSE) for the full text of both.

**This is not legal advice.** If you distribute Slote or run it as a service, confirm compliance with counsel.

## Why this fork exists

Upstream `appflowy_editor` on pub.dev does not expose every hook Slote needs (e.g. end-of-paragraph caret height via `EditorStyle.endOfParagraphCaretHeight` and logic in `AppFlowyRichText`). Local changes live in this tree; the app resolves this package via `dependency_overrides` in the root and `components/rich_text` / `components/rich_text/example` pubspecs.

## What you typically must share vs not (high level)

The obligations depend on **which license you follow** (MPL or AGPL) and **how you ship** the product (e.g. binary to users vs network-hosted editor).

### If complying under **MPL-2.0** (often used for “file-level” copyleft)

- **Usually must make available**: **source** for **Covered Software** you distribute—including **your modifications** to those files—and keep **license/copyright notices** as required (see MPL §§3.1–3.4 in [`LICENSE`](LICENSE)).
- **Usually does not automatically extend to**: unrelated proprietary code in **separate files** that is not part of the MPL-covered editor sources, provided you are not mixing/copying MPL code into those files in ways that create a larger covered work under MPL rules.

### If complying under **AGPL-3.0**

- **Stricter**, especially for **network use**: AGPL is intended so that users interacting with a **modified version over a network** can obtain **source** of that version—see the AGPL preamble discussion in [`LICENSE`](LICENSE) (network server / source availability).
- Scope can be **broader** than MPL for some deployment models.

## Practical checklist for Slote maintainers

1. Keep this directory’s [`LICENSE`](LICENSE) with the fork; do not strip required notices from edited upstream files.
2. If you publish Slote or offer it as a service, decide explicitly **MPL vs AGPL** compliance with legal review.
3. Document where recipients can obtain **source** for this fork (e.g. your repo or archive), in line with the license path you choose.

## Related docs

- Slote rich text roadmap / product notes: [`../rich_text/docs/ROADMAP.md`](../rich_text/docs/ROADMAP.md)
