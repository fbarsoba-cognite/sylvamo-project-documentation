# Content Sync Guide: Repo → SharePoint Deck

**Purpose:** Copy content from repo files into the SharePoint deck (IDL Pilot - Data Modeling V2) when gaps are found.  
**Use with:** [DECK_COMPARISON_CHECKLIST.md](DECK_COMPARISON_CHECKLIST.md)

---

## Quick Reference: Source Files

| File | Use For |
|------|---------|
| [SLIDES_OUTLINE.md](SLIDES_OUTLINE.md) | Slide titles, bullet points, tables |
| [README.md](README.md) | Instance counts, quality stats, RAW summary |
| [ACTUAL_DATA_WALKTHROUGH.md](ACTUAL_DATA_WALKTHROUGH.md) | Verified data, step-by-step examples |
| [DATA_PIPELINE_DEEP_DIVE.md](DATA_PIPELINE_DEEP_DIVE.md) | Extractor table, transformation mapping |
| [SPEAKER_NOTES.md](SPEAKER_NOTES.md) | Talking points (for speaker notes in PPT) |

---

## Slide-by-Slide Copy-Paste Content

### Slide 4: Data Model at a Glance

**From SLIDES_OUTLINE.md (lines 60–101):**

- Model evolution table (PoC → Core → Extended)
- Two data models table (SylvamoMfgCore, sylvamo_mfg_extended)
- Live instance counts (Core + Extended)
- Key point: "Built on CDM for compatibility with Industrial Tools"

**From README.md (lines 65–88):** Use if counts differ; README has verified Feb 2026 data.

---

### Slide 9: Source Systems

**From SLIDES_OUTLINE.md (lines 176–188):**

| System | Data Type | Owner |
|--------|-----------|-------|
| SAP ERP | Materials, Costs, Work Orders | Finance/Ops |
| PPR System | Reels, Rolls, Packages | Production |
| Proficy GBDB | Production Events | Manufacturing |
| PI Server | Process Tags (3,500+) | Engineering |
| SharePoint | Quality Reports | Quality Team |

---

### Slide 10: Integration Architecture

**From SLIDES_OUTLINE.md (lines 193–211):** ASCII pipeline diagram (Source → Extractors → RAW → Transformations → Model)

---

### Slide 11: Extractors

**From SLIDES_OUTLINE.md (lines 216–231) or DATA_PIPELINE_DEEP_DIVE.md:**

Extractor table with: Extractor, Source, RAW Database, Volume, Status.

---

### Slide 13: Quality Traceability

**Critical – use verified data from README.md (lines 102–124) or ACTUAL_DATA_WALKTHROUGH.md:**

| Metric | Value |
|--------|-------|
| Total Quality Records | 180 |
| Rejected Rolls | 53 (29.4% rejection rate) |
| Total Time Lost | 5,761 minutes (96 hours) |

**Top Defect Types:**
| Defect | Count | % of Total |
|--------|-------|------------|
| 006 - Curl | 41 | 22.8% |
| 001 - Baggy Edges | 15 | 8.3% |
| Side to side up curl | 13 | 7.2% |
| 176 - Mill Wrinkles | 9 | 5.0% |
| 159 - Wobbly Roll | 8 | 4.4% |

**Equipment Hotspots:**
| Equipment | Incidents | Time Lost |
|-----------|-----------|-----------|
| Sheeter No.1 | 107 (59.4%) | ~3,000 min |
| Sheeter No.2 | 51 (28.3%) | 2,781 min |
| Roll Prep | 16 | - |

**Key insight:** "Curl defects on Sheeter No.1 and No.2 account for 87.7% of all quality issues."

---

### Slide 14: Material Cost & PPV

**From SLIDES_OUTLINE.md (lines 291–314) or README.md:**

PPV by material type (FIBR, RAWM, PKNG), top materials table, GraphQL query example.

---

### Slide 18: Real Data Statistics

**From README.md (lines 65–140) – full statistics block:**

- Classic: 30,952 assets, 3,864 time series
- Core model instance counts
- Extended model instance counts
- RAW database summary
- Quality insights (180, 53 rejected, 96 hrs, Sheeter 87.7%)

---

## Tables to Copy (Formatted for PowerPoint)

### Core Model Instance Counts

| View | Instances | Source |
|------|-----------|--------|
| Asset | 1,000+ | SAP Functional Locations |
| Event | 1,000+ | Proficy, SAP |
| Material | 1,000+ | SAP Materials |
| MfgTimeSeries | 1,000+ | PI Server |
| Reel | 1,000+ | PPR System |
| Roll | 1,000+ | PPR System |
| RollQuality | 580 | SharePoint |

### Extended Model Instance Counts

| View | Instances | Status |
|------|-----------|--------|
| WorkOrder | 1,000+ | ✓ Active |
| ProductionOrder | 1,000+ | ✓ Active |
| ProductionEvent | 1,000+ | ✓ Active |
| CostEvent | 716 | ✓ Active |
| Equipment | 0 | Pending |

### RAW Database Summary

| RAW Database | Tables | Description |
|--------------|--------|-------------|
| raw_ext_fabric_sapecc | 25 | SAP ECC tables via Fabric |
| raw_ext_fabric_ppr | 18 | PPR production data |
| raw_ext_fabric_ppv | 2 | PPV cost snapshots |
| raw_ext_sharepoint | 2 | Quality reports from SharePoint |
| raw_ext_sql_proficy | 2 | Proficy production events |
| raw_ext_pi | 2 | PI time series states |
| raw_ext_sap | 5 | SAP OData extracts |

---

## GraphQL Examples to Include

**From SLIDES_OUTLINE.md (lines 329–343) – listReel with rolls:**

```graphql
{
  listReel(limit: 10) {
    items {
      reelNumber
      productionDate
      asset { name }
      rolls {
        items {
          rollNumber
          width
        }
      }
    }
  }
}
```

**From SLIDES_OUTLINE.md (lines 419–441) – traceability query (backup slide):**

```graphql
{
  getRoll(externalId: "roll:EME13B08061N") {
    rollNumber
    width
    reel {
      reelNumber
      productionDate
      productDefinition { name, basisWeight }
      equipment {
        name
        asset { name }
      }
    }
    package {
      packageNumber
      status
      sourcePlant { name }
      destinationPlant { name }
    }
  }
}
```

---

## Data Verification Stamp

Add to slides with statistics: **"Data verified: February 16, 2026"**

---

## Sync Workflow

1. Run through [DECK_COMPARISON_CHECKLIST.md](DECK_COMPARISON_CHECKLIST.md).
2. For each unchecked item, find the content in this guide.
3. Copy from the specified file into the corresponding SharePoint slide.
4. Re-verify counts against README.md if data may have changed.
