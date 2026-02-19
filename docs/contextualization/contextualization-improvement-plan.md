# Contextualization Improvement Plan

**Date:** 2026-02-19
**Status:** Draft
**Related Jira:** SVQS-186 (Contextualization Improvement)

---

## Customer Priorities

The following were identified as the top contextualization priorities:

1. **P&ID Contextualization pipeline** — Link P&ID diagrams to assets and time series so users can click equipment on a P&ID and see linked sensors/data
2. **PI Tag contextualization to SAP Hierarchy (deeper FLOCs)** — Link PI time series to specific equipment in the SAP FLOC hierarchy, not just Paper Machine 1/2
3. **Material Costs and Purchasing Costs** — Link cost events (PPV) to materials and assets for cost analysis and variance tracking

---

## Current State

### What's Connected Today

From an **Asset**, you can currently see:

| Related Data | Relation | Direction | Status |
|---|---|---|---|
| Time Series | MfgTimeSeries.assets → Asset | Reverse | PM-level only |
| Reels | Reel.asset → Asset | Reverse | Working |
| Events (WO, PPV) | Event.asset → Asset | Reverse | Partial (FLOC-dependent) |
| Files (P&IDs) | MfgFile.assets → Asset | Reverse | Working |
| Quality Reports | RollQuality.asset → Asset | Reverse | Working |
| Children | Asset.parent → Asset | Reverse | Full hierarchy |

### What's Missing

| Connection | Fields Exist? | Data Available? | Status |
|---|---|---|---|
| Asset → Rolls | Roll.asset exists, no reverse on Asset | Yes | **Gap** |
| Event → Reel/Roll | Fields defined, never populated | Likely | **Gap** |
| CostEvent → Material | Field defined, writes NULL | Yes (materialCode) | **Gap** |
| CostEvent → Asset | Field defined, writes NULL | Yes (plantCode) | **Gap** |
| ProductionOrder → Asset | Field defined, writes NULL | Likely (FLOC) | **Gap** |
| ProductionOrder → Reel | Field defined, writes NULL | Likely (Proficy) | **Gap** |
| ProductionEvent → Asset/Reel | Fields defined, write NULL | Likely (Proficy) | **Gap** |
| Package → Roll/Asset | No relations defined | Unknown | **Gap** |
| Material → Asset | No relation defined | Possible | **Gap** |
| TS → Equipment (deep) | Aliases misaligned | Yes (PI tags + FLOCs) | **Shallow** |

---

## Priority 1: P&ID Contextualization Pipeline

> **Goal:** Users click equipment on a P&ID and see linked sensors/time series. Search a tag name and find the P&ID it appears on.

### P1.1 Verify P&ID annotation pipeline is running

**What:** The `cdf_p_and_id_parser` module is selected in `config.dev.yaml`. It includes the `ctx_files_pandid_annotater` extraction pipeline that scans P&ID files for asset/time series references and creates annotations.

**Check:**
- Is the P&ID annotator pipeline running and producing annotations?
- How many P&ID files have been annotated? (3,952 files exist in MfgFile)
- Are annotations linking to the correct asset/TS nodes?

**Effort:** 2 hours (investigation + fixes) | **Impact:** Very High

### P1.2 Activate connection writer for P&ID → Asset/TS links

**What:** The `cdf_common` module contains a `contextualization_connection_writer` function that converts P&ID annotations into direct relations (File.assets). This is referenced in the `cdf_ingestion` workflow but `cdf_common` is selected in `config.dev.yaml`.

**Check:**
- Is the connection writer running after annotations are created?
- Are File.assets relations being written?
- Does MfgFile.assets show linked assets when you open a P&ID?

**Change (if not working):** Ensure the connection writer function is deployed, triggered after annotation, and writes to the correct view/space.

**Effort:** 4 hours | **Impact:** Very High

### P1.3 Enrich P&ID search experience

**What:** After P1.1 and P1.2, P&IDs should be linked to assets and time series. To complete the experience:
- From an Asset, see linked P&IDs (already exists via `files` reverse relation)
- From a Time Series, see the P&ID it appears on (may need a reverse relation or search config update)

**Change:** Add SearchConfig enhancements if needed so users can search P&IDs by equipment name or tag.

**Effort:** 2 hours | **Impact:** High

---

