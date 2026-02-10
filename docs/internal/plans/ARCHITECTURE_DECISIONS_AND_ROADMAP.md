# Sylvamo Data Model: Architecture Decisions & Roadmap

**Purpose:** Meeting preparation for Sylvamo architecture decisions  
**Date:** February 2026  
**Status:** Draft for Discussion

---

## Executive Summary

Sylvamo has **three active data models** in CDF, each serving different purposes. This document explains the current state, how they relate to the Cognite ISA-95 framework, and a recommended roadmap for consolidation and full ISA-95 alignment.

| Model | Space | Purpose | Status |
|-------|-------|---------|--------|
| **sylvamo_mfg_core** | sylvamo_mfg_core_schema | CDM-integrated core (Asset, Event, Reel, Roll, TimeSeries, Files) | **Active** |
| **sylvamo_mfg** | sylvamo_mfg | ISA-95/88 extended (Asset, Equipment, Recipe, ProductDefinition, Package) | **Active** |
| **sylvamo_mfg_extended** | sylvamo_mfg_extended_schema | Activity specialization (WorkOrder, ProductionOrder, CostEvent) | **Active** |

**Key Decision:** Align toward a **unified model** that implements full Cognite ISA-95 while preserving Sylvamo extensions (Package, inter-plant traceability).

---

## 1. Current State: Three Models Compared

### 1.1 sylvamo_mfg_core (Toolkit Module: mfg_core)

**Space:** `sylvamo_mfg_core_schema` / `sylvamo_mfg_core_instances`  
**Data Model:** sylvamo_mfg_core / v1

| Entity | CDM Interface | Description | Data Count |
|--------|---------------|-------------|------------|
| Asset | CogniteAsset | SAP functional location hierarchy (floc:0769-xx) | 44,898 |
| MfgTimeSeries | CogniteTimeSeries | PI/Proficy time series with preview | 3,532 |
| Event | CogniteActivity | Unified events (WorkOrder, PPV, Proficy, ProductionOrder) | 92,000+ |
| Reel | CogniteDescribable, CogniteSourceable | Paper reel (ISA Batch) | 83,600+ |
| Roll | CogniteDescribable, CogniteSourceable | Cut roll (ISA MaterialLot) | 1,000+ |
| Material | CogniteDescribable, CogniteSourceable | SAP materials | TBD |
| RollQuality | CogniteDescribable, CogniteSourceable | Quality test results | TBD |
| CogniteFile | CogniteFile | Files with instance_id linking | 97 |

**Characteristics:**
- Full CDM integration (CogniteAsset, CogniteActivity, CogniteTimeSeries)
- SAP Asset hierarchy (Eastover Mill, 44K+ nodes)
- Single Event type (unified WorkOrder, PPV, Proficy, ProductionOrder)
- GraphQL API published
- Transforms from RAW: SAP, Fabric, Proficy, SharePoint

---

### 1.2 sylvamo_mfg (Toolkit Module: mfg_data)

**Space:** `sylvamo_mfg`  
**Data Model:** sylvamo_manufacturing / v10

| Entity | ISA Mapping | Description | Data Count |
|--------|-------------|-------------|------------|
| Asset | Site/Enterprise | Eastover Mill, Sumpter Facility | 2 |
| Equipment | Unit | PM1, PM2, Winder, Sheeter | 4 |
| ProductDefinition | ProductDefinition | Bond 20lb, Offset 50lb, Cover 80lb | 3 |
| Recipe | Recipe (ISA-88) | General + master recipes | 4 |
| Reel | Batch | Paper reels | 61,000+ |
| Roll | MaterialLot | Cut from reel | 200,000+ |
| Package | (Sylvamo extension) | Inter-plant transfer | 50,000+ |
| QualityResult | QualityResult | Caliper, Moisture, Basis Weight | 21 |
| MaterialCostVariance | — | PPV cost data | 176 |
| LabTest, ManufacturingEvent, Measurement | — | Proficy/Sylvamo extensions | — |

**Characteristics:**
- ISA-95/88 aligned per Johan Stabekk guidance
- CDM Asset + Equipment for hierarchy (simplified vs full ISA Site/Unit)
- Package entity for inter-plant traceability (Sylvamo extension)
- Recipe with ISA-88 types (general, site, master, control)
- Source: Dumped from CDF; consolidated from legacy isa_data, products_data

---

### 1.3 sylvamo_mfg_extended (Toolkit Module: mfg_extended)

**Space:** `sylvamo_mfg_extended_schema` / `sylvamo_mfg_extended_instances`

| Entity | CDM Interface | Description | Data Source |
|--------|---------------|-------------|-------------|
| WorkOrder | CogniteActivity | SAP work orders (IW28) | Fabric |
| ProductionOrder | CogniteActivity | SAP production orders | SAP Gateway |
| ProductionEvent | CogniteActivity | Proficy execution events | Proficy SQL |
| CostEvent | CogniteActivity | PPV cost events | Fabric PPV |
| Equipment | CogniteEquipment | Manufacturing equipment | Pending |
| MaintenanceActivity, Notification, Operation | CogniteActivity | Abstract/specialized | Pending |

