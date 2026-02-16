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

## Step 6: Business Value Demonstration

### Discovery 1: Quality Pattern Identification

**What the Data Shows:**
- Sheeter No.1 and No.2 account for 87.7% of all quality issues
- Curl defects (code 006) represent 22.8% of all defects
- Total time lost: 96 hours across 180 quality events

**Business Impact:**
- Focus maintenance efforts on Sheeter No.1 and No.2
- Investigate curl defect root cause (potential winding tension issue)
- Estimated potential savings: 96 hours × $X/hour productivity

### Discovery 2: Multi-Plant Work Order Visibility

**What the Data Shows:**
- Plant 7825 (Eastover) has 48.9% of all work orders
- 10 plants represented in work order data
- Work orders link to functional locations (equipment)

**Business Impact:**
- Compare maintenance practices across plants
- Identify high-maintenance equipment
- Plan preventive maintenance based on patterns

### Discovery 3: Cost Tracking Foundation

**What the Data Shows:**
- 716 materials tracked for PPV
- Full cost visibility from SAP
- Material type categorization (FIBR, RAWM, PKNG)

**Business Impact:**
- Track purchase price variance over time
- Identify cost-saving opportunities
- Link material costs to production batches

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
