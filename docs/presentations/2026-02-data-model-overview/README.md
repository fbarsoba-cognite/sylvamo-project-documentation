# Sylvamo CDF Data Model - Presentation Materials

**Presentation Title:** Sylvamo Manufacturing Data Model  
**Subtitle:** ISA-95/ISA-88 Aligned Data Model for Paper Manufacturing  
**Duration:** 60 minutes (20 slides @ ~3 min each)  
**Target Audience:** Technical stakeholders, data engineers, manufacturing SMEs  
**Last Updated:** February 2026

---

## Overview

This presentation covers the Sylvamo Manufacturing Data Model implemented in Cognite Data Fusion (CDF). It explains the data architecture, integration patterns, use cases, and roadmap for the project.

## Presentation Objectives

By the end of this presentation, attendees will understand:

1. **Data Model Architecture** - How the sylvamo_mfg_core model is structured
2. **ISA-95/ISA-88 Alignment** - Why we chose CDM + ISA standards
3. **Data Pipeline** - How data flows from source systems to CDF
4. **Use Cases** - Quality traceability and cost analysis capabilities
5. **Implementation** - CI/CD and deployment practices
6. **Roadmap** - What's next for the data model

## Files in This Folder

| File | Description |
|------|-------------|
| [SLIDES_OUTLINE.md](SLIDES_OUTLINE.md) | Detailed slide-by-slide outline with content |
| [SPEAKER_NOTES.md](SPEAKER_NOTES.md) | Full speaker notes for each slide (~3 min per slide) |
| [DEMO_SCRIPT.md](DEMO_SCRIPT.md) | Step-by-step demo walkthrough for CDF Fusion |
| [DATA_PIPELINE_DEEP_DIVE.md](DATA_PIPELINE_DEEP_DIVE.md) | Complete 35-table pipeline mapping, Fabric infrastructure |
| [ACTUAL_DATA_WALKTHROUGH.md](ACTUAL_DATA_WALKTHROUGH.md) | **NEW** Step-by-step explanation of actual CDF data (verified Feb 2026) |
| [Sylvamo_CDF_Data_Model_Presentation.pptx](Sylvamo_CDF_Data_Model_Presentation.pptx) | PowerPoint slides (generated from template) |
| `assets/` | Screenshots and diagrams for slides |

## Presentation Structure

| Section | Slides | Time | Topics |
|---------|--------|------|--------|
| **1. Introduction** | 1-3 | 9 min | Title, Agenda, Business Context |
| **2. Data Model Overview** | 4-8 | 15 min | Architecture, ERD, ISA alignment, Entities |
| **3. Data Pipeline** | 9-12 | 12 min | Sources, Integration, Extractors, Transformations |
| **4. Use Cases** | 13-16 | 12 min | Quality, PPV, Search, GraphQL |
| **5. Implementation** | 17-18 | 6 min | CI/CD, Statistics |
| **6. Roadmap & Wrap-up** | 19-20 | 6 min | Sprint progress, Q&A |

## Key Data Points to Reference

> **Last verified:** February 16, 2026 (from live CDF queries)

**Data Model Spaces:**
| Space | Purpose |
|-------|---------|
| `sylvamo_mfg_core_schema` | Core model schema (views, containers) |
| `sylvamo_mfg_core_instances` | Core model data instances |
| `sylvamo_mfg_ext_schema` | Extended model schema (ISA-95 aligned) |
| `sylvamo_mfg_ext_instances` | Extended model data instances |

**Data Models:**
- `SylvamoMfgCore` (v1) - 7 views for manufacturing core
- `sylvamo_mfg_extended` (v1) - 8 views for ISA-95 extensions

### Live Instance Counts (Verified)

