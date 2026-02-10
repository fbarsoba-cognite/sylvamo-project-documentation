# Sylvamo Data Source Registry & Pipeline Tracker

> **Purpose:** Single source of truth for tracking all data flowing into CDF — from source systems through extractors, RAW tables, transformations, and into the data model.
> **Audience:** Cognite team + Sylvamo stakeholders (Cam, Valmir)
> **Last Updated:** 2026-02-10 (v2 — enriched from extractor configs)
> **Jira Ticket:** [SVQS-160](https://cognitedata.atlassian.net/browse/SVQS-160)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Fabric Infrastructure Map](#2-fabric-infrastructure-map)
3. [Source Systems & Full Pipeline Mapping](#3-source-systems--full-pipeline-mapping)
4. [Data Model Summary](#4-data-model-summary)
5. [Gap Analysis](#5-gap-analysis)
6. [RAW Database Naming Issues](#6-raw-database-naming-issues)
7. [Known Extraction Issues](#7-known-extraction-issues)
8. [Validation Checklist](#8-validation-checklist)
9. [Open Questions & Action Items](#9-open-questions--action-items)
10. [**Things to Fix or Ask (Prioritized Punch List)**](#10-things-to-fix-or-ask-prioritized-punch-list)

---

## 1. Architecture Overview

```
┌─────────────────────┐     ┌──────────────┐     ┌──────────────┐     ┌────────────────────┐     ┌─────────────────────┐
│   SOURCE SYSTEMS    │────▶│  EXTRACTORS  │────▶│  RAW TABLES  │────▶│  TRANSFORMATIONS   │────▶│   DATA MODEL VIEWS  │
│                     │     │              │     │              │     │                    │     │                     │
│ • Fabric (PPR/PPV)  │     │ • fabric-*   │     │ raw_ext_*    │     │ • populate_*       │     │ sylvamo_mfg_core    │
│ • Fabric (SAP ECC)  │     │ • sap-odata  │     │              │     │ • create_*         │     │ sylvamo_mfg_ext     │
│ • SAP Gateway       │     │ • sql-ext    │     │              │     │                    │     │ sylvamo_mfg (v10)   │
│ • Proficy GBDB      │     │ • pi-ext     │     │              │     │                    │     │                     │
│ • PI Servers        │     │ • sp-ext     │     │              │     │                    │     │                     │
│ • SharePoint        │     │              │     │              │     │                    │     │                     │
└─────────────────────┘     └──────────────┘     └──────────────┘     └────────────────────┘     └─────────────────────┘
```

---

## 2. Fabric Infrastructure Map

This section documents the Microsoft Fabric workspaces and lakehouses that serve as source systems. Critical for understanding where data lives and which service principal has access.

### 2.1 Workspaces & Lakehouses

| # | Workspace | Workspace ID | Lakehouse | Lakehouse ID | Data Domain | SP Access |
|---|-----------|-------------|-----------|-------------|-------------|-----------|
| 1 | `ws_enterprise_prod` | *(name-based)* | `LH_SILVER_ppreo` | *(name-based)* | PPR production data (reels, rolls, packages, quality, blends) | sp-dev ✅ |
| 2 | `ws_enterprise_prod` | *(name-based)* | `LH_SILVER_ppreo` | *(name-based)* | PPV cost data (`Tables/enterprise/ppv_snapshot`) | sp-dev ✅ |
| 3 | CoE workspace | `e0366989-5d8c-4d3c-8803-ddc874400cf5` | `lh_gold_pm` | `a4e491e5-289b-4fa1-961e-3f8239e398cc` | SAP PM work orders (IW28) | sp-dev ✅ |
| 4 | `ws_enterprise_dev` | `0640c2e3-4c9f-4204-9a8e-c254375a2d4c` | `LH_SILVER_sapecc` | *(name-based, corrected by Rodrigo)* | SAP ECC tables (AUFK, AFKO, AFVC) | sp-dev ✅ |
| 5 | `ws_enterprise_prod` | `8266f376-3a64-4872-813d-5d1984389171` | `LH_SILVER_sapecc` | — | SAP ECC tables (prod copy) | sp-prod only ❌ |

### 2.2 Service Principal Rules

> **From Valmir (2026-02-03):** `sp-dev` → only DEV workspaces. `sp-prod` → only PROD workspaces.

| Service Principal | App ID | Access Scope |
|-------------------|--------|-------------|
| `sp-cdf-fabric-extractor-dev` | `73a40d42-8cf4-4048-80d1-54c8d28cb58d` | `ws_enterprise_prod` (PPR/PPV), CoE workspace (lh_gold_pm), `ws_enterprise_dev` (LH_SILVER_sapecc) |
| `sp-cdf-sap-extractor-dev` | `778dcec6-a85a-4799-a78e-1aee9d7aa3d3` | SAP Gateway OData (`sapsgvci.sylvamo.com:8075`) |
| `sp-cdf-pi-extractor-dev` | `b7671a6c-8680-4b10-b8d0-141767de9877` | PI Servers (S769PI01, S769PI03, S519PIP1) |
| `sp-cdf-file-extractor-dev` | `4050f0ee-519e-4485-ac2b-f3221071c92e` | SharePoint Online |
| `sp-cdf-sql-extractor-dev` | `3ec90782-5f9f-482d-9da2-46567276519b` | Proficy GBDB SQL Server |

### 2.3 Fabric Table Inventory (from Lakehouse exploration)

**LH_SILVER_ppreo (PPR — ws_enterprise_prod):**

| Fabric Path | Description | Data Content |
|-------------|-------------|-------------|
| `Tables/HIST_REEL` | Reel production history | `reel_number`, `reel_manufactured_date` (YYYYMMDD), `reel_product_code`, `reel_average_basis_weight`, `reel_average_caliper`, `reel_average_moisture`, `reel_finished_weight`, `reel_status_ind`, `reel_reel_width_num`, `reel_actual_diameter_num` |
| `Tables/HIST_ROLL` | Roll production history (child of reel) | `roll_number`, `roll_reel_number` (parent ref), `roll_basis_weight`, `roll_caliper`, `roll_width_num`, `roll_original_diameter`, `roll_current_weight`, `roll_producing_machine`, `ROLL_MANUFACTURING_DATE` |
| `Tables/HIST_PACKAGE` | Package/shipping units | `pack_package_number`, `pack_number_rolls_in_package`, `pack_assembled_date`, `pack_ship_date`, `pack_current_inv_point` |
| `Tables/HIST_ROLL_QUALITY` | Roll quality measurements & test results | Quality metrics, test results, flags. **Note:** trailing space in Fabric table name! |
| `Tables/HIST_BLEND` | Blend/recipe compositions | Blend compositions, material mix ratios |
| `Tables/HIST_MATERIAL` | Material information | Material codes, descriptions |
| `Tables/HIST_ORDER_ITEM` | Customer order items | Order items, customer order references |
| `Tables/PRODUCTION_TOTAL` | Aggregated production metrics | Daily/shift production summaries |
| `Tables/MILL` | Mill reference data | Mill codes, names, locations |

**lh_gold_pm (SAP PM — CoE workspace):**

| Fabric Path | SAP Transaction | Description | Data Content |
|-------------|----------------|-------------|-------------|
| `Tables/iw28` | IW28 | SAP Work Order List | All maintenance work orders across all plants. **Filter needed:** `WERKS IN ('0769', '0519')` |

**LH_SILVER_sapecc (SAP ECC — ws_enterprise_dev):**

| Fabric Path | SAP Table | Description | Data Content |
|-------------|-----------|-------------|-------------|
| `Tables/AUFK` | AUFK | Order Master Data | `AUFNR` (order number), `WERKS` (plant), `KTEXT` (description), `AUTYP` (order type). **Filter:** `WERKS IN ('0769','0519') AND AUTYP = '30'` |
| `Tables/AFKO` | AFKO | Order Header Data | `AUFNR`, `AUFPL` (routing number). Links AUFK to AFVC |
| `Tables/AFVC` | AFVC | Order Operations | `AUFPL` (routing), `VORNR` (operation number), `STEUS` (control key), `LTXA1` (operation description) |

**Plant Code Reference:**

| Plant Code | Mill Name |
|-----------|-----------|
| `0769` | Eastover Mill |
| `0519` | Sumter Mill |

---

## 3. Source Systems & Full Pipeline Mapping

> **One table to rule them all.** Every RAW table in one flat view — source system, extractor, raw location, transformation, and data model target. Scroll or Ctrl+F to find anything.

### Legend

✅ End-to-end | 🔶 Partial / issues | ❌ Missing | 🔲 Planned | ❓ Unknown | ⚠️ DB naming issue ([Section 6](#6-raw-database-naming-issues))

### Master Pipeline Table

| # | Source System | Extractor | Ext. Status | RAW Database | RAW Table | Description | Expected Rows | Transformation | Target View | Pipeline Status | Notes |
|---|-------------|-----------|-------------|-------------|-----------|-------------|---------------|----------------|-------------|-----------------|-------|
| | **FABRIC — PPR** (LH_SILVER_ppreo, `ws_enterprise_prod`) | | | | | | | | | | **SP:** `sp-cdf-fabric-extractor-dev` |
| 1 | Fabric (PPR) | `fabric-connector-ppr` | ✅ Running | ⚠️ `raw_sylvamo_fabric` → should be `raw_ext_fabric_ppr` | `ppr_hist_reel` | Reel production history — parent unit (reel_number, manufactured_date, basis_weight, caliper, moisture, weight, status) | ~61,000 | `populate_Reel` | `Reel` (mfg_core) | 🔶 DB mismatch | Config writes to wrong DB |
| 2 | Fabric (PPR) | `fabric-connector-ppr` | ✅ Running | `raw_ext_fabric_ppr` ✅ | `ppr_hist_roll` | Roll history — child of reel (roll_number, reel_number, basis_weight, caliper, width, weight, producing_machine) | ~2,300,000 | `populate_Roll` | `Roll` (mfg_core) | ✅ End-to-end | md5-key + incremental-field. SVQS-155 resolved |
| 3 | Fabric (PPR) | `fabric-connector-ppr` | ✅ Running | ⚠️ `raw_sylvamo_fabric` | `ppr_hist_package` | Package/shipping units (package_number, rolls_in_package, assembled_date, ship_date, inventory_point) | ~50,000 | ❌ None | ❌ None | 🔶 Extractor only | **GAP:** Package view exists in mfg_data |
| 4 | Fabric (PPR) | `fabric-connector-ppr` | ✅ Running | ⚠️ `raw_sylvamo_fabric` | `ppr_hist_roll_quality` | Roll quality measurements and test results (quality metrics, flags) | ❓ | ❌ None | ❌ None | 🔶 Extractor only | Trailing space in Fabric table name! Different from SP `roll_quality` |
| 5 | Fabric (PPR) | `fabric-connector-ppr` | ✅ Running | ⚠️ `raw_sylvamo_fabric` | `ppr_hist_blend` | Blend/recipe compositions (blend compositions, material mix ratios) | ❓ | ❌ None | ❌ None | 🔶 Extractor only | Could map to `Recipe` in mfg_data? |
| 6 | Fabric (PPR) | `fabric-connector-ppr` | ✅ Running | ⚠️ `raw_sylvamo_fabric` | `ppr_hist_material` | Material info from PPR (material codes, descriptions) | ❓ | ❌ None | ❌ None | 🔶 Extractor only | Overlaps with SAP `materials` |
| 7 | Fabric (PPR) | `fabric-connector-ppr` | ✅ Running | ⚠️ `raw_sylvamo_fabric` | `ppr_hist_order_item` | Customer order line items (order items, customer order references) | ❓ | ❌ None | ❌ None | 🔶 Extractor only | Could relate to shipments/trends (SOW) |
| 8 | Fabric (PPR) | `fabric-connector-ppr` | ✅ Running | ⚠️ `raw_sylvamo_fabric` | `ppr_production_total` | Aggregated production metrics (daily/shift summaries) | ❓ | ❌ None | ❌ None | 🔶 Extractor only | Reporting/KPI data |
| 9 | Fabric (PPR) | `fabric-connector-ppr` | ✅ Running | ⚠️ `raw_sylvamo_fabric` | `ppr_mill` | Mill reference data (mill codes, names, locations) | ❓ | ❌ None | ❌ None | 🔶 Extractor only | Dimension table for lookups |
| | **FABRIC — PPV** (LH_SILVER_ppreo, `ws_enterprise_prod`) | | | | | | | | | | **SP:** `sp-cdf-fabric-extractor-dev` |
| 10 | Fabric (PPV) | `fabric-connector-ppv` | ✅ Running | `raw_ext_fabric_ppv` ✅ | `ppv_snapshot` | Material cost / purchase price variance (material, description, type, plant, standard_cost, ppv, snapshot_date) | ~200+ | `populate_Event_PPV` | `Event` (mfg_core) | ✅ End-to-end | |
| 11 | Fabric (PPV) | `fabric-connector-ppv` | ✅ Running | `raw_ext_fabric_ppv` ✅ | `ppv_snapshot` | *(same table, second transform)* | *(same)* | `populate_CostEvent` | `CostEvent` (mfg_ext) | ✅ End-to-end | Extended view |
| | **FABRIC — SAP ECC** (lh_gold_pm + LH_SILVER_sapecc) | | | | | | | | | | **SP:** `sp-cdf-fabric-extractor-dev`. Plants: 0769=Eastover, 0519=Sumter |
| 12 | Fabric (SAP ECC) | `fabric-connector-sapecc` | ✅ DONE | `raw_ext_fabric_sapecc` ✅ | `sapecc_work_orders` | SAP Work Order List — IW28 transaction (all plants, filter in transform) | ~407,000 | `populate_Event_WorkOrders` | `Event` (mfg_core) | ✅ End-to-end | Extracted 2026-02-03 from lh_gold_pm |
| 13 | Fabric (SAP ECC) | `fabric-connector-sapecc` | ✅ DONE | `raw_ext_fabric_sapecc` ✅ | `sapecc_work_orders` | *(same table, second transform)* | *(same)* | `populate_WorkOrder` | `WorkOrder` (mfg_ext) | ✅ End-to-end | Extended view |
| 14 | Fabric (SAP ECC) | `fabric-connector-sapecc` | ✅ DONE | `raw_ext_fabric_sapecc` ✅ | `sapecc_aufk` | Order Master Data — AUFNR, WERKS, KTEXT, AUTYP | ~4,500,000 | ❌ (used in join) | `Operation` (pending) | 🔶 Needs join transform | From LH_SILVER_sapecc (DEV) |
| 15 | Fabric (SAP ECC) | `fabric-connector-sapecc` | ✅ DONE | `raw_ext_fabric_sapecc` ✅ | `sapecc_afko` | Order Header Data — AUFNR, AUFPL (links AUFK↔AFVC) | ~4,500,000 | ❌ (used in join) | `Operation` (pending) | 🔶 Needs join transform | From LH_SILVER_sapecc (DEV) |
| 16 | Fabric (SAP ECC) | `fabric-connector-sapecc` | 🔶 In Progress | `raw_ext_fabric_sapecc` | `sapecc_afvc` | Order Operations — AUFPL, VORNR, STEUS, LTXA1 | ~7,200,000 | ❌ (used in join) | `Operation` (mfg_ext) | 🔶 Extraction in progress | From LH_SILVER_sapecc (DEV) |
| | **SAP GATEWAY (OData)** | | | | | | | | | | **SP:** `sp-cdf-sap-extractor-dev`. Gateway: `sapsgvci.sylvamo.com:8075` |
| 17 | SAP Gateway | `sap-odata-extractor` | ✅ Running | ⚠️ `raw_sylvamo_sap` → should be `raw_ext_sap` | `bp_details` | Business Partner / Customer details (filter: comp eq 'DS75') | ❓ | ❌ None | ❌ None | 🔶 Extracted, unused | DB naming mismatch |
| 18 | SAP Gateway | `sap-odata-extractor` | ✅ Running | `raw_ext_sap` | `asset_hierarchy` | SAP Functional Locations — asset tree (may be split: `sap_floc_eastover` + `sap_floc_sumter`) | ❓ | `populate_Asset` | `Asset` (mfg_core) | ✅ End-to-end | Verify actual RAW table names |
| 19 | SAP Gateway | `sap-odata-extractor` | ✅ Running | `raw_ext_sap` | `materials` | Material master data (material codes, descriptions) | ❓ | `populate_Material` | `Material` (mfg_core) | ✅ End-to-end | |
| 20 | SAP Gateway | `sap-odata-extractor` | ✅ Running | `raw_ext_sap` | `work_orders` | Work orders via OData | ❓ | ❌ (superseded?) | — | ❓ Superseded? | Replaced by `sapecc_work_orders` from Fabric? |
| 21 | SAP Gateway | `sap-odata-extractor` | ✅ Running | `raw_ext_sap` | `production_orders` | Production orders | ❓ | `populate_Event_ProductionOrders`, `populate_ProductionOrder` | `Event`, `ProductionOrder` | ✅ End-to-end | From lakehouse |
| | **PROFICY GBDB** (SQL Server) | | | | | | | | | | **SP:** `sp-cdf-sql-extractor-dev`. ODBC Driver 17 |
| 22 | Proficy GBDB | `sql-extractor-proficy` | ✅ Running | `raw_ext_sql_proficy` | `events_tests` | Production events + test results (actual Proficy readings) | ❓ | `populate_Event_Proficy` | `Event` (mfg_core) | ✅ End-to-end | |
| 23 | Proficy GBDB | `sql-extractor-proficy` | ✅ Running | `raw_ext_sql_proficy` | `events_tests` | *(same table)* | *(same)* | `populate_ProductionEvent` | `ProductionEvent` (mfg_ext) | ✅ End-to-end | Extended view |
| 24 | Proficy GBDB | `sql-extractor-proficy` | ✅ Running | `raw_ext_sql_proficy` | `events_tests` | *(same table)* | *(same)* | `populate_ProficyDatapoints` | Time Series Datapoints | ✅ End-to-end | Readings as TS |
| 25 | Proficy GBDB | `sql-extractor-proficy` | ✅ Running | `raw_ext_sql_proficy` | `tag_info` | Tag/sensor metadata (tag names, units, descriptions) | ❓ | `create_ProficyTimeSeries_CDF`, `populate_ProficyTimeSeries` | CDF TS, `MfgTimeSeries` (mfg_core) | ✅ End-to-end | |
| 26 | Proficy GBDB | `sql-extractor-proficy` | ✅ Running | `raw_ext_sql_proficy` | `tests` | Lab test definitions (Test_Id, Sample_Id, Var_Id, Event_Num, Result) | ❓ | ❌ None | ❌ None | 🔶 Extractor only | Could map to `LabTest` in mfg_data |
| 27 | Proficy GBDB | `sql-extractor-proficy` | ✅ Running | `raw_ext_sql_proficy` | `samples` | Sample tracking data (sample metadata) | ❓ | ❌ None | ❌ None | 🔶 Extractor only | Could map to `LabTest` in mfg_data |
| 28 | Proficy GBDB | `sql-extractor-proficy` | ✅ Running | `raw_ext_sql_proficy` | `key_columns` | GBDB key column metadata | ❓ | ❌ None | ❌ None | 🔶 Extracted | Internal metadata — likely not needed |
| 29 | Proficy GBDB | `sql-extractor-proficy` | ✅ Running | `raw_ext_sql_proficy` | `event_tables` | GBDB event table metadata | ❓ | ❌ None | ❌ None | 🔶 Extracted | Internal metadata — likely not needed |
| 30 | Proficy GBDB | `sql-extractor-proficy` | ✅ Running | `raw_ext_sql_proficy` | `all_tables` | GBDB all table metadata | ❓ | ❌ None | ❌ None | 🔶 Extracted | Internal metadata — likely not needed |
| | **PI SERVERS** (Historians) | | | | | | | | | | **SP:** `sp-cdf-pi-extractor-dev`. TS space: `sylvamo_assets`. Backfill: 365d |
| 31 | PI (Eastover) | `pi-extractor-eastover` | ✅ Running | `raw_ext_pi` | `s769pi01_metadata` | PI tag metadata — S769PI01.sylvamo.com (~75 tags: levels, O2 reactor, temp, bleach) | ~75 tags | `populate_TimeSeries` | `MfgTimeSeries` (mfg_core) | ✅ TS direct to CDF | Investigate metadata table usefulness |
| 32 | PI (PM) | `pi-extractor-pm` | ✅ Running | `raw_ext_pi` | `s769pi03_metadata` | PI tag metadata — S769PI03 | ❓ | `populate_TimeSeries` | `MfgTimeSeries` (mfg_core) | ✅ TS direct to CDF | "Not relevant data?" — needs review |
| 33 | PI (S519) | `pi-extractor-s519` | ✅ Running | `raw_ext_pi` | `s519pip1_metadata` | PI tag metadata — S519PIP1 (Sheeters) | ❓ | `populate_TimeSeries` | `MfgTimeSeries` (mfg_core) | ✅ TS direct to CDF | **Is this Sumter?** Missing data reported |
| | **SHAREPOINT ONLINE** | | | | | | | | | | **SP:** `sp-cdf-file-extractor-dev`. Site: Sumter/Shared Documents |
| 34 | SharePoint | `sharepoint-extractor` | ✅ Running | `raw_ext_sharepoint` | `documents` | SharePoint files (shift reports, SOPs, KOPs, manuals, P&IDs, TCCs) | ❓ | `populate_Files` (via `_cdf.files`) | `CogniteFile` (CDM) | 🔶 Indirect | Marked "duplicate" — clarify |
| 35 | SharePoint | `sharepoint-extractor` | ✅ Running | `raw_ext_sharepoint` | `roll_quality` | Roll quality inspection reports (roll ID, defect code, rejected?, location, inspector) | 21+ | `populate_RollQuality` | `RollQuality` (mfg_core) | ✅ End-to-end | Different from PPR `ppr_hist_roll_quality` |

### Pipeline Summary

| Status | Count | Details |
|--------|-------|---------|
| ✅ End-to-end | 15 | Full pipeline: extractor → RAW → transform → model |
| 🔶 Partial | 16 | Extracted but: wrong DB (⚠️), no transform, or transform pending |
| ❌ Missing | 0 | — |
| 🔲 Planned | 0 | — |
| ❓ Unknown | 1 | `work_orders` via OData — possibly superseded |

> **Key notes:**
> - **PPR Join Key to Proficy:** `reel_number` (e.g., EM0010126020) → `substring(5)` maps to Proficy `Event_Num`. See `PPR_PROFICY_NAMING_CONVENTION.md`
> - **SAP ECC planned join:** AUFK + AFKO + AFVC → `Operation` view (filter: `WERKS IN ('0769','0519') AND AUTYP = '30'`)
> - **PI extractors** push time series **directly to CDF TS** (not via RAW). Metadata tables in `raw_ext_pi` are tag metadata only.

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
| mfg_core | Asset | `populate_Asset` | `raw_ext_sap.sap_floc_*` | ✅ |
| mfg_core | Material | `populate_Material` | `raw_ext_sap.materials` | ✅ |
| mfg_core | Reel | `populate_Reel` | `raw_ext_fabric_ppr.ppr_hist_reel` | 🔶 DB name issue |
| mfg_core | Roll | `populate_Roll` | `raw_ext_fabric_ppr.ppr_hist_roll` | ✅ |
| mfg_core | RollQuality | `populate_RollQuality` | `raw_ext_sharepoint.roll_quality` | ✅ |
| mfg_core | Event | `populate_Event_Proficy` | `raw_ext_sql_proficy.events_tests` | ✅ |
| mfg_core | Event | `populate_Event_WorkOrders` | `raw_ext_fabric_sapecc.sapecc_work_orders` | ✅ (data now available!) |
| mfg_core | Event | `populate_Event_ProductionOrders` | `raw_ext_sap.production_orders` | ✅ |
| mfg_core | Event | `populate_Event_PPV` | `raw_ext_fabric_ppv.ppv_snapshot` | ✅ |
| mfg_core | MfgTimeSeries | `populate_TimeSeries` + `populate_Proficy*` | `_cdf.timeseries` + proficy | ✅ |
| mfg_core | CogniteFile | `populate_Files` | `_cdf.files` | ✅ |
| mfg_ext | WorkOrder | `populate_WorkOrder` | `raw_ext_fabric_sapecc.sapecc_work_orders` | ✅ (data now available!) |
| mfg_ext | ProductionOrder | `populate_ProductionOrder` | `raw_ext_sap.production_orders` | ✅ |
| mfg_ext | ProductionEvent | `populate_ProductionEvent` | `raw_ext_sql_proficy.events_tests` | ✅ |
| mfg_ext | CostEvent | `populate_CostEvent` | `raw_ext_fabric_ppv.ppv_snapshot` | ✅ |
| mfg_ext | Equipment | ❌ No transformation | ❌ No source identified | ❌ |
| mfg_ext | MaintenanceActivity | ❌ No transformation | ❌ No source identified | ❌ |
| mfg_ext | Notification | ❌ No transformation | ❌ Valmir to provide | ❌ |
| mfg_ext | Operation | ❌ No transformation | 🔶 `sapecc_afvc` being extracted | 🔶 Data almost ready |

---

## 5. Gap Analysis

### 5.1 RAW Tables Without Transformations (Extracted but unused)

| # | RAW Database | RAW Table | Data Description | Potential Target | Priority | Action Required |
|---|-------------|-----------|-----------------|-----------------|----------|-----------------|
| 1 | `raw_ext_fabric_ppr` | `ppr_hist_package` | Package/shipping units: package#, roll count, dates, inventory | `Package` (mfg_data) | High | Create transformation |
| 2 | `raw_ext_fabric_ppr` | `ppr_hist_roll_quality` | Roll quality measurements from PPR system | `QualityResult` (mfg_data) | Medium | Clarify vs SharePoint `roll_quality` |
| 3 | `raw_ext_fabric_ppr` | `ppr_hist_blend` | Blend/recipe compositions and material mix | `Recipe` (mfg_data) | Medium | Evaluate if blend = recipe |
| 4 | `raw_ext_fabric_ppr` | `ppr_hist_material` | Material codes and descriptions from PPR | `Material` (mfg_core) supplement? | Low | SAP is source-of-truth |
| 5 | `raw_ext_fabric_ppr` | `ppr_hist_order_item` | Customer order items and references | Shipments/trends? | Medium | Evaluate for SOW requirements |
| 6 | `raw_ext_fabric_ppr` | `ppr_production_total` | Daily/shift production summaries | KPI/Reporting | Low | Not in current data model |
| 7 | `raw_ext_fabric_ppr` | `ppr_mill` | Mill codes, names, locations | Reference/dimension | Low | Lookup table for transforms |
| 8 | `raw_ext_fabric_sapecc` | `sapecc_aufk` | Order Master Data (4.5M rows) | Used in join for `Operation` | High | Part of AUFK+AFKO+AFVC join |
| 9 | `raw_ext_fabric_sapecc` | `sapecc_afko` | Order Header Data (4.5M rows) | Used in join for `Operation` | High | Part of AUFK+AFKO+AFVC join |
| 10 | `raw_ext_fabric_sapecc` | `sapecc_afvc` | Order Operations (7.2M rows) | `Operation` (mfg_ext) | High | AFVC extraction in progress |
| 11 | `raw_ext_sap` | `work_orders` | Work orders via OData | Superseded by `sapecc_work_orders`? | Low | Clarify if still needed |
| 12 | `raw_ext_sap` | `bp_details` | Business Partner / Customer details | ❓ | Low | Vendor/customer data — is it needed? |
| 13 | `raw_ext_sql_proficy` | `tests` | Lab test definitions | `LabTest` (mfg_data) | Medium | Reference data for Proficy |
| 14 | `raw_ext_sql_proficy` | `samples` | Sample tracking data | `LabTest` (mfg_data) | Medium | Sample metadata |
| 15 | `raw_ext_sql_proficy` | `key_columns` | GBDB key column metadata | Internal | Low | Likely not needed |
| 16 | `raw_ext_sql_proficy` | `event_tables` | GBDB event table metadata | Internal | Low | Likely not needed |
| 17 | `raw_ext_sql_proficy` | `all_tables` | GBDB all table metadata | Internal | Low | Likely not needed |

### 5.2 Data Model Views Without Data Sources

| # | Data Model | View | Required Data Source | Status | Owner | Notes |
|---|-----------|------|---------------------|--------|-------|-------|
| 1 | mfg_ext | Equipment | SAP equipment master | ❌ No source | Valmir/Cam | May come from IFLOT in Fabric? |
| 2 | mfg_ext | MaintenanceActivity | SAP PM data | ❌ No source | Valmir/Cam | Related to work orders? |
| 3 | mfg_ext | Notification | SAP IW29 (or similar) | ❌ No source | Valmir | Same data as work orders? |
| 4 | mfg_ext | Operation | `sapecc_afvc` (AUFK+AFKO+AFVC join) | 🔶 **Data almost ready** | Cognite | AFVC extraction in progress, join transform needed |
| 5 | mfg_data | Package | `ppr_hist_package` (available in RAW) | 🔶 Needs transformation | Cognite | ~50K rows available |
| 6 | mfg_data | Recipe | `ppr_hist_blend`? | ❓ Needs mapping | Sylvamo | Blend compositions = recipe? |
| 7 | mfg_data | ProductDefinition | ❓ | ❌ Unknown source | Sylvamo | Currently derived from basis weight ranges |
| 8 | mfg_data | QualityResult | `ppr_hist_roll_quality` and/or `samples` | ❓ Needs mapping | Sylvamo | Two potential sources |
| 9 | mfg_data | LabTest | `raw_ext_sql_proficy.tests` + `samples` | ❓ Needs mapping | Sylvamo | Proficy reference data |
| 10 | mfg_data | Measurement | ❓ | ❌ Unknown source | Sylvamo | |
| 11 | mfg_data | ManufacturingEvent | Multiple sources? | ❓ Relationship to Event | Sylvamo | |

### 5.3 Source Conflicts / Ambiguities

| # | Issue | Tables Involved | Details | Resolution Needed |
|---|-------|----------------|---------|-------------------|
| 1 | **Work orders dual source** | `raw_ext_sap.work_orders` (OData) vs `raw_ext_fabric_sapecc.sapecc_work_orders` (Fabric IW28) | Fabric version has ~407K rows and is the active source for transforms. Is OData version deprecated? | Decision: likely Fabric is primary |
| 2 | **Roll quality dual source** | `raw_ext_fabric_ppr.ppr_hist_roll_quality` (PPR system) vs `raw_ext_sharepoint.roll_quality` (SharePoint list) | PPR = automated quality measurements? SharePoint = manual inspection reports? They appear to be **different data** | Clarify with Sylvamo |
| 3 | **Material dual source** | `raw_ext_sap.materials` (SAP master) vs `raw_ext_fabric_ppr.ppr_hist_material` (PPR) | SAP is likely the master. PPR may have production-specific material attributes | SAP = source-of-truth |
| 4 | **Asset hierarchy naming** | Transform reads `sap_floc_eastover` + `sap_floc_sumter` but user table says `asset_hierarchy` | Are these the same table or split by site? | Verify RAW table names |
| 5 | **PI metadata relevance** | `s769pi01_metadata`, `s769pi03_metadata`, `s519pip1_metadata` | "Not relevant data?" — needs investigation | Investigate content |
| 6 | **SAP client number** | OData config shows `client: "100"` but earlier docs reference `client: "300"` | Which is correct? | Verify with SAP team |
| 7 | **AUFK/AFKO/AFVC dual lakehouse** | lh_gold_pm (CoE) has lowercase `aufk/afko/afvc`, LH_SILVER_sapecc (DEV) has uppercase `AUFK/AFKO/AFVC` | Are these the same data? Which is production? | Clarify with Valmir |

---

## 6. RAW Database Naming Issues

> **CRITICAL:** There are two naming conventions in use. Old configs write to one DB, transforms read from another. This causes data to be extracted but invisible to transformations.

### 6.1 Naming Convention History

| Era | Pattern | Example | Used By |
|-----|---------|---------|---------|
| **Old** (Jan 2026) | `raw_sylvamo_<source>` | `raw_sylvamo_fabric`, `raw_sylvamo_sap` | Early extractor configs (PPR all-tables, SAP OData, HIST_REEL standalone, HIST_ROLL_QUALITY) |
| **New** (Feb 2026) | `raw_ext_<type>_<source>` | `raw_ext_fabric_ppr`, `raw_ext_fabric_ppv`, `raw_ext_fabric_sapecc`, `raw_ext_sap` | Production configs, all transformations |

### 6.2 Affected Configs

| Config | Writes To (Old) | Transforms Read From (New) | Impact |
|--------|----------------|---------------------------|--------|
| `fabric-connector-ppr-all.yml` | `raw_sylvamo_fabric.hist_reel` | `raw_ext_fabric_ppr.ppr_hist_reel` | ❌ **Transform can't read data** — wrong DB AND wrong table name |
| `fabric-connector-ppr-all.yml` | `raw_sylvamo_fabric.hist_roll` | `raw_ext_fabric_ppr.ppr_hist_roll` | ❌ **Transform can't read data** — wrong DB AND wrong table name |
| `fabric-connector-ppr-all.yml` | `raw_sylvamo_fabric.hist_package` | (no transform yet) | ⚠️ Future mismatch if transform created with new naming |
| `fabric-connector-ppr-all.yml` | `raw_sylvamo_fabric.hist_roll_quality` | (no transform yet) | ⚠️ Future mismatch |
| `fabric-connector-hist-reel.yml` | `raw_sylvamo_fabric.ppr_hist_reel` | `raw_ext_fabric_ppr.ppr_hist_reel` | ❌ **Wrong DB** — table name correct but DB wrong |
| `fabric-connector-hist-roll-quality.yml` | `raw_sylvamo_fabric.ppr_hist_roll_quality` | (no transform yet) | ⚠️ Wrong DB |
| `sap-odata-extractor.yml` | `raw_sylvamo_sap.bp_details` | `raw_ext_sap.bp_details` | ❌ **Wrong DB** |
| `fabric-connector-hist-roll-full.yml` (v2) | `raw_ext_fabric_ppr.ppr_hist_roll` ✅ | `raw_ext_fabric_ppr.ppr_hist_roll` ✅ | ✅ **Correct** |

### 6.3 Resolution Required

**Action:** Update ALL old configs to use `raw_ext_*` naming convention with `ppr_` prefixed table names. Specifically:
1. HIST_REEL config: change `raw_sylvamo_fabric` → `raw_ext_fabric_ppr`
2. HIST_ROLL_QUALITY config: change `raw_sylvamo_fabric` → `raw_ext_fabric_ppr`
3. PPR all-tables config: change DB to `raw_ext_fabric_ppr` and add `ppr_` prefix to all table names
4. SAP OData config: change `raw_sylvamo_sap` → `raw_ext_sap`
5. After update: re-run extractors to populate correct RAW databases
6. Optionally: delete old `raw_sylvamo_fabric` / `raw_sylvamo_sap` databases after migration

---

## 7. Known Extraction Issues

### 7.1 Fabric Connector Bugs

| Issue | Symptom | Workaround | Status |
|-------|---------|-----------|--------|
| **KeyError bug** | Connector crashes after extracting first table when multiple tables configured | Extract **ONE table at a time** — comment/uncomment in config | Open (Fabric connector issue) |
| **Default batch size** | Only 1,000 rows extracted (default `read_batch_size`) | Set `read_batch_size: 100000` or higher | Documented |
| **OOM crash (SVQS-155)** | `numpy._core._exceptions._ArrayMemoryError` on 2.3M row tables | Reduce batch sizes: `ingest-batch-size: 20000`, `fabric-ingest-batch-size: 500`. Use `md5-key: true` + `incremental-field` | Resolved with v2 config |
| **Row key overwrite** | Without `md5-key`, connector uses row indices (0-999) as keys — each batch overwrites previous | Set `md5-key: true` to generate unique hash-based keys | Documented |
| **Trailing space in table name** | `HIST_ROLL_QUALITY ` has trailing space in Fabric | Include trailing space in `raw-path` config | Known |

### 7.2 SAP OData Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| `Anmeldung fehlgeschlagen` (401) | Invalid Gateway credentials | Verify COGNITE username/password |
| `500 Internal Server Error` | RFC Bridge credentials invalid | SAP team must fix SM59 RFC Destination |
| `/IWFND/CM_BEC022` | "User or password incorrect for backend" | Update stored credentials in SM59 |
| Empty response | Wrong SAP client or filter syntax | Verify `sap-client` value (100 vs 300?) |

---

## 8. Validation Checklist

### 8.1 Data Source Completeness Validation

| # | Source | RAW Database | RAW Table | Fabric Rows (Expected) | RAW Rows (Actual) | Match? | Last Validated |
|---|--------|-------------|-----------|----------------------|-------------------|--------|----------------|
| 1 | PPR | `raw_ext_fabric_ppr` | `ppr_hist_reel` | ~61,000 | ❓ | ❓ | — |
| 2 | PPR | `raw_ext_fabric_ppr` | `ppr_hist_roll` | ~2,300,000 | ❓ | ❓ | — |
| 3 | PPR | `raw_ext_fabric_ppr` | `ppr_hist_package` | ~50,000 | ❓ | ❓ | — |
| 4 | PPR | `raw_ext_fabric_ppr` | `ppr_hist_roll_quality` | ❓ | ❓ | ❓ | — |
| 5 | PPR | `raw_ext_fabric_ppr` | `ppr_hist_blend` | ❓ | ❓ | ❓ | — |
| 6 | PPR | `raw_ext_fabric_ppr` | `ppr_hist_material` | ❓ | ❓ | ❓ | — |
| 7 | PPR | `raw_ext_fabric_ppr` | `ppr_hist_order_item` | ❓ | ❓ | ❓ | — |
| 8 | PPR | `raw_ext_fabric_ppr` | `ppr_production_total` | ❓ | ❓ | ❓ | — |
| 9 | PPR | `raw_ext_fabric_ppr` | `ppr_mill` | ❓ | ❓ | ❓ | — |
| 10 | PPV | `raw_ext_fabric_ppv` | `ppv_snapshot` | ~200 | ❓ | ❓ | — |
| 11 | SAP ECC | `raw_ext_fabric_sapecc` | `sapecc_work_orders` | ~407,000 | ❓ | ❓ | Extracted 2026-02-03 |
| 12 | SAP ECC | `raw_ext_fabric_sapecc` | `sapecc_aufk` | ~4,500,000 | ❓ | ❓ | Extracted (DEV) |
| 13 | SAP ECC | `raw_ext_fabric_sapecc` | `sapecc_afko` | ~4,500,000 | ❓ | ❓ | Extracted (DEV) |
| 14 | SAP ECC | `raw_ext_fabric_sapecc` | `sapecc_afvc` | ~7,200,000 | ❓ | ❓ | In Progress |
| 15 | SAP OData | `raw_ext_sap` | `asset_hierarchy` | ❓ | ❓ | ❓ | — |
| 16 | SAP OData | `raw_ext_sap` | `materials` | ❓ | ❓ | ❓ | — |
| 17 | SAP OData | `raw_ext_sap` | `work_orders` | ❓ | ❓ | ❓ | — |
| 18 | SAP OData | `raw_ext_sap` | `production_orders` | ❓ | ❓ | ❓ | — |
| 19 | SAP OData | `raw_ext_sap` | `bp_details` | ❓ | ❓ | ❓ | — |
| 20 | Proficy | `raw_ext_sql_proficy` | `events_tests` | ❓ | ❓ | ❓ | — |
| 21 | Proficy | `raw_ext_sql_proficy` | `tag_info` | ❓ | ❓ | ❓ | — |
| 22 | Proficy | `raw_ext_sql_proficy` | `tests` | ❓ | ❓ | ❓ | — |
| 23 | Proficy | `raw_ext_sql_proficy` | `samples` | ❓ | ❓ | ❓ | — |
| 24 | SharePoint | `raw_ext_sharepoint` | `documents` | ❓ | ❓ | ❓ | — |
| 25 | SharePoint | `raw_ext_sharepoint` | `roll_quality` | ❓ | 21+ | ❓ | — |
| 26 | PI | `raw_ext_pi` | `s769pi01_metadata` | ❓ | ❓ | ❓ | — |
| 27 | PI | `raw_ext_pi` | `s769pi03_metadata` | ❓ | ❓ | ❓ | — |
| 28 | PI | `raw_ext_pi` | `s519pip1_metadata` | ❓ | ❓ | ❓ | — |

### 8.2 Transformation Validation

| # | Transformation | Source RAW | Target View | RAW Rows In | Instances Out | Transform Status | Last Run |
|---|---------------|-----------|-------------|-------------|---------------|-----------------|----------|
| 1 | `populate_Asset` | `raw_ext_sap.sap_floc_*` | Asset | ❓ | ❓ | ❓ | — |
| 2 | `populate_Material` | `raw_ext_sap.materials` | Material | ❓ | ❓ | ❓ | — |
| 3 | `populate_Reel` | `raw_ext_fabric_ppr.ppr_hist_reel` | Reel | ~61K | ❓ | ❓ | — |
| 4 | `populate_Roll` | `raw_ext_fabric_ppr.ppr_hist_roll` | Roll | ~2.3M | ❓ | ❓ | — |
| 5 | `populate_RollQuality` | `raw_ext_sharepoint.roll_quality` | RollQuality | 21+ | ❓ | ❓ | — |
| 6 | `populate_Event_Proficy` | `raw_ext_sql_proficy.events_tests` | Event | ❓ | ❓ | ❓ | — |
| 7 | `populate_Event_PPV` | `raw_ext_fabric_ppv.ppv_snapshot` | Event | ~200 | ❓ | ❓ | — |
| 8 | `populate_Event_ProductionOrders` | `raw_ext_sap.production_orders` | Event | ❓ | ❓ | ❓ | — |
| 9 | `populate_Event_WorkOrders` | `raw_ext_fabric_sapecc.sapecc_work_orders` | Event | ~407K | ❓ | ✅ Data available | — |
| 10 | `populate_WorkOrder` | `raw_ext_fabric_sapecc.sapecc_work_orders` | WorkOrder | ~407K | ❓ | ✅ Data available | — |
| 11 | `populate_ProductionOrder` | `raw_ext_sap.production_orders` | ProductionOrder | ❓ | ❓ | ❓ | — |
| 12 | `populate_ProductionEvent` | `raw_ext_sql_proficy.events_tests` | ProductionEvent | ❓ | ❓ | ❓ | — |
| 13 | `populate_CostEvent` | `raw_ext_fabric_ppv.ppv_snapshot` | CostEvent | ~200 | ❓ | ❓ | — |
| 14 | *(new)* AUFK+AFKO+AFVC join | `raw_ext_fabric_sapecc.sapecc_aufk/afko/afvc` | Operation | ~7.2M ops | ❓ | 🔶 Transform needed | — |

---

## 9. Open Questions & Action Items

### 9.1 Questions for Sylvamo (Cam / Valmir)

| # | Question | Context | Priority | Owner | Status |
|---|----------|---------|----------|-------|--------|
| Q1 | What data do **Notifications** contain and where do they come from? | mfg_ext has Notification view but no source | High | Valmir | 🔲 Open |
| Q2 | What is the source for **Bills of Materials**? Is it Materials, PPV, or something else? | Referenced in SOW | High | Valmir | 🔲 Open |
| Q3 | What are **Orders, Shipments and Trends** in the SOW? | Cam mentioned shipments come from PPR (`ppr_hist_order_item`?); some UC1 inputs from spreadsheets (flat rate/ton) | Medium | Cam | 🔲 Open |
| Q4 | Is `s519pip1` the **Sumter** PI server? | PI Server S519 — unclear site mapping | Medium | Cam | 🔲 Open |
| Q5 | Is `ppr_hist_roll_quality` the same data as SharePoint `roll_quality`? | PPR = automated measurements? SharePoint = manual inspections? Appear to be **different data** | Medium | Sylvamo | 🔲 Open |
| Q6 | Is `ppr_hist_material` supplemental to SAP `materials`? | Two material sources — SAP likely master | Low | Sylvamo | 🔲 Open |
| Q7 | What should map to **Recipe** in the data model? | `ppr_hist_blend` (blend compositions) is a candidate | Medium | Sylvamo | 🔲 Open |
| Q8 | What should map to **ProductDefinition**, **QualityResult**, **LabTest**, **Measurement**? | Views exist in mfg_data but no mapping defined | High | Sylvamo | 🔲 Open |
| Q9 | Can you provide **source row counts** for validation? | Need to validate RAW completeness for running extractors | High | Cam/Valmir | 🔲 Open |
| Q10 | When will AFVC extraction complete and is the data from **DEV** workspace acceptable? | AUFK/AFKO done from DEV. Will we need to re-extract from PROD? | High | Valmir | 🔲 Open |
| Q11 | Which **SAP client** is correct: `100` or `300`? | OData config says 100, earlier docs say 300 | Medium | SAP team | 🔲 Open |
| Q12 | Is there an **IFLOT** (Functional Locations) table in Fabric lakehouses? | Needed for Equipment view. Config has commented TODO | Medium | Valmir | 🔲 Open |

### 9.2 Internal Action Items

| # | Action | Priority | Owner | Target Date | Status |
|---|--------|----------|-------|-------------|--------|
| A1 | **Fix RAW DB naming:** Update all old configs from `raw_sylvamo_fabric` → `raw_ext_fabric_ppr` and `raw_sylvamo_sap` → `raw_ext_sap` | 🔴 Critical | Cognite | ASAP | 🔲 |
| A2 | **Re-run HIST_REEL extractor** with corrected DB name (`raw_ext_fabric_ppr`) | 🔴 Critical | Cognite | After A1 | 🔲 |
| A3 | Create **AUFK+AFKO+AFVC join transformation** for Operation view | High | Cognite | After AFVC extraction | 🔲 |
| A4 | Investigate PI metadata tables — determine if they contain useful data | Medium | Cognite | — | 🔲 |
| A5 | Verify SAP RAW table names: `asset_hierarchy` vs `sap_floc_eastover`/`sap_floc_sumter` | High | Cognite | — | 🔲 |
| A6 | Clarify relationship between `mfg_core`/`mfg_extended` and `mfg_data` (v10) models | Medium | Cognite | — | 🔲 |
| A7 | Create transformation for **Package** view (`ppr_hist_package` → Package) | Medium | Cognite | — | 🔲 |
| A8 | Build **validation script** to count RAW rows vs source and vs model instances | High | Cognite | — | 🔲 |
| A9 | Investigate SharePoint `documents` table — marked as "duplicate" | Low | Cognite | — | 🔲 |
| A10 | Create file metadata extraction pipeline | Medium | Cognite | — | 🔲 |
| A11 | **Delete old RAW databases** (`raw_sylvamo_fabric`, `raw_sylvamo_sap`) after migration | Low | Cognite | After A1+A2 verified | 🔲 |
| A12 | Decide: extract AUFK/AFKO/AFVC from **PROD** workspace or keep DEV data | High | Cognite+Valmir | — | 🔲 |

---

## Appendix A: SOW Data Requirements Cross-Reference

| SOW Requirement | Data Source | RAW Table(s) | In Model? | Status |
|----------------|------------|-------------|-----------|--------|
| File metadata | SharePoint | `documents` | CogniteFile | 🔶 Partial |
| Notifications | SAP (IW29?) | ❌ Not extracted | Notification (mfg_ext) | ❌ Missing |
| Operations | SAP AFVC (via Fabric) | `sapecc_afvc` (being extracted) | Operation (mfg_ext) | 🔶 Data almost ready |
| Bills of Materials | ❓ | ❓ | ❓ | ❓ Valmir to provide |
| Production tracking | Fabric PPR | `ppr_hist_reel`, `ppr_hist_roll` | Reel, Roll, Event | ✅ Core done |
| Orders, shipments, trends | PPR `ppr_hist_order_item` + spreadsheets? | ❓ | ❓ | 🔶 Cam investigating |
| SharePoint docs (shift reports, SOPs, KOPs, manuals, P&IDs, TCCs) | SharePoint | `documents`, `roll_quality` | CogniteFile, RollQuality | ✅ |

---

## Appendix B: Extractor Configuration File Index

| Config File | Extractor | Tables | RAW Database | Status | Notes |
|------------|-----------|--------|-------------|--------|-------|
| `fabric-connector-ppr-all.yml` | Fabric (PPR) | All 9 PPR tables | ⚠️ `raw_sylvamo_fabric` (OLD) | Outdated | KeyError bug — run one table at a time |
| `fabric-connector-hist-reel.yml` | Fabric (PPR) | HIST_REEL only | ⚠️ `raw_sylvamo_fabric` (OLD) | Outdated | Needs DB name fix |
| `fabric-connector-hist-roll-full.yml` (v2) | Fabric (PPR) | HIST_ROLL only | ✅ `raw_ext_fabric_ppr` | **Active** | With md5-key, incremental-field, reduced batch sizes |
| `fabric-connector-hist-roll-quality.yml` | Fabric (PPR) | HIST_ROLL_QUALITY | ⚠️ `raw_sylvamo_fabric` (OLD) | Outdated | Trailing space in Fabric table name |
| `fabric-connector-sapecc-v2.yml` (DEV) | Fabric (SAP ECC) | AUFK, AFKO, AFVC | ✅ `raw_ext_fabric_sapecc` | **Active** | Run one table at a time. AFVC current |
| `fabric-connector-sapecc-workorders.yml` | Fabric (SAP ECC) | iw28 | ✅ `raw_ext_fabric_sapecc` | **Done** | ~407K rows extracted |
| `sap-odata-extractor.yml` | SAP OData | BP_DetailsSet | ⚠️ `raw_sylvamo_sap` (OLD) | Running | Needs DB name fix to `raw_ext_sap` |

---

## How to Use This Document

1. **For daily standups:** Use section 10 (Punch List) — prioritized, actionable items grouped by type
2. **For Sylvamo meetings:** Use section 10 "ASK SYLVAMO" items — pre-built talking points with context
3. **For internal tracking:** Use section 8 (Validation Checklist) — fill in row counts as validation is performed
4. **For development:** Use section 3 (Source Systems & Pipeline Mapping) — extractor info + table-level detail in one place
5. **For config fixes:** Use sections 6 + 10 "FIX NOW" — lists every config that needs updating with priority
6. **For Fabric team coordination:** Use section 2 (Fabric Infrastructure Map) — workspace/lakehouse/SP topology
7. **For SVQS-160:** Reference this document as the comprehensive data lineage tracker

> **Next Steps (see Section 10 Priority Matrix for full view):**
> 1. **THIS WEEK:** Fix RAW DB naming in all old configs and re-run extractors (F1–F5)
> 2. **THIS WEEK:** Schedule Sylvamo meeting using ASK items A1–A9 as agenda
> 3. **THIS SPRINT:** Build AUFK+AFKO+AFVC join transform (B1) and Package transform (B2)
> 4. **THIS SPRINT:** Build validation script (B3) once Sylvamo provides expected counts
> 5. **BACKLOG:** Remaining transforms (B4–B6) pending Sylvamo confirmation on mappings

---

## 10. Things to Fix or Ask (Prioritized Punch List)

> **Use this section as your standup checklist and Sylvamo meeting agenda.**
> Items are grouped by type and sorted by priority within each group.

---

### FIX NOW — Config / Data Issues (Cognite team, no external dependency)

| # | What | Why It Matters | Effort | Status |
|---|------|---------------|--------|--------|
| F1 | **Fix RAW DB names in all old extractor configs** (`raw_sylvamo_fabric` → `raw_ext_fabric_ppr`, `raw_sylvamo_sap` → `raw_ext_sap`) | Transforms can't read data written to wrong DB. HIST_REEL, HIST_PACKAGE, HIST_ROLL_QUALITY, HIST_BLEND, HIST_MATERIAL, HIST_ORDER_ITEM, PRODUCTION_TOTAL, MILL, and SAP OData `bp_details` are all affected. See [Section 6](#6-raw-database-naming-issues) for full list. | Small — config change + re-run | 🔲 |
| F2 | **Re-run HIST_REEL extractor** after DB name fix | Reel transformation (`populate_Reel`) will fail or read stale data until the reel data lands in `raw_ext_fabric_ppr.ppr_hist_reel` | Small — re-run extraction (~61K rows) | 🔲 |
| F3 | **Re-run remaining PPR tables** (HIST_PACKAGE, HIST_BLEND, HIST_MATERIAL, HIST_ORDER_ITEM, PRODUCTION_TOTAL, MILL, HIST_ROLL_QUALITY) with correct DB names | All 7 tables are currently in `raw_sylvamo_fabric` — useless to transforms | Medium — run one at a time (KeyError bug) | 🔲 |
| F4 | **Verify `populate_Event_WorkOrders` and `populate_WorkOrder` transforms now succeed** | `sapecc_work_orders` (~407K rows) was extracted 2026-02-03. Transforms should now have data. | Small — run transforms, check results | 🔲 |
| F5 | **Verify SAP RAW table names** — do transforms read `asset_hierarchy` or `sap_floc_eastover` + `sap_floc_sumter`? | If table names don't match, `populate_Asset` may be broken or reading old data | Small — check transform SQL vs actual RAW tables | 🔲 |
| F6 | **Delete old RAW databases** (`raw_sylvamo_fabric`, `raw_sylvamo_sap`) after migration confirmed | Avoid confusion — two copies of data in different DBs | Small — after F1-F3 verified | 🔲 |

---

### ASK SYLVAMO — Questions That Block Progress (for Cam / Valmir meeting)

| # | Question | Who | Why It Blocks | Suggested Meeting Talking Point |
|---|----------|-----|--------------|-------------------------------|
| A1 | **Is the data from DEV workspace acceptable, or do we need to re-extract AUFK/AFKO/AFVC from PROD?** | Valmir | If DEV data differs from PROD, the Operation view will have wrong data | "We extracted ~16M rows from `ws_enterprise_dev`. Is this the same data as production? Should we plan a re-extraction from `ws_enterprise_prod` (needs sp-prod access)?" |
| A2 | **What data do Notifications contain and where do they come from?** | Valmir | `Notification` view in mfg_ext has no data source at all | "Is this SAP IW29? Is there a Fabric lakehouse table for it? Or is it the same as work orders?" |
| A3 | **What is the source for Bills of Materials?** | Valmir | Referenced in SOW but no data source or RAW table identified | "Is this from SAP (BOM explosion)? PPR materials? PPV? Do you have an OData service or Fabric table for BOMs?" |
| A4 | **What are Orders, Shipments and Trends (SOW)?** | Cam | SOW requirement with unclear data source | "Cam mentioned shipments come from PPR and some UC1 inputs from spreadsheets (flat rate/ton). Is `ppr_hist_order_item` the right table? What about the spreadsheet data — how do we ingest it?" |
| A5 | **Is `ppr_hist_roll_quality` (PPR system) different from SharePoint `roll_quality`?** | Sylvamo | Two tables with overlapping names but likely different data (automated vs manual) | "We have roll quality data from two sources. PPR appears to be automated quality measurements. SharePoint appears to be manual inspection reports. Are these different? Should both go into the model?" |
| A6 | **What should map to Recipe, ProductDefinition, QualityResult, LabTest, Measurement in `mfg_data`?** | Sylvamo | 5 views in the data model with no defined data source | "We have candidates: `ppr_hist_blend` → Recipe? `samples`/`tests` → LabTest? `ppr_hist_roll_quality` → QualityResult? Help us confirm the mappings." |
| A7 | **Can you provide source row counts so we can validate extraction completeness?** | Cam/Valmir | We need to confirm RAW data matches source to trust the pipeline | "For each Fabric table and SAP endpoint, what's the expected row count? We'll compare against what landed in CDF RAW." |
| A8 | **Is `s519pip1` the Sumter PI server?** | Cam | PI server S519 — site mapping unclear. Data reported as "missing" | "We have 3 PI servers: S769PI01 (Eastover), S769PI03 (PM), S519PIP1 (?). Is S519 = Sumter? Is the data complete?" |
| A9 | **Is there an IFLOT (Functional Locations) table in Fabric?** | Valmir | Needed for Equipment view in mfg_ext — currently empty | "We need SAP functional location / equipment master data. Is there an IFLOT or equipment table in any lakehouse?" |
| A10 | **Which SAP client is correct: `100` or `300`?** | SAP team | OData config uses 100, older docs reference 300 | Verify before expanding OData endpoints |

---

### BUILD — New Transforms / Scripts Needed (Cognite team, after dependencies resolved)

| # | What to Build | Depends On | Effort | Priority |
|---|--------------|-----------|--------|----------|
| B1 | **AUFK+AFKO+AFVC join transformation** → `Operation` view | AFVC extraction complete (F4 above) | Medium | High — sprint 2 goal |
| B2 | **Package transformation** (`ppr_hist_package` → `Package` view) | F3 — re-extract to correct DB | Medium | Medium |
| B3 | **Validation script** — compare RAW row counts vs Fabric source and vs model instance counts | A7 — need expected counts from Sylvamo | Medium | High |
| B4 | **File metadata transformation** — enrich CogniteFile with SharePoint metadata | Clarify `documents` table "duplicate" flag | Small | Medium |
| B5 | **Blend → Recipe transformation** (if confirmed) | A6 — confirm mapping with Sylvamo | Small | Low — pending confirmation |
| B6 | **Proficy tests/samples → LabTest transformation** (if confirmed) | A6 — confirm mapping with Sylvamo | Small | Low — pending confirmation |

---

### INVESTIGATE — Unknowns to Research (Cognite team, can do independently)

| # | What to Investigate | Expected Outcome | Effort |
|---|-------------------|-----------------|--------|
| I1 | **PI metadata tables** (`s769pi01_metadata`, `s769pi03_metadata`, `s519pip1_metadata`) — do they contain useful data? | Determine if tag metadata should feed into model or is just reference | Small — read RAW tables in CDF |
| I2 | **SharePoint `documents` table** — why is it marked "duplicate"? | Clarify if documents go to RAW + CDF Files (double), or if RAW table is stale | Small — check CDF |
| I3 | **Relationship between `mfg_core`/`mfg_extended` and `mfg_data` (v10)** | Understand which model is the "real" production model and which is legacy | Medium — review model definitions |
| I4 | **PPR-to-Proficy join key** — validate naming convention mapping | Ensure reel_number ↔ Event_Num cross-reference works reliably | Small — test with sample data |
| I5 | **Proficy `key_columns`, `event_tables`, `all_tables`** — are these just metadata? | Confirm these are internal GBDB metadata and can be deprioritized | Small — read RAW tables |

---

### Quick-Reference Priority Matrix

```
                    ┌──────────────────────────────────────────┐
  URGENT            │  F1  F2  F3  F4  F5                     │  Fix configs & re-run extractors
  (do this week)    │  A1  A2  A3  A7                         │  Ask Sylvamo (schedule meeting)
                    │  B1                                      │  Build join transform
                    ├──────────────────────────────────────────┤
  IMPORTANT         │  B2  B3                                  │  Package transform + validation
  (this sprint)     │  A4  A5  A6  A8  A9                     │  Clarify data sources
                    │  I1  I2  I3                              │  Investigate unknowns
                    ├──────────────────────────────────────────┤
  BACKLOG           │  F6  B4  B5  B6                          │  Cleanup + pending transforms
  (next sprint)     │  A10  I4  I5                             │  SAP client + minor research
                    └──────────────────────────────────────────┘
```

---

*Document version: 3.0 — Updated 2026-02-10. Combined Source Systems + Pipeline Mapping into single Section 3. Added prioritized punch list (Section 10).*
