# sylvamo_mfg_core with PPV Integration

> **Proposed Extension: Adding Cost/PPV Tracking to mfg_core**

This document shows how Purchase Price Variance (PPV) could be modeled within the `sylvamo_mfg_core` data model, enabling cost analysis alongside quality traceability.

---

## Current State vs. Proposed

| Aspect | Current (mfg_core) | Proposed (mfg_core + PPV) |
|--------|-------------------|---------------------------|
| **Views** | 7 | 8 (+CostEvent) |
| **Use Cases** | Quality Traceability | Quality + Cost Analysis |
| **PPV Location** | mfg_extended | mfg_core |

---

## Proposed Entity Relationship Diagram

```mermaid
erDiagram
    Asset ||--o{ Reel : "reels"
    Asset ||--o{ MfgTimeSeries : "timeSeries"
    Asset ||--o{ Event : "events"
    Asset ||--o{ RollQuality : "qualityReports"
    Asset ||--o{ CostEvent : "costEvents"
    Asset ||--o{ Asset : "children"

    Material ||--o{ CostEvent : "costEvents"
    Material ||--o{ Reel : "reels"

    Reel ||--o{ Roll : "rolls"
    Reel ||--o{ Event : "events"
    Reel }o--|| Asset : "asset"
    Reel }o--o| Material : "material"

    Roll ||--o{ RollQuality : "qualityResults"
    Roll ||--o{ Event : "events"
    Roll }o--|| Reel : "reel"

    RollQuality }o--|| Roll : "roll"
    RollQuality }o--|| Asset : "asset"

    CostEvent }o--|| Material : "material"
    CostEvent }o--|| Asset : "plant"

    Event }o--o{ Asset : "assets"
    Event }o--o| Reel : "reel"
    Event }o--o| Roll : "roll"

    Asset {
        string name PK
        string description
        string assetType
        string plantCode
        string assetPath
        relation parent FK
    }

    Material {
        string materialCode PK
        string name
        string description
        string materialType
        string materialGroup
    }

    Reel {
        string reelNumber PK
        timestamp productionDate
        float weight
        float width
        relation asset FK
        relation material FK
    }

    Roll {
        string rollNumber PK
        float width
        float diameter
        relation reel FK
    }

    RollQuality {
        string externalId PK
        string defectCode
        boolean isRejected
        string location
        float minutesLost
        relation roll FK
        relation asset FK
    }

    CostEvent {
        string externalId PK
        string varianceType
        float ppvAmount
        float standardCost
        float actualCost
        float quantity
        string unit
        timestamp postingDate
        relation material FK
        relation plant FK
    }

    Event {
        string externalId PK
        string eventType
        string eventSubtype
        string sourceId
        string sourceSystem
    }

    MfgTimeSeries {
        string externalId PK
        string name
        string unit
        boolean isStep
    }
```

---

## Flow Diagram: Complete mfg_core with PPV

```mermaid
flowchart TB
    subgraph Core["📦 sylvamo_mfg_core (with PPV)"]
        subgraph Quality["Use Case 1: Quality Traceability"]
            Asset["Asset<br/>44,000+ nodes"]
            Reel["Reel<br/>83,600+ batches"]
            Roll["Roll<br/>2,300,000+ lots"]
            RollQuality["RollQuality<br/>580 tests"]
        end
        
        subgraph Cost["Use Case 2: PPV Analysis"]
            Material["Material<br/>58,000+ items"]
            CostEvent["CostEvent<br/>716 PPV records"]
        end
        
        subgraph Supporting["Supporting Entities"]
            Event["Event<br/>92,000+ events"]
            MfgTimeSeries["MfgTimeSeries<br/>3,500+ tags"]
        end
    end

    Asset --> Reel
    Asset --> RollQuality
    Asset --> CostEvent
    Reel --> Roll
    Roll --> RollQuality
    Material --> CostEvent
    Material -.-> Reel
```

---

## CostEvent Properties

| Property | Type | Description | Source |
|----------|------|-------------|--------|
| `externalId` | string | Unique identifier | Generated |
| `varianceType` | string | "PPV", "FREIGHT", etc. | ppv_snapshot |
| `ppvAmount` | float | Variance amount (USD) | `current_ppv` |
| `standardCost` | float | Expected cost | `standard_cost` |
| `actualCost` | float | Actual paid cost | Calculated |
| `quantity` | float | Material quantity | ppv_snapshot |
| `unit` | string | Unit of measure | ppv_snapshot |
| `postingDate` | timestamp | When variance recorded | ppv_snapshot |
| `material` | relation | → Material | `material_number` |
| `plant` | relation | → Asset (plant) | `plant_code` |

