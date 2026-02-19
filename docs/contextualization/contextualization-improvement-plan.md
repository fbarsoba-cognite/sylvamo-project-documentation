# Contextualization Improvement Plan

**Date:** 2026-02-19 (updated 2026-02-19)
**Status:** Active
**Related Jira:** SVQS-186 (Contextualization Improvement)

---

## Customer Priorities (from PM)

These are the top 3 priorities, quoted directly from the project manager:

> 1. **P&ID Contextualization pipeline** — Need all P&IDs contextualized with: Equipment No. to SAP asset, file-to-file (P&ID continuations), and PI tag contextualization if possible — otherwise time series with assets.
> 2. **PI Tags to deeper FLOC** — By entity matching in some way (like name of tag with name of asset, or other rules).
> 3. **Material and purchasing costs** — Data associated here needs to be contextualized. Variable, but review data and give a first try of contextualization to tie everything together.

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

Analysis of the actual PI tag and asset data revealed:

- **3,468 PI time series** — ALL linked to Paper Machine level only (PM1 or PM2). Zero at equipment level.
- **PI tags have NO hyphens and NO dots** — format is `pi:471MR610`, not `pi:471-PT-101.PV` as previously assumed.
- **97% of PI tags are scanner profile measurements** (BW, CP, MR, MS, SBW, BWSP, etc.) — positional readings across the paper web. They naturally belong to scanner/QCS section-level FLOCs, not individual equipment.
- **~78 tags (~2%) are process instruments** (FC, HC, DW, WIND, FI, LI) — these can potentially be mapped to equipment-level FLOCs.
- **PI tag names and SAP sort_fields use different naming conventions** — `471MR610` (PI) vs `471005082`/`47100L327` (SAP). No string normalization will make them match.
- **PI tag descriptions ARE rich** — 100% have descriptions like "Reel Moisture Profile POS 325", "Size Press Basis Weight Profile POS 136", "E1 Winder - Front Drum Load".
- **FLOC descriptions share vocabulary** — REEL (28 FLOCs), SIZE PRESS (19), DRYER (103), WINDER (32), CALENDER (10) in PM1 alone.
- **Entity matching tables are empty** — no rules, no manual mappings, no confirmed matches currently in `db_entity_matching`.
- **`pi_tag_prefix_floc_mapping` table exists** with area-level mappings (471→PM1, 472→PM2) for 12 PI prefixes.

### What's Missing

| Connection | Fields Exist? | Data Available? | Status |
|---|---|---|---|
| TS → Equipment (deep) | Aliases exist but misaligned | Descriptions are the key | **Shallow (PM-level only)** |
| P&ID → Asset (Eq. No.) | File.assets defined | P&IDs have equipment numbers | **Pipeline TBD** |
| P&ID → P&ID (continuations) | No relation defined | P&IDs reference each other | **Gap** |
| P&ID → Time Series (PI tags) | No direct relation | P&IDs show PI tag names | **Gap** |
| CostEvent → Material | Field defined, writes NULL | Yes (materialCode) | **Gap** |
| CostEvent → Asset | Field defined, writes NULL | Yes (plantCode) | **Gap** |
| Asset → Rolls | Roll.asset exists, no reverse on Asset | Yes | **Gap** |
| Event → Reel/Roll | Fields defined, never populated | Likely | **Gap** |

---

## Priority 1: P&ID Contextualization Pipeline

> **PM requirement:** Need all P&IDs contextualized with: Eq No. to SAP asset, file-to-file (P&ID continuations), and PI tag contextualization if possible.

### P1.1 Verify P&ID annotation pipeline is running

**What:** The `cdf_p_and_id_parser` module is deployed in `config.dev.yaml`. It includes the `ctx_files_pandid_annotater` extraction pipeline that scans P&ID files for asset/TS references and creates annotations.

**Check:**
- Is the P&ID annotator pipeline running and producing annotations?
- How many of the 3,952 P&ID files have been annotated?
- Are annotations detecting equipment numbers, PI tag names, and P&ID continuation references?

