> **Note:** These materials were prepared for the Sprint 2 demo (Feb 2026) and may contain outdated statistics. Verify current data in CDF.

# Sylvamo CDF Data Model - Slides Outline

**Total Slides:** 20  
**Duration:** 60 minutes (~3 min per slide)

---

## Section 1: Introduction (9 min, 3 slides)

### Slide 1: Title Slide

**Title:** Sylvamo Manufacturing Data Model  
**Subtitle:** ISA-95/ISA-88 Aligned for Paper Manufacturing

**Visual:** Sylvamo logo + CDF logo

**Content:**
- Presenter name and role
- Date: February 2026
- "Connecting Manufacturing Data for Operational Excellence"

---

### Slide 2: Agenda

**Title:** What We'll Cover Today

**Content:**
1. Business Context & Project Goals
2. Data Model Architecture
3. Data Pipeline & Integration
4. Use Cases & Demonstrations
5. Implementation & CI/CD
6. Roadmap & Next Steps

**Visual:** Simple numbered list or icons for each section

---

### Slide 3: Business Context

**Title:** Why This Matters for Sylvamo

**Content:**
- **Challenge:** Data silos across SAP, PI, Proficy, SharePoint
- **Opportunity:** Unified view of manufacturing operations
- **Goals:**
  - End-to-end product traceability (reel to customer)
  - Quality insights across production
  - Cost visibility with PPV analysis
  - Inter-plant material tracking

**Visual:** Before/After diagram showing siloed vs. unified data

---

## Section 2: Data Model Overview (15 min, 5 slides)

### Slide 4: Data Model at a Glance

**Title:** sylvamo_mfg_core - Overview

**Content:**

> *Data verified: February 16, 2026*

**Model Evolution:**
| Stage | Model | Status |
|-------|-------|--------|
| PoC | sylvamo_mfg | Validated |
| Production | sylvamo_mfg_core | Live |
| Extended | sylvamo_mfg_extended | Partially Populated |

**Two Data Models:**

| Model | Space | Views | Description |
|-------|-------|-------|-------------|
| SylvamoMfgCore | sylvamo_mfg_core_schema | 7 | Core manufacturing entities |
| sylvamo_mfg_extended | sylvamo_mfg_ext_schema | 8 | ISA-95 aligned extensions |

**Live Instance Counts (Core Model):**
| View | Instances | Source |
|------|-----------|--------|
| Asset | 1,000+ | SAP Functional Locations |
| Event | 1,000+ | Proficy, SAP |
| Material | 1,000+ | SAP Materials |
| MfgTimeSeries | 1,000+ | PI Server |
| Reel | 1,000+ | PPR System |
| Roll | 1,000+ | PPR System |
| RollQuality | 580 | SharePoint |

**Extended Model:**
| View | Instances | Status |
|------|-----------|--------|
| WorkOrder | 1,000+ | ✓ Active |
| ProductionOrder | 1,000+ | ✓ Active |
| ProductionEvent | 1,000+ | ✓ Active |
| CostEvent | 716 | ✓ Active |
| Equipment | 0 | Pending |

**Key Point:** Built on CDM for compatibility with Industrial Tools - Search, Canvas, InField work out of the box

**Visual:** Three-layer evolution diagram (PoC → Core → Extended)

---

### Slide 5: Entity Relationship Diagram

**Title:** How Entities Connect

**Visual:** Full ERD (Mermaid diagram from README)

```
Asset → Equipment → Reel → Roll → Package
                 ↘ Recipe ↙
            ProductDefinition
                     ↓
            MaterialCostVariance
```

**Key Relationships:**
- Asset contains Equipment
- Equipment produces Reels
- Reels are cut into Rolls
- Rolls are bundled into Packages
- QualityResult tests Reels and Rolls

---

### Slide 6: ISA-95/ISA-88 Alignment

**Title:** Standards-Based Design

**Content:**
| Our Model | ISA-95/88 Concept | CDM Foundation |
|-----------|-------------------|----------------|
| Asset | Site, Area, Unit | CogniteAsset |
| Equipment | Equipment Module | CogniteEquipment |
| Reel | Batch | CogniteDescribable |
| Roll | Material Lot | CogniteDescribable |
| Recipe | General/Master Recipe | Custom View |

**Key Design Decisions:**
1. CDM Asset + Equipment (not full ISA hierarchy)
2. Reel = Batch (paper reel production run)
3. Roll = MaterialLot (sellable unit)
4. Package = Sylvamo extension for inter-plant tracking

**Visual:** ISA-95 pyramid with mappings

---

### Slide 7: Core Entities - Production

**Title:** Production Entities

