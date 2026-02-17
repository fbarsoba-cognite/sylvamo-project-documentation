> **Note:** These materials were prepared for the Sprint 2 demo (Feb 2026) and may contain outdated statistics. Verify current data in CDF.

# Actual Data Walkthrough - Step by Step

> **Last Updated:** February 16, 2026  
> **Data Source:** Live CDF queries to `sylvamo-dev` project

This document provides a step-by-step walkthrough of the actual data in CDF, explaining what each entity contains and how they connect.

---

## Step 1: Understanding the Data Model Architecture

The Sylvamo data model consists of two main layers:

### Layer 1: `sylvamo_mfg_core` (Core Manufacturing Model)

```
Spaces:
  ├── sylvamo_mfg_core_schema    → Contains views and containers
  └── sylvamo_mfg_core_instances → Contains actual data nodes
```

**Purpose:** Base manufacturing entities that map to CDM (Cognite Data Model) standards.

| View | CDM Parent | Description |
|------|------------|-------------|
| Asset | CogniteAsset | Plant hierarchy from SAP Functional Locations |
| Event | CogniteActivity | Production and maintenance events |
| Material | CogniteDescribable | SAP material master records |
| MfgTimeSeries | CogniteTimeSeries | PI Server time series metadata |
| Reel | CogniteDescribable | Paper reels (production batches) |
| Roll | CogniteDescribable | Individual rolls cut from reels |
| RollQuality | Custom | Quality test results from SharePoint |

### Layer 2: `sylvamo_mfg_extended` (ISA-95 Aligned Model)

```
Spaces:
  ├── sylvamo_mfg_ext_schema    → Extended views and containers
  └── sylvamo_mfg_ext_instances → Extended data nodes
```

**Purpose:** ISA-95/ISA-88 aligned entities for detailed manufacturing operations.

| View | ISA-95 Concept | Description |
|------|----------------|-------------|
| WorkOrder | Maintenance Request | SAP work orders (IW28) |
| MaintenanceActivity | Maintenance Activity | Linked activities |
| Notification | Maintenance Notification | SAP notifications |
| Operation | Maintenance Operation | Work order operations |
| ProductionOrder | Production Order | SAP production orders |
| ProductionEvent | Process Event | Proficy production events |
| CostEvent | Cost Variance | PPV cost snapshots |
| Equipment | Equipment | Plant equipment |

---

## Step 2: Data Sources and RAW Layer

### Source Systems

```
┌─────────────────────────────────────────────────────────────────┐
│                      SOURCE SYSTEMS                              │
├─────────────────────────────────────────────────────────────────┤
│  SAP ECC          │  Work orders, materials, functional locs     │
│  SAP PPR          │  Reels, rolls, packages                      │
│  SAP PPV          │  Cost variance snapshots                     │
│  PI Server        │  Process time series (3,864 tags)           │
│  Proficy          │  Production events, lab tests                │
│  SharePoint       │  Quality reports (180 records)               │
└─────────────────────────────────────────────────────────────────┘
```

### RAW Databases (Staging Layer)

**Database: `raw_ext_fabric_sapecc` (25 tables)**
Contains SAP ECC transactional data extracted via Microsoft Fabric.

| Table | Records | Description |
|-------|---------|-------------|
| sapecc_aufk | 2,000+ | Work order headers |
| sapecc_ibin | - | Bill of materials |
| sapecc_equz | - | Equipment assignments |
| sapecc_plfl | - | Production orders |
| sapecc_tvlkt | - | Vendor data |
| *(21 more)* | - | Various SAP tables |

**Database: `raw_ext_fabric_ppr` (18 tables)**
Contains Paper Production Recording system data.

| Table | Key Columns | Description |
|-------|-------------|-------------|
| ppr_hist_reel | REEL_ID, WEIGHT, DIMENSIONS | Production reels |
| ppr_hist_roll | ROLL_ID, PARENT_REEL, WIDTH | Cut rolls |
| *(16 more)* | - | Historical data |

**Database: `raw_ext_sharepoint` (2 tables)**
Contains quality reports from SharePoint.

| Table | Records | Description |
|-------|---------|-------------|
| roll_quality | 180 | Main quality tracking |
| roll_quality_excel | - | Excel-based reports |

**Database: `raw_ext_sql_proficy` (2 tables)**
Contains production event data from Proficy GBDB.

| Table | Records | Description |
|-------|---------|-------------|
| events_tests | 2,000+ | Production events with tests |
| tag_info | - | Tag metadata |