**Effort:** 2 hours | **Impact:** Very High

### P1.2 Activate connection writer for P&ID → Asset links (Eq No.)

**What:** The `cdf_common` module contains a `contextualization_connection_writer` that converts P&ID annotations into direct relations. Equipment numbers detected on P&IDs should be matched to SAP asset nodes.

**Deliverable:** When opening a P&ID in CDF, clicking an equipment number navigates to the SAP asset. From an asset, the "Files" tab shows all P&IDs where it appears.

**Change (if not working):** Ensure the connection writer:
- Reads equipment number annotations from P&IDs
- Matches them to asset nodes (via sort_field, equipment_number, or FLOC)
- Writes MfgFile.assets relations

**Effort:** 4 hours | **Impact:** Very High

### P1.3 P&ID → P&ID continuations (file-to-file)

**What:** P&IDs reference other P&ID sheets ("continued on sheet X", "see drawing Y"). These should be linked so users can navigate between related P&IDs.

**Change:**
- Parse continuation references from P&ID annotations
- Create file-to-file relations (may need a new relation property on MfgFile or use annotations)
- Ensure the UI can navigate between continuation sheets

**Effort:** 6 hours | **Impact:** High

### P1.4 PI tag contextualization on P&IDs

**What:** P&IDs show PI tag names (like `471MR610`). When the annotator detects these, they should be linked to the corresponding MfgTimeSeries nodes.

**Check:** Does the annotator already detect PI tag names? If so:
- Match detected tag names to MfgTimeSeries external IDs (`pi:` + tag name)
- Write the annotation link to the time series node

**Result:** From a P&ID, users can click a PI tag and navigate to its live data.

**Effort:** 4 hours | **Impact:** Very High

### P1.5 Enrich P&ID search experience

**What:** After P1.1–P1.4, verify the end-to-end experience:
- Search an equipment name → find the P&ID it appears on
- Search a PI tag → find the P&ID showing that tag
- From a P&ID → see linked assets, time series, and continuation sheets

**Effort:** 2 hours | **Impact:** High

---

## Priority 2: PI Tags to Deeper FLOC (Entity Matching)

> **PM requirement:** By entity matching — like name of tag with name of asset, or other rules.

### Data Reality

Based on validation, the viable matching approach is **description-based**, not alias/name-based:

| PI Tag | Description | Matchable To |
|---|---|---|
| `471MR325` | "Reel Moisture Profile POS 325" | REEL SYSTEMS, #1 P/M (`010-090`) |
| `471BWSP136` | "Size Press Basis Weight Profile POS 136" | Size press section |
| `472DW001` | "E2 Winder - Front Drum Load" | WINDER section (`020-095`) |
| `471HC001` | "Calender Queen Roll Crown Adjust" | CALENDER section |

97% of tags are scanner profiles that map to 2-3 section-level FLOCs. The ~78 process tags can potentially reach equipment level.

### P2.1 Build keyword-based section mapping

**What:** Map PI tags to section-level FLOCs using equipment keywords in their descriptions. This is the highest-ROI step — it moves 3,400+ tags from PM-level to section-level.

**Change:** Create a new transformation or update `populate_TimeSeries.Transformation.sql` to use description keywords:

```sql
CASE
    WHEN description LIKE '%Reel%' AND externalId LIKE 'pi:471%'
    THEN node_reference('sylvamo_mfg_core_instances', 'floc:0769-06-01-010-090')
    WHEN description LIKE '%Size Press%' AND externalId LIKE 'pi:471%'
    THEN node_reference('sylvamo_mfg_core_instances', 'floc:0769-06-01-010-???')
    -- ... more keyword rules per PM
END
```

**Result:** Time series linked to paper machine sections (Reel, Size Press, Dryer, Calender, Winder) instead of just PM1/PM2.

**Effort:** 4 hours | **Impact:** High (moves 97% of TS one level deeper)

### P2.2 Description-based entity matching for process tags

**What:** For the ~78 process instrument tags (FC, HC, DW, WIND, FI, LI), use CDF Entity Matching ML to match PI tag descriptions against FLOC descriptions.