**Asset:**
- Eastover Mill, Sumpter Facility
- Hierarchical structure (plant → area → unit)
- 45,953 nodes from SAP Functional Locations

**Equipment:**
- PM1, PM2 (Paper Machines)
- Winders, Sheeters
- Links to Asset hierarchy

**Recipe:**
- General & Master Recipes
- Target parameters (basis weight, moisture)
- Links to ProductDefinition and Equipment

**Visual:** Asset hierarchy tree with Equipment attached

---

### Slide 8: Core Entities - Material Flow

**Title:** Material Flow Entities

**Reel (Batch):**
- 61,335 reels in system
- Production date, weight, dimensions
- Links to Asset (paper machine), ProductDefinition

**Roll (Material Lot):**
- 100,000+ rolls
- Cut from reels
- Width, diameter, quality status

**Package:**
- Inter-plant transfer tracking
- Source plant → Destination plant
- Contains multiple rolls

**QualityResult:**
- Caliper, Moisture, Basis Weight tests
- isInSpec flag for compliance

**Visual:** Flow diagram: Reel → Roll → Package with QualityResult testing

---

## Section 3: Data Pipeline (12 min, 4 slides)

### Slide 9: Source Systems

**Title:** Where Data Comes From

| System | Data Type | Owner |
|--------|-----------|-------|
| SAP ERP | Materials, Costs, Work Orders | Finance/Ops |
| PPR System | Reels, Rolls, Packages | Production |
| Proficy GBDB | Production Events | Manufacturing |
| PI Server | Process Tags (3,500+) | Engineering |
| SharePoint | Quality Reports | Quality Team |

**Visual:** Icons for each source system with data types

---

### Slide 10: Integration Architecture

**Title:** Data Flow to CDF

**Visual:** Full pipeline flowchart

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│  Source Systems │────▶│   Extractors │────▶│  CDF RAW    │
│  SAP, PI, etc.  │     │  Fabric, PI  │     │  Databases  │
└─────────────────┘     └──────────────┘     └──────┬──────┘
                                                    │
                        ┌──────────────────────────▼────────┐
                        │         Transformations           │
                        │  24 SQL queries (scheduled)       │
                        └──────────────────────────┬────────┘
                                                   │
                        ┌──────────────────────────▼────────┐
                        │      sylvamo_mfg_core Model       │
                        │      365,000+ nodes               │
                        └───────────────────────────────────┘
```

**Key Point:** RAW → Transform → Data Model pattern

---

### Slide 11: Extractors

**Title:** Data Extraction Layer

| Extractor | Source | RAW Database | Volume | Status |
|-----------|--------|--------------|--------|--------|
| Fabric Connector | Microsoft Fabric | raw_ext_fabric_ppr | 61K reels, 2.3M rolls, 50K packages | Running |
| Fabric Connector | Microsoft Fabric | raw_ext_fabric_ppv | 200 PPV snapshots | Running |
| Fabric Connector | Microsoft Fabric | raw_ext_fabric_sapecc | 407K work orders (IW28) | Running |
| PI Extractor | PI Server (S769PI01, S769PI03) | CDF Time Series | 3,500+ tags | Running |
| SharePoint | SharePoint Online | raw_ext_sharepoint | 21+ quality reports | Running |
| SAP OData | SAP Gateway | raw_ext_sap | Materials, FLocs, BP | Running |
| SQL Extractor | Proficy GBDB | raw_ext_sql_proficy | Production events, lab tests | Running |

**RAW Database Convention:** `raw_ext_<extractor>_<source>`

**Key Point:** Each source has dedicated service principal (sp-cdf-*-extractor-dev)

**Visual:** Extractor status dashboard showing volumes

---

### Slide 12: Transformations

**Title:** RAW to Data Model

**Content:**
- **24 SQL Transformations** running on schedule
- Convert RAW tables to Data Model nodes
- Handle deduplication, data quality, relationships

**Example Transformation:**
```sql
SELECT
    concat('reel:', cast(reel_number as STRING)) as externalId,
    'sylvamo_mfg_core_instances' as space,
    reel_number as name,
    to_timestamp(production_date) as productionDate,
    node_reference('...', concat('asset:', paper_machine)) as asset