**Characteristics:**
- Activity specialization (split from generic Event)
- Extends mfg_core (references Asset, Reel, Material)
- Feb 2026 design per Johan/Fernando discussion
- WorkOrder links to Asset via functional_location

---

## 2. Comparison: mfg_core vs mfg_data vs Cognite ISA Extension

### 2.1 Entity Mapping Matrix

| Cognite ISA Extension | sylvamo_mfg_core | sylvamo_mfg | Notes |
|-----------------------|------------------|-------------|-------|
| Enterprise | — | — | Skipped (Johan) |
| Site | Asset (floc:0769) | Asset | CDM Asset = Site |
| Area | — | — | Skipped (Johan) |
| ProcessCell | — | — | Skipped (Johan) |
| Unit | Asset (Equipment type) | Equipment | CDM Equipment = Unit |
| EquipmentModule | — | — | Not implemented |
| Batch | Reel | Reel | ISA Batch = paper reel |
| MaterialLot | Roll | Roll | ISA MaterialLot = cut roll |
| ProductDefinition | — | ProductDefinition | mfg_data only |
| Recipe | — | Recipe | mfg_data only |
| QualityResult | RollQuality | QualityResult | Both; different naming |
| WorkOrder | Event (eventType) | — | mfg_core unified; mfg_extended specialized |
| Material | Material | — | mfg_core only |
| — | Event | ManufacturingEvent | Unified vs specialized |
| — | MfgTimeSeries | SylvamoTimeSeries | Both |
| — | — | Package | Sylvamo extension |

### 2.2 Key Divergences

| Aspect | mfg_core | mfg_data | Cognite ISA |
|--------|----------|----------|-------------|
| **Asset hierarchy** | SAP floc (44K nodes) | 2 sites only | Enterprise→Site→Area→ProcessCell→Unit |
| **Events** | Single Event type | ManufacturingEvent | WorkOrder, Batch, etc. |
| **Equipment** | Embedded in Asset | Separate Equipment view | Separate Unit/Equipment |
| **Recipe** | None | Yes (ISA-88) | Yes |
| **ProductDefinition** | None | Yes | Yes |
| **Package** | None | Yes | Not in spec |

---

## 3. Cognite ISA Manufacturing Extension Reference

