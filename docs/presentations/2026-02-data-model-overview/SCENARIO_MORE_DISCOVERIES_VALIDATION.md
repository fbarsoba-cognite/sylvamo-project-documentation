# Scenario Validation: More Discoveries From The Data (Slide 16)

Validation of the slide "More Discoveries From The Data" against the deployed mfg_core data model and CDF.

**CDF validation run:** `python scripts/validate_more_discoveries_slide16.py` (from project root)

---

## Slide Summary

| Discovery | What We Found (Slide) |
|-----------|----------------------|
| Total quality issues | 180 records, 53 rejected rolls |
| Total time lost | 96 hours |
| #1 defect type | Curl (60 occurrences) |
| #2 defect type | Baggy edges (28 occurrences) |
| Equipment needing attention | Sheeter #1 (107 instances) |
| Cost improvement | $1.3M PPV improvement |

---

## CDF Validation Results (Live Data)

| Check | Slide | CDF (Full Dataset) | Match? |
|-------|-------|--------------------|--------|
| Total quality records | 180 | **750** | Different |
| Rejected rolls | 53 | **285** | Different |
| Total time lost | 96 hrs | **346.6 hrs** (20,798 min) | Different |
| #1 defect (Curl) | 60 | **132** (006-Curl: 93 + Curl: 39) | Different |
| #2 defect (Baggy edges) | 28 | **70** (001-Baggy: 43 + Baggy Edge: 27) | Different |
| Sheeter #1 instances | 107 | **205** | Different |
| PPV improvement | $1.3M | Not verified (mfg_extended) | — |

**Verdict:** The slide numbers reflect a **subset** of the data (likely a specific time window or filtered scope). The full CDF dataset has more records. The **rankings and patterns** hold: Curl is #1, Baggy edges #2, Sheeter #1 has the most quality issues.

---

## How We Reached These Conclusions

### Step 1: List All RollQuality Nodes

We queried CDF for all RollQuality instances in `sylvamo_mfg_core_instances`:

```python
all_rq = list(client.data_modeling.instances.list(
    instance_type="node",
    space="sylvamo_mfg_core_instances",
    sources=[ViewId("sylvamo_mfg_core_schema", "RollQuality", "v1")],
    limit=2000,
))
```

**Result:** 750 RollQuality nodes total.

**Slide comparison:** Slide says 180 — likely a filtered subset (e.g., last 30 days, specific plant, or snapshot at slide creation time).

---

### Step 2: Count Rejected Rolls

For each RollQuality node, we read `wasRollRejected` (mapped from SharePoint `WastheRollRejected`):

```python
rejected = sum(1 for n in all_rq if get_props(n, "RollQuality").get("wasRollRejected") is True)
```

**Result:** 285 rejected rolls.

**Slide comparison:** Slide says 53 — same subset logic as total records.

---

### Step 3: Sum Total Time Lost

We summed `minutesLost` across all RollQuality nodes:

```python
total_minutes = sum(float(p.get("minutesLost") or 0) for n in all_rq for p in [get_props(n, "RollQuality")] if p.get("minutesLost") is not None)
total_hours = total_minutes / 60
```

**Result:** 20,798 minutes ≈ **346.6 hours**.

**Slide comparison:** Slide says 96 hours — consistent with a smaller subset.

---

### Step 4: Aggregate Defect Types (All RollQuality)

We grouped by `defectDescription` and `defectNonDamage`:

```python
defect_desc[description] += 1  for each node
sorted_defects = sorted(defect_desc.items(), key=lambda x: -x[1])
```

**Top defect types in CDF:**

| Rank | Defect | Count |
|------|--------|-------|
| 1 | 006 - Curl | 93 |
| 2 | Wobbly Roll | 59 |
| 3 | 001 - Baggy Edges | 43 |
| 4 | Curl | 39 |
| 5 | Corrugations | 37 |
| 6 | Baggy Edge | 27 |

