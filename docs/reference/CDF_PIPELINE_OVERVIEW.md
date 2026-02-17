# CDF Pipeline Overview — Sylvamo mfg_core

> **Purpose:** Single-page overview of the complete data pipeline — source systems, extractors, RAW tables, transformations, CDF functions, and data model.  
> **Source:** Extracted from `sylvamo/modules/` codebase  
> **Last Updated:** February 2026

---

## 1. End-to-End Flow

```
SOURCE SYSTEMS          EXTRACTORS (Pipelines)       RAW TABLES              TRANSFORMATIONS / FUNCTIONS       DATA MODEL
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
SAP Gateway (OData)  →  ep_db_extractor (Cont.)   →  raw_ext_sap            →  populate_Asset                   →  Asset
                                                      raw_ext_sql_proficy  →  populate_Material                 →  Material
Proficy GBDB        →  (same)                    →  raw_ext_sql_proficy   →  populate_Event_Proficy            →  Event
                                                                          →  populate_ProficyTimeSeries        →  MfgTimeSeries
                                                                          →  create_ProficyTimeSeries_CDF      →  CDF TimeSeries
                                                                          →  de_proficy_datapoints_ingest (Fn) →  CDF TimeSeries datapoints

Microsoft Fabric    →  ep_fabric_ppr_hourly       →  raw_ext_fabric_ppr     →  populate_Reel (hourly)           →  Reel
(PPR)                  (0 * * * *)                   ppr_gr, ppr_ll, etc   →  populate_Roll (hourly)           →  Roll
                   →  ep_fabric_ppr_hist_reel    →  ppr_hist_reel
                      (Continuous)
                   →  ep_fabric_ppr_daily        →  ppr_hist_roll, etc
                      (0 2 * * *)

Microsoft Fabric    →  ep_fabric_ppv_daily        →  raw_ext_fabric_ppv     →  populate_Event_PPV               →  Event
(PPV)                  (0 2 * * *)                   ppv_snapshot         →  populate_CostEvent               →  CostEvent

Microsoft Fabric    →  ep_fabric_sapecc_daily     →  raw_ext_fabric_sapecc  →  populate_Event_WorkOrders        →  Event
(SAP ECC)               (0 2 * * *)                   sapecc_work_orders   →  populate_WorkOrder               →  WorkOrder

PI Servers          →  ep_pi_s769pi03             →  CDF TimeSeries         →  populate_TimeSeries              →  MfgTimeSeries
                      ep_pi_s769pi01 (Cont.)
                      ep_pi_s519pip1

SharePoint          →  ep_file_extractor (Cont.) →  raw_ext_sharepoint     →  populate_Files                   →  CogniteFile
                                                      roll_quality         →  populate_RollQuality             →  RollQuality
                                                                          →  de_sharepoint_list_to_data_model →  RollQuality (CDF Function)
                                                      (CDF Function, Mon–Fri hourly)
```

---

## 2. Extraction Pipelines (from codebase)

| externalId | Name | Schedule | RAW Target | Source |
|------------|------|----------|------------|--------|
| `ep_db_extractor` | DB Extractor - SAP OData & Proficy | Continuous | raw_ext_sap, raw_ext_sql_proficy | db-extractor |
| `ep_file_extractor` | File Extractor - SharePoint | Continuous | raw_ext_sharepoint | sharepoint-extractor |
| `ep_pi_s769pi03` | PI Extractor - S769PI03 (PM) | Continuous | raw_ext_pi | pi-extractor |
| `ep_pi_s769pi01` | PI Extractor - S769PI01 (Eastover) | Continuous | raw_ext_pi | pi-extractor |
| `ep_pi_s519pip1` | PI Extractor - S519PIP1 (Sumter) | Continuous | raw_ext_pi | pi-extractor |
| `ep_fabric_ppr_hourly` | Fabric - PPR Hourly (4 tables) | `0 * * * *` | raw_ext_fabric_ppr | fabric-connector-ppr |
| `ep_fabric_ppr_hist_reel` | Fabric - PPR Hist Reel | Continuous | raw_ext_fabric_ppr | fabric-connector-ppr |
| `ep_fabric_ppr_daily` | Fabric - PPR Daily (14 tables) | `0 2 * * *` | raw_ext_fabric_ppr | fabric-connector-ppr |
| `ep_fabric_ppv_daily` | Fabric - PPV Daily | `0 2 * * *` | raw_ext_fabric_ppv | fabric-connector-ppv |
| `ep_fabric_sapecc_daily` | Fabric - SAP ECC Daily | `0 2 * * *` | raw_ext_fabric_sapecc | fabric-connector-sapecc |

---

## 3. Transformations (SQL)

### mfg_core (from `sylvamo/modules/mfg_core/transformations/`)

