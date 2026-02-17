# Data Pipeline & Sources

**Date:** 2026-02-17 (Updated)  
**Model:** `sylvamo_mfg_core` (Production, 7 views). `sylvamo_mfg_extended` exists but is secondary.

---

> **Note:** For comprehensive transformation documentation including SQL examples, data flow diagrams, and troubleshooting, see [TRANSFORMATIONS.md](../data-model/TRANSFORMATIONS.md).

---

## Overview

This document describes the data sources and extractors that feed into the Sylvamo CDF data model. For transformation details, see the [comprehensive transformation documentation](../data-model/TRANSFORMATIONS.md).

## Data Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SOURCE SYSTEMS                                     │
├─────────────────┬─────────────────┬─────────────────┬──────────────────────┤
│   SAP ERP       │   PPR System    │   SharePoint    │   Proficy            │
│   (Materials)   │   (Production)  │   (Quality)     │   (Lab Tests)        │
└────────┬────────┴────────┬────────┴────────┬────────┴──────────┬───────────┘
         │                 │                 │                   │
         ▼                 ▼                 ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MICROSOFT FABRIC                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ PPV Snapshot│  │ PPR Hist    │  │ Roll Quality│  │ Event Tests         │ │
│  │ (SAP Data)  │  │ Reel/Roll   │  │ Reports     │  │ (Lab Data)          │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└────────┬────────────────┬────────────────┬────────────────┬─────────────────┘
         │                │                │                │
         ▼                ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CDF RAW DATABASES                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  raw_ext_fabric_ppr/                                                         │
│    ├── ppr_hist_reel         → Reel                                          │
│    ├── ppr_hist_roll         → Roll                                          │
│    └── ppr_hist_package      → (future)                                       │
│                                                                              │
│  raw_ext_fabric_ppv/                                                         │
│    └── ppv_snapshot          → CostEvent (extended, secondary)                          │
│                                                                              │
│  raw_ext_sharepoint/                                                         │
│    └── roll_quality          → RollQuality (mfg_core)                                 │
│                                                                              │
│  raw_ext_sql_proficy/                                                        │
│    └── tests                 → RollQuality (mfg_core) (lab tests)                     │
└────────────────────────────────────────────────────────────────────────────┘
         │
         ▼ [Transformations]
┌─────────────────────────────────────────────────────────────────────────────┐
│                      sylvamo_mfg_core (7 views)                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  Views:                                                                      │
│    Asset, Event, Material, MfgTimeSeries, Reel, Roll, RollQuality           │
│    (Equipment is modeled as assetType on Asset)                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Sources

### 1. SAP ERP Data (via Fabric)

| RAW Table | Description | Refresh |
|-----------|-------------|---------|
| `raw_ext_fabric_ppv/ppv_snapshot` | Material cost and PPV data | Daily |

**Key Fields:**
- `material` - SAP material number
- `material_description` - Material name
- `material_type` - Classification (RAWM, HALB, etc.)
- `plant` - Plant code
- `current_ppv` / `prior_ppv` - Purchase price variance
- `current_standard_cost` / `prior_standard_cost` - Standard costs
- `ppv_snapshot_date` - Snapshot timestamp

### 2. PPR Production Data (via Fabric)

| RAW Table | Description | Records |
|-----------|-------------|---------|
| `raw_ext_fabric_ppr/ppr_hist_reel` | Paper reel production history | 61,000+ |
| `raw_ext_fabric_ppr/ppr_hist_roll` | Cut roll history | 200,000+ |
| `raw_ext_fabric_ppr/ppr_hist_package` | Package/shipping history | 50,000+ |

**Reel Key Fields:**
- `reel_number` - Unique reel identifier (e.g., EM0010110008)
- `reel_manufactured_date` - Production date (YYYYMMDD)
- `reel_product_code` - Product type (W = Wove)
- `reel_average_basis_weight` - Basis weight measurement
- `reel_average_caliper` - Caliper measurement
- `reel_average_moisture` - Moisture percentage
- `reel_finished_weight` - Final weight in lbs
- `reel_status_ind` - Status code (C = Complete)