**Change:**
- Configure CDF Entity Matching sources: PI process tags (name + description) vs FLOC nodes (description)
- Constrain by area prefix (471→PM1 FLOCs, 472→PM2 FLOCs)
- Review ML-suggested matches, approve good ones
- Load approved matches into `contextualization_manual_input`

**Result:** Process instruments linked to specific equipment (pumps, drives, valves).

**Effort:** 6 hours | **Impact:** Medium (covers ~2% of tags but highest depth)

### P2.3 Populate entity matching rules and manual tables

**What:** The `db_entity_matching` tables are currently empty. Seed them with:
- Rule-based mappings (area prefix rules, keyword rules)
- Manual mappings from P2.2 review
- Validated matches from P2.1

**Effort:** 2 hours | **Impact:** High (enables the matching pipeline)

### P2.4 Run EntityMatching workflow and validate

**What:** After P2.1–P2.3, run the EntityMatching workflow and measure depth using the validation app.

**Targets:**
- ≥90% of PI time series linked to section-level or deeper (currently 0%)
- ≥50% of process instruments linked to equipment-level

**Effort:** 2 hours | **Impact:** Validation

---

## Priority 3: Material and Purchasing Costs

> **PM requirement:** Review data and give a first try of contextualization. Variable, but tie everything together.

### P3.0 Data exploration and mapping discovery

**What:** Before implementing, review the raw cost/material data to identify all available linking fields. This is exploratory.

**Check:**
- What fields exist in PPV/cost event raw data? (materialCode, plantCode, purchaseOrder, vendor, costCenter, etc.)
- What fields exist in Material raw data?
- Are there SAP tables (RESB, STPO, MAST) that provide BOM links (Material → FLOC)?
- Can purchase orders be linked to work orders or assets?

**Deliverable:** A mapping diagram showing which raw fields can link to which CDF entities.

**Effort:** 4 hours | **Impact:** Foundation for P3.1–P3.4

### P3.1 CostEvent → Material

**What:** CostEvent has `materialCode` in the raw data and a `material` relation field defined in the view. The transformation currently writes NULL.

**Change:** In `populate_Event_CostEvents.Transformation.sql`, match `materialCode` to Material nodes:

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

**What:** CostEvent has `plantCode` in raw data. May also have FLOC or cost center that maps to an asset area.

**Change:** Map available location fields to asset FLOC:

```sql
CASE
    WHEN functionalLocation IS NOT NULL AND functionalLocation LIKE '0769%'
    THEN node_reference('sylvamo_mfg_core_instances', concat('floc:', functionalLocation))
    WHEN plantCode = '0769'
    THEN node_reference('sylvamo_mfg_core_instances', 'floc:0769')
    ELSE NULL
END as asset
```

**Result:** Cost events linked to the area/asset where the cost was incurred.

**Effort:** 2 hours | **Impact:** Medium-High

### P3.3 Material → CostEvent reverse relation

**What:** After P3.1, ensure from a Material you can see all cost events (PPV entries).

**Change:** Add `costEvents` reverse relation in the Material view or ensure the navigation path exists.

**Result:** From a material, see all purchasing cost variances and history.

**Effort:** 2 hours | **Impact:** High

### P3.4 Material → Asset (via BOM)

**What:** SAP BOM tables (MAST, STPO) link materials to FLOCs. If we can use this, materials can be linked to the assets/areas that consume them.

**Change:** Build a transformation that reads BOM data and creates Material → Asset links.

**Result:** From an asset, see what materials it consumes; from a material, see which assets use it.

**Effort:** 6 hours | **Impact:** High (if BOM data is available)

---

## Additional Improvements (Lower Priority)

### A.1 Add `rolls` reverse relation on Asset view

Add `rolls` reverse relation in `Asset.View.yaml` pointing through `MfgRoll.asset`. From any asset in CDF Search, see all rolls produced there.

**Effort:** 1 hour | **Impact:** High

