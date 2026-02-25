# Virtual Instrumentation Tags — Implementation Guide

This guide explains how virtual instrumentation tags work in the Sylvamo Industrial Data Landscape and how to implement, maintain, and validate them. It is written for data engineers who may not be experts in contextualization.

**Jira:** [SVQS-261](https://cognitedata.atlassian.net/browse/SVQS-261), [SVQS-282](https://cognitedata.atlassian.net/browse/SVQS-282)  
**ADO PR:** [#992](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/992)

---

## 1. Background: What Are Virtual Tags?

### The Concept

**Virtual tags** (also called *synthetic* or *shadow* tags) are Asset nodes in CDF that represent instrumentation (sensors, transmitters, control valves) that do **not** exist in SAP. We create them from PI time series tag names so that:

1. Each time series can be linked to a discrete asset (the instrument it represents)
2. P&ID annotation can match instrumentation symbols on diagrams
3. CDF search returns the correct time series when users search for a specific instrument

### Why SAP Does Not Have This Data

SAP tracks **functional locations** (FLOCs) and **major equipment** (pumps, motors, valves). It does **not** track instrumentation — the transmitters, sensors, and control valves that generate process data. This is true across virtually all SAP-based industrial clients. Instrumentation is typically managed in PI System, DCS, or historians, not in SAP asset management.

### What Darren Downtain Recommended

Darren Downtain (SA Lead, Americas) reviewed Sylvamo's contextualization in February 2026 and recommended creating virtual tags:

> "A lot of times when you try to do time series contextualization, instruments don't exist coming from SAP because people don't track instrumentation in SAP. You literally have nothing to contextualize against. Where you can utilize missing tags from P&IDs - those give you all instrumentation tags. You generate 'virtual tags' (sometimes called shadow tags). This allows you to contextualize items within P&IDs to those virtual tags as well as time series data containing a tag value."

**Reference:** Darren review transcript (in sylvamo repo: `docs/contextualization/2026-02-19-darren-review-transcript.md`) — see section "01:02:43 - Time Series & Virtual/Synthetic Tags".

---

## 2. How It Works

### Transformation Pipeline Flow (SVQS-282)

**Assumption:** We no longer use classic time series (`_cdf.timeseries`). MfgTimeSeries is populated by an extractor, connector, or other transformation that writes directly to the data model.

```
1. populate_Asset
   Creates FLOC hierarchy from SAP (functional locations, equipment)
                    |
                    v
2. MfgTimeSeries population  (external)
   Populated by extractor/connector or RAW-based transformation — NOT from _cdf.timeseries
                    |
                    v
3. populate_VirtualInstrumentationTags  (SVQS-282)
   Creates one vtag: asset per PI time series. Source: MfgTimeSeries (cdf_nodes)
   Parent: Anvar's curated FLOC > prefix mapping > floc:0769
   All get tags: ['DetectInDiagrams'] for file annotation
                    |
                    v
4. generate_VirtualTag_Aliases  (SVQS-282)
   Populates aliases on vtag assets. Source: MfgTimeSeries (cdf_nodes)
                    |
                    v
5. recontextualize_TimeSeries  (SVQS-282)
   For Anvar's 210 curated PI tags: adds vtag to existing assets (array_union). Source: MfgTimeSeries
                    |
                    v
6. Entity Matching / Manual Mappings  (SVQS-283, etc.)
   Adds deeper FLOC links (equipment-level) via manual CSV or ML matching
   These links are PRESERVED by recontextualize_TimeSeries (array_union)
```

### The array_union fix (Max's review — PR #992)

**The problem:** Replacing the entire `assets` array with `array(vtag)` would destroy FLOC links from entity matching and manual mappings.

**The fix:** `recontextualize_TimeSeries` uses `array_union(coalesce(existing_assets, array()), array(new_refs))` to **merge** new links with existing ones instead of overwriting.

### Prefix → FLOC Mapping Table

| PI Prefix | Parent FLOC (external ID) | Description | Tag Count |
|-----------|----------------------------|-------------|-----------|
| 471* | floc:0769-06-01-010 | Paper Machine 1 | 1,725 |
| 472* | floc:0769-06-01-020 | Paper Machine 2 | 1,708 |
| 460* | floc:0769-06-01-010 | PM1 Chemical Additives | 11 |
| 461* | floc:0769-06-01-020 | PM2 Chemical Additives | 5 |
| 311* | floc:0769 | Eastover Mill root | 1 |
| 402* | floc:0769 | Eastover Mill root | 1 |
| * (fallback) | floc:0769 | Eastover Mill root | — |

### External ID Conventions

| Entity | Convention | Example |
|--------|------------|---------|
| Virtual instrument asset | `vtag:{PI_TAG_NAME}` | `vtag:471MR325` |
| Functional location asset | `floc:{SAP_FLOC}` | `floc:0769-06-01-010` |
| PI time series (CDF) | `pi:{TAG}` | `pi:471MR325` |

---

## 3. Files Changed (SVQS-282 / PR #992)

### Removed (no classic time series)

| File | Reason |
|------|--------|
| `sync_TimeSeries_from_CDF.*` | Removed — we no longer use `_cdf.timeseries` |
| `populate_TimeSeries.*` | Removed — MfgTimeSeries populated by extractor/connector; no separate asset-update step |

### New Files

| File | Purpose |
|------|---------|
| `populate_VirtualInstrumentationTags.Transformation.sql` | Creates one Asset node per PI time series. Source: MfgTimeSeries (cdf_nodes). Parent from Anvar's curated sheet > prefix mapping > floc:0769. |
| `populate_VirtualInstrumentationTags.Transformation.yaml` | Transformation config |
| `generate_VirtualTag_Aliases.Transformation.sql` | Populates aliases on vtag assets. Source: MfgTimeSeries (cdf_nodes). |
| `generate_VirtualTag_Aliases.Transformation.yaml` | Transformation config |
| `recontextualize_TimeSeries.Transformation.sql` | For Anvar's 210 curated PI tags: **adds** vtag to existing assets via `array_union`. Source: MfgTimeSeries (cdf_nodes). |
| `recontextualize_TimeSeries.Transformation.yaml` | Transformation config |
| `scripts/load_anvar_sheet_to_raw.py` | One-time loader for Anvar's 210 PI-tag-to-FLOC mappings into `raw_ext_pi.pi_tag_to_floc` |

### Modified Files

| File | Change |
|------|--------|
| `generate_TimeSeries_Aliases.Transformation.sql` | Refactored to source from MfgTimeSeries (cdf_nodes) only. |

### Why Each Change

- **populate_VirtualInstrumentationTags:** Creates instrument-level assets that don't exist in SAP. Reads `_cdf.timeseries`, filters for `pi:%`, emits one Asset per tag with parent from Anvar's sheet or prefix mapping.
- **generate_VirtualTag_Aliases:** File annotation needs aliases on assets to match P&ID text. This populates PI tag name variants (uppercase, stripped punctuation) on the vtag assets.
- **recontextualize_TimeSeries:** For Anvar's 210 curated tags, adds the vtag reference. Uses `array_union` to preserve existing links.

---

## 4. How to Add New Prefixes

When new PI tag prefixes appear (e.g., from a new area or mill), add them to the `populate_VirtualInstrumentationTags` transformation.

### Step 1: Identify the prefix and parent FLOC

1. Query `_cdf.timeseries` or RAW for PI tags with the new prefix.
2. Determine which functional location (FLOC) they belong to (consult plant engineers or P&ID documentation).
3. Verify the parent FLOC exists as an Asset in CDF (e.g., `floc:0769-06-01-XXX`).

### Step 2: Add a CASE branch in the SQL

In `populate_VirtualInstrumentationTags.Transformation.sql`, add a new `WHEN` clause:

```sql
WHEN ts.`externalId` LIKE 'pi:XXX%'
THEN node_reference('sylvamo_mfg_core_instances', 'floc:YYYY-...')
```

Place it **before** the `ELSE` (fallback) clause. Order matters: more specific prefixes should come first.

### Step 3: Verify MfgTimeSeries population

MfgTimeSeries is populated by an extractor, connector, or RAW-based transformation. Ensure new PI tags are included in that population. `populate_VirtualInstrumentationTags` creates the `vtag:` asset; `recontextualize_TimeSeries` adds vtag to curated tags. No change needed for standard PI prefixes unless you have non-PI time series that need special handling.

### Step 4: Deploy and validate

1. Run `cdf build --env dev`
2. Run `cdf deploy --dry-run --env dev`
3. Deploy and run both transformations
4. Verify new virtual tags appear under the correct parent in CDF

---

## 5. How to Validate

### Validation Tests (T1–T7)

The contextualization validation app includes tests that indirectly validate virtual tags:

| Test | What It Checks |
|------|----------------|
| **T1** | Schema, alias transformations, PI mapping table |
| **T4.0** | Total time series count |
| **T4.1** | TS with aliases (≥80% target) |
| **T4.9** | TS linked to equipment/sensor-level assets (≥50% target) — virtual tags satisfy this |
| **T7.1–T7.3** | Transformation freshness, entity counts |

### How to Run Validation

```bash
# From sylvamo repo root, with CDF credentials in .env
python -m streamlit run sylvamo/tests/validation_app/app.py
```

Click **Run Validation** and review Pass/Fail/Warn for each phase.

### Expected Results After Virtual Tags

- **T4.9** should **PASS** — Time series linked to equipment/sensor-level assets. Virtual tags (`assetType=VirtualInstrument`) count as equipment-level for this test.
- **Asset count (T7.3)** should increase by ~3,468 (the number of virtual tags).
- **CDF Search:** Searching for a PI tag (e.g., `471MR325`) should return the asset and its linked time series.

### Manual Checks

1. **CDF Fusion → Assets:** Filter by `assetType = VirtualInstrument`. You should see ~3,468 nodes.
2. **Sample a virtual tag:** Open `vtag:471MR325` and verify it has `parent` = Paper Machine 1 FLOC, `aliases` containing the tag name, and `sourceId` = `virtual:pi:471MR325`.
3. **Sample a time series:** Open a PI time series (e.g., `pi:471MR325`) in MfgTimeSeries view and verify `assets` references `vtag:471MR325`.

---

## 6. Relationship to File Annotation Pipeline

### Before Virtual Tags

The file annotation pipeline (for P&IDs) has two main steps:

1. **Pattern-based extraction** — Detects tag-shaped text in documents.
2. **Diagram detection** — Matches detected tags against assets in the hierarchy. Only assets that **exist** can be annotated.

Without virtual tags, instrumentation did not exist as assets. Diagram detection could only match against FLOC sort fields and major equipment. All instrumentation circles and bubbles on P&IDs were **detected but not annotated** — the pipeline had nothing to match them to.

### After Virtual Tags

Virtual tags provide aliases for every PI instrument. When the pipeline runs diagram detection, it can now match:

- Tag `471MR325` on a P&ID → `vtag:471MR325` (virtual asset with alias `471MR325`)
- Tag `472-PT-101` → `vtag:472-PT-101` (alias variants handle hyphen differences)

### Darren's Lion Delasel Example

Darren showed a Streamlit dashboard from the Lion Delasel project:

- **Initial run:** 67% annotation score (many instrumentation tags detected but not matched)
- **After adding virtual tags:** 93% annotation score

The same principle applies to Sylvamo: virtual tags dramatically improve P&ID annotation completeness because every instrument on the diagram now has a corresponding asset to match against.

---

## 7. Future Improvements

### When Sylvamo Adds Instrumentation to SAP

If Sylvamo (or another source) begins tracking instrumentation in SAP or another system:

1. Create a transformation to populate Asset nodes from that source.
2. Update the transformation that populates MfgTimeSeries to reference the real instrument assets instead of `vtag:`.
3. Deprecate or remove `populate_VirtualInstrumentationTags` for tags that now have real assets.
4. Virtual tags can be phased out gradually or kept for tags not yet in the authoritative source.

### Files-as-Source-of-Truth (Darren Mentioned)

Darren referenced a "Files-as-Source-of-Truth" module that creates asset hierarchy from P&ID data. This could further improve hierarchy quality by deriving structure from diagrams. It is not for quick start but is available for future use.

### ISA 5.1 Classification

Virtual tags could be classified by ISA 5.1 instrument type (e.g., PT = pressure transmitter, FT = flow transmitter) based on tag name patterns. This would enable filtering and analytics by instrument type. The tag naming convention (e.g., `471PT101` = area 471, PT, loop 101) could drive this.

---

## References

- **ADR:** [ADR-002: Virtual Instrumentation Tags](decisions/ADR-002-VIRTUAL-INSTRUMENTATION-TAGS.md)
- **Jira:** [SVQS-261](https://cognitedata.atlassian.net/browse/SVQS-261), [SVQS-282](https://cognitedata.atlassian.net/browse/SVQS-282)
- **ADO PR #992:** [Virtual Instrumentation Tags](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/992)
- **Darren review summary:** `docs/contextualization/2026-02-19-darren-review-summary.md` (sylvamo repo)
- **Darren review transcript:** `docs/contextualization/2026-02-19-darren-review-transcript.md` (sylvamo repo)
- **Contextualization next steps:** `docs/contextualization/CONTEXTUALIZATION_NEXT_STEPS.md` (sylvamo repo)
- **Transformation files:** `sylvamo/modules/mfg_core/transformations/populate_VirtualInstrumentationTags.*`, `recontextualize_TimeSeries.Transformation.sql`, `generate_VirtualTag_Aliases.Transformation.sql`, `generate_TimeSeries_Aliases.Transformation.sql`
