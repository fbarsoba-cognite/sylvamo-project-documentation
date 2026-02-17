# sylvamo_mfg_core with PPV Integration

> **Proposed Extension: Adding Cost/PPV Tracking to mfg_core**

This document shows how Purchase Price Variance (PPV) could be modeled within the `sylvamo_mfg_core` data model, enabling cost analysis alongside quality traceability.

---

## Current State vs. Proposed

| Aspect | Current (mfg_core) | Proposed (mfg_core + PPV) |
|--------|-------------------|---------------------------|
| **Views** | 7 | 9 (+CostEvent, +GoodsReceipt) |
| **Use Cases** | Quality Traceability | Quality + Cost Analysis |
| **PPV Location** | mfg_extended | mfg_core |
| **Drill-down** | Not available | GoodsReceipt → PO transactions |

---

## Proposed Entity Relationship Diagram

```mermaid
erDiagram
    Asset ||--o{ Reel : "reels"
    Asset ||--o{ MfgTimeSeries : "timeSeries"
    Asset ||--o{ Event : "events"
    Asset ||--o{ RollQuality : "qualityReports"
    Asset ||--o{ CostEvent : "costEvents"
    Asset ||--o{ GoodsReceipt : "goodsReceipts"
    Asset ||--o{ Asset : "children"

    Material ||--o{ CostEvent : "costEvents"
    Material ||--o{ GoodsReceipt : "goodsReceipts"
    Material ||--o{ Reel : "reels"
    
    GoodsReceipt }o--|| Material : "material"
    GoodsReceipt }o--|| Asset : "plant"
    GoodsReceipt ||--o{ CostEvent : "costEvents"

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
    CostEvent }o--o| GoodsReceipt : "goodsReceipt"

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

    GoodsReceipt {
        string externalId PK
        string purchaseOrder PK
        string poItem
        string vendor
        float quantity
        string unit
        float actualPrice
        float netValue
        timestamp postingDate
        timestamp grDate
        relation material FK
        relation plant FK
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
        relation goodsReceipt FK
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
            RollQuality["RollQuality<br/>~750 tests"]
        end
        
        subgraph Cost["Use Case 2: PPV Analysis"]
            Material["Material<br/>58,000+ items"]
            GoodsReceipt["GoodsReceipt<br/>100,000+ transactions"]
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
    Asset --> GoodsReceipt
    Reel --> Roll
    Roll --> RollQuality
    Material --> CostEvent
    Material --> GoodsReceipt
    GoodsReceipt -.-> CostEvent
    Material -.-> Reel
```

---

## Two PPV Data Sources

The PPV use case has **two data sources** from Fabric that serve different purposes:

### 1. `ppv_snapshot` → CostEvent (Aggregated PPV)

| Aspect | Value |
|--------|-------|
| **Table** | `raw_ext_fabric_ppv.ppv_snapshot` |
| **Records** | ~716 |
| **Granularity** | Material + Plant + Period |
| **Contains** | Pre-calculated PPV amounts |
| **Use Case** | High-level variance analysis |

### 2. `ppv_purchase_order_gr_na` → GoodsReceipt (Transactional)

| Aspect | Value |
|--------|-------|
| **Table** | `raw_ext_fabric_ppv.ppv_purchase_order_gr_na` |
| **Records** | ~100,000+ |
| **Granularity** | Individual purchase order line items |
| **Contains** | Actual prices paid, quantities, vendors |
| **Use Case** | Drill-down to specific transactions |

### Relationship Between Tables