### A.2 Populate Event.reel and Event.roll

Update `populate_Event_*.Transformation.sql` to map reel/roll identifiers from raw data.

**Effort:** 4 hours | **Impact:** Medium

### A.3 ProductionOrder/ProductionEvent → Asset + Reel

Map Proficy source fields to asset and reel node references.

**Effort:** 4 hours | **Impact:** Medium

### A.4 Package → Roll links

Add `rolls` relation to Package view and populate via transformation.

**Effort:** 4 hours | **Impact:** Medium

### A.5 WorkOrder ↔ Event cross-linking

Add reverse relation on Asset view for WorkOrder events.

**Effort:** 2 hours | **Impact:** Medium

---

## Execution Order

| # | Item | Priority | Effort | Impact | Dependencies |
|---|------|----------|--------|--------|-------------|
| 1 | **P1.1** Verify P&ID annotation pipeline | P&ID | 2h | Very High | None |
| 2 | **P1.2** Connection writer: P&ID → Asset (Eq No.) | P&ID | 4h | Very High | P1.1 |
| 3 | **P1.3** P&ID → P&ID continuations | P&ID | 6h | High | P1.1 |
| 4 | **P1.4** PI tag contextualization on P&IDs | P&ID | 4h | Very High | P1.1 |
| 5 | **P2.1** Keyword section mapping (TS → section FLOC) | PI→FLOC | 4h | High | None |
| 6 | **P3.0** Cost data exploration | Costs | 4h | Foundation | None |
| 7 | **P3.1** CostEvent → Material | Costs | 2h | High | P3.0 |
| 8 | **P3.2** CostEvent → Asset | Costs | 2h | Medium-High | P3.0 |
| 9 | **P2.2** Description-based entity matching (process tags) | PI→FLOC | 6h | Medium | P2.1 |
| 10 | **P2.3** Seed entity matching tables | PI→FLOC | 2h | High | P2.1 |
| 11 | **P3.3** Material → CostEvent reverse | Costs | 2h | High | P3.1 |
| 12 | **P3.4** Material → Asset via BOM | Costs | 6h | High | P3.0 |
| 13 | **P1.5** P&ID search experience | P&ID | 2h | High | P1.2–P1.4 |
| 14 | **P2.4** Validate TS depth | PI→FLOC | 2h | Validation | P2.1–P2.3 |
| 15 | **A.1–A.5** Additional improvements | Extra | 15h | Medium | Various |

**Total estimated effort:** ~63 hours

---

## Success Criteria

### P&ID (Priority 1)
- [ ] P&ID files annotated with equipment numbers, PI tags, and continuation refs
- [ ] Clicking equipment number on P&ID navigates to SAP asset
- [ ] Clicking PI tag on P&ID navigates to time series live data
- [ ] P&ID continuation sheets are linked (file-to-file)
- [ ] Search by equipment name or PI tag returns relevant P&IDs

### PI → Deeper FLOC (Priority 2)
- [ ] ≥90% of PI time series linked to section-level FLOCs (Reel, Size Press, Dryer, etc.)
- [ ] Process instruments (~78 tags) linked to equipment-level where possible
- [ ] Entity matching tables populated with rules and validated matches

### Material & Costs (Priority 3)
- [ ] CostEvent → Material relation populated
- [ ] CostEvent → Asset relation populated (at least plant/area level)
- [ ] Material → CostEvent reverse navigation works
- [ ] Data mapping documented for future enhancements

### Navigation from Each Entity
| From | You Should See |
|------|---------------|
| **Asset** | Time series (section-level), reels, rolls, events, **P&IDs with Eq No.**, quality reports, work orders, children |
| **P&ID** | **Linked assets (Eq No.)**, **linked time series (PI tags)**, **continuation P&IDs** |
| **Time Series** | **Section-level asset** (Reel Systems, Size Press, etc. — not just PM1/PM2) |
| **CostEvent** | **Material**, **asset** |
| **Material** | **Cost events**, **consuming assets (via BOM)** |

Items in **bold** are new connections this plan creates.