**Source:** [cognitedata/library - isa_manufacturing_extension](https://github.com/cognitedata/library/tree/main/modules/models/isa_manufacturing_extension)

### 3.1 Full ISA Hierarchy (Cognite Spec)

```
Organizational (ISA-95):
  Enterprise → Site → Area → ProcessCell → Unit → EquipmentModule → ControlModule

Procedural (ISA-88):
  Recipe → Procedure → UnitProcedure → Operation → Phase

Production (ISA-95 L3):
  ProductDefinition → ProductRequest → ProductSegment

Execution:
  Batch, WorkOrder

Quality & Process:
  QualityResult, ProcessParameter, ISATimeSeries
```

### 3.2 Johan Stabekk Guidance (Jan 28, 2026)

- **Use CDM Asset + Equipment** instead of ISA Site/Unit/Area/ProcessCell
- **Reel = Batch**, **Roll = MaterialLot**
- **Package** for inter-plant tracking (Sylvamo extension)
- **Start simple**, extend later
- **Records & Streams** for Proficy quality data (not time series per reel)

---

## 4. Alignment Analysis

### 4.1 Current Alignment with Cognite ISA

| ISA Branch | mfg_core | mfg_data | Gap |
|------------|----------|----------|-----|
| Organizational | Asset (CDM) | Asset + Equipment (CDM) | No Enterprise/Area/ProcessCell |
| Procedural | — | Recipe | No Procedure/UnitProcedure/Operation/Phase |
| Production | — | ProductDefinition | No ProductRequest/ProductSegment |
| Batch/MaterialLot | Reel, Roll | Reel, Roll | Aligned |
| Quality | RollQuality | QualityResult | Aligned |
| Work | Event (WorkOrder) | — | mfg_extended has WorkOrder |
| Package | — | Package | Sylvamo extension |

### 4.2 What Full ISA-95 Implementation Would Add

| Addition | Benefit | Effort |
|----------|---------|--------|
| Enterprise, Area, ProcessCell | Full hierarchy for multi-site reporting | Medium |
| Procedure, UnitProcedure, Operation, Phase | Batch procedural traceability | High |
| ProductRequest, ProductSegment | Production order → batch linkage | Medium |
| WorkOrder (ISA spec) | Align with Cognite WorkOrder | Low (mfg_extended has it) |
| ProcessParameter, ISATimeSeries | Phase-level process data | Medium |

---

## 5. Roadmap

### Phase 1: Consolidation (Q1 2026)

**Objective:** Single source of truth, reduce duplication

| Task | Action | Owner |
|------|--------|-------|
| 1.1 | Document decision: mfg_core as primary vs mfg_data | Architecture |
| 1.2 | Map mfg_data entities to mfg_core or deprecate | TBD |
| 1.3 | Merge mfg_extended into mfg_core or keep separate | TBD |
| 1.4 | Unify Event model (keep unified vs split to ISA types) | TBD |

### Phase 2: ISA-95 Incremental Alignment (Q2 2026)

**Objective:** Add ISA entities where they add value

| Task | Action | Priority |
|------|--------|----------|
| 2.1 | Add ProductDefinition to mfg_core (from mfg_data) | High |
| 2.2 | Add Recipe to mfg_core (from mfg_data) | High |
| 2.3 | Add Package to mfg_core (Sylvamo extension) | High |
| 2.4 | Add Equipment as CogniteEquipment (from mfg_data) | Medium |
| 2.5 | Consider Area/ProcessCell if multi-site complexity grows | Low |

### Phase 3: Full ISA-95 (Future)

**Objective:** Full alignment with Cognite ISA Manufacturing Extension

| Task | Action | Trigger |
|------|--------|---------|
| 3.1 | Adopt Cognite isa_manufacturing_extension module | Product/Strategic |
| 3.2 | Map Sylvamo entities to ISA spec containers | — |
| 3.3 | Add Procedure, UnitProcedure, Operation, Phase | Batch procedural need |
| 3.4 | Add ProductRequest, ProductSegment | Production order need |

---

## 6. Model Evolution Options

### Option A: mfg_core as Primary, Absorb mfg_data

**Approach:** Extend mfg_core with ProductDefinition, Recipe, Package, Equipment from mfg_data. Deprecate sylvamo_mfg space.

**Pros:** Single model, CDM-first, already has scale (44K assets)  
**Cons:** Migration of mfg_data instances; possible breaking changes

### Option B: mfg_data as Primary, Enhance with mfg_core

**Approach:** Migrate mfg_core Asset hierarchy into mfg_data. Use mfg_data as canonical.

**Pros:** Already has Recipe, ProductDefinition, Package  
**Cons:** mfg_data has 2 assets only; would need SAP hierarchy

### Option C: New Unified Model (Recommended)

**Approach:** Create new `sylvamo_mfg_unified` space that:
- Uses mfg_core Asset hierarchy (SAP floc)
- Adds ProductDefinition, Recipe, Package from mfg_data
- Consolidates Event types (unified or specialized)
- Implements CogniteEquipment
- Keeps Sylvamo extensions (Package)

**Pros:** Clean slate, best of both  
**Cons:** Migration effort, parallel run

---

## 7. Recommendations for Sylvamo Meeting

### 7.1 Immediate Decisions Needed

1. **Primary model:** mfg_core vs mfg_data vs new unified?
2. **Event model:** Keep unified Event or split to WorkOrder, ProductionOrder, CostEvent?
3. **Asset hierarchy:** Keep SAP floc (44K) or simplify to 2 sites?
4. **Package:** Confirm Package entity for inter-plant traceability

### 7.2 Recommended Direction

1. **Adopt mfg_core as primary** – It has scale, CDM integration, and active transformations
2. **Add missing ISA entities to mfg_core** – ProductDefinition, Recipe, Package, Equipment
3. **Keep unified Event for now** – Split to specialized types only if use cases demand it
4. **Preserve Sylvamo extensions** – Package, inter-plant, paper-specific fields
5. **Incremental ISA alignment** – Add entities as needed, not big-bang

### 7.3 Full ISA-95 Alignment Path

When/if full Cognite ISA implementation is required:

1. **Evaluate** cognitedata/library isa_manufacturing_extension module
2. **Map** Sylvamo entities to ISA spec (Asset→Site, Equipment→Unit, Reel→Batch, etc.)
3. **Extend** with Sylvamo-specific containers (Package, paper specs)
4. **Migrate** data via transformations
5. **Deprecate** legacy spaces after validation

---

## 8. Appendix: Toolkit Module Summary

| Module | Spaces | Entities | Transformations |
|--------|--------|----------|-----------------|
| mfg_core | sylvamo_mfg_core_schema, _instances | 8 (Asset, Event, Reel, Roll, Material, RollQuality, MfgTimeSeries, CogniteFile) | 14+ |
| mfg_data | sylvamo_mfg | 16 views | Dumped from CDF |
| mfg_extended | sylvamo_mfg_extended_schema, _instances | 6 (WorkOrder, ProductionOrder, etc.) | 4 ready |
| mfg_location | — | Location filters | — |
| infield | — | Infield-specific | — |
| admin | — | Admin, SourceSystems | — |

---

## 9. References

- [Cognite ISA Manufacturing Extension](https://github.com/cognitedata/library/tree/main/modules/models/isa_manufacturing_extension)
- [ISA Extension & Sylvamo Alignment](./COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md)
- [Johan ISA95 Guidance Summary](./JOHAN_ISA95_GUIDANCE_SUMMARY.md)
- [Data Model Specification](../reference/data-model/DATA_MODEL_SPECIFICATION.md)
- [Appendix: sylvamo_mfg_core](../reference/data-model/APPENDIX_MFG_CORE_MODEL.md)

---

*Document created: February 2026*