```
┌─────────────────────────────────────────────────────────────────┐
│  ppv_purchase_order_gr_na (Transactional)                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ PO: 4500001234 │ Material: 100001 │ Qty: 500 │ $2.50/ea │   │
│  │ PO: 4500001235 │ Material: 100001 │ Qty: 300 │ $2.45/ea │   │
│  │ PO: 4500001236 │ Material: 100001 │ Qty: 200 │ $2.60/ea │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼ (aggregated by SAP)              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ppv_snapshot (Aggregated)                               │   │
│  │  Material: 100001 │ Plant: EO │ PPV: $1,250 favorable    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## GoodsReceipt Properties

| Property | Type | Description | Source Column |
|----------|------|-------------|---------------|
| `externalId` | string | Unique identifier | Generated |
| `purchaseOrder` | string | SAP PO number | `purchase_order` |
| `poItem` | string | PO line item | `po_item` |
| `vendor` | string | Vendor code | `vendor` |
| `quantity` | float | Quantity received | `quantity` |
| `unit` | string | Unit of measure | `unit` |
| `actualPrice` | float | Price paid per unit | `actual_price` |
| `netValue` | float | Total value (qty × price) | `net_value` |
| `postingDate` | timestamp | SAP posting date | `posting_date` |
| `grDate` | timestamp | Goods receipt date | `gr_date` |
| `material` | relation | → Material | `material_number` |
| `plant` | relation | → Asset (plant) | `plant` |

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

## GraphQL Query: PPV Drill-Down to Purchase Orders

```graphql
{
  # Start from aggregated PPV, drill down to transactions
  listCostEvent(
    filter: { ppvAmount: { gt: 10000 } }
    first: 5
  ) {
    items {
      ppvAmount
      standardCost
      material {
        materialCode
        name
        # Drill down to individual purchase orders
        goodsReceipts(first: 10) {
          items {
            purchaseOrder
            poItem
            vendor
            quantity
            actualPrice
            netValue
            grDate
          }
        }
      }
    }
  }
}
```

---

## GraphQL Query: Vendor Analysis

```graphql
{
  # Find all goods receipts from a specific vendor
  listGoodsReceipt(
    filter: { vendor: { eq: "VENDOR001" } }
    first: 20
  ) {
    items {
      purchaseOrder
      actualPrice
      quantity
      netValue
      material {
        name
        materialType
      }
      plant {
        name
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
        PPV["ppv_snapshot<br/>716 records<br/>(aggregated)"]
        GR["ppv_purchase_order_gr_na<br/>100,000+ records<br/>(transactional)"]
    end

    subgraph RAW["CDF RAW"]
        R1["raw_ext_fabric_ppv<br/>ppv_snapshot"]
        R2["raw_ext_fabric_ppv<br/>ppv_purchase_order_gr_na"]
    end

    subgraph Transform["Transformations"]
        T1["cost_event_to_core.sql"]
        T2["goods_receipt_to_core.sql"]
    end

    subgraph Model["sylvamo_mfg_core"]
        CE["CostEvent<br/>716 nodes"]
        GRE["GoodsReceipt<br/>100,000+ nodes"]
        MAT["Material<br/>58,000 nodes"]
        AST["Asset<br/>44,000 nodes"]
    end

    PPV --> R1 --> T1 --> CE
    GR --> R2 --> T2 --> GRE
    CE -.-> MAT
    CE -.-> AST
    GRE -.-> MAT
    GRE -.-> AST
    GRE -.-> CE
```

---

## Transformation SQL (Proposed)

### 1. CostEvent from ppv_snapshot

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

### 2. GoodsReceipt from ppv_purchase_order_gr_na

```sql
-- Transform Purchase Order GR to GoodsReceipt in mfg_core
SELECT
    concat('gr_', purchase_order, '_', po_item, '_', gr_date) as externalId,
    purchase_order as purchaseOrder,
    po_item as poItem,
    vendor,
    quantity,
    unit,
    actual_price as actualPrice,
    net_value as netValue,
    to_timestamp(posting_date) as postingDate,
    to_timestamp(gr_date) as grDate,
    -- Relations
    node_reference('sylvamo_mfg_core_schema', 'Material', material_number) as material,
    node_reference('sylvamo_mfg_core_schema', 'Asset', plant) as plant
FROM
    `raw_ext_fabric_ppv`.`ppv_purchase_order_gr_na`
WHERE
    material_number IS NOT NULL
    AND plant IS NOT NULL
```

---

## Implementation Steps

### Phase 1: CostEvent (Aggregated PPV)
1. **Add CostEvent Container** to `mfg_core/data_modeling/containers/`
2. **Add CostEvent View** to `mfg_core/data_modeling/views/`
3. **Update Material View** - Add `costEvents` reverse relation
4. **Update Asset View** - Add `costEvents` reverse relation
5. **Create Transformation** - `cost_event_core.transformation.yaml`

### Phase 2: GoodsReceipt (Transactional Detail)
6. **Add GoodsReceipt Container** to `mfg_core/data_modeling/containers/`
7. **Add GoodsReceipt View** to `mfg_core/data_modeling/views/`
8. **Update Material View** - Add `goodsReceipts` reverse relation
9. **Update Asset View** - Add `goodsReceipts` reverse relation
10. **Update CostEvent View** - Add `goodsReceipts` relation (optional link)
11. **Create Transformation** - `goods_receipt_core.transformation.yaml`

### Phase 3: Deploy
12. **Deploy & Verify** - `cdf deploy --dry-run` then `cdf deploy`

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