## Priority 2: PI Tag → SAP Hierarchy (Deeper FLOCs)

> **Goal:** PI time series linked to specific equipment (pumps, drives, valves), not just Paper Machine 1/2.

### P2.1 Fix Time Series alias gap (no-hyphens)

**What:** PI tag aliases keep hyphens (`471-PT-101`) but asset aliases strip spaces (`471PT101`). The ML entity matcher can't find exact matches at equipment level.

**Change:** Add a "no hyphens" alias variant in `generate_TimeSeries_Aliases.Transformation.sql`:

```sql
-- Alias 6: Tag prefix without hyphens (match asset sortField without spaces)
upper(replace(regexp_extract(substring(externalId, 4), '^([^.]+)', 1), '-', ''))
```

**Result:** Entity matching can now match PI tags to specific equipment assets.

**Effort:** 1 hour | **Impact:** High

### P2.2 Add equipment-level entity matching rules

**What:** Current 10 rules only match area prefixes (`^(471)` → `^(471)`). They never reach equipment level.

**Change:** Add rules with full tag patterns in `contextualization_rule_input.RawRows.ndjson`:

```json
{"key": 11, "columns": {"AssetRegExp": "^(\\d{3}[A-Z]{2,}\\d+)", "EntityRegExp": "^(\\d{3}[A-Z]{2,}\\d+)", "description": "Full tag pattern -> equipment sortField (e.g. 471PT101)"}}
```

**Result:** Rule-based matching targets specific equipment, not just areas.

**Effort:** 2 hours | **Impact:** High

### P2.3 Bulk manual mapping generation (PI tag → Equipment FLOC)

**What:** The highest-impact item. Use PI tag metadata + FLOC data to programmatically generate PI tag → equipment FLOC mappings.

**Change:** Build a script/transformation that:
1. Reads PI tag metadata (tag names, prefixes) and asset FLOCs (sortField, equipmentNumber)
2. Generates candidate mappings by normalizing both sides and matching
3. Loads results into `contextualization_manual_input` RAW table

**Result:** Hundreds/thousands of time series linked to specific equipment, not just paper machines.

**Effort:** 8 hours | **Impact:** Very High

### P2.4 Run EntityMatching and validate depth

**What:** After P2.1–P2.3, run the EntityMatching workflow and measure equipment-level linkage using the validation app (T4.9 metric).

**Target:** ≥50% of time series linked to equipment-level (or deeper) assets.

**Effort:** 2 hours | **Impact:** Validation

---

## Priority 3: Material Costs and Purchasing Costs

> **Goal:** Cost events (PPV) linked to materials and assets for cost analysis and variance tracking.

### P3.1 CostEvent → Material

**What:** CostEvent has `materialCode` in the raw data and a `material` relation field defined in the view. The transformation currently writes NULL.

**Change:** In `populate_CostEvent.Transformation.sql` (mfg_extended) and `populate_Event_CostEvents.Transformation.sql` (mfg_core), match `materialCode` to Material nodes:

```sql
CASE
    WHEN materialCode IS NOT NULL AND trim(materialCode) != ''
    THEN node_reference('sylvamo_mfg_core_instances', concat('material:', materialCode))
    ELSE NULL
END as material
```

**Result:** Cost/PPV analysis can navigate from cost events to the specific material.

**Effort:** 2 hours | **Impact:** High

### P3.2 CostEvent → Asset

**What:** CostEvent has `plantCode` in raw data. Can link to plant-level asset at minimum, or to a more specific area if the raw data includes FLOC or area information.

**Change:** Map `plantCode` to asset FLOC in the CostEvent transformation:

```sql
CASE
    WHEN plantCode IS NOT NULL AND plantCode LIKE '0769%'
    THEN node_reference('sylvamo_mfg_core_instances', concat('floc:', plantCode))
    ELSE NULL
END as asset
```

**Result:** Cost events linked to the plant/area where the cost was incurred.

**Effort:** 1 hour | **Impact:** Medium

### P3.3 Material → CostEvent reverse relation

**What:** After P3.1, add a reverse relation on Material so that from a Material you can see all cost events (PPV entries) associated with it.

**Change:** Add `costEvents` reverse relation in the Material view or ensure the data model exposes this navigation path.

**Result:** From a material, see all purchasing cost variances.

**Effort:** 2 hours | **Impact:** High