---

## Step 3: Core Model Data - Detailed Analysis

### 3.1 Asset Hierarchy (30,952 classic assets)

**Source:** SAP Functional Locations via OData extractor

```
Classic CDF Assets (30,952 total)
├── floc:0769-... (Eastover Mill)
│   ├── floc:0769-01-... (Area 01)
│   │   └── floc:0769-01-04-030-030 (HARDWOOD STACKING LOCKOUT ZONE 3)
│   ├── floc:0769-02-... (Area 02)
│   └── ...
├── floc:7825-... (Plant 7825)
└── ...
```

**Sample Assets:**
| External ID | Name |
|-------------|------|
| floc:0769-70-04-020-080-045 | WELDER, PORTABLE, FIBERS |
| floc:0769-05-04-020-060-800-020 | LEVEL, STEAM CONDENSATE FLASH TANK |
| floc:0769-02-01-010-010-800-015 | TEMPERATURE, CHIP BIN |
| floc:0769-04-01-010-020-040 | SYSTEM, #1LIME RECOAT FTR HI PSI PUMP |

### 3.2 Time Series (3,864 tags)

**Source:** PI Server via PI Extractor

All time series follow the naming convention: `pi:<tag_name>`

**Sample Time Series:**
| External ID | Name | Description |
|-------------|------|-------------|
| pi:471MR325 | 471MR325 | Process variable |
| pi:472CP658 | 472CP658 | Control point |
| pi:472BW259 | 472BW259 | Basis weight |
| pi:472CP391 | 472CP391 | Control point |

### 3.3 Roll Quality Data (180 records)

**Source:** SharePoint quality tracking list

This is the richest quality dataset in the model, providing real operational insights.

**Summary Statistics:**
| Metric | Value |
|--------|-------|
| Total Quality Records | 180 |
| Rejected Rolls | 53 |
| Rejection Rate | 29.4% |
| Total Time Lost | 5,761 minutes |
| Time Lost (Hours) | 96 hours |

**Top Defect Types:**
```
Defect Distribution (sorted by frequency)

006 - Curl                          ████████████████████ 41 (22.8%)
001 - Baggy Edges                   ███████ 15 (8.3%)
Side to side up curl                ██████ 13 (7.2%)
176 - Mill Wrinkles                 ████ 9 (5.0%)
159 - Wobbly Roll                   ████ 8 (4.4%)
Run ability issues, reduce speed    ███ 6 (3.3%)
Collating box jams                  ███ 6 (3.3%)
Soft spots, baggy edge              ███ 6 (3.3%)
Other                               █████████████████████████ 76 (42.2%)
```

**Equipment Analysis:**
```
Equipment with Most Quality Issues

Sheeter No.1    ████████████████████████████████████████ 107 (59.4%)
  └── Top defects: Curl (18), Side to side up curl (13), Wobbly Roll (8)

Sheeter No.2    ███████████████████ 51 (28.3%)
  └── Top defects: Curl (23), Baggy Edges (7), Collating jams (6)
  └── Time lost: 2,781 minutes (46.4 hours)

Roll Prep       ████ 16 (8.9%)
Sheeter No.3    ██ 5 (2.8%)
Middle          █ 1 (0.6%)
```

**Key Insight - Sheeter No.2 Analysis:**

Sheeter No.2 shows a pattern of "Curl" defects (23 occurrences) and "Baggy Edges" (7 occurrences). The total time lost for this equipment is 46.4 hours.

Example incident:
- **Date:** 2025-12-13
- **Defect:** Baggy edge causing major wrinkles
- **Time Lost:** 35 minutes
- **Description:** "001 - Baggy Edges"

---

## Step 4: Extended Model Data - ISA-95 Entities

### 4.1 Work Orders (1,000+ in model, 2,000+ in RAW)

**Source:** `raw_ext_fabric_sapecc.sapecc_work_orders`

Work orders represent maintenance activities tracked in SAP IW28.

**Distribution by Plant:**
| Plant Code | Work Orders | Description |
|------------|-------------|-------------|
| 7825 | 978 | Eastover Mill (primary) |
| MG01 | 313 | MG plant 01 |
| MG19 | 213 | MG plant 19 |
| 0769 | 132 | Additional plant |
| 8675 | 116 | Additional plant |
| FL43 | 100 | Additional plant |
| FL02 | 95 | Additional plant |
| 0010 | 30 | Additional plant |
| MG48 | 17 | Additional plant |
| 0519 | 6 | Additional plant |

