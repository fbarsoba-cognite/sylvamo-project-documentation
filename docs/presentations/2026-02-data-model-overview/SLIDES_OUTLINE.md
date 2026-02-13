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

**Model Evolution:**
| Stage | Model | Nodes | Status |
|-------|-------|-------|--------|
| PoC | sylvamo_mfg | 197 | Validated |
| Production | sylvamo_mfg_core | 450,000+ | Live |
| Extended | mfg_extended | TBD | In Progress |

**Current Production Model:**
| Component | Value |
|-----------|-------|
| Schema Space | sylvamo_mfg_core_schema |
| Instance Space | sylvamo_mfg_core_instances |
| Views | 8 (Asset, Event, Material, Reel, Roll, MfgTimeSeries, RollQuality, CogniteFile) |
| Containers | 7 (MfgAsset, MfgEvent, MfgReel, MfgRoll, MfgTimeSeries, Material, RollQuality) |
| Transformations | 24 automated SQL |
| Total Nodes | 450,000+ real production data |

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

**Real Production Data:**
| Metric | Value |
|--------|-------|
| Total Reels Tracked | 83,600+ |
| Total Reel Weight | 2,864,026 lbs |
| Average Reel Weight | 57,281 lbs |
| Quality Results | 21 (71% pass rate) |

**Defect Distribution (Real Data):**
- Crushed Edge: 2 occurrences
- Baggy Edge: 2 occurrences
- Up Curl: 2 occurrences

**Traceability Flow:**
1. Customer complaint about roll quality
2. Search for roll by roll number in CDF
3. Navigate to parent reel (relationship link)
4. View quality test results (isInSpec flag)
5. Check process conditions (3,532 linked time series)

**Key Insight:** What took 4 systems and manual correlation is now relationship navigation

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

**sylvamo_mfg_core Statistics (Live Data):**
| Entity | Count | Source | Notes |
|--------|-------|--------|-------|
| Asset | 44,898 | SAP Functional Locations | 9 hierarchy levels |
| Event | 92,000+ | SAP, Proficy, Fabric | WorkOrders, ProdOrders, ProficyEvents |
| Material | 58,342+ | SAP Materials | Full material master |
| MfgTimeSeries | 3,532 | PI Server | 75+ linked to assets |
| Reel | 83,600+ | Fabric PPR | 2.8M lbs total weight |
| Roll | 2,300,000+ | Fabric PPR | From RAW table rows |
| RollQuality | 21+ | SharePoint | 71% pass rate |
| CogniteFile | 97 | CDF Files | Linked to assets |
| Work Orders | 407,000 | SAP IW28 via Fabric | Maintenance history |
| **TOTAL** | **365,000+** | Real production data |

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

### Backup A: Detailed Container Properties

Full property list for each container (Asset, Reel, Roll, etc.)

### Backup B: Transformation Mapping

Complete RAW table → Data Model mapping table

### Backup C: GraphQL Query Examples

Additional query examples for advanced use cases

---

*Slides outline for Sylvamo CDF Data Model presentation*
