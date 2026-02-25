# Contextualization Improvement Plan

**Date:** 2026-02-19 (updated 2026-02-24)
**Status:** Active
**Related Jira:** SVQS-186 (Contextualization Improvement)

This document is the **strategy and source-of-truth** for contextualization. Ticket-level execution detail lives in [SPRINT_3_TICKET_CONSOLIDATION.md](SPRINT_3_TICKET_CONSOLIDATION.md).

---

## Customer Priorities (from PM)

These are the top 3 priorities, quoted directly from the project manager:

> 1. **P&ID Contextualization pipeline** — Need all P&IDs contextualized with: Equipment No. to SAP asset, file-to-file (P&ID continuations), and PI tag contextualization if possible — otherwise time series with assets.
> 2. **PI Tags to deeper FLOC** — By entity matching in some way (like name of tag with name of asset, or other rules).
> 3. **Material and purchasing costs** — Data associated here needs to be contextualized. Variable, but review data and give a first try of contextualization to tie everything together.

---

## Current Status (Sprint 3)

Sprint 3 has 16 contextualization-labeled tickets grouped into workstreams. See [SPRINT_3_TICKET_CONSOLIDATION.md](SPRINT_3_TICKET_CONSOLIDATION.md) for the full analysis (curated mapping, gaps, recommendations).

| Workstream | Primary Tickets | Maps to PM Priority |
|------------|-----------------|----------------------|
| **A: Foundation / Aliases** | SVQS-263, SVQS-282 | P&ID, PI→FLOC |
| **B: Time Series / Virtual Tags** | SVQS-282, SVQS-235, SVQS-219 | PI Tags to deeper FLOC |
| **C: File Annotation / P&ID Refinement** | SVQS-263, SVQS-234, SVQS-280, SVQS-233, SVQS-231 | P&ID Contextualization |
| **D: Equipment** | SVQS-258 | Optional (Phase 4) |
| **E: Metrics / Reporting** | SVQS-264 | Cross-cutting |
| **Other: Entity Matching** | SVQS-174, SVQS-173, SVQS-138 | Material and purchasing costs |

---

## Current State

### What's Connected Today

From an **Asset**, you can currently see:

| Related Data | Relation | Direction | Status |
|---|---|---|---|
| Time Series | MfgTimeSeries.assets → Asset | Reverse | **PM-level only** (all 3,468 PI tags → PM1 or PM2) |
| Reels | Reel.asset → Asset | Reverse | Working |
| Events (WO, PPV) | Event.asset → Asset | Reverse | Partial (FLOC-dependent) |
| Files (P&IDs) | MfgFile.assets → Asset | Reverse | Working |
| Quality Reports | RollQuality.asset → Asset | Reverse | Working |
| Children | Asset.parent → Asset | Reverse | Full hierarchy |

### Data Validation Findings (2026-02-19)

- **3,468 PI time series** — ALL linked to Paper Machine level only (PM1 or PM2). Zero at equipment level.
- **PI tags have NO hyphens and NO dots** — format is `pi:471MR610`, not `pi:471-PT-101.PV` as previously assumed.
- **97% of PI tags are scanner profile measurements** (BW, CP, MR, MS, SBW, BWSP, etc.) — map to section-level FLOCs.
- **~78 tags (~2%) are process instruments** (FC, HC, DW, WIND, FI, LI) — can potentially reach equipment level.
- **PI tag names and SAP sort_fields use different naming conventions** — no string normalization will match them.
- **PI tag descriptions ARE rich** — 100% have descriptions like "Reel Moisture Profile POS 325", "Size Press Basis Weight Profile POS 136".
- **Entity matching tables are empty** — no rules, no manual mappings in `db_entity_matching`.
- **`pi_tag_prefix_floc_mapping` table exists** with area-level mappings (471→PM1, 472→PM2) for 12 PI prefixes.

### What's Missing

| Connection | Status |
|---|---|
| TS → Equipment (deep) | **Shallow (PM-level only)** |
| P&ID → Asset (Eq No.) | **Pipeline TBD** |
| P&ID → P&ID (continuations) | **Gap** |
| P&ID → Time Series (PI tags) | **Gap** |
| CostEvent → Material | **Gap** |
| CostEvent → Asset | **Gap** |
| Asset → Rolls | **Gap** |
| Event → Reel/Roll | **Gap** |

---

## Open Gaps (Darren Guidance, No Ticket)