FROM raw_ext_fabric_ppr.ppr_hist_reel
```

**Schedule:** Hourly refresh for production data

**Visual:** Transformation list with run status

---

## Section 4: Use Cases (12 min, 4 slides)

### Slide 13: Use Case 1 - Paper Quality Traceability

**Title:** Quality Traceability: Roll → Reel → Tests

**Business Need:** Track quality issues back to production conditions

**Real Production Data (February 2026):**
| Metric | Value |
|--------|-------|
| Total Quality Records | 180 |
| Rejected Rolls | 53 (29.4% rejection rate) |
| Total Time Lost | 5,761 minutes (96 hours) |
| Time Series Available | 3,864 PI tags |

**Top Defect Types (Actual Data):**
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

**Key Insight:** Curl defects on Sheeter No.1 and No.2 account for 87.7% of all quality issues. Focus maintenance here for maximum impact.

**How the Data Model Made This Possible:**

| Without Data Model | With Data Model |
|-------------------|-----------------|
| Quality in SharePoint (isolated) | `RollQuality` view with `equipment` property |
| Equipment in SAP (separate) | `RollQuality` → `Asset` relationship |
| Manual correlation required | Single GraphQL query |
| Hours of analysis | Seconds to insight |

**Data Model Structure Used:**
```
RollQuality (View)
├── equipment (property) ──► Links to "Sheeter No.2"
├── defectCode (property) ─► "006 - Curl" 
├── minutesLost (property) ► 35 minutes
└── asset (relationship) ──► Plant hierarchy
```

**Traceability Flow:**
1. Customer complaint about roll quality → Search roll number
2. Navigate to parent reel → View production date
3. Check quality test results → See defect code
4. Correlate with process conditions → 3,864 time series

**Visual:** Screenshot of CDF Fusion showing roll → reel → quality drill-down

---

### Slide 14: Use Case 2 - Material Cost & PPV

**Title:** Purchase Price Variance Analysis

**Business Need:** Track raw material cost impacts on products

**Real PPV Data by Material Type:**
| Type | Count | Total PPV | Impact |
|------|-------|-----------|--------|
| Packaging (PKNG) | 102 | +$9,254 | Overpaying |
| Raw Materials (RAWM) | 61 | -$23,063 | Favorable |
| Fiber (FIBR) | 7 | -$104,342 | Very Favorable |

**Top Materials by PPV Impact (Real Data):**
| Material | Description | PPV |
|----------|-------------|-----|
| 000005210009 | Softwood | -$72,631 |
| 000005054010 | Mixed Hardwood Chips | -$24,802 |
| 000001019900 | Caustic Soda | -$22,095 |

**Query:**
```graphql
{
  listMaterialCostVariance(filter: { ppvChange: { gt: 500 }}) {
    items { material, materialType, ppvChange }
  }
}
```

**Key Insight:** Finance data → Operational decisions (which products affected by cost changes?)

**Visual:** PPV chart showing fiber vs. packaging cost trends

---

### Slide 15: Search Experience

**Title:** Industrial Tools Search

**Features Enabled:**
- Events linked to Assets (Proficy, SAP Work Orders)
- Files linked to Assets (P&IDs, drawings)
- Time Series linked to Assets (PI tags)
- Location filters for scoped views

**Demo Points:**
1. Select "Sylvamo MFG Core" location filter
2. Search for "PM1" asset
3. View linked events, files, time series
4. Navigate relationships

**Visual:** Screenshot of CDF Fusion search with linked data

---

### Slide 16: GraphQL Queries

**Title:** API Access with GraphQL

**Example Query:**
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

**Access Patterns:**
- GraphQL Explorer in CDF
- SDK integration (Python, JavaScript)
- REST API fallback

**Visual:** GraphQL Explorer screenshot with query results

---

## Section 5: Implementation & CI/CD (6 min, 2 slides)

### Slide 17: CI/CD Pipeline

**Title:** Deployment Pipeline

**Tools:**
- **Cognite Toolkit CLI** (cdf-tk)
- Commands: `cdf-tk build`, `cdf-tk deploy`

**Flow:**
```
Feature Branch (PR)
    └─▶ cdf build → cdf deploy --dry-run
        └─▶ Validates config, shows changes

Main Branch
    └─▶ cdf build → cdf deploy
        └─▶ DEV → STAGING → PROD (with approvals)