| Transformation | Source | Target | Schedule |
|----------------|--------|--------|----------|
| `tr_populate_Asset` | raw_ext_sap | Asset | Default |
| `tr_populate_Reel` | raw_ext_fabric_ppr.ppr_hist_reel | Reel | `0 * * * *` (hourly) |
| `tr_populate_Roll` | raw_ext_fabric_ppr.ppr_hist_roll | Roll | `0 * * * *` (hourly) |
| `tr_populate_TimeSeries` | _cdf.timeseries | MfgTimeSeries | Default |
| `tr_populate_Event_WorkOrders` | raw_ext_fabric_sapecc.sapecc_work_orders | Event | Default |
| `tr_populate_Event_PPV` | raw_ext_fabric_ppv.ppv_snapshot | Event | Default |
| `tr_populate_Event_ProductionOrders` | raw_ext_sap.production_orders | Event | Default |
| `tr_populate_Files` | _cdf.files | CogniteFile | Default |
| `tr_populate_Material` | raw_ext_sap.materials | Material | Default |
| `tr_populate_RollQuality` | raw_ext_sharepoint.roll_quality | RollQuality | Default |
| `tr_populate_ProficyTimeSeries` | raw_ext_sql_proficy | MfgTimeSeries | Default |
| `tr_populate_ProficyEventIdTimeSeries` | raw_ext_sql_proficy | MfgTimeSeries | Default |
| `tr_create_ProficyTimeSeries_CDF` | raw_ext_sql_proficy | CDF TimeSeries | Default |
| `tr_create_ProficyEventIdTimeSeries_CDF` | raw_ext_sql_proficy | CDF TimeSeries | Default |

### mfg_extended (from `sylvamo/modules/mfg_extended/transformations/`)

| Transformation | Source | Target |
|----------------|--------|--------|
| `tr_populate_WorkOrder` | Event (filtered) | WorkOrder |
| `tr_populate_ProductionOrder` | Event (filtered) | ProductionOrder |
| `tr_populate_ProductionEvent` | Event (filtered) | ProductionEvent |
| `tr_populate_CostEvent` | Event (filtered) | CostEvent |
| `tr_populate_Operation` | Event (filtered) | Operation |

### admin

| Transformation | Source | Target |
|----------------|--------|--------|
| `tr_populate_SourceSystems` | Reference data | CogniteSourceSystem |

### contextualization (cdf_connection_sql)

| Transformation | Purpose |
|----------------|---------|
| `timeseries_to_asset` | Link time series to assets |
| `timeseries_to_equipment` | Link time series to equipment |
| `activity_to_asset` | Link activities to assets |
| `activity_to_equipment` | Link activities to equipment |
| `activity_to_timeseries` | Link activities to time series |

---

## 4. CDF Functions (scheduled)

| Function | Schedule | Purpose |
|----------|----------|---------|
| `de_sharepoint_list_to_data_model` | `0 * * * 1-5` (Mon–Fri hourly) | Writes SharePoint roll quality list directly to RollQuality view |
| `de_proficy_datapoints_ingest` | `0 * * * *` (hourly) | Writes Proficy numeric and string datapoints to CDF TimeSeries |

> **Note:** RollQuality is populated by both `tr_populate_RollQuality` (from RAW) and `de_sharepoint_list_to_data_model` (direct from SharePoint). The CDF function uses `rq:` external IDs; the transformation uses different logic. See SVQS-244 for alignment.

---

## 5. RAW Databases (from extractors)

| Database | Tables (examples) | Extractor |
|----------|-------------------|-----------|
| raw_ext_sap | 5 (asset_hierarchy, materials, production_orders, etc.) | ep_db_extractor |
| raw_ext_sql_proficy | 6 (events_tests, tag_info, tests, samples, etc.) | ep_db_extractor |
| raw_ext_fabric_ppr | 19+ (ppr_hist_reel, ppr_hist_roll, ppr_hist_package, ppr_gr, ppr_ll, etc.) | ep_fabric_ppr_* |
| raw_ext_fabric_ppv | 1–2 (ppv_snapshot) | ep_fabric_ppv_daily |
| raw_ext_fabric_sapecc | 97+ (sapecc_work_orders, sapecc_aufk, sapecc_afko, sapecc_afvc) | ep_fabric_sapecc_daily |
| raw_ext_pi | timeseries_metadata (per PI server) | ep_pi_* |
| raw_ext_sharepoint | documents, roll_quality, files_metadata | ep_file_extractor |

---

## 6. Related Documentation

| Document | Description |
|----------|-------------|
| [EXTRACTORS.md](extractors/EXTRACTORS.md) | Extractor configuration details |
| [DATA_PIPELINE_AND_SOURCES.md](extractors/DATA_PIPELINE_AND_SOURCES.md) | Data sources and RAW mapping |
| [DATA_SOURCE_REGISTRY.md](extractors/DATA_SOURCE_REGISTRY.md) | Master pipeline table (all RAW tables) |
| [TRANSFORMATIONS.md](data-model/TRANSFORMATIONS.md) | Transformation SQL and data flow |