---

## Additional Improvements (Lower Priority)

### A.1 Add `rolls` reverse relation on Asset view

**What:** Asset view has reverse relations for reels, events, timeSeries, files, qualityReports, children — but NOT rolls. Roll already has a forward `asset` relation.

**Change:** Add `rolls` reverse relation in `Asset.View.yaml` pointing through `MfgRoll.asset`.

**Result:** From any asset in CDF Search, see all rolls produced there.

**Effort:** 1 hour | **Impact:** High

### A.2 Populate Event.reel and Event.roll

**What:** The Event view defines `reel` and `roll` relation fields, but no transformation writes them.

**Change:** Update `populate_Event_*.Transformation.sql` files to map reel/roll identifiers from the raw data.

**Result:** Navigate from events directly to the reel/roll they relate to.

**Effort:** 4 hours | **Impact:** Medium

### A.3 ProductionOrder/ProductionEvent → Asset + Reel

**What:** Both transformations write NULL for `asset` and `reel`. Raw Proficy data likely has FLOC and reel references.

**Change:** Map Proficy source fields to asset and reel node references.

**Result:** Full production traceability.

**Effort:** 4 hours | **Impact:** Medium

### A.4 Package → Roll links

**What:** Package is currently isolated. If raw data has roll numbers per package, create the link.

**Change:** Add `rolls` relation to Package view and populate via transformation.

**Result:** Order fulfillment traceability: Package → Roll → Reel → Asset.

**Effort:** 4 hours | **Impact:** Medium

### A.5 WorkOrder ↔ Event cross-linking

**What:** From an Asset, see all maintenance work orders and their history.

**Change:** Add reverse relation on Asset view for WorkOrder events.

**Result:** Full maintenance history from any asset.

**Effort:** 2 hours | **Impact:** Medium

---

## Execution Order

| Order | Item | Priority | Effort | Impact | Dependencies |
|-------|------|----------|--------|--------|-------------|
| 1 | P1.1 Verify P&ID annotation pipeline | P&ID | 2h | Very High | None |
| 2 | P1.2 Activate connection writer | P&ID | 4h | Very High | P1.1 |
| 3 | P2.1 TS alias fix (no-hyphens) | PI→FLOC | 1h | High | None |
| 4 | P2.2 Equipment-level matching rules | PI→FLOC | 2h | High | P2.1 |
| 5 | P3.1 CostEvent → Material | Costs | 2h | High | None |
| 6 | P3.2 CostEvent → Asset | Costs | 1h | High | None |
| 7 | P3.3 Material → CostEvent reverse | Costs | 2h | High | P3.1 |
| 8 | P2.3 Bulk TS → Equipment mappings | PI→FLOC | 8h | Very High | P2.1, P2.2 |
| 9 | P1.3 P&ID search experience | P&ID | 2h | High | P1.2 |
| 10 | P2.4 Validate depth (T4.9) | PI→FLOC | 2h | Validation | P2.3 |
| 11 | A.1 Asset.rolls reverse relation | Additional | 1h | High | None |
| 12 | A.2–A.5 Remaining improvements | Additional | 14h | Medium | Various |

**Total estimated effort:** ~41 hours

---

## Success Criteria

After all phases, navigating from each entity should show:

| From | You Should See |
|------|---------------|
| **Asset** | Time series (equipment-level), reels, **rolls**, events, files, quality reports, work orders, children |
| **Reel** | Rolls (via Roll.reel), events, asset, production orders |
| **Roll** | Reel, asset, events, quality results, **packages** |
| **Event** | Asset, **reel**, **roll** (where applicable) |
| **Time Series** | **Equipment-level** asset (not just paper machine) |
| **Package** | **Rolls** it contains |
| **CostEvent** | **Material**, **asset** |
| **Material** | Cost events (reverse), **asset** |

Items in **bold** are new connections this plan would create.

---

## Validation

Use the existing validation app (`sylvamo/tests/validation_app/`) to measure progress:

- **T4.9:** % of time series linked to equipment-level assets (target: ≥50%)
- **New metric:** % of events with reel/roll populated
- **New metric:** % of cost events with material linked
- **New metric:** % of work order events with asset linked

See also: [Equipment- and Sensor-Level Contextualization](equipment-and-sensor-level-contextualization.md) for testing methodology.