**Roll Key Fields:**
- `roll_number` - Unique roll identifier
- `roll_reel_number` - Parent reel reference
- `roll_basis_weight` - Basis weight
- `roll_caliper` - Caliper measurement
- `roll_current_weight` - Weight in lbs
- `roll_producing_machine` - Machine code (EMW01, etc.)

**Package Key Fields:**
- `pack_package_number` - Unique package ID
- `pack_number_rolls_in_package` - Roll count
- `pack_assembled_date` - Assembly date
- `pack_ship_date` - Shipping date
- `pack_current_inv_point` - Inventory location

### 3. SharePoint Quality Data

> **Codebase:** `cdf_sharepoint` module also uses `files_metadata` for PDF→CogniteFile population.


| RAW Table | Description | Records |
|-----------|-------------|---------|
| `raw_ext_sharepoint/roll_quality` | Roll quality inspection reports | 580+ |

**Key Fields:**
- `title` - Roll ID being inspected
- `defect` - Defect code (e.g., "005 - Crushed Edge")
- `was_the_roll_rejected` - Yes/No
- `location` - Defect location (Top, Bottom, All)
- `who_is_entering` - Inspector name
- `created_by` - Source equipment (e.g., "Mill Floor Sheeter Sheeter 1")

### 4. Proficy Lab Data (SQL Extractor)

| RAW Table | Description | Status |
|-----------|-------------|--------|
| `raw_ext_sql_proficy/tests` | Lab test results | Configured |
| `raw_ext_sql_proficy/events` | Production events | Configured |

---

## Transformations

### Transform 1: RAW → Reel

**Source:** `raw_ext_fabric_ppr/ppr_hist_reel`  
**Target:** `sylvamo_mfg_core:Reel`

```sql
-- Transformation: populate_reels
SELECT
  CONCAT('reel:', REEL_NUMBER) AS externalId,
  REEL_NUMBER AS reelNumber,
  TO_TIMESTAMP(REEL_MANUFACTURED_DATE, 'YYYYMMDD') AS productionDate,
  CAST(REEL_FINISHED_WEIGHT AS FLOAT) AS weight,
  CAST(REEL_REEL_WIDTH_NUM AS FLOAT) AS width,
  CAST(REEL_ACTUAL_DIAMETER_NUM AS FLOAT) AS diameter,
  REEL_STATUS_IND AS status,
  -- Product mapping based on basis weight
  CASE 
    WHEN REEL_AVERAGE_BASIS_WEIGHT < 22 THEN 'product:wove-20'
    ELSE 'product:wove-24'
  END AS productDefinition_externalId,
  'floc:0769-06-01-010' AS asset_externalId  // ADR-001: Reel links to Asset
FROM `raw_ext_fabric_ppr`.`ppr_hist_reel`
```

### Transform 2: RAW → Roll

**Source:** `raw_ext_fabric_ppr/ppr_hist_roll`  
**Target:** `sylvamo_mfg_core:Roll`

```sql
-- Transformation: populate_rolls
SELECT
  CONCAT('roll:', ROLL_NUMBER) AS externalId,
  ROLL_NUMBER AS rollNumber,
  CAST(ROLL_WIDTH_NUM AS FLOAT) AS width,
  CAST(ROLL_ORIGINAL_DIAMETER AS FLOAT) AS diameter,
  CAST(ROLL_CURRENT_WEIGHT AS FLOAT) AS weight,
  'Produced' AS status,
  'A' AS qualityGrade,
  CONCAT('reel:', ROLL_REEL_NUMBER) AS reel_externalId
FROM `raw_ext_fabric_ppr`.`ppr_hist_roll`
```

### Transform 3: RAW → (future)

**Source:** `raw_ext_fabric_ppr/ppr_hist_package`  
**Target:** `sylvamo_mfg_core:Package (future)`

```sql
-- Transformation: populate_packages
SELECT
  CONCAT('pkg:', PACK_PACKAGE_NUMBER) AS externalId,
  PACK_PACKAGE_NUMBER AS packageNumber,
  CAST(PACK_NUMBER_ROLLS_IN_PACKAGE AS INT) AS rollCount,
  CASE 
    WHEN PACK_SHIP_DATE IS NOT NULL AND TRIM(PACK_SHIP_DATE) != '' THEN 'Shipped'
    WHEN PACK_ASSEMBLED_DATE IS NOT NULL THEN 'Assembled'
    ELSE 'Created'
  END AS status,
  TO_TIMESTAMP(PACK_SHIP_DATE, 'YYYYMMDD') AS shippedDate,
  'asset:eastover' AS sourcePlant_externalId,
  'asset:sumpter' AS destinationPlant_externalId
FROM `raw_ext_fabric_ppr`.`ppr_hist_package`
```