**RAW Columns:**
- `AVAIL_BEF_MALFUNCTION` - Availability before failure
- `DESCRIPTION` - Work order description
- `EQUIPMENT` - Equipment reference
- `ABC_INDICATOR` - Priority indicator
- `FUNCTIONAL_LOCATION` - SAP functional location
- `CREATED_ON` - Creation date
- `NOTIFICATION_TYPE` - Notification type
- `USER_STATUS` - Current status
- `MAINTENANCE_PLANT` - Plant code

### 4.2 Cost Events (716 records)

**Source:** `raw_ext_fabric_ppv.ppv_snapshot`

Cost events track Purchase Price Variance (PPV) for materials.

**Data Structure:**
| Column | Description |
|--------|-------------|
| material | Material code |
| material_description | Material name |
| material_type | Type (FIBR, RAWM, PKNG, etc.) |
| current_standard_cost | Current cost |
| prior_standard_cost | Previous cost |
| current_ppv | Current PPV value |
| prior_ppv | Prior PPV value |
| plant | Plant code |
| ppv_snapshot_date | Snapshot timestamp |

**Current Summary:**
| Metric | Value |
|--------|-------|
| Total Materials | 716 |
| Total Current Standard Cost | $37,707.57 |
| Total Prior Standard Cost | $37,707.57 |
| Net Variance | $0.00 |

Note: Current snapshot shows no variance as costs are equal.

### 4.3 Production Events (1,000+ records)

**Source:** `raw_ext_sql_proficy.events_tests`

Production events from Proficy GBDB capture real-time production data.

**Data Structure:**
| Column | Description |
|--------|-------------|
| Var_Id | Variable identifier |
| Event_Num | Event sequence number |
| Productive_Start_Time | Production start |
| Productive_End_Time | Production end |
| PU_Id | Production unit ID |
| Result | Test result |
| event_id | Unique event ID |

---

## Step 5: Data Flow Pipeline

### Complete Pipeline Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                          SOURCE SYSTEMS                             │
├────────────────────────────────────────────────────────────────────┤
│  SAP ECC    │  PPR    │  PPV    │  PI    │  Proficy  │ SharePoint  │
└──────┬──────┴────┬────┴────┬────┴───┬────┴─────┬─────┴──────┬──────┘
       │           │         │        │          │            │
       ▼           ▼         ▼        ▼          ▼            ▼
┌────────────────────────────────────────────────────────────────────┐
│                          EXTRACTORS                                 │
├────────────────────────────────────────────────────────────────────┤
│ Fabric (x3) │  PI Extractor  │  SQL Extractor  │ SharePoint Ext.   │
└──────┬──────────────┬─────────────────┬────────────────────┬───────┘
       │              │                 │                    │
       ▼              ▼                 ▼                    ▼
┌────────────────────────────────────────────────────────────────────┐
│                          CDF RAW LAYER                              │
├────────────────────────────────────────────────────────────────────┤
│ raw_ext_fabric_sapecc (25)  │ raw_ext_pi (2)       │               │
│ raw_ext_fabric_ppr (18)     │ raw_ext_sql_proficy (2)              │
│ raw_ext_fabric_ppv (2)      │ raw_ext_sharepoint (2)               │
└──────────────────────────────────┬─────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│                       TRANSFORMATIONS (SQL)                         │
├────────────────────────────────────────────────────────────────────┤
│  24+ SQL transformations running on schedule                        │
│  - Asset transformation (SAP FLOC → Asset view)                    │
│  - Reel transformation (PPR → Reel view)                           │
│  - WorkOrder transformation (SAPECC → WorkOrder view)              │
│  - etc.                                                             │
└──────────────────────────────────┬─────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│                         DATA MODEL                                  │
├────────────────────────────────────────────────────────────────────┤
│  sylvamo_mfg_core_schema/instances                                 │
│  ├── Asset (1,000+)                                                │
│  ├── Event (1,000+)                                                │
│  ├── Material (1,000+)                                             │
│  ├── Reel (1,000+)                                                 │
│  ├── Roll (1,000+)                                                 │
│  └── RollQuality (580)                                             │
│                                                                     │
│  sylvamo_mfg_ext_schema/instances                                  │
│  ├── WorkOrder (1,000+)                                            │
│  ├── MaintenanceActivity (1,000+)                                  │
│  ├── ProductionOrder (1,000+)                                      │
│  ├── ProductionEvent (1,000+)                                      │
│  └── CostEvent (716)                                               │
└────────────────────────────────────────────────────────────────────┘
```

---

## Step 6: How the Data Model Enables These Discoveries

> **Key Point:** These findings were only possible BECAUSE of the connected data model. Without it, this analysis would require manual correlation across 5+ systems.

### Discovery 1: Quality Pattern Identification

**The Finding:**
- Sheeter No.1 and No.2 account for 87.7% of all quality issues
- Curl defects (code 006) represent 22.8% of all defects
- Total time lost: 96 hours across 180 quality events

**How the Data Model Enabled This:**

```
┌─────────────────────────────────────────────────────────────────┐
│  DATA MODEL STRUCTURE THAT MADE THIS POSSIBLE                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   RollQuality (View)                                           │
│   ├── equipment (property) ──────────► Links to Equipment      │
│   ├── defectCode (property) ─────────► "006 - Curl"           │
│   ├── minutesLost (property) ────────► 35 minutes             │
│   └── isRejected (property) ─────────► true/false             │
│                                                                 │
│   Equipment → Asset (relationship) ──► "Sheeter No.2"         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

