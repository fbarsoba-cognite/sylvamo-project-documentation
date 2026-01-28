# Sylvamo Manufacturing Data Model

**ISA-95/ISA-88 aligned data model for paper manufacturing**

This repository contains the data model specification for Sylvamo's manufacturing operations in Cognite Data Fusion (CDF).

## Overview

The `sylvamo_mfg` data model implements ISA-95 and ISA-88 standards adapted for paper manufacturing, with extensions for inter-plant traceability.

| Component | Value |
|-----------|-------|
| **Space** | `sylvamo_mfg` |
| **Data Model** | `sylvamo_manufacturing/v4` |
| **Views** | 9 (Asset, Equipment, ProductDefinition, Recipe, Reel, Roll, Package, QualityResult, MaterialCostVariance) |
| **Sample Data** | 43 nodes |

## Entity Relationship Diagram

```mermaid
erDiagram
    Asset ||--o{ Equipment : "contains"
    Equipment ||--o{ Reel : "produces"
    Equipment ||--o{ Recipe : "runs"
    ProductDefinition ||--o{ Recipe : "defines"
    ProductDefinition ||--o{ Reel : "specifies"
    ProductDefinition ||--o{ MaterialCostVariance : "cost impact"
    Reel ||--o{ Roll : "cut into"
    Reel ||--o{ QualityResult : "tested by"
    Roll ||--o{ QualityResult : "tested by"
    Roll }o--|| Package : "bundled in"

    Asset {
        string name PK
        string description
        string assetType
    }

    Equipment {
        string name PK
        string equipmentType
        relation asset FK
    }

    ProductDefinition {
        string productId PK
        string name
        float basisWeight
    }

    Recipe {
        string recipeId PK
        string name
        string recipeType
        json targetParameters
        relation productDefinition FK
        relation equipment FK
    }

    Reel {
        string reelNumber PK
        timestamp productionDate
        relation productDefinition FK
        relation equipment FK
    }

    Roll {
        string rollNumber PK
        float width
        relation reel FK
    }

    Package {
        string packageNumber PK
        string status
        string sourcePlant
        string destinationPlant
    }

    QualityResult {
        string testName PK
        float resultValue
        boolean isInSpec
        relation reel FK
    }

    MaterialCostVariance {
        string material PK
        string materialType
        float currentPPV
        float priorPPV
        float ppvChange
        relation productDefinition FK
    }
```

## Flow Diagram

```mermaid
flowchart TB
    subgraph Organizational["🏭 Organizational Hierarchy (CDM)"]
        Asset["Asset<br/>Eastover Mill, Sumpter Facility"]
        Equipment["Equipment<br/>PM1, PM2, Winder, Sheeter"]
    end

    subgraph Production["📦 Production (ISA-95/88)"]
        ProductDefinition["ProductDefinition<br/>Bond 20lb, Offset 50lb, Cover 80lb"]
        Recipe["Recipe<br/>General & Master Recipes"]
        Reel["Reel (Batch)<br/>Paper reels"]
        Roll["Roll (MaterialLot)<br/>Cut from reel"]
    end

    subgraph Quality["🔬 Quality"]
        QualityResult["QualityResult<br/>Caliper, Moisture, Basis Weight"]
    end

    subgraph Logistics["🚚 Logistics"]
        Package["Package<br/>Inter-plant Transfer"]
    end

    Asset --> Equipment
    Equipment --> Reel
    Equipment --> Recipe
    ProductDefinition --> Recipe
    ProductDefinition --> Reel
    Reel --> Roll
    Reel --> QualityResult
    Roll --> QualityResult
    Roll --> Package
```

## Use Cases

### Use Case 2: Paper Quality Association ✅
**Objective:** Associate paper quality metrics with production data to track quality trends across plants.

| Scenario | Query | Status |
|----------|-------|--------|
| Quality Traceability | Roll → Reel → Quality Tests | ✅ Verified |
| Inter-Plant Tracking | Package status Eastover → Sumpter | ✅ Verified |
| Recipe Compliance | Target vs Actual quality comparison | ✅ Verified |
| Production Dashboard | Summary metrics across all entities | ✅ Verified |

**[See Full Query Examples →](docs/USE_CASES_AND_QUERIES.md)**

### Use Case 1: Material Cost & PPV Analysis ✅
**Objective:** Track purchase price variance for raw materials and link to products.

| Scenario | Query | Status |
|----------|-------|--------|
| PPV Analysis by Material | List all materials with PPV changes | ✅ Verified |
| Product Cost Impact | Link costs to ProductDefinition | ✅ Verified |
| Period-over-Period | Compare current vs prior costs | ✅ Verified |

**[See Full Query Examples →](docs/USE_CASES_AND_QUERIES.md)**

---

## Key Design Decisions

Based on guidance from Johan Stabekk (Cognite ISA Expert, Jan 28, 2026):

1. **CDM Asset + Equipment** instead of ISA Site/Unit hierarchy
2. **Reel** as ISA Batch (paper reel = batch)
3. **Roll** as ISA MaterialLot (sellable unit)
4. **Package** entity for inter-plant traceability (Sylvamo extension)
5. **Recipe** entity following ISA-88 (general, site, master, control types)

## Documentation

| Document | Description |
|----------|-------------|
| [**Use Cases & Queries**](docs/USE_CASES_AND_QUERIES.md) | Verified use case scenarios with live query examples |
| [**Data Model Specification**](docs/DATA_MODEL_SPECIFICATION.md) | Complete spec with all containers, properties, and examples |
| [Data Model Diagram](docs/SYLVAMO_MFG_DATA_MODEL_DIAGRAM.md) | Visual diagrams with Mermaid |
| [Expert Scenarios](docs/USE_CASE_VALIDATION_EXPERT_SCENARIOS.md) | Industry use cases enabled by this model |
| [ISA Alignment](docs/COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md) | ISA-95/88 alignment analysis |
| [Johan's Guidance](docs/JOHAN_ISA95_GUIDANCE_SUMMARY.md) | Expert recommendations from Cognite |

## Sample Data

| Entity | Count | Examples |
|--------|-------|----------|
| Asset | 2 | Eastover Mill, Sumpter Facility |
| Equipment | 4 | PM1, PM2, Winder 1, Sheeter 1 |
| ProductDefinition | 3 | Bond 20lb, Offset 50lb, Cover 80lb |
| Recipe | 4 | 1 general + 3 master recipes |
| Reel | 3 | PM1-20260128-001, PM1-20260128-002, PM2-20260128-001 |
| Roll | 11 | Cut from reels (8.5" and 6.0" widths) |
| Package | 3 | Shipped, InTransit, Received |
| QualityResult | 8 | Caliper, Moisture, Basis Weight, Brightness |
| MaterialCostVariance | 5 | Pulp, Filler, Coating, Chemical costs |

## GraphQL Query Example

```graphql
{
  listReel {
    items {
      reelNumber
      productionDate
      productDefinition { name basisWeight }
      equipment { name equipmentType }
    }
  }
}
```

## License

Internal use only - Cognite/Sylvamo

---

*Created: January 28, 2026*
