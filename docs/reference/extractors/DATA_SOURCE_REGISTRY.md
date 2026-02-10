# Sylvamo Data Source Registry & Pipeline Tracker

> **Purpose:** Single source of truth for tracking all data flowing into CDF — from source systems through extractors, RAW tables, transformations, and into the data model.
> **Audience:** Cognite team + Sylvamo stakeholders (Cam, Valmir)
> **Last Updated:** 2026-02-10
> **Jira Ticket:** [SVQS-160](https://cognitedata.atlassian.net/browse/SVQS-160)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Source Systems Summary](#2-source-systems-summary)
3. [Full Pipeline Mapping](#3-full-pipeline-mapping)
4. [Data Model Summary](#4-data-model-summary)
5. [Gap Analysis](#5-gap-analysis)
6. [Validation Checklist](#6-validation-checklist)
7. [Open Questions & Action Items](#7-open-questions--action-items)

---

## 1. Architecture Overview

```
┌─────────────────────┐     ┌──────────────┐     ┌──────────────┐     ┌────────────────────┐     ┌─────────────────────┐
│   SOURCE SYSTEMS    │────▶│  EXTRACTORS  │────▶│  RAW TABLES  │────▶│  TRANSFORMATIONS   │────▶│   DATA MODEL VIEWS  │
│                     │     │              │     │              │     │                    │     │                     │
│ • Fabric (PPR/PPV)  │     │ • fabric-*   │     │ raw_ext_*    │     │ • populate_*       │     │ sylvamo_mfg_core    │
│ • SAP Gateway       │     │ • sap-odata  │     │              │     │ • create_*         │     │ sylvamo_mfg_ext     │
│ • Proficy GBDB      │     │ • sql-ext    │     │              │     │                    │     │ sylvamo_mfg (v10)   │
│ • PI Servers        │     │ • pi-ext     │     │              │     │                    │     │                     │
│ • SharePoint        │     │ • sp-ext     │     │              │     │                    │     │                     │
└─────────────────────┘     └──────────────┘     └──────────────┘     └────────────────────┘     └─────────────────────┘
```

---

## 2. Source Systems Summary

| # | Source System | System Type | Extractor Name | Extractor Status | RAW Database | Notes |
|---|--------------|-------------|----------------|------------------|--------------|-------|
| 1 | Microsoft Fabric (PPR) | Lakehouse | `fabric-connector-ppr` | ✅ Running | `raw_ext_fabric_ppr` | Production/paper reel & roll data |
| 2 | Microsoft Fabric (PPV) | Lakehouse | `fabric-connector-ppv` | ✅ Running | `raw_ext_fabric_ppv` | Cost/financial variance data |
| 3 | SAP Gateway | ERP (via Fabric) | `sap-odata-extractor` | ✅ Running | `raw_ext_sap` | Asset hierarchy, materials, orders |
| 4 | Proficy GBDB | Historian DB | `sql-extractor-proficy` | ✅ Running | `raw_ext_sql_proficy` | Lab tests, production events, tag metadata |
| 5 | PI Server (Eastover) | Historian | `pi-extractor-eastover` | ✅ Running | `raw_ext_pi` | Time series - Eastover mill |
| 6 | PI Server (PM) | Historian | `pi-extractor-pm` | ✅ Running | `raw_ext_pi` | Time series - PM tags |
| 7 | PI Server (S519) | Historian | `pi-extractor-s519` | ✅ Running | `raw_ext_pi` | Time series - Sumter? (needs confirmation) |
| 8 | SharePoint Online | Document Mgmt | `sharepoint-extractor` | ✅ Running | `raw_ext_sharepoint` | Shift reports, SOPs, roll quality |
| 9 | Microsoft Fabric (SAP ECC) | Lakehouse | `fabric-connector-sapecc` | 🔲 Planned | `raw_ext_fabric_sapecc` | Work orders from SAP ECC |

---

## 3. Full Pipeline Mapping

### Legend
- ✅ = Complete and working
- 🔶 = Partial / needs validation
- ❌ = Missing / not implemented
- 🔲 = Planned / not started
- ❓ = Unknown / needs investigation

---

### 3.1 Microsoft Fabric — PPR (Production/Paper Records)

| RAW Table | Description | Transformation | Target View(s) | Pipeline Status | Data Validation | Notes |
|-----------|-------------|----------------|-----------------|-----------------|-----------------|-------|
| `ppr_hist_reel` | Reel production data (ISA-95 Batch) | `populate_Reel` | `Reel` (mfg_core) | ✅ End-to-end | 🔶 Validate counts | Core production data |
| `ppr_hist_roll` | Roll data (ISA-95 MaterialLot) | `populate_Roll` | `Roll` (mfg_core) | ✅ End-to-end | 🔶 Validate counts | Core production data |
| `ppr_hist_package` | Package/packaging data | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | **GAP:** No Package view in mfg_core, but `mfg_data` has Package view |
| `ppr_hist_roll_quality` | Roll quality from PPR | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Uses SharePoint `roll_quality` instead? Clarify source-of-truth |
| `ppr_hist_blend` | Blend/recipe data | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Could map to `Recipe` in mfg_data? |
| `ppr_hist_material` | Material data from PPR | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Overlaps with SAP `materials`? |
| `ppr_hist_order_item` | Order item details | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Relates to production orders? |
| `ppr_production_total` | Production totals/aggregates | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Aggregate reporting data |
| `ppr_mill` | Mill reference data | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Reference/dimension table |

**Summary:** Only 2 of 9 PPR tables have full pipeline coverage. 7 tables are extracted but not yet consumed by transformations.

---

### 3.2 Microsoft Fabric — PPV (Cost/Financial Variance)

| RAW Table | Description | Transformation | Target View(s) | Pipeline Status | Data Validation | Notes |
|-----------|-------------|----------------|-----------------|-----------------|-----------------|-------|
| `ppv_snapshot` | Material cost variance | `populate_Event_PPV` (mfg_core) | `Event` (mfg_core) | ✅ End-to-end | 🔶 Validate counts | Financial data |
| | | `populate_CostEvent` (mfg_ext) | `CostEvent` (mfg_ext) | ✅ End-to-end | 🔶 Validate counts | Extended view |

**Summary:** Full coverage — single table, mapped to both core and extended models.

---

### 3.3 SAP Gateway (via Fabric / OData)

| RAW Table | Description | Transformation | Target View(s) | Pipeline Status | Data Validation | Notes |
|-----------|-------------|----------------|-----------------|-----------------|-----------------|-------|
| `asset_hierarchy` | SAP FLOCs (asset tree) | `populate_Asset` | `Asset` (mfg_core) | ✅ End-to-end | 🔶 Validate counts | **Note:** Transformation uses `sap_floc_eastover` + `sap_floc_sumter` — verify RAW table name mapping |
| `materials` | Material master data | `populate_Material` | `Material` (mfg_core) | ✅ End-to-end | 🔶 Validate counts | Material codes & descriptions |
| `work_orders` | Maintenance work orders | ❌ None from this table | ❌ | 🔶 Extractor only | ❓ | **Note:** `populate_Event_WorkOrders` reads from `raw_ext_fabric_sapecc.sapecc_work_orders` (different source!) |
| `production_orders` | Production orders | `populate_Event_ProductionOrders` (mfg_core) | `Event` (mfg_core) | ✅ End-to-end | 🔶 Validate counts | |
| | | `populate_ProductionOrder` (mfg_ext) | `ProductionOrder` (mfg_ext) | ✅ End-to-end | 🔶 Validate counts | Extended view |
| `bp_details` | Business partner details | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Vendor/customer data? |

**Key Issue:** `work_orders` from `raw_ext_sap` is extracted but transformations read from `raw_ext_fabric_sapecc.sapecc_work_orders`. Which is the correct source? Is the SAP extractor version deprecated?

---

### 3.4 Proficy GBDB (SQL Server Historian)

| RAW Table | Description | Transformation | Target View(s) | Pipeline Status | Data Validation | Notes |
|-----------|-------------|----------------|-----------------|-----------------|-----------------|-------|
| `events_tests` | Production events + test results | `populate_Event_Proficy` (mfg_core) | `Event` (mfg_core) | ✅ End-to-end | 🔶 Validate counts | |
| | | `populate_ProductionEvent` (mfg_ext) | `ProductionEvent` (mfg_ext) | ✅ End-to-end | 🔶 Validate counts | Extended view |
| | | `populate_ProficyDatapoints` | Time Series Datapoints | ✅ End-to-end | 🔶 | Readings as TS datapoints |
| `tag_info` | Tag/sensor metadata | `create_ProficyTimeSeries_CDF` | CDF Time Series | ✅ End-to-end | 🔶 | Creates CDF TS resources |
| | | `populate_ProficyTimeSeries` | `MfgTimeSeries` (mfg_core) | ✅ End-to-end | 🔶 | Into data model view |
| `tests` | Test definitions | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Reference data for events_tests? |
| `samples` | Sample data | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Could map to `LabTest` in mfg_data? |
| `key_columns` | Key column definitions | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Metadata/reference |
| `event_tables` | Event table definitions | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Metadata/reference |
| `all_tables` | All table definitions | ❌ No transformation | ❌ No target view | 🔶 Extractor only | ❓ | Metadata/reference |

**Summary:** Core event/TS data has full coverage. Reference tables (`tests`, `samples`, `key_columns`, `event_tables`, `all_tables`) are extracted but not yet consumed.

---

### 3.5 PI Servers (Time Series Historians)

| RAW Table | Source PI Server | Description | Transformation | Pipeline Status | Data Validation | Notes |
|-----------|-----------------|-------------|----------------|-----------------|-----------------|-------|
| `s769pi01_metadata` | S769PI01 (Eastover) | PI tag metadata | `populate_TimeSeries` (generic) | 🔶 Partial | ❓ Investigate | "Not relevant data?" — needs review |
| `s769pi03_metadata` | S769PI03 (PM) | PI tag metadata | `populate_TimeSeries` (generic) | 🔶 Partial | ❓ Investigate | "Not relevant data?" — needs review |
| `s519pip1_metadata` | S519PIP1 | PI tag metadata | `populate_TimeSeries` (generic) | 🔶 Partial | ❓ Investigate | **Is this Sumter?** Missing data? |
| *(TS data)* | S769PI01 | Actual time series values | Direct to CDF Time Series | ✅ Via PI extractor | 🔶 | Tags: digesters, washing, O2, bleach |
| *(TS data)* | S519PIP1 | Sheeters time series | Direct to CDF Time Series | ✅ Via PI extractor | 🔶 | Tags: sheeters |

**Note:** PI extractors push time series data directly to CDF (not via RAW). The `_metadata` RAW tables contain tag metadata only. The `populate_TimeSeries` transformation maps CDF TS into the data model.

---

### 3.6 SharePoint Online

| RAW Table | Description | Transformation | Target View(s) | Pipeline Status | Data Validation | Notes |
|-----------|-------------|----------------|-----------------|-----------------|-----------------|-------|
| `documents` | SharePoint documents | `populate_Files` (reads `_cdf.files`) | `CogniteFile` (CDM) | 🔶 Indirect | ❓ | Extractor → CDF Files → Transform reads `_cdf.files`, not RAW directly. Marked as "duplicate" — clarify |
| `roll_quality` | Roll quality reports | `populate_RollQuality` | `RollQuality` (mfg_core) | ✅ End-to-end | 🔶 Validate counts | Overlaps with `ppr_hist_roll_quality`? |

---

### 3.7 Microsoft Fabric — SAP ECC (Planned)

| RAW Table | Description | Transformation | Target View(s) | Pipeline Status | Data Validation | Notes |
|-----------|-------------|----------------|-----------------|-----------------|-----------------|-------|
| `sapecc_work_orders` | SAP IW28 work orders | `populate_Event_WorkOrders` (mfg_core) | `Event` (mfg_core) | 🔲 Planned | ❌ | Transformation exists but extractor not running |
| | | `populate_WorkOrder` (mfg_ext) | `WorkOrder` (mfg_ext) | 🔲 Planned | ❌ | Extended view |

**Dependency:** Multiple transformations already reference `raw_ext_fabric_sapecc.sapecc_work_orders` — this extractor needs to be prioritized.

---

## 4. Data Model Summary

### 4.1 Model Hierarchy

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     sylvamo_mfg_core (SylvamoMfgCore v1)                │
│  Schema: sylvamo_mfg_core_schema | Instances: sylvamo_mfg_core_instances│
│                                                                          │
│  Views: Asset, Event, Material, Reel, Roll, RollQuality,               │
│         MfgTimeSeries, CogniteFile                                      │
└───────────────────────────────┬──────────────────────────────────────────┘
                                │ extends
┌───────────────────────────────▼──────────────────────────────────────────┐
│                   sylvamo_mfg_extended (v1)                              │
│  Schema: sylvamo_mfg_ext_schema | Instances: sylvamo_mfg_ext_instances  │
│                                                                          │
│  Views: WorkOrder, ProductionOrder, ProductionEvent, CostEvent,         │
│         Equipment, MaintenanceActivity, Notification, Operation         │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                   sylvamo_mfg (sylvamo_manufacturing v10)               │
│  Space: sylvamo_mfg                                                      │
│                                                                          │
│  Views: Asset, Equipment, Reel, Roll, Package, Recipe,                  │
│         ProductDefinition, QualityResult, LabTest,                      │
│         MaterialCostVariance, Measurement, ManufacturingEvent,          │
│         SylvamoAsset, SylvamoEquipment, SylvamoTimeSeries,             │
│         SylvamoActivity                                                  │
└──────────────────────────────────────────────────────────────────────────┘
```

### 4.2 View-to-Data-Source Mapping

| Data Model | View | Populated By | Source RAW | Status |
|------------|------|-------------|------------|--------|
| mfg_core | Asset | `populate_Asset` | `raw_ext_sap` (sap_floc_*) | ✅ |
| mfg_core | Material | `populate_Material` | `raw_ext_sap.materials` | ✅ |
| mfg_core | Reel | `populate_Reel` | `raw_ext_fabric_ppr.ppr_hist_reel` | ✅ |
| mfg_core | Roll | `populate_Roll` | `raw_ext_fabric_ppr.ppr_hist_roll` | ✅ |
| mfg_core | RollQuality | `populate_RollQuality` | `raw_ext_sharepoint.roll_quality` | ✅ |
| mfg_core | Event | `populate_Event_Proficy` | `raw_ext_sql_proficy.events_tests` | ✅ |
| mfg_core | Event | `populate_Event_WorkOrders` | `raw_ext_fabric_sapecc.sapecc_work_orders` | 🔲 (extractor planned) |
| mfg_core | Event | `populate_Event_ProductionOrders` | `raw_ext_sap.production_orders` | ✅ |
| mfg_core | Event | `populate_Event_PPV` | `raw_ext_fabric_ppv.ppv_snapshot` | ✅ |
| mfg_core | MfgTimeSeries | `populate_TimeSeries` + `populate_Proficy*` | `_cdf.timeseries` + proficy | ✅ |
| mfg_core | CogniteFile | `populate_Files` | `_cdf.files` | ✅ |
| mfg_ext | WorkOrder | `populate_WorkOrder` | `raw_ext_fabric_sapecc.sapecc_work_orders` | 🔲 |
| mfg_ext | ProductionOrder | `populate_ProductionOrder` | `raw_ext_sap.production_orders` | ✅ |
| mfg_ext | ProductionEvent | `populate_ProductionEvent` | `raw_ext_sql_proficy.events_tests` | ✅ |
| mfg_ext | CostEvent | `populate_CostEvent` | `raw_ext_fabric_ppv.ppv_snapshot` | ✅ |
| mfg_ext | Equipment | ❌ No transformation | ❌ No source identified | ❌ |
| mfg_ext | MaintenanceActivity | ❌ No transformation | ❌ No source identified | ❌ |
| mfg_ext | Notification | ❌ No transformation | ❌ Valmir to provide | ❌ |
| mfg_ext | Operation | ❌ No transformation | ❌ Available but not wired | ❌ |

---

## 5. Gap Analysis

### 5.1 RAW Tables Without Transformations (Extracted but unused)

| # | RAW Database | RAW Table | Potential Target | Action Required |
|---|-------------|-----------|-----------------|-----------------|
| 1 | `raw_ext_fabric_ppr` | `ppr_hist_package` | `Package` (mfg_data) | Create transformation for Package view |
| 2 | `raw_ext_fabric_ppr` | `ppr_hist_roll_quality` | `RollQuality` or `QualityResult` | Clarify: use this or SharePoint `roll_quality`? |
| 3 | `raw_ext_fabric_ppr` | `ppr_hist_blend` | `Recipe` (mfg_data) | Evaluate if blend = recipe |
| 4 | `raw_ext_fabric_ppr` | `ppr_hist_material` | `Material` (mfg_core) | Overlaps with SAP materials — define source-of-truth |
| 5 | `raw_ext_fabric_ppr` | `ppr_hist_order_item` | `ProductionOrder`? | Map to existing or new view |
| 6 | `raw_ext_fabric_ppr` | `ppr_production_total` | Reporting / aggregates | Determine if needed in model |
| 7 | `raw_ext_fabric_ppr` | `ppr_mill` | Reference data | Mill dimension table — needed for lookups? |
| 8 | `raw_ext_sap` | `work_orders` | `WorkOrder` (mfg_ext) | Replaced by `sapecc_work_orders`? Clarify |
| 9 | `raw_ext_sap` | `bp_details` | ❓ | Business partner — is this needed? |
| 10 | `raw_ext_sql_proficy` | `tests` | Reference for events_tests | Needed for lab test definitions? |
| 11 | `raw_ext_sql_proficy` | `samples` | `LabTest` (mfg_data) | Evaluate mapping |
| 12 | `raw_ext_sql_proficy` | `key_columns` | Internal metadata | Likely not needed in model |
| 13 | `raw_ext_sql_proficy` | `event_tables` | Internal metadata | Likely not needed in model |
| 14 | `raw_ext_sql_proficy` | `all_tables` | Internal metadata | Likely not needed in model |

### 5.2 Data Model Views Without Data Sources

| # | Data Model | View | Required Data Source | Status | Owner |
|---|-----------|------|---------------------|--------|-------|
| 1 | mfg_ext | Equipment | SAP equipment master | ❌ No source | Valmir/Cam |
| 2 | mfg_ext | MaintenanceActivity | SAP PM data | ❌ No source | Valmir/Cam |
| 3 | mfg_ext | Notification | SAP IW29 (or similar) | ❌ No source | Valmir to provide |
| 4 | mfg_ext | Operation | SAP AFVC (available) | ❌ Not wired | Needs transformation |
| 5 | mfg_data | Package | `ppr_hist_package` (available) | 🔶 Needs transformation | Cognite team |
| 6 | mfg_data | Recipe | `ppr_hist_blend`? | ❓ Needs mapping | Clarify with Sylvamo |
| 7 | mfg_data | ProductDefinition | ❓ | ❌ Unknown source | Clarify with Sylvamo |
| 8 | mfg_data | QualityResult | `ppr_hist_roll_quality` or `samples`? | ❓ Needs mapping | Clarify source |
| 9 | mfg_data | LabTest | `raw_ext_sql_proficy.samples`? | ❓ Needs mapping | Clarify with Sylvamo |
| 10 | mfg_data | Measurement | ❓ | ❌ Unknown source | Clarify with Sylvamo |
| 11 | mfg_data | ManufacturingEvent | Multiple sources? | ❓ Relationship to Event | Clarify with Sylvamo |

### 5.3 Source Conflicts / Ambiguities

| # | Issue | Tables Involved | Question | Resolution Needed |
|---|-------|----------------|----------|-------------------|
| 1 | **Work orders dual source** | `raw_ext_sap.work_orders` vs `raw_ext_fabric_sapecc.sapecc_work_orders` | Which is primary? Is SAP OData version deprecated? | Decision by team |
| 2 | **Roll quality dual source** | `raw_ext_fabric_ppr.ppr_hist_roll_quality` vs `raw_ext_sharepoint.roll_quality` | Which is source-of-truth? Different data? | Clarify with Sylvamo |
| 3 | **Material dual source** | `raw_ext_sap.materials` vs `raw_ext_fabric_ppr.ppr_hist_material` | SAP = master, PPR = supplemental? | Clarify scope |
| 4 | **Asset hierarchy naming** | `raw_ext_sap.asset_hierarchy` vs transform reads `sap_floc_eastover/sap_floc_sumter` | Different RAW table names? | Verify RAW table names |
| 5 | **PI metadata relevance** | `s769pi01_metadata`, `s769pi03_metadata`, `s519pip1_metadata` | "Not relevant data?" — needs investigation | Investigate content |
| 6 | **Fabric RAW DB naming** | Config uses `raw_sylvamo_fabric` vs transforms use `raw_ext_fabric_ppr` | Mismatch between extractor config and transformations | Verify which DB is current |

---

## 6. Validation Checklist

### 6.1 Data Source Completeness Validation

For each running extractor, validate row counts between source and RAW:

| # | Source System | RAW Database | RAW Table | Source Row Count | RAW Row Count | Match? | Last Validated |
|---|-------------|-------------|-----------|-----------------|---------------|--------|----------------|
| 1 | Fabric PPR | `raw_ext_fabric_ppr` | `ppr_hist_reel` | ❓ | ❓ | ❓ | — |
| 2 | Fabric PPR | `raw_ext_fabric_ppr` | `ppr_hist_roll` | ❓ | ❓ | ❓ | — |
| 3 | Fabric PPR | `raw_ext_fabric_ppr` | `ppr_hist_package` | ❓ | ❓ | ❓ | — |
| 4 | Fabric PPR | `raw_ext_fabric_ppr` | `ppr_hist_roll_quality` | ❓ | ❓ | ❓ | — |
| 5 | Fabric PPR | `raw_ext_fabric_ppr` | `ppr_hist_blend` | ❓ | ❓ | ❓ | — |
| 6 | Fabric PPR | `raw_ext_fabric_ppr` | `ppr_hist_material` | ❓ | ❓ | ❓ | — |
| 7 | Fabric PPR | `raw_ext_fabric_ppr` | `ppr_hist_order_item` | ❓ | ❓ | ❓ | — |
| 8 | Fabric PPR | `raw_ext_fabric_ppr` | `ppr_production_total` | ❓ | ❓ | ❓ | — |
| 9 | Fabric PPR | `raw_ext_fabric_ppr` | `ppr_mill` | ❓ | ❓ | ❓ | — |
| 10 | Fabric PPV | `raw_ext_fabric_ppv` | `ppv_snapshot` | ❓ | ❓ | ❓ | — |
| 11 | SAP | `raw_ext_sap` | `asset_hierarchy` | ❓ | ❓ | ❓ | — |
| 12 | SAP | `raw_ext_sap` | `materials` | ❓ | ❓ | ❓ | — |
| 13 | SAP | `raw_ext_sap` | `work_orders` | ❓ | ❓ | ❓ | — |
| 14 | SAP | `raw_ext_sap` | `production_orders` | ❓ | ❓ | ❓ | — |
| 15 | SAP | `raw_ext_sap` | `bp_details` | ❓ | ❓ | ❓ | — |
| 16 | Proficy | `raw_ext_sql_proficy` | `events_tests` | ❓ | ❓ | ❓ | — |
| 17 | Proficy | `raw_ext_sql_proficy` | `tag_info` | ❓ | ❓ | ❓ | — |
| 18 | Proficy | `raw_ext_sql_proficy` | `tests` | ❓ | ❓ | ❓ | — |
| 19 | Proficy | `raw_ext_sql_proficy` | `samples` | ❓ | ❓ | ❓ | — |
| 20 | SharePoint | `raw_ext_sharepoint` | `documents` | ❓ | ❓ | ❓ | — |
| 21 | SharePoint | `raw_ext_sharepoint` | `roll_quality` | ❓ | ❓ | ❓ | — |
| 22 | PI (Eastover) | `raw_ext_pi` | `s769pi01_metadata` | ❓ | ❓ | ❓ | — |
| 23 | PI (PM) | `raw_ext_pi` | `s769pi03_metadata` | ❓ | ❓ | ❓ | — |
| 24 | PI (S519) | `raw_ext_pi` | `s519pip1_metadata` | ❓ | ❓ | ❓ | — |

### 6.2 Transformation Validation

| # | Transformation | Source RAW | Target View | RAW Rows In | Instances Out | Transform Status | Last Run |
|---|---------------|-----------|-------------|-------------|---------------|-----------------|----------|
| 1 | `populate_Asset` | `raw_ext_sap.sap_floc_*` | Asset | ❓ | ❓ | ❓ | — |
| 2 | `populate_Material` | `raw_ext_sap.materials` | Material | ❓ | ❓ | ❓ | — |
| 3 | `populate_Reel` | `raw_ext_fabric_ppr.ppr_hist_reel` | Reel | ❓ | ❓ | ❓ | — |
| 4 | `populate_Roll` | `raw_ext_fabric_ppr.ppr_hist_roll` | Roll | ❓ | ❓ | ❓ | — |
| 5 | `populate_RollQuality` | `raw_ext_sharepoint.roll_quality` | RollQuality | ❓ | ❓ | ❓ | — |
| 6 | `populate_Event_Proficy` | `raw_ext_sql_proficy.events_tests` | Event | ❓ | ❓ | ❓ | — |
| 7 | `populate_Event_PPV` | `raw_ext_fabric_ppv.ppv_snapshot` | Event | ❓ | ❓ | ❓ | — |
| 8 | `populate_Event_ProductionOrders` | `raw_ext_sap.production_orders` | Event | ❓ | ❓ | ❓ | — |
| 9 | `populate_Event_WorkOrders` | `raw_ext_fabric_sapecc.sapecc_work_orders` | Event | ❓ | ❓ | 🔲 Blocked | — |
| 10 | `populate_WorkOrder` | `raw_ext_fabric_sapecc.sapecc_work_orders` | WorkOrder | ❓ | ❓ | 🔲 Blocked | — |
| 11 | `populate_ProductionOrder` | `raw_ext_sap.production_orders` | ProductionOrder | ❓ | ❓ | ❓ | — |
| 12 | `populate_ProductionEvent` | `raw_ext_sql_proficy.events_tests` | ProductionEvent | ❓ | ❓ | ❓ | — |
| 13 | `populate_CostEvent` | `raw_ext_fabric_ppv.ppv_snapshot` | CostEvent | ❓ | ❓ | ❓ | — |

---

## 7. Open Questions & Action Items

### 7.1 Questions for Sylvamo (Cam / Valmir)

| # | Question | Context | Priority | Owner | Status |
|---|----------|---------|----------|-------|--------|
| Q1 | What data do **Notifications** contain and where do they come from? | mfg_ext has Notification view but no source | High | Valmir | 🔲 Open |
| Q2 | What is the source for **Bills of Materials**? Is it Materials, PPV, or something else? | Referenced in SOW | High | Valmir | 🔲 Open |
| Q3 | What are **Orders, Shipments and Trends** in the SOW? | Cam mentioned shipments come from PPR; some UC1 inputs from spreadsheets | Medium | Cam | 🔲 Open |
| Q4 | Is `s519pip1` the **Sumter** PI server? | PI Server S519 — unclear site mapping | Medium | Cam | 🔲 Open |
| Q5 | Is `ppr_hist_roll_quality` the same as SharePoint `roll_quality`? | Two potential sources for roll quality | Medium | Sylvamo | 🔲 Open |
| Q6 | Is `ppr_hist_material` supplemental to SAP `materials`? | Two material sources | Medium | Sylvamo | 🔲 Open |
| Q7 | What should map to **Recipe** in the data model? | `ppr_hist_blend` is a candidate | Medium | Sylvamo | 🔲 Open |
| Q8 | What should map to **ProductDefinition**, **QualityResult**, **LabTest**, **Measurement**? | Views exist in mfg_data but no mapping defined | High | Sylvamo | 🔲 Open |
| Q9 | Can you provide source row counts for validation? | Need to validate RAW completeness | High | Cam/Valmir | 🔲 Open |
| Q10 | What is the target date for `fabric-connector-sapecc`? | Multiple transforms depend on it | High | Cam/Valmir | 🔲 Open |

### 7.2 Internal Action Items

| # | Action | Priority | Owner | Target Date | Status |
|---|--------|----------|-------|-------------|--------|
| A1 | Investigate PI metadata tables — determine if they contain useful data | Medium | Cognite | — | 🔲 |
| A2 | Verify RAW DB naming: `raw_sylvamo_fabric` vs `raw_ext_fabric_ppr` | High | Cognite | — | 🔲 |
| A3 | Verify SAP RAW table names: `asset_hierarchy` vs `sap_floc_eastover`/`sap_floc_sumter` | High | Cognite | — | 🔲 |
| A4 | Clarify relationship between `mfg_core`/`mfg_extended` and `mfg_data` (v10) models | Medium | Cognite | — | 🔲 |
| A5 | Create transformation for Package view (`ppr_hist_package` → Package) | Medium | Cognite | — | 🔲 |
| A6 | Build validation script to count RAW rows vs source | High | Cognite | — | 🔲 |
| A7 | Investigate SharePoint `documents` table — marked as "duplicate" | Low | Cognite | — | 🔲 |
| A8 | Create file metadata extraction pipeline | Medium | Cognite | — | 🔲 |

---

## Appendix: SOW Data Requirements Cross-Reference

| SOW Requirement | Data Source | RAW Table | In Model? | Status |
|----------------|------------|-----------|-----------|--------|
| File metadata | SharePoint | `documents` | CogniteFile | 🔶 Partial |
| Notifications | SAP (IW29?) | ❌ Not extracted | Notification (mfg_ext) | ❌ Missing |
| Operations | SAP (AFVC?) | ❌ Available but not wired | Operation (mfg_ext) | ❌ Missing |
| Bills of Materials | ❓ | ❓ | ❓ | ❓ Valmir to provide |
| Production tracking | Fabric PPR | `ppr_hist_*` | Reel, Roll, Event | ✅ Core done |
| Orders, shipments, trends | PPR + spreadsheets? | ❓ | ❓ | 🔶 Cam investigating |
| SharePoint docs (shift reports, SOPs, KOPs, manuals, P&IDs, TCCs) | SharePoint | `documents`, `roll_quality` | CogniteFile, RollQuality | ✅ |

---

## How to Use This Document

1. **For Sylvamo meetings:** Focus on sections 5 (Gap Analysis) and 7 (Open Questions) — these highlight what's missing and what needs decisions
2. **For internal tracking:** Use section 6 (Validation Checklist) — fill in row counts as validation is performed
3. **For development:** Use section 3 (Full Pipeline Mapping) — shows exactly which transformations exist and which need to be built
4. **For SVQS-160:** Reference this document as the comprehensive data lineage tracker

> **Next Steps:**
> 1. Review this document internally
> 2. Schedule walkthrough with Sylvamo (Cam + Valmir) to fill gaps
> 3. Build automated validation script (action A6)
> 4. Prioritize missing transformations based on use case requirements