**Core Model (`sylvamo_mfg_core_schema`):**
| View | Instance Count | Description |
|------|----------------|-------------|
| Asset | 1,000+ | From SAP Functional Locations |
| Event | 1,000+ | Proficy events, SAP activities |
| Material | 1,000+ | SAP materials master |
| MfgTimeSeries | 1,000+ | PI Server time series metadata |
| Reel | 1,000+ | Paper machine production runs |
| Roll | 1,000+ | Individual rolls cut from reels |
| RollQuality | 580 | SharePoint quality reports |

**Extended Model (`sylvamo_mfg_ext_schema`):**
| View | Instance Count | Description |
|------|----------------|-------------|
| WorkOrder | 1,000+ | SAP maintenance work orders |
| MaintenanceActivity | 1,000+ | Maintenance activities |
| ProductionOrder | 1,000+ | SAP production orders |
| ProductionEvent | 1,000+ | Proficy production events |
| CostEvent | 716 | PPV cost variance records |
| Equipment | 0 | Pending population |
| Operation | 0 | Pending population |
| Notification | 0 | Pending population |

### RAW Database Summary

| RAW Database | Tables | Description |
|--------------|--------|-------------|
| `raw_ext_fabric_sapecc` | 25 | SAP ECC tables via Fabric |
| `raw_ext_fabric_ppr` | 18 | PPR production data |
| `raw_ext_fabric_ppv` | 2 | PPV cost snapshots |
| `raw_ext_sharepoint` | 2 | Quality reports from SharePoint |
| `raw_ext_sql_proficy` | 2 | Proficy production events |
| `raw_ext_pi` | 2 | PI time series states |
| `raw_ext_sap` | 5 | SAP OData extracts |

### Real Data Discoveries

**Roll Quality Analysis (180 records from SharePoint):**
- **Total Records:** 180 quality events
- **Rejected Rolls:** 53 (29.4% rejection rate)
- **Total Time Lost:** 5,761 minutes (96 hours)

**Top Defect Types:**
| Defect | Count | % of Total |
|--------|-------|------------|
| 006 - Curl | 41 | 22.8% |
| 001 - Baggy Edges | 15 | 8.3% |
| Side to side up curl | 13 | 7.2% |
| 176 - Mill Wrinkles | 9 | 5.0% |
| 159 - Wobbly Roll | 8 | 4.4% |

**Equipment with Most Issues:**
| Equipment | Incidents | Time Lost |
|-----------|-----------|-----------|
| Sheeter No.1 | 107 | 2,980 min |
| Sheeter No.2 | 51 | 2,781 min (46.4 hrs) |
| Roll Prep | 16 | - |
| Sheeter No.3 | 5 | - |

**Work Orders (SAP ECC):**
| Plant | Work Orders |
|-------|-------------|
| 7825 (Eastover) | 978 |
| MG01 | 313 |
| MG19 | 213 |
| 0769 | 132 |
| 8675 | 116 |

**Other Volumes:**
| Source | Count |
|--------|-------|
| Classic Assets | 30,952 |
| Time Series | 3,864 |
| PPV Records | 716 |
| Proficy Events | 2,000+ |

---

## How the Data Model Enables These Discoveries

> **Key Message:** The findings above were only possible BECAUSE of the connected data model. Without it, this analysis would require manual correlation across 5+ disconnected systems.

### Before vs. After the Data Model

| Discovery | Data Sources | Without Model | With Model |
|-----------|--------------|---------------|------------|
| Quality patterns by equipment | SharePoint + SAP | Hours of manual correlation | 1 query, seconds |
| Multi-plant work order comparison | SAP ECC (10 plants) | Separate exports per plant | Single cross-plant query |
| Cost-to-production traceability | SAP FI + SAP MM + PPR | Impossible to link | Direct relationship navigation |

### Data Model Relationships That Enable Analysis