| Data Model Component | Property/Relationship | What It Enabled |
|---------------------|----------------------|-----------------|
| `RollQuality` view | `equipment` property | Group defects by equipment |
| `RollQuality` view | `defectCode` property | Categorize defect types |
| `RollQuality` view | `minutesLost` property | Calculate total time lost |
| `RollQuality` → `Asset` | Direct relation | Link quality to plant hierarchy |

**Without the Data Model:**
- Quality data in SharePoint (isolated)
- Equipment data in SAP (separate system)
- No automated correlation possible
- Manual lookup required for each quality event

**With the Data Model:**
- Single query returns quality + equipment + time lost
- Automatic aggregation by equipment
- Pattern detection in seconds, not hours

**The Query That Found This:**
```graphql
{
  listRollQuality(limit: 500) {
    items {
      equipment        # ← Property links to equipment
      defectCode       # ← Defect categorization
      minutesLost      # ← Time impact
      isRejected       # ← Outcome
    }
  }
}
```

---

### Discovery 2: Multi-Plant Work Order Visibility

**The Finding:**
- Plant 7825 (Eastover) has 48.9% of all work orders
- 10 plants represented in work order data
- Work orders link to functional locations (equipment)

**How the Data Model Enabled This:**

```
┌─────────────────────────────────────────────────────────────────┐
│  DATA MODEL STRUCTURE THAT MADE THIS POSSIBLE                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   WorkOrder (View) - ISA-95 aligned                            │
│   ├── plant (property) ──────────────► "7825" (Eastover)       │
│   ├── functionalLocation (property) ─► SAP FLOC reference      │
│   ├── equipment (property) ──────────► Equipment reference     │
│   └── asset (relationship) ──────────► Asset hierarchy         │
│                                                                 │
│   Asset (View) - CDM CogniteAsset                              │
│   ├── workOrders (reverse relation) ─► All work orders here   │
│   └── parent/children ───────────────► Plant hierarchy         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

| Data Model Component | Property/Relationship | What It Enabled |
|---------------------|----------------------|-----------------|
| `WorkOrder` view | `plant` property | Filter/group by plant |
| `WorkOrder` view | `functionalLocation` | Link to asset hierarchy |
| `WorkOrder` → `Asset` | Direct relation | Navigate to equipment context |
| `Asset` view | `workOrders` reverse relation | See all WOs for an asset |

**Without the Data Model:**
- Work orders in SAP ECC (IW28)
- Asset hierarchy in separate SAP module
- Plant comparisons require manual data export
- No cross-plant visibility

**With the Data Model:**
- Query work orders across all plants at once
- Filter by plant, equipment type, date range
- Compare maintenance patterns plant-to-plant
- Navigate from work order → asset → plant hierarchy

**The Query That Found This:**
```graphql
{
  listWorkOrder(limit: 1000) {
    items {
      plant             # ← Group by plant
      description       # ← Work order details
      asset {           # ← Navigate to asset
        name
        parent { name } # ← Plant hierarchy
      }
    }
  }
}
```

---

### Discovery 3: Cost-to-Production Traceability

**The Finding:**
- 716 materials tracked for PPV (Purchase Price Variance)
- Full cost visibility from SAP
- Material type categorization (FIBR, RAWM, PKNG)

**How the Data Model Enabled This:**

```
┌─────────────────────────────────────────────────────────────────┐
│  DATA MODEL STRUCTURE THAT MADE THIS POSSIBLE                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   CostEvent (View) - Extended Model                            │
│   ├── material (relationship) ───────► Material view           │
│   ├── currentStandardCost (property) ► $3.86                   │
│   ├── priorStandardCost (property) ──► $3.86                   │
│   └── ppv (property) ────────────────► Variance amount         │
│                                                                 │
│   Material (View) - Core Model                                 │
│   ├── materialType (property) ───────► "FIBR", "RAWM", "PKNG" │
│   ├── description (property) ────────► Material name           │
│   └── reels (reverse relation) ──────► Production batches     │
│                                                                 │
│   Reel (View) - Core Model                                     │
│   └── material (relationship) ───────► What material was used │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

