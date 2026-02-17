> **Note:** These materials were prepared for the Sprint 2 demo (Feb 2026) and may contain outdated statistics. Verify current data in CDF.

# Sylvamo Data Pipeline Deep Dive

> **Purpose:** Detailed technical reference for all data flowing into CDF  
> **Audience:** Technical team, presenters needing backup detail  
> **Last Updated:** 2026-02-12  
> **Source:** [DATA_SOURCE_REGISTRY.md](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/blob/main/docs/reference/extractors/DATA_SOURCE_REGISTRY.md)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Fabric Infrastructure Map](#2-fabric-infrastructure-map)
3. [Complete Pipeline Mapping](#3-complete-pipeline-mapping)
4. [PPR Extraction Architecture](#4-ppr-extraction-architecture)
5. [Data Model Summary](#5-data-model-summary)
6. [Gap Analysis](#6-gap-analysis)
7. [Known Issues & Workarounds](#7-known-issues--workarounds)
8. [Validation Checklist](#8-validation-checklist)

---

## 1. Architecture Overview

```
┌─────────────────────┐     ┌──────────────┐     ┌──────────────┐     ┌────────────────────┐     ┌─────────────────────┐
│   SOURCE SYSTEMS    │────▶│  EXTRACTORS  │────▶│  RAW TABLES  │────▶│  TRANSFORMATIONS   │────▶│   DATA MODEL VIEWS  │
│                     │     │              │     │              │     │                    │     │                     │
│ • Fabric (PPR/PPV)  │     │ • fabric-*   │     │ raw_ext_*    │     │ • populate_*       │     │ sylvamo_mfg_core    │
│ • Fabric (SAP ECC)  │     │ • sap-odata  │     │              │     │ • create_*         │     │ sylvamo_mfg_ext     │
│ • SAP Gateway       │     │ • sql-ext    │     │              │     │                    │     │                     │
│ • Proficy GBDB      │     │ • pi-ext     │     │              │     │                    │     │                     │
│ • PI Servers        │     │ • sp-ext     │     │              │     │                    │     │                     │
│ • SharePoint        │     │              │     │              │     │                    │     │                     │
└─────────────────────┘     └──────────────┘     └──────────────┘     └────────────────────┘     └─────────────────────┘
```

### Key Numbers

| Metric | Value |
|--------|-------|
| Source Systems | 6 (Fabric PPR, Fabric PPV, Fabric SAP ECC, SAP Gateway, Proficy, PI, SharePoint) |
| Extractors | 7 active |
| RAW Databases | 6 (`raw_ext_*` naming) |
| RAW Tables | 35+ |
| Transformations | 24 SQL |
| Data Model Views | 8 (mfg_core) + 8 (mfg_extended) |
| Total Nodes | 450,000+ |

---

## 2. Fabric Infrastructure Map

### 2.1 Workspaces & Lakehouses

| # | Workspace | Lakehouse | Data Domain | SP Access |
|---|-----------|-----------|-------------|-----------|
| 1 | `ws_enterprise_prod` | `LH_SILVER_ppreo` | PPR production data (reels, rolls, packages, quality, blends) | sp-dev ✅ |
| 2 | `ws_enterprise_prod` | `LH_SILVER_ppreo` | PPV cost data (`Tables/enterprise/ppv_snapshot`) | sp-dev ✅ |
| 3 | CoE workspace | `lh_gold_pm` | SAP PM work orders (IW28) | sp-dev ✅ |
| 4 | `ws_enterprise_dev` | `LH_SILVER_sapecc` | SAP ECC tables (AUFK, AFKO, AFVC) | sp-dev ✅ |
| 5 | `ws_enterprise_prod` | `LH_SILVER_sapecc` | SAP ECC tables (prod copy) | sp-prod only ❌ |

### 2.2 Service Principals

| Service Principal | App ID | Access Scope |
|-------------------|--------|-------------|
| `sp-cdf-fabric-extractor-dev` | `73a40d42-8cf4-4048-80d1-54c8d28cb58d` | Fabric Lakehouses (PPR, PPV, SAP PM) |
| `sp-cdf-sap-extractor-dev` | `778dcec6-a85a-4799-a78e-1aee9d7aa3d3` | SAP Gateway OData |
| `sp-cdf-pi-extractor-dev` | `b7671a6c-8680-4b10-b8d0-141767de9877` | PI Servers |
| `sp-cdf-file-extractor-dev` | `4050f0ee-519e-4485-ac2b-f3221071c92e` | SharePoint Online |
| `sp-cdf-sql-extractor-dev` | `3ec90782-5f9f-482d-9da2-46567276519b` | Proficy GBDB SQL Server |

### 2.3 Fabric Table Inventory

**LH_SILVER_ppreo (PPR):**

| Fabric Path | Description | Key Columns |
|-------------|-------------|-------------|
| `Tables/HIST_REEL` | Reel production history | `reel_number`, `reel_manufactured_date`, `reel_product_code`, `reel_average_basis_weight`, `reel_finished_weight` |
| `Tables/HIST_ROLL` | Roll production history | `roll_number`, `roll_reel_number`, `roll_basis_weight`, `roll_width_num`, `ROLL_MANUFACTURING_DATE` |
| `Tables/HIST_PACKAGE` | Package/shipping units | `pack_package_number`, `pack_number_rolls_in_package`, `pack_ship_date` |
| `Tables/HIST_ROLL_QUALITY` | Roll quality measurements | Quality metrics, test results, flags |
| `Tables/HIST_BLEND` | Blend/recipe compositions | Material mix ratios |
| `Tables/HIST_MATERIAL` | Material information | Material codes, descriptions |
| `Tables/HIST_ORDER_ITEM` | Customer order items | Order references |
| `Tables/PRODUCTION_TOTAL` | Production metrics | Daily/shift summaries |
| `Tables/MILL` | Mill reference data | Mill codes, names |

**lh_gold_pm (SAP PM):**

| Fabric Path | SAP Transaction | Description |
|-------------|-----------------|-------------|
| `Tables/iw28` | IW28 | SAP Work Order List - **Filter:** `WERKS IN ('0769', '0519')` |

**LH_SILVER_sapecc (SAP ECC):**

| Fabric Path | SAP Table | Description |
|-------------|-----------|-------------|
| `Tables/AUFK` | AUFK | Order Master Data (~4.5M rows) |
| `Tables/AFKO` | AFKO | Order Header Data (~4.5M rows) |
| `Tables/AFVC` | AFVC | Order Operations (~7.2M rows) |

**Plant Code Reference:**

| Plant Code | Mill Name |
|-----------|-----------|
| `0769` | Eastover Mill |
| `0519` | Sumter Mill |

---

## 3. Complete Pipeline Mapping

### Legend

✅ End-to-end | 🔶 Partial | ❌ Missing | ⏳ Pending

### Fabric — PPR (LH_SILVER_ppreo)

| # | RAW Table | Description | Expected Rows | Transformation | Target View | Status |
|---|-----------|-------------|---------------|----------------|-------------|--------|
| 1 | `ppr_hist_reel` | Reel production history | ~61,000 | `populate_Reel` | Reel | ✅ |
| 2 | `ppr_hist_roll` | Roll history | ~2,300,000 | `populate_Roll` | Roll | ✅ |
| 3 | `ppr_hist_package` | Package/shipping | ~50,000 | ❌ None | Package (pending) | 🔶 |
| 4 | `ppr_hist_roll_quality` | Quality measurements | ❓ | ❌ None | QualityResult | 🔶 |
| 5 | `ppr_hist_blend` | Blend compositions | ❓ | ❌ None | Recipe? | 🔶 |
| 6 | `ppr_hist_material` | Material info | ❓ | ❌ None | — | 🔶 |
| 7 | `ppr_hist_order_item` | Customer orders | ❓ | ❌ None | — | ⏳ |
| 8 | `ppr_production_total` | Production metrics | ❓ | ❌ None | — | 🔶 |
| 9 | `ppr_mill` | Mill reference | ❓ | ❌ None | — | 🔶 |

### Fabric — PPV

| # | RAW Table | Description | Expected Rows | Transformation | Target View | Status |
|---|-----------|-------------|---------------|----------------|-------------|--------|
| 10 | `ppv_snapshot` | Material cost / PPV | ~200 | `populate_Event_PPV` | Event | ✅ |
| 11 | `ppv_snapshot` | (same) | (same) | `populate_CostEvent` | CostEvent | ✅ |

### Fabric — SAP ECC

| # | RAW Table | Description | Expected Rows | Transformation | Target View | Status |
|---|-----------|-------------|---------------|----------------|-------------|--------|
| 12 | `sapecc_work_orders` | Work Orders (IW28) | ~407,000 | `populate_Event_WorkOrders` | Event | ✅ |
| 13 | `sapecc_work_orders` | (same) | (same) | `populate_WorkOrder` | WorkOrder | ✅ |
| 14 | `sapecc_aufk` | Order Master Data | ~4,500,000 | ❌ (join pending) | Operation | 🔶 |
| 15 | `sapecc_afko` | Order Header Data | ~4,500,000 | ❌ (join pending) | Operation | 🔶 |
| 16 | `sapecc_afvc` | Order Operations | ~7,200,000 | ❌ (join pending) | Operation | 🔶 |

### SAP Gateway (OData)

| # | RAW Table | Description | Transformation | Target View | Status |
|---|-----------|-------------|----------------|-------------|--------|
| 17 | `asset_hierarchy` | SAP Functional Locations | `populate_Asset` | Asset | ✅ |
| 18 | `materials` | Material master data | `populate_Material` | Material | ✅ |
| 19 | `production_orders` | Production orders | `populate_ProductionOrder` | ProductionOrder | ✅ |
| 20 | `bp_details` | Business Partner | ❌ None | — | 🔶 |

### Proficy GBDB

| # | RAW Table | Description | Transformation | Target View | Status |
|---|-----------|-------------|----------------|-------------|--------|
| 21 | `events_tests` | Production events + tests | `populate_Event_Proficy` | Event | ✅ |
| 22 | `events_tests` | (same) | `populate_ProductionEvent` | ProductionEvent | ✅ |
| 23 | `events_tests` | (same) | `populate_ProficyDatapoints` | TS Datapoints | ✅ |
| 24 | `tag_info` | Tag metadata | `populate_ProficyTimeSeries` | MfgTimeSeries | ✅ |
| 25 | `tests` | Lab test definitions | ❌ None | LabTest? | 🔶 |
| 26 | `samples` | Sample tracking | ❌ None | LabTest? | 🔶 |

### PI Servers

| # | RAW Table | PI Server | Transformation | Target View | Status |
|---|-----------|-----------|----------------|-------------|--------|
| 27 | `s769pi01_metadata` | S769PI01 (Eastover) | `populate_TimeSeries` | MfgTimeSeries | ✅ |
| 28 | `s769pi03_metadata` | S769PI03 (PM) | `populate_TimeSeries` | MfgTimeSeries | ✅ |
| 29 | `s519pip1_metadata` | S519PIP1 (Sumter?) | `populate_TimeSeries` | MfgTimeSeries | ✅ |

### SharePoint

| # | RAW Table | Description | Transformation | Target View | Status |
|---|-----------|-------------|----------------|-------------|--------|
| 30 | `documents` | SharePoint files | `populate_Files` | CogniteFile | ✅ |
| 31 | `roll_quality` | Quality inspection reports | `populate_RollQuality` | RollQuality | ✅ |

### Pipeline Summary

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ End-to-end | 17 | 55% |
| 🔶 Partial | 13 | 42% |
| ⏳ Pending | 1 | 3% |

---

## 4. PPR Extraction Architecture

All 9 PPR tables are deployed via `Setup-FabricExtractors.ps1` on VM `C:\Cognite\FabricExtractor`.

### Deployment Components

| Component | Tables | Technology | Details |
|-----------|--------|------------|---------|
| **Windows Service** | HIST_REEL (~61K) | 32-bit Fabric connector | `FabricConnector` service, auto-restart |
| **Python 64-bit** | HIST_ROLL (~2.3M), HIST_ORDER_ITEM | Custom `deltalake` + `cognite-sdk` | Task Scheduler, 50K-row batches |
| **Task Scheduler** | 6 other PPR tables | 32-bit Fabric connector | Hourly polling |

### Why Python 64-bit for Large Tables?

The 32-bit Fabric connector executable is limited to ~2GB virtual address space. Tables with >2M rows cause:
- `ArrowMemoryError`
- `malloc failed`
- `inflateInit() failed`

The custom Python extractor (`fabric_delta_extractor.py`) uses 64-bit Python with the `deltalake` library for efficient Delta Lake reads.

### Scripts

| Script | Purpose |
|--------|---------|
| `Setup-FabricExtractors.ps1` | Consolidated deployment (generates configs, installs service, creates tasks) |
| `Manage-FabricExtractors.ps1` | Management (Status, Start, Stop, Restart, Logs) |
| `fabric_delta_extractor.py` | 64-bit Python extractor for large tables |

### Resolved Issues (2026-02-11)

- ✅ **DB naming:** All configs now use `raw_ext_fabric_ppr`
- ✅ **OOM on large tables:** Python 64-bit extractor
- ✅ **Trailing space in table name:** HIST_ROLL_QUALITY config corrected
- ✅ **md5-key:** All tables configured with `md5-key: true`
- ✅ **KeyError bug:** One table per config file (13 separate YAMLs)

---

## 5. Data Model Summary

### Model Hierarchy

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     sylvamo_mfg_core (v1)                                │
│  Schema: sylvamo_mfg_core_schema | Instances: sylvamo_mfg_core_instances│
│                                                                          │
│  Views: Asset, Event, Material, Reel, Roll, RollQuality,                │
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
```

### View-to-Data-Source Mapping

| Data Model | View | Populated By | Source RAW | Status |
|------------|------|-------------|------------|--------|
| mfg_core | Asset | `populate_Asset` | `raw_ext_sap.sap_floc_*` | ✅ 44,898 nodes |
| mfg_core | Material | `populate_Material` | `raw_ext_sap.materials` | ✅ 58,342+ |
| mfg_core | Reel | `populate_Reel` | `raw_ext_fabric_ppr.ppr_hist_reel` | ✅ 83,600+ |
| mfg_core | Roll | `populate_Roll` | `raw_ext_fabric_ppr.ppr_hist_roll` | ✅ 2.3M+ |
| mfg_core | RollQuality | `populate_RollQuality` | `raw_ext_sharepoint.roll_quality` | ✅ 21+ |
| mfg_core | Event | Multiple | SAP, Proficy, Fabric | ✅ 92,000+ |
| mfg_core | MfgTimeSeries | `populate_TimeSeries` | PI + Proficy | ✅ 3,532 |
| mfg_core | CogniteFile | `populate_Files` | `_cdf.files` | ✅ 97 |
| mfg_ext | WorkOrder | `populate_WorkOrder` | `sapecc_work_orders` | ✅ 407,000 |
| mfg_ext | ProductionOrder | `populate_ProductionOrder` | `production_orders` | ✅ |
| mfg_ext | ProductionEvent | `populate_ProductionEvent` | `events_tests` | ✅ |
| mfg_ext | CostEvent | `populate_CostEvent` | `ppv_snapshot` | ✅ |
| mfg_ext | Operation | ❌ None | `sapecc_afvc` | 🔶 Pending |
| mfg_ext | Equipment | ❌ None | — | ❌ No source |
| mfg_ext | Notification | ❌ None | — | ❌ No source |

---

## 6. Gap Analysis

### RAW Tables Without Transformations

| RAW Table | Potential Target | Priority | Action |
|-----------|-----------------|----------|--------|
| `ppr_hist_package` | Package (mfg_data) | High | Create transformation |
| `ppr_hist_roll_quality` | QualityResult | Medium | Clarify vs SharePoint |
| `ppr_hist_blend` | Recipe | Medium | Confirm mapping |
| `sapecc_aufk/afko/afvc` | Operation | High | Build join transform |
| `tests` + `samples` | LabTest | Medium | Proficy reference data |

### Data Model Views Without Data Sources

| View | Required Data Source | Status |
|------|---------------------|--------|
| Equipment | SAP equipment master (IFLOT?) | ❌ No source identified |
| Notification | SAP IW29 or similar | ❌ Valmir to provide |
| Operation | AUFK+AFKO+AFVC join | 🔶 Data ready, transform needed |

### Source Conflicts

| Issue | Details | Resolution |
|-------|---------|------------|
| Work orders dual source | OData vs Fabric IW28 | Fabric is primary (407K rows) |
| Roll quality dual source | PPR vs SharePoint | Different data - both needed |
| Material dual source | SAP vs PPR | SAP = source of truth |

---

## 7. Known Issues & Workarounds

### Fabric Connector Issues

| Issue | Symptom | Workaround |
|-------|---------|------------|
| KeyError bug | Crashes with multiple tables | One config per table |
| Default batch size | Only 1,000 rows | Set `read_batch_size: 100000` |
| OOM on 32-bit | ArrowMemoryError | Python 64-bit extractor |
| Row key overwrite | Duplicates | `md5-key: true` |

### SAP OData Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| 401 Unauthorized | `Anmeldung fehlgeschlagen` | Verify COGNITE credentials |
| 500 Internal | RFC Bridge error | SAP team fix SM59 |
| Empty response | Wrong client/filter | Verify `sap-client` value |

---

## 8. Validation Checklist

### Extraction Validation

| Source | RAW Table | Expected | Actual | Match? |
|--------|-----------|----------|--------|--------|
| PPR | `ppr_hist_reel` | ~61,000 | ❓ | — |
| PPR | `ppr_hist_roll` | ~2,300,000 | ❓ | — |
| PPR | `ppr_hist_package` | ~50,000 | ❓ | — |
| SAP ECC | `sapecc_work_orders` | ~407,000 | ✅ | ✅ |
| SAP ECC | `sapecc_aufk` | ~4,500,000 | ❓ | — |
| PPV | `ppv_snapshot` | ~200 | ❓ | — |

### Transformation Validation

| Transformation | Source Rows | Instances Created | Status |
|---------------|-------------|-------------------|--------|
| `populate_Asset` | ❓ | 44,898 | ✅ |
| `populate_Reel` | ~61K | 83,600+ | ✅ |
| `populate_Roll` | ~2.3M | 2,300,000+ | ✅ |
| `populate_WorkOrder` | ~407K | ❓ | ✅ |

---

## Quick Reference: RAW Database Naming

| Database | Source | Tables |
|----------|--------|--------|
| `raw_ext_fabric_ppr` | Fabric PPR | 9 tables (reels, rolls, packages, etc.) |
| `raw_ext_fabric_ppv` | Fabric PPV | 1 table (ppv_snapshot) |
| `raw_ext_fabric_sapecc` | Fabric SAP ECC | 4 tables (work_orders, aufk, afko, afvc) |
| `raw_ext_sap` | SAP Gateway OData | 4 tables (assets, materials, orders, bp) |
| `raw_ext_sql_proficy` | Proficy GBDB | 6 tables (events, tags, tests, samples) |
| `raw_ext_pi` | PI Server | 3 tables (metadata per server) |
| `raw_ext_sharepoint` | SharePoint | 2 tables (documents, roll_quality) |

---

*Data pipeline reference for Sylvamo CDF implementation*