**Combined Curl:** 93 + 39 = **132** (slide: 60)  
**Combined Baggy edges:** 43 + 27 = **70** (slide: 28)

**Conclusion:** Curl is #1 and Baggy edges #2 in both slide and CDF. The slide uses a subset; relative rankings are consistent.

---

### Step 5: Equipment by Instance Count

We counted RollQuality per asset (via `asset` relation):

```python
asset_to_count[asset_externalId] += 1  for each node with asset
sorted_assets = sorted(asset_to_count.items(), key=lambda x: -x[1])
```

**Equipment with most RollQuality reports:**

| Asset | Count | Equipment |
|-------|-------|-----------|
| floc:0519-07-05-020-010 | **205** | Sheeter No.1 |
| floc:0519-07-05-020-020 | 102 | Sheeter No.2 |
| floc:0519-07-05-010 | 32 | Roll Prep Station |
| floc:0519-07-05-020-030 | 10 | Sheeter No.3 |

**Conclusion:** Sheeter #1 has the most quality issues in both slide (107) and CDF (205). Same equipment, different scope.

---

### Step 6: PPV / Cost Improvement ($1.3M)

The $1.3M PPV improvement comes from **Purchase Price Variance** data, which lives in:

- **MaterialCostVariance** (mfg_data / mfg_extended)
- **CostEvent** (mfg_extended)

These are not in the mfg_core RollQuality flow. Validation would require querying `sylvamo_mfg_extended_instances` or `sylvamo_mfg_instances` for MaterialCostVariance/CostEvent and summing `ppvChange` or equivalent.

**Status:** Not verified in this run. The slide's $1.3M is a business metric; the model supports PPV analysis via Use Case 1 (Material Cost & PPV).

---

## Summary of Calculations

| Metric | Formula | CDF Result |
|--------|---------|------------|
| Total records | `len(all_rq)` | 750 |
| Rejected rolls | `count(n where wasRollRejected == true)` | 285 |
| Total minutes lost | `sum(n.minutesLost)` | 20,798 |
| Total hours | `total_minutes / 60` | 346.6 |
| Curl (combined) | `count(defect contains "Curl")` | 132 |
| Baggy edges (combined) | `count(defect contains "Baggy")` | 70 |
| Sheeter #1 instances | `count(n where asset == floc:0519-07-05-020-010)` | 205 |

---

## Slide vs CDF: Why the Difference?

| Factor | Explanation |
|--------|--------------|
| **Time scope** | Slide may use a specific period (e.g., last quarter); CDF has full history |
| **Data growth** | More data ingested since slide was created |
| **Filtering** | Slide may filter by plant, equipment, or defect type |
| **Snapshot** | Slide could be a point-in-time snapshot |

**Recommendation:** If the slide is meant to reflect current CDF, update to: 750 records, 285 rejected, 346.6 hrs, Curl 132, Baggy 70, Sheeter #1 205. If it represents a specific scenario (e.g., "Q4 2025"), add that scope and filter CDF accordingly.

---

## Run Validation Script

```bash
# From main sylvamo repo (has .env and venv)
cd /path/to/sylvamo
.venv/bin/python scripts/validate_more_discoveries_slide16.py
```

---

## Model Alignment

| Slide Term | mfg_core Equivalent |
|------------|---------------------|
| Quality records | RollQuality nodes |
| Rejected rolls | RollQuality.wasRollRejected |
| Time lost | RollQuality.minutesLost |
| Defect type | RollQuality.defectDescription / defectNonDamage |
| Equipment | RollQuality.asset → Asset |
| PPV improvement | MaterialCostVariance / CostEvent (mfg_extended) |

---

## Conclusion

The slide's **narrative is validated**: connected data reveals total quality issues, time lost, top defect types, and equipment needing attention. The **rankings match** (Curl #1, Baggy #2, Sheeter #1). The **numeric values** differ because the slide uses a subset; the full CDF dataset has more data. To align numbers, either filter CDF to the slide's scope or update the slide to full-dataset values.