| Data Model Component | Property/Relationship | What It Enabled |
|---------------------|----------------------|-----------------|
| `CostEvent` view | `material` relation | Link cost to material |
| `CostEvent` view | `ppv` property | Track variance |
| `Material` view | `materialType` property | Categorize materials |
| `Material` → `Reel` | Reverse relation | See which reels used this material |

**Without the Data Model:**
- PPV data in SAP Finance module
- Material data in SAP Materials Management
- Production data in PPR system
- No link between cost variance and production

**With the Data Model:**
- Query: "Which reels used materials with cost increases?"
- Track cost impact from raw material to finished product
- Identify production batches affected by price changes

**The Query That Found This:**
```graphql
{
  listCostEvent(filter: { ppv: { gt: 100 }}) {
    items {
      ppv
      material {
        description
        materialType
        reels { items { reelNumber, productionDate } }
      }
    }
  }
}
```

---

### Summary: Data Model Value Proposition

| Discovery | Data Sources Unified | Without Model | With Model |
|-----------|---------------------|---------------|------------|
| Quality Patterns | SharePoint + SAP | Hours of manual correlation | 1 query, seconds |
| Plant Comparison | SAP ECC (multiple plants) | Separate exports per plant | Single cross-plant query |
| Cost Traceability | SAP FI + SAP MM + PPR | Impossible to link | Direct relationship navigation |

**The Core Value:**
```
┌────────────────────────────────────────────────────────────────────┐
│  BEFORE: 5 Disconnected Systems                                    │
│                                                                     │
│   SharePoint ──╳── SAP ECC ──╳── PPR ──╳── PI ──╳── Proficy       │
│                                                                     │
│   Manual correlation required for any cross-system analysis        │
├────────────────────────────────────────────────────────────────────┤
│  AFTER: 1 Connected Data Model                                     │
│                                                                     │
│   RollQuality ───► Asset ───► WorkOrder                           │
│        │                │                                          │
│        ▼                ▼                                          │
│      Roll ───────► Reel ───────► Material ───────► CostEvent      │
│                      │                                             │
│                      ▼                                             │
│              MfgTimeSeries (3,864 PI tags)                        │
│                                                                     │
│   Any insight is ONE QUERY away                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## Step 7: Relationships and Navigation

### Asset → Equipment → Time Series

```graphql
{
  listAsset(filter: { name: { contains: "PM1" }}) {
    items {
      externalId
      name
      timeseries { items { externalId, name } }
    }
  }
}
```

### Roll → Reel → Quality

```graphql
{
  listRoll(filter: { rollNumber: { equals: "EME13B08061N" }}) {
    items {
      rollNumber
      width
      reel {
        reelNumber
        productionDate
        qualityResults { items { isInSpec, defectCode } }
      }
    }
  }
}
```

### Work Order → Asset → Plant

```graphql
{
  listWorkOrder(filter: { plant: { equals: "7825" }}) {
    items {
      externalId
      description
      asset { name, functionalLocation }
    }
  }
}
```

---

## Summary

| Category | Count | Status |
|----------|-------|--------|
| Data Model Spaces | 4 | Active |
| RAW Databases | 7 | Active |
| RAW Tables | 50+ | Active |
| Core Model Views | 7 | Populated |
| Extended Model Views | 8 | Partially Populated |
| Classic Assets | 30,952 | Active |
| Time Series | 3,864 | Active |
| Quality Records | 180 | Active |
| Work Orders (RAW) | 2,000+ | Active |
| PPV Records | 716 | Active |

**Key Takeaways:**
1. The data model is operational with real production data
2. Quality tracking reveals actionable insights (Sheeter patterns)
3. Multi-plant visibility is enabled through work orders
4. ISA-95 alignment provides standardized structure
5. Relationships enable drill-down analysis

---

*Document generated from live CDF queries - February 16, 2026*
