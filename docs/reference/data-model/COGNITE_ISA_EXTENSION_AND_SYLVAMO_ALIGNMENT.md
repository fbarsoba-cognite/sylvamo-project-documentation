# Cognite ISA Manufacturing Extension & Sylvamo ISA Model Alignment

**Date:** 2026-01-28 (Updated per Johan Stabekk guidance)  
**Last Updated:** 2026-01-28 (Model deployed to CDF)  
**Cognite spec:** [cognitedata/library - isa_manufacturing_extension](https://github.com/cognitedata/library/tree/main/modules/models/isa_manufacturing_extension)  
**Diagram:** [ISA DM-ISA DM.drawio.svg](docs/ISA%20DM-ISA%20DM.drawio.svg) (ISA-95/ISA-88 data model architecture)  
**Deployed Model:** `sylvamo_mfg/sylvamo_manufacturing/v2` (GraphQL API published, includes Recipe)  
**Key Decision:** Use CDM Asset + Equipment instead of ISA Site/Unit for organizational hierarchy

## Current Deployment Status

| Component | Status | Details |
|-----------|--------|---------|
| **Space** | ✅ Deployed | `sylvamo_mfg` |
| **Data Model** | ✅ Published | `sylvamo_manufacturing/v2` with 8 views (includes Recipe) |
| **GraphQL API** | ✅ Active | All 28 queries available |
| **Sample Data** | ✅ Populated | 38 nodes (Assets, Equipment, Products, Recipes, Reels, Rolls, Packages, QualityResults) |

### Deployed Entities

| Entity | Type | Count | Description |
|--------|------|-------|-------------|
| **Asset** | CDM | 2 | Eastover Mill, Sumpter Facility |
| **Equipment** | CDM | 4 | PM1, PM2, Winder, Sheeter |
| **ProductDefinition** | ISA | 3 | Bond 20lb, Offset 50lb, Cover 80lb |
| **Recipe** | ISA-88 | 4 | 1 general + 3 master recipes (Bond/Offset/Cover) |
| **Reel** | ISA (Batch) | 3 | Paper reels from PM1, PM2 |
| **Roll** | Custom | 11 | Cut from reels |
| **Package** | Custom | 3 | Inter-plant delivery tracking |
| **QualityResult** | ISA | 8 | Caliper, Moisture, Basis Weight, Brightness |

> **Google Docs:** This file is Markdown (for Cursor, VS Code, GitHub). If you paste it into Google Docs: internal links to other .md files will not work (use Section 6 for full URLs to GitHub). Tables will paste as plain text with pipes—recreate them with Insert > Table. Headings may need to be reapplied (Apply heading style).

---

<a id="table-of-contents"></a>
## Table of contents

**Main document**
- [1. Cognite ISA Manufacturing Extension - What It Is](#section-1-what-it-is)
  - [1.1 Purpose and principles](#section-11-purpose-and-principles)
  - [1.2 Module structure](#section-12-module-structure)
  - [1.3 Key entities (from the spec)](#section-13-key-entities)
- [2. ISA DM-ISA DM.drawio.svg - Diagram and Relationships](#section-2-diagram)
- [3. How Sylvamo ISA Models Align With the Spec](#section-3-align-with-spec)
  - [3.1 Spaces](#section-31-spaces)
  - [3.2 Entities implemented](#section-32-entities-implemented)
  - [3.3 Property-level alignment](#section-33-property-level-alignment)
  - [3.4 What we do not implement](#section-34-what-we-do-not-implement)
- [4. Diagram vs Our Model - Where We Align and Diverge](#section-4-diagram-vs-model)
  - [4.1 Relationships in the diagram](#section-41-relationships-in-diagram)
  - [4.2 Where our ISA model aligns](#section-42-where-we-align)
  - [4.3 Where our ISA model does not align](#section-43-where-we-do-not-align)
  - [4.4 Why alignment with the diagram/spec helps](#section-44-why-alignment-helps)
- [5. Summary Table](#section-5-summary-table)
- [6. References](#section-6-references)

**Appendix**
- [Appendix A. Deep Comparison (Property-Level)](#appendix-a-deep-comparison)
  - [A.1 Scope and Conventions](#appendix-a1-scope)
  - [A.2 Site – Deep Comparison](#appendix-a2-site)
  - [A.3 Unit – Deep Comparison](#appendix-a3-unit)
  - [A.4 ProductDefinition – Deep Comparison](#appendix-a4-productdefinition)
  - [A.5 QualityResult – Deep Comparison](#appendix-a5-qualityresult)
  - [A.6 Relations Summary](#appendix-a6-relations-summary)
  - [A.7 Appendix Summary](#appendix-a7-summary)

---

<a id="section-1-what-it-is"></a>
## 1. Cognite ISA Manufacturing Extension - What It Is

The **ISA Manufacturing Extension** is an official Cognite module that provides an **ISA-95/ISA-88** manufacturing domain model for CDF. It is maintained in the Cognite library and is the reference spec for ISA-aligned data modeling in CDF.

<a id="section-11-purpose-and-principles"></a>
### 1.1 Purpose and principles

- **ISA-95 (ANSI/ISA-95):** Enterprise-control system integration; hierarchy from enterprise (Level 0) down to production units (Level 4).
- **ISA-88 (ANSI/ISA-88):** Batch control; procedural model (Recipe → Procedure → UnitProcedure → Operation → Phase) and Batch execution.
- The module is **not** a full customer-specific model; it provides **placeholders and structures** so projects can add/remove properties and views as needed.
- It follows Cognite data modeling best practices: extends Core Data Model (CDM), supports direct and reverse relations, AI-friendly naming, and builds around the asset hierarchy.

<a id="section-12-module-structure"></a>
### 1.2 Module structure

```
isa_manufacturing_extension/
├── data_modeling/
│   ├── containers/     # Column-level schemas (e.g. sp_isa_manufacturing_Area, Site, Unit, Batch, QualityResult, …)
│   ├── views/          # Logical views over containers + relations (Area, Batch, Site, Unit, ProductDefinition, QualityResult, …)
│   ├── ISA_Manufacturing_EDM.DataModel.yaml   # Enterprise Data Model (all views + CDM interfaces)
│   ├── ISA_Manufacturing_SLM.DataModel.yaml   # Solution Level Model (ISA views only)
│   ├── sp_isa_manufacturing.Space.yaml         # Schema space
│   └── sp_isa_instance.Space.yaml             # Instance space (optional)
├── data_sets/
├── locations/          # EDM/SLM location filters
├── raw/                # RAW tables + optional seed CSV
├── transformations/    # SQL + YAML transformation pairs (e.g. site_tr, unit_tr, quality_result_tr, …)
├── workflows/         # wf_isa_manufacturing workflow
├── ISA DM-ISA DM.drawio.svg   # Architecture diagram
├── README.md
├── default.config.yaml
└── module.toml
```

Containers use the prefix `sp_isa_manufacturing_` and live in the `sp_isa_manufacturing` space. Views implement CDM interfaces (e.g. `CogniteDescribable`, `CogniteActivity`) where applicable.

<a id="section-13-key-entities"></a>
### 1.3 Key entities (from the spec)

| Category | Entities |
|----------|----------|
| **ISA-95 organizational hierarchy (Levels 0-4)** | Enterprise, Site, Area, ProcessCell, Unit, EquipmentModule, Equipment, ISAAsset |
| **ISA-88 procedural** | Recipe, Procedure, UnitProcedure, Operation, Phase, ControlModule |
| **ISA-95 Level 3 production** | ProductDefinition, ProductRequest, ProductSegment |
| **Execution / production** | Batch, WorkOrder |
| **Quality & process** | QualityResult, ProcessParameter |
| **Supporting** | Material, MaterialLot, Personnel, ISATimeSeries, ISAFile |

Relationships described in the spec include:

- **Organizational:** Enterprise → Site → Area → ProcessCell → Unit → EquipmentModule.
- **Procedural:** Recipe → Procedure → UnitProcedure → Operation → Phase; Batch links to Recipe, Site, WorkOrder.
- **Production:** ProductDefinition → Unit, ProductSegment; ProductRequest → WorkOrder, Batch; ProductSegment ↔ ProcessParameter.
- **Quality:** QualityResult → Batch, MaterialLot.
- **Process data:** ProcessParameter ↔ Phase, ProductSegment; ISATimeSeries ↔ ISAAsset, Equipment, Phase, ProductSegment, WorkOrder.

The [ISA DM-ISA DM.drawio.svg](docs/ISA%20DM-ISA%20DM.drawio.svg) diagram in the repo illustrates these relationships and hierarchies.

---

<a id="section-2-diagram"></a>
## 2. ISA DM-ISA DM.drawio.svg - Diagram and Relationships

The file **ISA DM-ISA DM.drawio.svg** is the official architecture diagram for the ISA Manufacturing Extension. Per the [module README](https://github.com/cognitedata/library/tree/main/modules/models/isa_manufacturing_extension), it shows:

- **ISA-95 organizational hierarchy (vertical):** Enterprise → Site → Area → ProcessCell → Unit → EquipmentModule
- **ISA-88 procedural hierarchy:** Recipe → Procedure → UnitProcedure → Operation → Phase
- **ISA-95 Level 3 production:** ProductDefinition → ProductRequest → ProductSegment
- **Cross-hierarchy links:** e.g. ProductDefinition ↔ Unit, Batch ↔ Site, WorkOrder ↔ Equipment
- **Process data:** ProcessParameter, ISATimeSeries linked to ISA-88 and ISA-95 entities
- **Work orders:** WorkOrders linking planning and execution

Sylvamo’s [ISA95_ISA88_ALIGNMENT_PLAN.md](docs/ISA95_ISA88_ALIGNMENT_PLAN.md) analyzes the same diagram (and IP ISA model) and summarizes:

- **Equipment hierarchy:** Enterprise → Site → Area → ProcessCell → Unit → EquipmentModule → ControlModule
- **Batch control:** Recipe → Procedure → UnitProcedure → Operation → Phase → Batch
- **Product / material:** ProductDefinition, ProductSegment, ProductRequest, Material, MaterialLot
- **Quality & work:** QualityResult (→ Batch, MaterialLot), WorkOrder, Equipment, Personnel
- **Core wrappers:** isaAsset, isaFiles, isaTimeSeries

So the **drawio diagram** and the **spec README** describe the same overall structure; our alignment doc uses that structure to compare Sylvamo to the spec.

---

<a id="section-3-align-with-spec"></a>
## 3. How Sylvamo ISA Models Align With the Spec

Sylvamo implements a **subset** of the Cognite ISA Manufacturing Extension, focused on what is needed for current use cases. **Key architectural decision (per Johan Stabekk guidance, Jan 28, 2026):** Use **CDM Asset + Equipment** instead of ISA Site/Unit for organizational hierarchy to avoid over-complication and leverage out-of-the-box CDM capabilities.

<a id="section-31-spaces"></a>
### 3.1 Spaces

| Spec | Sylvamo | Alignment |
|------|---------|-----------|
| Schema space `sp_isa_manufacturing` | `sylvamo_mfg` | Different name; same role (containers + views). |
| Instance space `sp_isa_instance` | (none; instances in `sylvamo_mfg`) | Single combined space; no schema/instance split. |

We use one space (`sylvamo_mfg`) for both schema and instances; the spec uses two. Functionally aligned; structurally simpler. The data model `sylvamo_mfg/v1` is published with GraphQL API.

<a id="section-32-entities-implemented"></a>
### 3.2 Entities implemented

**New Model (`sylvamo_mfg/sylvamo_manufacturing/v2`) - Deployed Jan 28, 2026:**

| Spec entity | Sylvamo Entity | Status | Notes |
|-------------|----------------|--------|-------|
| Site | **Asset** | ✅ Deployed | CDM Asset (per Johan) - Eastover, Sumpter |
| Unit | **Equipment** | ✅ Deployed | CDM Equipment (per Johan) - PM1, PM2, Winder, Sheeter |
| ProductDefinition | **ProductDefinition** | ✅ Deployed | ISA-aligned with paper extensions |
| Recipe | **Recipe** | ✅ Deployed | ISA-88 recipes (general + master) with target params |
| Batch | **Reel** | ✅ Deployed | ISA Batch = paper reel |
| MaterialLot | **Roll** | ✅ Deployed | Cut from reel |
| — | **Package** | ✅ Deployed | **Sylvamo extension** - inter-plant delivery |
| QualityResult | **QualityResult** | ✅ Deployed | ISA-aligned with Proficy fields |
| Enterprise | — | ❌ Skipped | Over-complication (per Johan) |
| Area | — | ❌ Skipped | Over-complication (per Johan) |
| ProcessCell | — | ❌ Skipped | Over-complication (per Johan) |
| Phase, WorkOrder, etc. | — | ❌ Not implemented | Future consideration |

Sylvamo aligns with the **spec's intent** using CDM primitives (Asset, Equipment) for organizational hierarchy and ISA entities (ProductDefinition, Recipe, Reel/Batch, Roll/MaterialLot, QualityResult) for production, plus the custom **Package** entity for inter-plant traceability. All entities are in the single `sylvamo_mfg` space.

<a id="section-33-property-level-alignment"></a>
### 3.3 Property-level alignment (from [ISA95_COGNITE_MODULE_DEEP_COMPARISON](docs/06-plans/ISA95_COGNITE_MODULE_DEEP_COMPARISON.md))

- **Organizational hierarchy:** We use **CDM Asset + Equipment** instead of ISA Site/Unit. Asset = functional location (top = Eastover/S); Equipment = bottom of functional location. This aligns with the spec's intent (organizational structure) but uses CDM's out-of-the-box capabilities rather than creating ISA-specific types.
- **ProductDefinition:** Core id, version, validity, name, description align. We use `productId`, `isActive`, `producibleUnits` (JSON) vs spec’s `product_definition_id`, `status`, `unit` (direct list). We add paper-specific fields (basisWeight, caliper, etc.).
- **QualityResult:** Core test and result fields align (`resultId`/`quality_result_id`, `testName`, `resultValue`, `batch`, `materialLot`, etc.). We add spec/extensions (e.g. `specTarget`, `isInSpec`, `sourceSystem`, `sourceId`, Proficy fields). Batch/MaterialLot are stored as text refs in our container; spec uses direct relations.

So **where we have entities, we align with the spec’s semantics and naming intent**, with deliberate simplifications (e.g. single space, no Enterprise/Area/ProcessCell) and domain extensions (paper, Proficy).

<a id="section-34-what-we-do-not-implement"></a>
### 3.4 What we do not implement (and why it matters)

- **Organizational hierarchy above Site:** Enterprise, Area, ProcessCell. Aligning would allow full ISA-95 Level 4 hierarchy and clearer multi-site/area reporting.
- **ISA-88 procedural:** Recipe, Procedure, UnitProcedure, Operation, Phase. Needed if we want batch procedural traceability and phase-level process data in the ISA model.
- **Production management:** ProductRequest, ProductSegment. Would link ProductDefinition to orders and segments and align with spec’s Level 3 production flow.
- **Execution:** WorkOrder (and its links to ProductRequest, Batch, Equipment, Personnel). Would align planning and execution with the spec.
- **QualityResult:** ✅ Now deployed in `sylvamo_mfg` with container and view. Linked to Reel for batch traceability.

Alignment with the spec **matters** so we can:

- Reuse Cognite’s documentation, training, and best practices.
- Stay compatible with CDM and Quickstart (CogniteDescribable, constraints).
- Add more ISA entities (Area, Batch in ISA space, WorkOrder, etc.) later without reworking the core.
- Compare and integrate with other Cognite ISA deployments that use the same module.

---

<a id="section-4-diagram-vs-model"></a>
## 4. Diagram vs Our Model - Where We Align and Diverge

The **ISA DM-ISA DM.drawio.svg** encodes the same structure as the spec README. Below we map that to what we have.

<a id="section-41-relationships-in-diagram"></a>
### 4.1 Relationships in the diagram (summary)

- **Organizational (vertical):** Enterprise → Site → Area → ProcessCell → Unit → EquipmentModule → ControlModule.
- **Procedural (ISA-88):** Recipe → Procedure → UnitProcedure → Operation → Phase; Batch ties to Recipe, Phase, etc.
- **Production (Level 3):** ProductDefinition → ProductSegment; ProductRequest → WorkOrder; ProductDefinition ↔ Unit.
- **Quality:** QualityResult → Batch, MaterialLot (and optionally Personnel).
- **Process/data:** ProcessParameter ↔ Phase, ProductSegment; ISATimeSeries linked to assets, equipment, phase, product segment, work order.
- **Work:** WorkOrder ↔ ProductRequest, Equipment, Personnel, ISATimeSeries.

<a id="section-42-where-we-align"></a>
### 4.2 Where our ISA model aligns

- **Organizational hierarchy:** We use **CDM Asset + Equipment** instead of ISA Site/Unit. Asset = functional location (top = Eastover/S); Equipment = bottom of functional location. This aligns with the diagram's intent (organizational structure) but uses CDM's out-of-the-box capabilities rather than creating ISA-specific types.
- **ProductDefinition:** We have the entity and link it to units via `producibleUnits` (JSON); the diagram/spec show ProductDefinition ↔ Unit and ProductDefinition → ProductSegment (we lack ProductSegment).
- **Batch/MaterialLot:** Batch = Reel, MaterialLot = Roll. These are deployed in `sylvamo_mfg` space, aligned with ISA Batch/MaterialLot.
- **Package:** We will add Package entity (set of rolls delivered) for traceability between plants.
- **QualityResult:** We have the container and intend the same relationships (Batch, MaterialLot); the view is being recreated to fix deployment issues.

So in the diagram terms: we **partially** implement the organizational branch (via CDM Asset/Equipment), the product branch (ProductDefinition), the batch branch (Batch/Reel, MaterialLot/Roll, Package), and the quality branch (QualityResult container).

<a id="section-43-where-we-do-not-align"></a>
### 4.3 Where our ISA model does not align

- **No Enterprise / Area / ProcessCell:** The diagram’s full chain Enterprise → Site → Area → ProcessCell → Unit is not in our ISA model.
- **No ISA-88 branch:** Recipe → … → Phase are not implemented; Batch/MaterialLot (Reel/Roll) are deployed in `sylvamo_mfg`.
- **No ProductRequest, ProductSegment:** So no ProductDefinition → ProductRequest → WorkOrder or ProductSegment ↔ ProcessParameter as in the diagram.
- **No WorkOrder, Equipment, Personnel, ProcessParameter, ISATimeSeries** in our ISA module: so we don’t show the work-order, equipment, or process-data links from the diagram.
- **QualityResult view:** ✅ Now deployed in `sylvamo_mfg` with 8 quality results linked to reels.

<a id="section-44-why-alignment-helps"></a>
### 4.4 Why alignment with the diagram/spec helps

- **Navigation and reporting:** Same mental model as the spec (hierarchy, batch, production, quality) makes it easier to build reports and apps that match Cognite’s ISA documentation.
- **Future extensions:** Adding Area, ProcessCell, Batch in ISA space, WorkOrder, or ProductSegment later fits the existing diagram and spec without redefining the world.
- **Support and upgrades:** When Cognite updates the ISA module or the diagram, we have a clear map of what we already match and what we added (e.g. paper specs, Proficy).
- **Quality:** ✅ QualityResult view now deployed in `sylvamo_mfg` with full alignment to the diagram.

---

<a id="section-5-summary-table"></a>
## 5. Summary Table

| Aspect | Cognite ISA extension (spec) | Sylvamo Model (`sylvamo_mfg`) | Alignment |
|--------|------------------------------|-------------------------------|-----------|
| **Source** | [GitHub - isa_manufacturing_extension](https://github.com/cognitedata/library/tree/main/modules/models/isa_manufacturing_extension) | `sylvamo_mfg/sylvamo_manufacturing/v2` | — |
| **Diagram** | [ISA DM-ISA DM.drawio.svg](docs/ISA%20DM-ISA%20DM.drawio.svg) | Same file under `docs/` | Same reference diagram |
| **Spaces** | Schema + instance | Single space `sylvamo_mfg` | ✅ Simplified but compatible |
| **Organizational hierarchy** | ISA Site, Unit, Enterprise, Area, ProcessCell | **Asset + Equipment** (CDM) | ✅ **Deployed** (per Johan) |
| **ProductDefinition** | Yes | ✅ Deployed (3 grades) | ✅ Aligned (+ paper extensions) |
| **Recipe** | Yes (ISA-88) | ✅ Deployed (4 recipes) | ✅ Aligned (general + master) |
| **Batch** | Yes | ✅ **Reel** deployed (3 reels) | ✅ Aligned |
| **MaterialLot** | Yes | ✅ **Roll** deployed (11 rolls) | ✅ Aligned |
| **Package** | Not in spec | ✅ **Package** deployed (3 packages) | ✅ **Sylvamo extension** (inter-plant) |
| **QualityResult** | Yes (container + view) | ✅ Deployed (8 results) | ✅ Aligned |
| **Other entities** | Many (WorkOrder, ProductSegment, Phase, …) | ❌ Not implemented | ✅ Intentional subset |
| **Naming** | snake_case (e.g. site_id) | camelCase (e.g. reelNumber) | Both valid |
| **GraphQL API** | Yes | ✅ Published (28 queries) | ✅ Fully functional |
| **Relations** | Full hierarchy + batch + production + quality | Asset→Equipment, Recipe→ProductDefinition, Recipe→Equipment, Reel→Roll, Roll→Package, QualityResult→Reel | ✅ Core flow implemented |

---

<a id="section-6-references"></a>
## 6. References

- **Cognite ISA Manufacturing Extension:**  
  [GitHub - isa_manufacturing_extension](https://github.com/cognitedata/library/tree/main/modules/models/isa_manufacturing_extension)
- **Module README (spec, entities, relationships):**  
  [README.md](https://github.com/cognitedata/library/blob/main/modules/models/isa_manufacturing_extension/README.md)
- **Diagram in repo:**  
  [ISA DM-ISA DM.drawio.svg](docs/ISA%20DM-ISA%20DM.drawio.svg)
- **Sylvamo alignment and comparison:**
  - [ISA95_COGNITE_MODULE_DEEP_COMPARISON.md](docs/06-plans/ISA95_COGNITE_MODULE_DEEP_COMPARISON.md)
  - [ISA95_ALIGNMENT_SUMMARY.md](docs/06-plans/ISA95_ALIGNMENT_SUMMARY.md)
  - [ISA95_MODEL_ALIGNMENT_CHANGES.md](docs/06-plans/ISA95_MODEL_ALIGNMENT_CHANGES.md)
- **Diagram / IP model analysis (entity list and hierarchy):**
  [ISA95_ISA88_ALIGNMENT_PLAN.md](docs/ISA95_ISA88_ALIGNMENT_PLAN.md)
- **Sylvamo CDF spaces:**
  [SYLVAMO_CDF_SPACES_AND_MODELS.md](docs/06-plans/SYLVAMO_CDF_SPACES_AND_MODELS.md)

---

<a id="appendix-a-deep-comparison"></a>
## Appendix A. Deep Comparison (Property-Level)

This appendix provides the property-level comparison between Sylvamo’s ISA model and the Cognite ISA Manufacturing Extension for the four entities we implement: **Site**, **Unit**, **ProductDefinition**, **QualityResult**. The Cognite module uses **snake_case** for container properties; we use **camelCase**. Both use **CogniteDescribable** on views. A standalone version of this appendix is maintained in [ISA95_COGNITE_MODULE_DEEP_COMPARISON.md](docs/06-plans/ISA95_COGNITE_MODULE_DEEP_COMPARISON.md).

<a id="appendix-a1-scope"></a>
### A.1 Scope and Conventions

#### A.1.1 What we compare

| Entity            | Cognite spec (container/view) | Sylvamo (container/view) | In scope |
|-------------------|--------------------------------|---------------------------|----------|
| Site              | `sp_isa_manufacturing_Site`    | `Asset` (sylvamo_mfg)      | ✅ CDM Asset |
| Unit              | `sp_isa_manufacturing_Unit`    | `Equipment` (sylvamo_mfg)  | ✅ CDM Equipment |
| ProductDefinition | `sp_isa_manufacturing_ProductDefinition` | `ProductDefinition` (sylvamo_mfg) | ✅ Deployed  |
| QualityResult     | `sp_isa_manufacturing_QualityResult`     | `QualityResult` (sylvamo_mfg)     | ✅ Deployed  |
| Batch             | `sp_isa_manufacturing_Batch`   | `Reel` (sylvamo_mfg)       | ✅ Deployed |
| MaterialLot       | `sp_isa_manufacturing_MaterialLot` | `Roll` (sylvamo_mfg)   | ✅ Deployed |
| —                 | —                              | `Package` (sylvamo_mfg)    | ✅ Sylvamo extension |

Other Cognite entities (Enterprise, Area, ProcessCell, Batch, Recipe, Phase, WorkOrder, etc.) are not implemented in our ISA space; see [Section 3](#section-3-align-with-spec) and [Section 4](#section-4-diagram-vs-model) for entity-level coverage.

#### A.1.2 Naming and structure

- **Spec:** Container names prefixed with `sp_isa_manufacturing_`; space `sp_isa_manufacturing` (schema) and optionally `sp_isa_instance` (instances). Property names in **snake_case** (e.g. `site_id`, `unit_id`).
- **Sylvamo:** Containers named by entity (e.g. `Asset`, `Equipment`, `Reel`); single space **sylvamo_mfg**. Property names in **camelCase** (e.g. `reelNumber`, `productionDate`).
- **CDM:** Both use views that implement **CogniteDescribable**; we use **requiresCogniteDescribable** on containers and indexes on ID properties for performance.

<a id="appendix-a2-site"></a>
### A.2 Site – Deep Comparison

#### A.2.1 Spec (Cognite module)

- **Role:** ISA-95 Level 4 – physical location where manufacturing is performed.
- **Typical properties** (from spec conventions and README): `site_id`, `name`, `location`, `country`, and CogniteDescribable fields (`name`, `description`). May include parent reference to Enterprise.
- **Relations:** Parent to Area/Unit (or direct Unit children in a simplified hierarchy).

#### A.2.2 Sylvamo implementation

**Container (`Site.container.yaml`):**

| Property           | Type      | Spec equivalent   | Notes |
|--------------------|-----------|-------------------|-------|
| `siteId`           | text      | `site_id`         | Primary identifier; aligned. |
| `name`             | text      | `name`            | Aligned. |
| `location`         | text      | `location`        | Aligned. |
| `country`          | text      | `country`         | Aligned. |
| `isaLevel`         | text      | —                 | **Sylvamo:** Always "Site". |
| `siteType`         | text      | —                 | **Sylvamo:** Mill, FinishingFacility, Warehouse, Distribution. |
| `aliases`          | json      | —                 | **Sylvamo:** SAP plant codes, legacy IDs. |
| `description`      | text      | `description`     | CogniteDescribable-style; aligned. |
| `createdDate`      | timestamp | —                 | **Sylvamo:** Metadata. |
| `lastModifiedDate` | timestamp | —                 | **Sylvamo:** Metadata. |

**View:** Implements container + **CogniteDescribable**; exposes **units** as reverse relation (multi_reverse_direct_relation) to Unit.

**Alignment:** Core semantics (id, name, location, country, description) match. We use camelCase and add **isaLevel**, **siteType**, **aliases**, and timestamp metadata. We do not have Enterprise/parent; single space.

<a id="appendix-a3-unit"></a>
### A.3 Unit – Deep Comparison

#### A.3.1 Spec (Cognite module)

- **Role:** ISA-95 Level 4 / ISA-88 – basic equipment entity; one or more processing activities; often under ProcessCell.
- **Typical properties:** `unit_id`, `name`, `description`, parent reference (`process_cell` or `site`), and CogniteDescribable fields.
- **Relations:** Parent from ProcessCell (or Site); children to EquipmentModule; reverse from ProductDefinition where ProductDefinition has `unit` as direct list.

#### A.3.2 Sylvamo implementation

**Container (`Unit.container.yaml`):**

| Property      | Type   | Spec equivalent   | Notes |
|---------------|--------|-------------------|-------|
| `unitId`      | text   | `unit_id`         | Primary identifier; aligned. |
| `name`        | text   | `name`            | Aligned. |
| `unitClass`   | text   | —                 | **Sylvamo:** PaperMachine, Winder, Rewinder, etc. |
| `unitType`    | text   | —                 | **Sylvamo:** e.g. Fourdrinier, Gap Former. |
| `capacity`    | float64| —                 | **Sylvamo:** Production capacity. |
| `capacityUnit`| text   | —                 | **Sylvamo:** tons/day, rolls/day, etc. |
| `isaLevel`    | text   | —                 | **Sylvamo:** Always "Unit". |
| `site`        | direct | `process_cell` or `site` | **Sylvamo:** Direct relation to Site (no ProcessCell). |
| `description` | text   | `description`     | Aligned. |
| `aliases`     | json   | —                 | **Sylvamo:** SAP equipment IDs, legacy codes. |
| `manufacturer`| text   | —                 | **Sylvamo:** Equipment metadata. |
| `model`       | text   | —                 | **Sylvamo:** Equipment metadata. |
| `installDate` | date   | —                 | **Sylvamo:** Equipment metadata. |
| `status`      | text   | —                 | **Sylvamo:** Active, Maintenance, Decommissioned. |

**View:** Implements container + **CogniteDescribable**; **site** relation with source view reference; reverse **productDefinitions** not exposed (ProductDefinition uses JSON `producibleUnits` instead of direct relation).

**Alignment:** Core id, name, description, and parent (site) align. We use **site** instead of process_cell; we add **unitClass**, **unitType**, **capacity**, **capacityUnit**, **isaLevel**, **aliases**, **manufacturer**, **model**, **installDate**, **status**. Full reverse relation from Unit to ProductDefinition would require ProductDefinition to use direct `unit` list (see [ISA95_MODEL_ALIGNMENT_CHANGES.md](docs/06-plans/ISA95_MODEL_ALIGNMENT_CHANGES.md)).

<a id="appendix-a4-productdefinition"></a>
### A.4 ProductDefinition – Deep Comparison

#### A.4.1 Spec (Cognite module)

- **Role:** ISA-95 Level 3 – definition of product process and resources; links to Units and ProductSegments.
- **Typical properties:** `product_definition_id`, `name`, `description`, `version`/validity, `status`, and relation to **unit** (often direct list of units). ProductSegments define segments within the product.
- **Relations:** To Unit (which units can produce); to ProductSegment; from ProductRequest.

#### A.4.2 Sylvamo implementation

**Container (`ProductDefinition.container.yaml`):**

| Property          | Type    | Spec equivalent        | Notes |
|-------------------|---------|-------------------------|-------|
| `productId`       | text    | `product_definition_id` | Aligned. |
| `name`            | text    | `name`                  | Aligned. |
| `description`     | text    | `description`           | Aligned. |
| `productType`     | text    | —                       | **Sylvamo:** Bond, Offset, Cover, Text. |
| `productFamily`   | text    | —                       | **Sylvamo:** Grouping. |
| `basisWeight`     | float64 | —                       | **Sylvamo:** Paper spec (lbs). |
| `basisWeightUnit` | text    | —                       | **Sylvamo:** lb, gsm. |
| `brightness`      | float64 | —                       | **Sylvamo:** Paper spec. |
| `caliper`         | float64 | —                       | **Sylvamo:** Paper spec (MILS). |
| `caliperUnit`     | text    | —                       | **Sylvamo:** MILS, mm. |
| `opacity`         | float64 | —                       | **Sylvamo:** Paper spec. |
| `smoothness`      | float64 | —                       | **Sylvamo:** Paper spec. |
| `moistureMin/Max/Target` | float64 | —               | **Sylvamo:** Quality specs. |
| `producibleUnits` | json    | `unit` (direct list)     | **Gap:** We use JSON list of unit externalIds; spec uses direct relation list. Prevents Unit → ProductDefinition reverse relation. |
| `sapMaterialCode` | text    | —                       | **Sylvamo:** SAP integration. |
| `isActive`        | boolean | `status`                | Semantically aligned (active/inactive). |
| `version`         | text    | `version`               | Aligned. |
| `effectiveDate`   | date    | —                       | **Sylvamo:** Validity. |
| `discontinuedDate` | date   | —                       | **Sylvamo:** Validity. |

**View:** Implements container + **CogniteDescribable**; exposes same properties. No ProductSegment or ProductRequest in our ISA space.

**Alignment:** Core id, name, description, version, and active/status align. We use **productId** and **isActive** vs spec **product_definition_id** and **status**; we use **producibleUnits** (JSON) instead of direct **unit** list. We add paper-specific (basisWeight, caliper, brightness, opacity, smoothness, moisture) and **sapMaterialCode**, **effectiveDate**, **discontinuedDate**. ProductSegment and ProductRequest are not implemented.

<a id="appendix-a5-qualityresult"></a>
### A.5 QualityResult – Deep Comparison

#### A.5.1 Spec (Cognite module)

- **Role:** Quality test results and inspection data; links to Batch and MaterialLot.
- **Typical properties:** `quality_result_id`, `name`, `description`, test name/method/type, result value/text/date, unit of measure, and **direct relations** to Batch and MaterialLot.
- **Relations:** To Batch; to MaterialLot; optionally to Personnel (analyst).

#### A.5.2 Sylvamo implementation

**Container (`QualityResult.container.yaml`):**

| Property     | Type     | Spec equivalent   | Notes |
|--------------|----------|-------------------|-------|
| `name`       | text     | `name`            | CogniteDescribable; aligned. |
| `description`| text     | `description`     | Aligned. |
| `resultId`   | text     | `quality_result_id`| Aligned. |
| `testName`   | text     | test name         | Aligned. |
| `testMethod` | text     | test method       | Aligned. |
| `testType`   | text     | —                 | **Sylvamo:** Physical, Chemical, Visual, Dimensional. |
| `resultValue`| float64  | result value      | Aligned. |
| `resultText` | text     | result text       | Aligned. |
| `resultDate` | timestamp| result date       | Aligned. |
| `unitOfMeasure` | text  | unit of measure   | Aligned. |
| `specMin`    | float64  | —                 | **Sylvamo:** Spec comparison. |
| `specMax`    | float64  | —                 | **Sylvamo:** Spec comparison. |
| `specTarget` | float64  | —                 | **Sylvamo:** Spec comparison. |
| `isInSpec`   | boolean  | —                 | **Sylvamo:** Derived in/out of spec. |
| `deviation`  | float64  | —                 | **Sylvamo:** Deviation from target. |
| `batch`      | text     | batch (direct)    | **Gap:** We store Batch/Reel external ID as text; spec uses direct relation. |
| `materialLot`| text     | material_lot (direct) | **Gap:** We store Roll external ID as text; spec uses direct relation. |
| `sourceSystem` | text  | —                 | **Sylvamo:** Proficy, SharePoint, PI. |
| `sourceId`   | text     | —                 | **Sylvamo:** Source system ID. |
| `varId`      | int32    | —                 | **Sylvamo:** Proficy variable ID. |
| `puId`       | int32    | —                 | **Sylvamo:** Proficy paper unit ID. |
| `testEventId`| int64    | —                 | **Sylvamo:** Proficy test event. |
| `status`     | text     | —                 | **Sylvamo:** Pending, Complete, Verified, Rejected. |
| `notes`      | text     | —                 | **Sylvamo:** Comments. |
| `createdDate`| timestamp| —                 | **Sylvamo:** CDF record creation. |

**View:** Our QualityResult **view** ✅ now deployed in sylvamo_mfg ("version must not be null" CDF issue). Container and properties are defined; view deployment is a known gap.

**Alignment:** Core result id, name, description, test name/method, result value/text/date, unit of measure align. We use **resultId** vs spec **quality_result_id**. We add spec comparison (**specMin**, **specMax**, **specTarget**, **isInSpec**, **deviation**), source tracking (**sourceSystem**, **sourceId**), Proficy fields (**varId**, **puId**, **testEventId**), and **status**/ **notes**/ **createdDate**. **batch** and **materialLot** are text refs (Reel/Roll external IDs) instead of direct relations, so navigation to Batch/MaterialLot views is not type-safe in the model.

<a id="appendix-a6-relations-summary"></a>
### A.6 Relations Summary

| Relation              | Spec (Cognite)        | Sylvamo                         |
|-----------------------|------------------------|----------------------------------|
| Site → Unit           | Yes (or via Area/ProcessCell) | Yes (direct; reverse `units` on Site). |
| Unit → Site           | Yes (or via ProcessCell)      | Yes (direct `site`).             |
| Unit → ProductDefinition | Reverse from ProductDefinition.unit (direct list) | Not exposed; ProductDefinition has `producibleUnits` (JSON). |
| ProductDefinition → Unit | direct list `unit`    | JSON `producibleUnits` (unit externalIds). |
| QualityResult → Batch | direct relation        | text (Batch/Reel external ID).  |
| QualityResult → MaterialLot | direct relation  | text (Roll external ID).         |

<a id="appendix-a7-summary"></a>
### A.7 Appendix Summary

- **Site:** Strong alignment. Differences: camelCase, single space, no Enterprise, and Sylvamo extensions (isaLevel, siteType, aliases, timestamps). Reverse **units** relation present.
- **Unit:** Strong alignment. Differences: camelCase, **site** instead of process_cell, and Sylvamo extensions (unitClass, unitType, capacity, manufacturer, model, status, etc.). Reverse **productDefinitions** not available while ProductDefinition uses JSON for units.
- **ProductDefinition:** Core aligned; notable gap: **producibleUnits** (JSON) vs spec **unit** (direct list). Paper and SAP extensions; no ProductSegment/ProductRequest.
- **QualityResult:** Core test/result fields aligned; **batch** and **materialLot** are text refs, not direct relations. ✅ View deployed in sylvamo_mfg. Sylvamo adds spec comparison, source tracking, and Proficy fields.

For changes made to improve alignment (indexes, constraints, CogniteDescribable, reverse relations), see [ISA95_MODEL_ALIGNMENT_CHANGES.md](docs/06-plans/ISA95_MODEL_ALIGNMENT_CHANGES.md).

↑ [Back to table of contents](#table-of-contents)