---

## Why Add PPV to mfg_core?

### Benefits

1. **Single Model** - Both use cases (Quality + Cost) in one coherent model
2. **Simpler Queries** - No cross-model joins needed
3. **Material Connection** - PPV directly linked to Material master
4. **Plant Connection** - Cost analysis by location via Asset

### Tradeoffs

1. **Model Size** - Adds ~1,000 nodes
2. **Scope Creep** - mfg_core grows beyond "core"
3. **ISA-95 Alignment** - Cost events might belong in separate domain

---

## GraphQL Query: Material Cost Analysis

```graphql
{
  # Get materials with their PPV
  listMaterial(first: 10, filter: { materialType: { eq: "RAW" } }) {
    items {
      materialCode
      name
      materialType
      costEvents {
        items {
          ppvAmount
          standardCost
          actualCost
          postingDate
          plant {
            name
            plantCode
          }
        }
      }
    }
  }
}
```

---

## GraphQL Query: Plant-Level PPV Summary

```graphql
{
  # Get PPV by plant
  listAsset(filter: { assetType: { eq: "PLANT" } }) {
    items {
      name
      plantCode
      costEvents {
        items {
          ppvAmount
          varianceType
          material {
            name
            materialGroup
          }
        }
      }
    }
  }
}
```

---

## Data Flow: PPV to mfg_core

```mermaid
flowchart LR
    subgraph Source["Microsoft Fabric"]
        PPV["ppv_snapshot<br/>716 records"]
    end

    subgraph RAW["CDF RAW"]
        R1["raw_ext_fabric_ppv<br/>ppv_snapshot"]
    end

    subgraph Transform["Transformation"]
        T1["cost_event_to_core.sql"]
    end

    subgraph Model["sylvamo_mfg_core"]
        CE["CostEvent<br/>716 nodes"]
        MAT["Material<br/>58,000 nodes"]
        AST["Asset<br/>44,000 nodes"]
    end

    PPV --> R1 --> T1 --> CE
    CE -.-> MAT
    CE -.-> AST
```

---

## Transformation SQL (Proposed)

```sql
-- Transform PPV to CostEvent in mfg_core
SELECT
    concat('ppv_', material_number, '_', plant, '_', posting_date) as externalId,
    'PPV' as varianceType,
    current_ppv as ppvAmount,
    standard_cost as standardCost,
    (current_ppv + standard_cost) as actualCost,
    quantity,
    unit,
    to_timestamp(posting_date) as postingDate,
    -- Relations
    node_reference('sylvamo_mfg_core_schema', 'Material', material_number) as material,
    node_reference('sylvamo_mfg_core_schema', 'Asset', plant) as plant
FROM
    `raw_ext_fabric_ppv`.`ppv_snapshot`
WHERE
    current_ppv IS NOT NULL
```

---

## Implementation Steps

1. **Add CostEvent Container** to `mfg_core/data_modeling/containers/`
2. **Add CostEvent View** to `mfg_core/data_modeling/views/`
3. **Update Material View** - Add `costEvents` reverse relation
4. **Update Asset View** - Add `costEvents` reverse relation
5. **Create Transformation** - `cost_event_core.transformation.yaml`
6. **Deploy & Verify** - `cdf deploy --dry-run` then `cdf deploy`

---

## Comparison: mfg_core vs mfg_extended Approach

| Aspect | PPV in mfg_core | PPV in mfg_extended (current) |
|--------|-----------------|-------------------------------|
| **Query Complexity** | Simple - single model | Moderate - cross-model |
| **Model Cohesion** | All production data together | Separated by domain |
| **ISA-95 Alignment** | Mixed domains | Better separation |
| **Maintenance** | One model to maintain | Two models |
| **Flexibility** | Less modular | More modular |

---

## Recommendation

**For Anvar's Review:**

1. **Short-term**: Keep PPV in mfg_extended for clean separation
2. **Long-term**: Consider merging if cross-model queries become painful
3. **Key Question**: Is cost analysis part of "core manufacturing" or a separate domain?

---

*Created: February 16, 2026*
*For discussion with Anvar*