```

**Authentication:** OAuth2 client credentials (Entra ID service principal)

**Visual:** Pipeline diagram with stages

---

### Slide 18: Real Data Statistics

**Title:** Production Data Summary

> *Verified: February 16, 2026 from live CDF queries*

**Classic CDF Resources:**
| Resource | Count |
|----------|-------|
| Assets | 30,952 |
| Time Series | 3,864 |

**Core Model Instances (`sylvamo_mfg_core`):**
| View | Instances | Source |
|------|-----------|--------|
| Asset | 1,000+ | SAP Functional Locations |
| Event | 1,000+ | SAP, Proficy |
| Material | 1,000+ | SAP Materials |
| MfgTimeSeries | 1,000+ | PI Server |
| Reel | 1,000+ | Fabric PPR |
| Roll | 1,000+ | Fabric PPR |
| RollQuality | 580 | SharePoint |

**Extended Model Instances (`sylvamo_mfg_extended`):**
| View | Instances | Source |
|------|-----------|--------|
| WorkOrder | 1,000+ | SAP ECC |
| MaintenanceActivity | 1,000+ | SAP ECC |
| ProductionOrder | 1,000+ | SAP ECC |
| ProductionEvent | 1,000+ | Proficy |
| CostEvent | 716 | PPV Snapshots |

**RAW Layer Statistics:**
| Database | Tables | Key Data |
|----------|--------|----------|
| raw_ext_fabric_sapecc | 25 | 2,000+ work orders |
| raw_ext_fabric_ppr | 18 | Reels, Rolls, Packages |
| raw_ext_sharepoint | 2 | 180 quality records |
| raw_ext_sql_proficy | 2 | 2,000+ events |
| raw_ext_fabric_ppv | 2 | 716 PPV records |

**Quality Insights:**
- 180 quality records analyzed
- 53 rejected rolls (29.4% rejection rate)
- 96 hours total time lost
- Sheeter No.1 & No.2 = 87.7% of issues

**Visual:** Bar chart or infographic of entity counts

---

## Section 6: Roadmap & Wrap-up (6 min, 2 slides)

### Slide 19: Sprint 2 Progress & Roadmap

**Title:** What's Next

**Current Sprint (Feb 2-13):**
- Search experience enhancements (6/9 complete)
- Event/File/TimeSeries linking to Assets
- Location filter optimization

**Upcoming:**
- P&ID Contextualization
- Sumter plant onboarding
- MFG Extended model (WorkOrder, ProductionOrder, CostEvent)

**MFG Extended Model Preview:**
- WorkOrder, Notification, Operation (Maintenance)
- ProductionOrder, ProductionEvent (Production)
- Equipment entity (ISA Equipment)

**Visual:** Roadmap timeline or kanban board

---

### Slide 20: Summary & Q&A

**Title:** Key Takeaways

**Summary:**
1. **Standards-based** - ISA-95/88 aligned with CDM foundation
2. **Real data** - 365K+ nodes from production systems
3. **Use cases enabled** - Quality traceability, cost analysis
4. **Integrated pipeline** - 5 extractors, 24 transformations
5. **CI/CD ready** - Automated deployment with cdf-tk

**Resources:**
- GitHub: [sylvamo-project-documentation](https://github.com/fbarsoba-cognite/sylvamo-project-documentation)
- CDF Fusion: sylvamo-dev project
- Documentation: `/docs/reference/`

**Q&A:** Open floor for questions

**Visual:** Summary icons or bullet points with contact info

---

## Appendix: Backup Slides

### Backup A: Complete Traceability Query

**Title:** End-to-End Traceability in One Query

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

**Key Point:** One query traverses: Roll → Reel → Equipment → Asset → Package → Plants

---

### Backup B: Transformation Mapping

**Title:** RAW to Data Model Mapping

| RAW Table | Target Entity | Key Transformations |
|-----------|---------------|---------------------|
| raw_ext_fabric_ppr.ppr_hist_reel | Reel | Weight, dimensions, production date |
| raw_ext_fabric_ppr.ppr_hist_roll | Roll | Width, diameter, parent reel link |
| raw_ext_fabric_ppr.ppr_hist_package | Package | Source/destination plant, status |
| raw_ext_fabric_ppv.ppv_snapshot | MaterialCostVariance | PPV calculations, material type |
| raw_ext_fabric_sapecc.sapecc_work_orders | Event (WorkOrder) | Functional location → asset |
| raw_ext_sap.sap_floc_eastover | Asset | SAP hierarchy, 9 levels |
| raw_ext_sharepoint.roll_quality | RollQuality | Test results, isInSpec |
| _cdf.timeseries (PI) | MfgTimeSeries | Unit, description, asset link |

**Total:** 24 SQL transformations across 3 toolkit modules

---

### Backup C: Johan Stabekk Quotes

**Title:** Expert Guidance on ISA Alignment

**On Simplicity:**
> "We don't want to over complicate it but we don't want to make it so simple that we sit with something that doesn't give them anything."

**On Hierarchy:**
> "We want an **asset type** and we want an **equipment type** and these two basically. That's over complicating it [to use full ISA hierarchy]."

**On Reel = Batch:**
> "A batch here is a reel and an extension of that batch is a roll."

**On Inter-plant Tracking:**
> "At IP we are inside of the four walls of a production plant. Here we're going to go **between two production plants**."

---

### Backup D: PPV Analysis Deep Dive

**Title:** Material Cost Variance Details

**Summary Statistics:**
- Total Materials Tracked: 176
- Materials with Non-Zero PPV: 21
- Net PPV: -$118,151.12 (Favorable)

**By Material Type:**
| Type | Count | Total PPV | Interpretation |
|------|-------|-----------|----------------|
| FIBR | 7 | -$104,342 | Favorable (wood/fiber) |
| RAWM | 61 | -$23,063 | Favorable (chemicals) |
| PKNG | 102 | +$9,254 | Unfavorable (packaging) |
| PRD1 | 6 | $0.00 | Neutral |

**Top Impact Materials:**
1. WOOD, SOFTWOOD: -$72,631
2. CHIPS, MIXED HARDWOOD: -$24,802
3. CAUSTIC SODA: -$22,095

---

### Backup E: Quality Defect Analysis

**Title:** Quality Results Deep Dive

> *Verified: February 16, 2026*

**Quality Summary:**
| Metric | Value |
|--------|-------|
| Total Records | 180 |
| Rejected Rolls | 53 |
| Rejection Rate | 29.4% |
| Total Time Lost | 5,761 minutes (96 hours) |

**Complete Defect Distribution:**
| Defect | Count | % of Total |
|--------|-------|------------|
| 006 - Curl | 41 | 22.8% |
| 001 - Baggy Edges | 15 | 8.3% |
| Side to side up curl | 13 | 7.2% |
| 176 - Mill Wrinkles | 9 | 5.0% |
| 159 - Wobbly Roll | 8 | 4.4% |
| Run ability issues | 6 | 3.3% |
| Collating box jams | 6 | 3.3% |
| Soft spots, baggy edge | 6 | 3.3% |
| Other | 76 | 42.2% |

**Equipment Analysis:**
| Equipment | Incidents | Time Lost | Top Defect |
|-----------|-----------|-----------|------------|
| Sheeter No.1 | 107 (59.4%) | ~3,000 min | Curl (18) |
| Sheeter No.2 | 51 (28.3%) | 2,781 min | Curl (23) |
| Roll Prep | 16 (8.9%) | - | - |
| Sheeter No.3 | 5 (2.8%) | - | Baggy Edges |

**Business Insight:** Curl defects on Sheeter No.1 and No.2 account for 41 of 180 total defects (22.8%)

**Root Cause Focus:**
- Winding tension settings (curl pattern)
- Edge handling procedures (baggy edges)
- Equipment calibration (Sheeter No.2)

---

### Backup F: Search Experience Architecture

**Title:** How Relationships Enable Search

```
When user clicks Asset (PM1):
    ├── Events tab shows:
    │   └── WorkOrders linked via FUNCTIONAL_LOCATION
    │   └── Proficy Events linked via PU_Id
    │   └── PPV Events linked via plant code
    │
    ├── Files tab shows:
    │   └── P&IDs linked via assets property (CDM)
    │   └── Drawings linked via assets property
    │
    └── TimeSeries tab shows:
        └── PI tags linked via assets property (CDM)
        └── 1,695+ tags per paper machine