### Transform 4: RAW → CostEvent (extended, secondary)

**Source:** `raw_ext_fabric_ppv/ppv_snapshot`  
**Target:** `sylvamo_mfg_extended:CostEvent`

```sql
-- Transformation: populate_material_cost_variance
SELECT
  CONCAT('mcv:', material) AS externalId,
  CAST(material AS STRING) AS material,
  material_description AS materialDescription,
  material_type AS materialType,
  plant,
  gl_account AS glAccount,
  units,
  CAST(current_quantity AS FLOAT) AS currentQuantity,
  CAST(prior_quantity AS FLOAT) AS priorQuantity,
  CAST(current_standard_cost AS FLOAT) AS currentStandardCost,
  CAST(prior_standard_cost AS FLOAT) AS priorStandardCost,
  CAST(current_unit_cost AS FLOAT) AS currentUnitCost,
  CAST(prior_unit_cost AS FLOAT) AS priorUnitCost,
  CAST(current_ppv AS FLOAT) AS currentPPV,
  CAST(prior_ppv AS FLOAT) AS priorPPV,
  CAST(current_ppv AS FLOAT) - CAST(prior_ppv AS FLOAT) AS ppvChange,
  TO_TIMESTAMP(ppv_snapshot_date) AS snapshotDate,
  CAST(ppv_surrogate_key AS STRING) AS surrogateKey
FROM `raw_ext_fabric_ppv`.`ppv_snapshot`
```

### Transform 5: RAW → RollQuality (mfg_core)

**Source:** `raw_ext_sharepoint/roll_quality`  
**Target:** `sylvamo_mfg_core:RollQuality`

```sql
-- Transformation: populate_quality_results
SELECT
  CONCAT('qr:', title) AS externalId,
  'Roll Quality Inspection' AS testName,
  'Visual Inspection' AS testMethod,
  COALESCE(defect, 'No defects') AS resultText,
  CASE WHEN was_the_roll_rejected = 'Yes' THEN FALSE ELSE TRUE END AS isInSpec,
  CONCAT('roll:', title) AS roll_externalId
FROM `raw_ext_sharepoint`.`roll_quality`
```

---

## Data Refresh Schedule

| Transformation | Frequency | Window |
|----------------|-----------|--------|
| populate_reels | Daily | 2:00 AM EST |
| populate_rolls | Daily | 2:15 AM EST |
| populate_packages | Daily | 2:30 AM EST |
| populate_material_cost_variance | Daily | 3:00 AM EST |
| populate_quality_results | Hourly | On change |

---

## Data Quality Rules

### Roll ID Normalization
- SharePoint roll IDs may have 'EM' prefix stripped
- Transformation adds 'EM' prefix if missing for matching

### Timestamp Handling
- PPR dates in YYYYMMDD format → ISO 8601
- Null dates handled gracefully

### Material Deduplication
- Materials are unique by material number
- Latest snapshot retained on conflict

---

## Current Data Statistics

> **Verified:** February 2026 against CDF sylvamo-dev

| Entity | Count | Source |
|--------|-------|--------|
| Asset | 45,900+ | SAP Functional Locations (ISA-95 assetType) |
| Reel | 83,600+ | `raw_ext_fabric_ppr/ppr_hist_reel` |
| Roll | 2,300,000+ | `raw_ext_fabric_ppr/ppr_hist_roll` |
| RollQuality | 580 | `raw_ext_sharepoint/roll_quality` |
| Event | 92,000+ | SAP Work Orders, Proficy, PPV |
| Material | 58,000+ | SAP Material Master |
| MfgTimeSeries | 3,500+ | PI Server |
| CostEvent | 716 | `raw_ext_fabric_ppv/ppv_snapshot` |
| **TOTAL** | **450,000+** | mfg_core (primary) |

---

*Document updated: February 17, 2026*