Items from Feb 19, 23, 24 conversations with Darren that have no Sprint 3 ticket coverage:

| Phase | Item | Description | Priority |
|-------|------|-------------|----------|
| phase1 | 1.6 | Use equipment record for equipment table (serial, model, manufacturer) | important |
| phase1 | 1.8 | Handle duplicate sort fields; isolation for cross-site deduplication | important |
| phase1 | 1.10 | Clean up asset hierarchy presentation | nice-to-have |
| crosscutting | 5.2 | Present missing-tags info before end of quick start | important |
| crosscutting | 5.3 | Frame: I detected X tags, you had Y in source | important |
| crosscutting | 5.4 | Offer options: load missing tags or create virtual tags | important |
| crosscutting | 5.8 | Communicate virtual-tag approach to Sylvamo | important |
| crosscutting | 5.9 | Pull in Jack Zho when pipeline deployed for config help | nice-to-have |

---

## Action Plan (Now / Next / Later)

### Now (Sprint 3 focus)

- **SVQS-282** — Virtual instrumentation tags (Phase 2)
- **SVQS-263** — File annotation pipeline on all documents (Phase 1, 3)
- **SVQS-235, SVQS-219** — Time series to deeper FLOCs; categorize PI tags (Phase 2)
- **SVQS-234** — Refine P&ID asset tag matching (Phase 3)
- **SVQS-258** — Evaluate equipment table (Phase 4)
- **SVQS-264** — Before/after contextualization metrics (cross-cutting)
- **SVQS-173, SVQS-174** — Purchasing/production contextualization (Priority 3)

### Next

- **SVQS-280, SVQS-233** — Files to Assets (SOPs, non-P&IDs) — clarify approach vs execution
- **SVQS-231** — File-to-file linking within P&IDs
- Address gaps 1.6, 1.8, 5.2–5.4, 5.8 (sub-tasks or new tickets)

### Later

- **SVQS-136** — Consider closing (superseded)
- **SVQS-138** — Clarify scope or merge into SVQS-174
- Gap 1.10 (asset hierarchy presentation) — defer
- Gap 5.9 (Jack Zho) — operational note

---

## Success Criteria

### P&ID (Priority 1)

- [ ] P&ID files annotated with equipment numbers, PI tags, and continuation refs
- [ ] Clicking equipment number on P&ID navigates to SAP asset
- [ ] Clicking PI tag on P&ID navigates to time series live data
- [ ] P&ID continuation sheets are linked (file-to-file)
- [ ] Search by equipment name or PI tag returns relevant P&IDs

### PI → Deeper FLOC (Priority 2)

- [ ] ≥90% of PI time series linked to section-level or deeper (target ~100% with virtual tags)
- [ ] Process instruments (~78 tags) linked to equipment-level where possible
- [ ] Virtual tags created from TS names; recontextualization complete

### Material & Costs (Priority 3)

- [ ] CostEvent → Material relation populated
- [ ] CostEvent → Asset relation populated (at least plant/area level)
- [ ] Material → CostEvent reverse navigation works
- [ ] Production orders and purchasing data contextualized (SVQS-174, SVQS-173)

### Navigation from Each Entity

| From | You Should See |
|------|---------------|
| **Asset** | Time series (section-level), reels, rolls, events, **P&IDs with Eq No.**, quality reports, work orders, children |
| **P&ID** | **Linked assets (Eq No.)**, **linked time series (PI tags)**, **continuation P&IDs** |
| **Time Series** | **Section-level asset** (Reel, Size Press, Dryer, etc. — not just PM1/PM2) |
| **CostEvent** | **Material**, **asset** |
| **Material** | **Cost events**, **consuming assets (via BOM)** |

Items in **bold** are new connections this plan creates.

---

## References

- [SPRINT_3_TICKET_CONSOLIDATION.md](SPRINT_3_TICKET_CONSOLIDATION.md) — Ticket-level analysis, workstreams, gaps, recommendations
- [PR_992_SVQS_282_VIRTUAL_INSTRUMENTATION_TAGS.md](PR_992_SVQS_282_VIRTUAL_INSTRUMENTATION_TAGS.md) — PR #992 explanation for Max: populate_TimeSeries, array_union fix, pipeline
- Darren transcript summaries (Feb 19, 23, 24) — Ground truth for gaps and priorities; see `docs/contextualization/` in sylvamo repo
