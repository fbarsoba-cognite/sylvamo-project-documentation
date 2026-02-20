# Virtual Instrumentation Tags — Implementation Guide

This guide explains how virtual instrumentation tags work in the Sylvamo Industrial Data Landscape and how to implement, maintain, and validate them. It is written for data engineers who may not be experts in contextualization.

**Jira:** [SVQS-261](https://cognitedata.atlassian.net/browse/SVQS-261)

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

### Transformation Pipeline Flow

```
1. populate_Asset
   Creates FLOC hierarchy from SAP (functional locations, equipment)
                    |
                    v
2. populate_VirtualInstrumentationTags  (NEW - SVQS-261)
   Creates virtual assets (vtag:471MR325, etc.) from PI time series
   Places each under the correct FLOC based on prefix mapping
                    |
                    v
3. populate_TimeSeries  (MODIFIED)
   Maps PI time series to vtag: assets (instead of PM-level floc:)
   Proficy tags still map to PM-level assets
                    |
                    v
4. generate_TimeSeries_Aliases  (unchanged)
   Populates aliases on MfgTimeSeries for entity matching
                    |
                    v
5. Entity Matching
   Matches MfgTimeSeries aliases to Asset aliases
   Now finds vtag: assets matching TS aliases (100% discrete match for PI)
```

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

## 3. Files Changed

### New Files

| File | Purpose |
|------|---------|
| `populate_VirtualInstrumentationTags.Transformation.sql` | Creates one Asset node per PI time series, with prefix-to-FLOC mapping |
| `populate_VirtualInstrumentationTags.Transformation.yaml` | Transformation config (destination: Asset view, instance space) |

### Modified Files

| File | Change |
|------|--------|
| `populate_TimeSeries.Transformation.sql` | `assets` property now references `vtag:{PI_TAG}` for PI time series instead of PM-level `floc:` |

### Why Each Change

- **populate_VirtualInstrumentationTags:** Without this, there are no instrument-level assets. The transformation reads `_cdf.timeseries`, filters for `pi:%` external IDs, and emits one Asset per tag with the correct parent and aliases.
- **populate_TimeSeries:** Previously it wrote `assets = [floc:0769-06-01-010]` or `[floc:0769-06-01-020]` for all PI tags. Now it writes `assets = [vtag:471MR325]` (or the specific tag) so each time series links to its discrete instrument.

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

### Step 3: Add to populate_TimeSeries if needed

`populate_TimeSeries` derives the `vtag:` reference from the PI tag name directly; it does not use the prefix mapping. As long as `populate_VirtualInstrumentationTags` creates the `vtag:` asset, `populate_TimeSeries` will reference it correctly. No change needed unless you have non-PI time series that need special handling.

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
2. Update `populate_TimeSeries` to reference the real instrument assets instead of `vtag:`.
3. Deprecate or remove `populate_VirtualInstrumentationTags` for tags that now have real assets.
4. Virtual tags can be phased out gradually or kept for tags not yet in the authoritative source.

### Files-as-Source-of-Truth (Darren Mentioned)

Darren referenced a "Files-as-Source-of-Truth" module that creates asset hierarchy from P&ID data. This could further improve hierarchy quality by deriving structure from diagrams. It is not for quick start but is available for future use.

### ISA 5.1 Classification

Virtual tags could be classified by ISA 5.1 instrument type (e.g., PT = pressure transmitter, FT = flow transmitter) based on tag name patterns. This would enable filtering and analytics by instrument type. The tag naming convention (e.g., `471PT101` = area 471, PT, loop 101) could drive this.

---

## References

- **ADR:** [ADR-002: Virtual Instrumentation Tags](decisions/ADR-002-VIRTUAL-INSTRUMENTATION-TAGS.md)
- **Jira:** [SVQS-261](https://cognitedata.atlassian.net/browse/SVQS-261)
- **Darren review summary:** `docs/contextualization/2026-02-19-darren-review-summary.md` (sylvamo repo)
- **Darren review transcript:** `docs/contextualization/2026-02-19-darren-review-transcript.md` (sylvamo repo)
- **Transformation files:** `sylvamo/modules/mfg_core/transformations/populate_VirtualInstrumentationTags.*`, `populate_TimeSeries.Transformation.sql`