```

**Key:** All relationships use direct relation properties + reverse relations on Asset view

---

### Backup G: GitHub Documentation Index

**Title:** Documentation Resources

**Reference Documentation:**
| Document | Description |
|----------|-------------|
| [DATA_MODEL_SPECIFICATION.md](../../../reference/data-model/DATA_MODEL_SPECIFICATION.md) | Complete spec with all containers |
| [ARCHITECTURE_DECISIONS_AND_ROADMAP.md](../../../reference/data-model/ARCHITECTURE_DECISIONS_AND_ROADMAP.md) | ADRs and roadmap |
| [TRANSFORMATIONS.md](../../../reference/data-model/TRANSFORMATIONS.md) | 24 SQL transformations |
| [USE_CASES_AND_QUERIES.md](../../../reference/use-cases/USE_CASES_AND_QUERIES.md) | Verified queries with real data |
| [JOHAN_ISA95_GUIDANCE_SUMMARY.md](../../../reference/data-model/JOHAN_ISA95_GUIDANCE_SUMMARY.md) | Expert guidance summary |
| [EXTRACTORS.md](../../../reference/extractors/EXTRACTORS.md) | Extractor configurations |
| [DATA_MODEL_WALKTHROUGH.md](../../../reference/data-model/DATA_MODEL_WALKTHROUGH.md) | Step-by-step example |

**GitHub Repository:** https://github.com/fbarsoba-cognite/sylvamo-project-documentation

---

*Slides outline for Sylvamo CDF Data Model presentation*
