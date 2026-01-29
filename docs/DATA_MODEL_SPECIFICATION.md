# Sylvamo Manufacturing Data Model Specification

**Space:** `sylvamo_mfg`  
**Data Model:** `sylvamo_manufacturing`  
**Version:** `v9`  
**Date:** 2026-01-28

---

## Table of Contents

1. [Overview](#overview)
2. [Containers](#containers)
3. [Views](#views)
4. [Relationships](#relationships)
5. [Sample Data](#sample-data)
6. [GraphQL API](#graphql-api)

---

## Overview

This data model implements ISA-95/ISA-88 standards for paper manufacturing with the following key entities:

| Entity | ISA Mapping | Description |
|--------|-------------|-------------|
| Asset | Site/Enterprise | Functional location (Mill, Facility) |
| Equipment | Unit | Production equipment (Paper Machine, Winder) |
| ProductDefinition | ProductDefinition | Paper grade specification |
| Recipe | Recipe | Production recipe (ISA-88) |
| Reel | Batch | Paper reel (batch of production) |
| Roll | MaterialLot | Cut roll (sellable unit) |
| Package | — | Inter-plant transfer package (Sylvamo extension) |
| QualityResult | QualityResult | Quality test measurement |

---

## Containers

### Asset

**External ID:** `Asset`  
**Description:** Functional location representing mills and facilities

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | Text | Yes | Asset name (e.g., "Eastover Mill") |
| `description` | Text | No | Asset description |
| `assetType` | Text | No | Type: Mill, Facility, Warehouse |
| `location` | Text | No | Physical location/address |
| `sapPlantCode` | Text | No | SAP plant code |

---

### Equipment

**External ID:** `Equipment`  
**Description:** Production equipment within an asset

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | Text | Yes | Equipment name (e.g., "Paper Machine 1") |
| `description` | Text | No | Equipment description |
| `equipmentType` | Text | No | Type: PaperMachine, Winder, Sheeter, Coater |
| `sapEquipmentId` | Text | No | SAP equipment identifier |
| `asset` | DirectRelation → Asset | No | Parent asset |
| `capacity` | Float | No | Production capacity |
| `capacityUnit` | Text | No | Unit of capacity (tons/day, etc.) |

---

### ProductDefinition

**External ID:** `ProductDefinition`  
**Description:** Paper grade specification

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `productId` | Text | Yes | Product identifier (e.g., "BOND-20") |
| `name` | Text | Yes | Product name (e.g., "Bond 20lb") |
| `description` | Text | No | Product description |
| `basisWeight` | Float | No | Basis weight in lb/3000 sq ft |
| `caliper` | Float | No | Thickness in mils |
| `brightness` | Float | No | Brightness percentage |
| `opacity` | Float | No | Opacity percentage |
| `isActive` | Boolean | No | Active product flag |
| `productFamily` | Text | No | Product family (Bond, Offset, Cover) |
| `sapMaterialNumber` | Text | No | SAP material number |

---

### Recipe

**External ID:** `Recipe`  
**Description:** ISA-88 production recipe

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `recipeId` | Text | Yes | Recipe identifier |
| `name` | Text | Yes | Recipe name |
| `recipeType` | Text | Yes | Type: general, site, master, control |
| `version` | Text | No | Recipe version |
| `status` | Text | No | Status: approved, draft, obsolete |
| `description` | Text | No | Recipe description |
| `productDefinition` | DirectRelation → ProductDefinition | No | Product this recipe makes |
| `equipment` | DirectRelation → Equipment | No | Equipment this recipe runs on |
| `targetParameters` | JSON | No | Target quality parameters |
| `processSettings` | JSON | No | Machine process settings |
| `qualitySpecs` | JSON | No | Quality specifications (min/max/target) |
| `effectiveFrom` | Timestamp | No | Effective start date |
| `effectiveTo` | Timestamp | No | Effective end date |

**Recipe Types (ISA-88):**
- `general` - Site-independent formula
- `site` - Adapted for a specific site
- `master` - Equipment-specific recipe
- `control` - Single batch execution

**Example targetParameters:**
```json
{
  "basisWeight": 20.0,
  "caliper": 3.5,
  "brightness": 92,
  "moisture": 4.5
}
```

**Example processSettings:**
```json
{
  "headboxPressure": 12.5,
  "dryerTemperature": 180,
  "machineSpeed": 850,
  "calendering": "light"
}
```

---

### Reel

**External ID:** `Reel`  
**Description:** Paper reel (ISA-95 Batch)

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `reelNumber` | Text | Yes | Reel identifier (e.g., "PM1-20260128-001") |
| `productionDate` | Timestamp | No | Production date/time |
| `productDefinition` | DirectRelation → ProductDefinition | No | Paper grade |
| `equipment` | DirectRelation → Equipment | No | Paper machine that produced it |
| `weight` | Float | No | Reel weight |
| `weightUnit` | Text | No | Weight unit (kg, lb, ton) |
| `width` | Float | No | Reel width in inches |
| `diameter` | Float | No | Reel diameter in inches |
| `status` | Text | No | Status: InProduction, Complete, Tested, Released |
| `gradeRunId` | Text | No | Grade run identifier |

---

### Roll

**External ID:** `Roll`  
**Description:** Paper roll (ISA-95 MaterialLot) - cut from reel

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `rollNumber` | Text | Yes | Roll identifier |
| `reel` | DirectRelation → Reel | No | Source reel |
| `width` | Float | No | Roll width in inches |
| `diameter` | Float | No | Roll diameter |
| `weight` | Float | No | Roll weight |
| `status` | Text | No | Status: Cut, Packaged, Shipped, Delivered |
| `qualityGrade` | Text | No | Quality grade (A, B, C) |
| `cutDate` | Timestamp | No | When the roll was cut |

---

### Package

**External ID:** `Package`  
**Description:** Inter-plant transfer package (Sylvamo extension)

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `packageNumber` | Text | Yes | Package identifier |
| `packageType` | Text | No | Package type |
| `rollCount` | Integer | No | Number of rolls in package |
| `sourcePlant` | DirectRelation → Asset | No | Origin plant (typed relation) |
| `destinationPlant` | DirectRelation → Asset | No | Destination plant (typed relation) |
| `status` | Text | No | Status: Created, Shipped, InTransit, Received |
| `createdDate` | Timestamp | No | Package creation date |
| `shippedDate` | Timestamp | No | Ship date |
| `receivedDate` | Timestamp | No | Receive date |
| `trackingNumber` | Text | No | Shipping tracking number |

---

### QualityResult

**External ID:** `QualityResult`  
**Description:** Quality test measurement

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `testName` | Text | Yes | Test name (Caliper, Moisture, Basis Weight, Brightness) |
| `testMethod` | Text | No | Testing method/standard |
| `reel` | DirectRelation → Reel | No | Tested reel |
| `roll` | DirectRelation → Roll | No | Tested roll |
| `resultValue` | Float | No | Numeric result |
| `resultText` | Text | No | Text result (for non-numeric) |
| `unitOfMeasure` | Text | No | Unit (mils, %, lb, etc.) |
| `specTarget` | Float | No | Target specification |
| `specMin` | Float | No | Minimum specification |
| `specMax` | Float | No | Maximum specification |
| `isInSpec` | Boolean | No | Pass/fail flag |
| `testDate` | Timestamp | No | When the test was performed |
| `sourceSystem` | Text | No | Source system (Proficy, Lab, etc.) |
| `sourceId` | Text | No | Source record ID |

---

## Relationships

| From | Property | To | Type | Description |
|------|----------|----|----|-------------|
| Equipment | `asset` | Asset | N:1 | Equipment belongs to Asset |
| Recipe | `productDefinition` | ProductDefinition | N:1 | Recipe makes Product |
| Recipe | `equipment` | Equipment | N:1 | Recipe runs on Equipment |
| Reel | `productDefinition` | ProductDefinition | N:1 | Reel is a Product |
| Reel | `equipment` | Equipment | N:1 | Reel made on Equipment |
| Roll | `reel` | Reel | N:1 | Roll cut from Reel |
| Roll | `package` | Package | N:1 | Roll bundled in Package |
| Package | `sourcePlant` | Asset | N:1 | Package originates from Asset |
| Package | `destinationPlant` | Asset | N:1 | Package destined for Asset |
| QualityResult | `reel` | Reel | N:1 | Quality test on Reel |
| QualityResult | `roll` | Roll | N:1 | Quality test on Roll |
| MaterialCostVariance | `productDefinition` | ProductDefinition | N:1 | Cost linked to Product |

---

## Sample Data

### Assets (2)
| External ID | Name | Type |
|-------------|------|------|
| asset:eastover | Eastover Mill | Mill |
| asset:sumpter | Sumpter Facility | Facility |

### Equipment (4)
| External ID | Name | Type | Asset |
|-------------|------|------|-------|
| equip:eastover-pm1 | Paper Machine 1 (PM1) | PaperMachine | Eastover |
| equip:eastover-pm2 | Paper Machine 2 (PM2) | PaperMachine | Eastover |
| equip:eastover-winder1 | Winder 1 | Winder | Eastover |
| equip:sumpter-sheeter1 | Sheeter 1 | Sheeter | Sumpter |

### ProductDefinitions (3)
| External ID | Name | Basis Weight |
|-------------|------|--------------|
| product:bond-20 | Bond 20lb | 20.0 |
| product:offset-50 | Offset 50lb | 50.0 |
| product:cover-80 | Cover 80lb | 80.0 |

### Recipes (4)
| External ID | Name | Type | Product | Equipment |
|-------------|------|------|---------|-----------|
| recipe:bond-20-general | Bond 20lb General Recipe | general | Bond 20lb | — |
| recipe:bond-20-pm1 | Bond 20lb Master Recipe for PM1 | master | Bond 20lb | PM1 |
| recipe:offset-50-pm2 | Offset 50lb Master Recipe for PM2 | master | Offset 50lb | PM2 |
| recipe:cover-80-pm1 | Cover 80lb Master Recipe for PM1 | master | Cover 80lb | PM1 |

### Reels (3)
| External ID | Reel Number | Product | Equipment |
|-------------|-------------|---------|-----------|
| reel:PM1-20260128-001 | PM1-20260128-001 | Bond 20lb | PM1 |
| reel:PM1-20260128-002 | PM1-20260128-002 | Bond 20lb | PM1 |
| reel:PM2-20260128-001 | PM2-20260128-001 | Offset 50lb | PM2 |

### Rolls (11)
| Reel | Rolls | Width |
|------|-------|-------|
| PM1-20260128-001 | 4 rolls | 8.5" |
| PM1-20260128-002 | 4 rolls | 8.5" |
| PM2-20260128-001 | 3 rolls | 6.0" |

### Packages (3)
| Package Number | Status | Route |
|----------------|--------|-------|
| PKG-EO-SU-20260128-001 | Shipped | Eastover → Sumpter |
| PKG-EO-SU-20260127-001 | InTransit | Eastover → Sumpter |
| PKG-EO-SU-20260125-001 | Received | Eastover → Sumpter |

### QualityResults (8)
| Reel | Test | Result | Target | Status |
|------|------|--------|--------|--------|
| PM1-20260128-001 | Caliper | 4.05 | 4.00 | ✅ Pass |
| PM1-20260128-001 | Moisture | 5.40 | 5.50 | ✅ Pass |
| PM1-20260128-001 | Basis Weight | 20.20 | 20.00 | ✅ Pass |
| PM1-20260128-001 | Brightness | 92.50 | 92.00 | ✅ Pass |
| PM2-20260128-001 | Caliper | 4.55 | 4.00 | ✅ Pass |
| PM2-20260128-001 | Moisture | 5.90 | 5.50 | ✅ Pass |
| PM2-20260128-001 | Basis Weight | 20.70 | 20.00 | ✅ Pass |
| PM2-20260128-001 | Brightness | 93.00 | 92.00 | ✅ Pass |

---

## GraphQL API

### Endpoint
```
https://<cluster>.cognitedata.com/api/v1/projects/<project>/models/datamodels/graphql
```

### Data Model ID
```
space: sylvamo_mfg
externalId: sylvamo_manufacturing
version: v7
```

### Example Queries

#### List all reels with product and equipment
```graphql
{
  listReel {
    items {
      reelNumber
      productionDate
      status
      productDefinition {
        name
        basisWeight
      }
      equipment {
        name
        equipmentType
      }
    }
  }
}
```

#### Get quality results with traceability
```graphql
{
  listQualityResult {
    items {
      testName
      resultValue
      specTarget
      isInSpec
      reel {
        reelNumber
        productDefinition {
          name
        }
      }
    }
  }
}
```

#### Get recipes with targets
```graphql
{
  listRecipe {
    items {
      name
      recipeType
      status
      targetParameters
      processSettings
      productDefinition {
        name
      }
      equipment {
        name
      }
    }
  }
}
```

#### Get packages with plant details (typed relations)
```graphql
{
  listPackage {
    items {
      packageNumber
      status
      sourcePlant {
        name
        assetType
      }
      destinationPlant {
        name
        assetType
      }
      rollCount
      shippedDate
      receivedDate
    }
  }
}
```

---

## Data Connections & Contextualization

### Connecting PI Time Series to Reels via Event_Num

The `event_num` field is the **key connection point** between Proficy lab tests, PI time series data, and production reels.

#### Event_Num Format

```
26-01-22027
│  │  └─── Reel sequence number (connects to PPR reel data)
│  └────── Paper machine (01 = PM1, 02 = PM2)
└───────── Year (2026)
```

#### Connection Flow

```
┌─────────────────────┐
│  PI Time Series     │
│  (Scanner data)     │──────────────────────────────┐
│  Continuous reading │                              │
└─────────────────────┘                              │
                                                     ▼
┌─────────────────────┐     parse sequence     ┌──────────┐
│  Proficy Lab Test   │─────────────────────▶  │   REEL   │
│  event_num:         │     "22027"            │          │
│  "26-01-22027"      │                        │SequenceID│
└─────────────────────┘                        └────┬─────┘
                                                    │
                                           cut into │
                                                    ▼
                                              ┌──────────┐
                                              │  ROLLS   │
                                              │          │
                                              └──────────┘
```

#### Key Fields for Connection

| Source System | Field | Connects To | Method |
|---------------|-------|-------------|--------|
| **Proficy** | `event_num` | Reel | Parse sequence number (3rd segment) |
| **PPR** | `reel_number` | Contains sequence | String match |
| **PI** | Time series | Reel | Via equipment + timestamp window |

#### SQL Join Example

```sql
-- Connect Proficy lab tests to PPR reels
SELECT lt.*, r.reel_number, r.reel_manufactured_date
FROM lab_tests lt
JOIN ppr_hist_reel r 
  ON r.reel_number LIKE '%' || split_part(lt.event_num, '-', 3)
  AND EXTRACT(YEAR FROM r.reel_manufactured_date) = 
      (2000 + CAST(split_part(lt.event_num, '-', 1) AS INT))
```

#### Important Notes

1. **Lab tests (Proficy)** are performed on **REELS** (before cutting into rolls)
2. **PI Scanner** provides continuous measurement on the same reel
3. Lab tests **VERIFY** that scanner (PI) data is accurate
4. To trace from lab test to rolls: `LabTest → Reel → Roll(s)`
5. The `event_num` format `YY-PM-XXXXXXX` is the **key for reel connection**

### PI Time Series Contextualization

| PI Tag Pattern | Entity | Connection Method |
|----------------|--------|-------------------|
| `PM1.*` | Equipment (PM1) | Tag name prefix |
| `CALIPER.*` | QualityResult | Test type mapping |
| `MOISTURE.*` | QualityResult | Test type mapping |

**Current State:** PI time series are stored as **legacy time series** with metadata linking to equipment.

**Future Enhancement:** Add direct relationships from time series to Reel entities based on production timestamps.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1 | 2026-01-28 | Initial model with 7 views |
| v2 | 2026-01-28 | Added Recipe entity |
| v3 | 2026-01-28 | Added typed relations for diagram visualization |
| v4 | 2026-01-28 | Added MaterialCostVariance entity |
| v5 | 2026-01-28 | Fixed view version references |
| v6 | 2026-01-28 | All typed relations fixed (Package→Asset, Recipe/Reel→Equipment v2) |
| v7 | 2026-01-28 | Added Roll→Package relation ("bundled in") |
| v8 | 2026-01-28 | Added Asset hierarchy (parent/children relations) |
| v9 | 2026-01-28 | Updated all views to align with Asset v2 hierarchy |

---

*Specification created: January 28, 2026*