```
┌────────────────────────────────────────────────────────────────────┐
│  CONNECTED DATA MODEL STRUCTURE                                    │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   RollQuality ───► Asset ───► WorkOrder                           │
│        │                │                                          │
│        │ equipment      │ plant                                    │
│        ▼                ▼                                          │
│      Roll ───────► Reel ───────► Material ───────► CostEvent      │
│                      │                                             │
│                      │ timeseries                                  │
│                      ▼                                             │
│              MfgTimeSeries (3,864 PI tags)                        │
│                                                                     │
│   Every arrow = A relationship in the data model                   │
│   Every insight = ONE QUERY across multiple systems                │
└────────────────────────────────────────────────────────────────────┘
```

### Example: Quality Pattern Discovery

**The Finding:** Sheeter No.1 and No.2 account for 87.7% of quality issues

**Data Model Properties Used:**
| View | Property/Relationship | Purpose |
|------|----------------------|---------|
| `RollQuality` | `equipment` (property) | Group defects by equipment |
| `RollQuality` | `defectCode` (property) | Categorize defect types |
| `RollQuality` | `minutesLost` (property) | Calculate time impact |
| `RollQuality` → `Asset` | Direct relation | Link to plant hierarchy |

**The Query:**
```graphql
{
  listRollQuality(limit: 500) {
    items {
      equipment     # ← Links to "Sheeter No.2"
      defectCode    # ← "006 - Curl"
      minutesLost   # ← Time lost per defect
    }
  }
}
```

### Presentation Takeaway

When presenting, emphasize:
1. **The data model IS the value** - without relationships, data stays siloed
2. **Views and properties** enable filtering and grouping
3. **Relationships** enable navigation across systems
4. **One query** replaces hours of manual correlation

## Demo Environment

- **CDF Project:** sylvamo-dev
- **Cluster:** az-eastus-1
- **URL:** https://az-eastus-1.cognitedata.com

## Prerequisites for Presenter

1. Access to CDF Fusion (sylvamo-dev project)
2. Location filter "Sylvamo MFG Core" selected
3. Sample data loaded (Eastover Mill assets, reels, time series)
4. GraphQL Explorer access for live queries

## Related Documentation

### Data Model
- [Data Model Specification](../../reference/data-model/DATA_MODEL_SPECIFICATION.md) - Complete container and property specs
- [Architecture Decisions & Roadmap](../../reference/data-model/ARCHITECTURE_DECISIONS_AND_ROADMAP.md) - ADRs and phase planning
- [Data Model Walkthrough](../../reference/data-model/DATA_MODEL_WALKTHROUGH.md) - Step-by-step traceability example
- [Johan ISA-95 Guidance](../../reference/data-model/JOHAN_ISA95_GUIDANCE_SUMMARY.md) - Expert recommendations
- [ISA Alignment Analysis](../../reference/data-model/COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md) - Standards mapping

### Data Pipeline
- [Transformations](../../reference/data-model/TRANSFORMATIONS.md) - 24 SQL transformations documented
- [Extractors](../../reference/extractors/EXTRACTORS.md) - Extractor configurations
- [Data Source Registry](../../reference/extractors/DATA_SOURCE_REGISTRY.md) - RAW table inventory
- [Data Pipeline & Sources](../../reference/extractors/DATA_PIPELINE_AND_SOURCES.md) - Source system details

### Use Cases
- [Use Cases & Queries](../../reference/use-cases/USE_CASES_AND_QUERIES.md) - Verified queries with real data
- [Expert Scenarios](../../reference/use-cases/USE_CASE_VALIDATION_EXPERT_SCENARIOS.md) - Industry use cases

### CI/CD
- [CI/CD Overview](../../reference/cicd/CICD_OVERVIEW.md) - Pipeline setup
- [Complete Setup Guide](../../reference/cicd/CICD_COMPLETE_SETUP_GUIDE.md) - Step-by-step guide

### Sprint Planning
- [Sprint 3 Plan](../../internal/sprint-planning/SPRINT_3_PLAN.md) - Current sprint work
- [Sprint 2 Plan (Archived)](../../deprecated/sprint-planning/SPRINT_2_PLAN.md)

---

*Presentation materials prepared for Sylvamo CDF implementation team.*
