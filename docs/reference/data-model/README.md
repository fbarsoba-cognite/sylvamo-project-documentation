# Sylvamo Data Model Documentation

> **Purpose:** Comprehensive guide for navigating Sylvamo data model documentation  
> **Audience:** Sylvamo stakeholders, Cognite implementation team  
> **Last Updated:** February 2026

---

## Overview

This folder contains the complete documentation for Sylvamo's CDF data models. The documentation covers:

- **Current Production Model** (`sylvamo_mfg_core`) - 450,000+ nodes from real source systems
- **Legacy PoC Model** (`sylvamo_mfg`) - Original ISA-aligned schema with sample data
- **Target Framework** (Cognite ISA Manufacturing Extension) - Full ISA-95/ISA-88 reference

**Primary Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md](ARCHITECTURE_DECISIONS_AND_ROADMAP.md) - The main comprehensive document for architecture discussions.

---

## Meeting Discussion Order

For architecture discussions and stakeholder meetings, follow this recommended order:

### 1. Executive Summary (5 min)
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 1](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#1-executive-summary)

**Key Points:**
- Three model layers: PoC → Production → ISA Target
- Production model runs today with 44,898 assets, 92K+ events, 83K+ reels
- Key question: How to evolve toward full ISA-95 alignment while preserving operational data

**Discussion:** Establish baseline understanding of current state.

---

### 2. Current State: Three Model Layers (10 min)
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 2](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#2-current-state-three-model-layers)

**Key Points:**
- PoC Model (`sylvamo_mfg`): 9 entities, 197 sample nodes, no transformations
- Production Model (`sylvamo_mfg_core`): 8 entities, 450K+ nodes, 17 transformations
- ISA Extension: 25+ entities, full ISA-95/ISA-88 coverage

**Visual:** Three-layer diagram showing evolution path

| Dimension | PoC | Production | ISA Target |
|-----------|-----|------------|------------|
| Entities | 9 views | 8 views | 25+ views |
| Real Data | 197 nodes | 450,000+ | Seed only |
| CDM Integration | Partial | Full | Full |
| Transformations | None | 17 active | Templates |

**Discussion:** Which layer are we discussing? What's the target?

---

### 3. Architecture Decisions Made (15 min)
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 3](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#3-architecture-decisions-made)

**5 Key ADRs:**

| ADR | Decision | Rationale |
|-----|----------|-----------|
| **ADR-1** | Use CDM Asset + Equipment instead of ISA organizational hierarchy | Leverages out-of-the-box CDM capabilities; Johan's recommendation |
| **ADR-2** | Unified Event entity for all event types | Simplifies Search; eventType distinguishes WorkOrder, ProductionOrder, etc. |
| **ADR-3** | Reel = ISA Batch, Roll = ISA MaterialLot | Paper-manufacturing naming aligned with ISA concepts |
| **ADR-4** | Schema/Instance space separation | Matches ISA Extension pattern; cleaner access control |
| **ADR-5** | MfgTimeSeries with `timeseries` property type | Enables preview/sparkline in CDF UI |

**Discussion:** Confirm these decisions or identify concerns.

---

### 4. Entity Comparison: Current vs ISA-95 Target (10 min)
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 4](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#4-entity-comparison-current-vs-isa-95-target)

**Entity Mapping:**

| Current Entity | ISA-95 Equivalent | Alignment Status |
|----------------|-------------------|------------------|
| Asset (CogniteAsset) | Site, Area, ProcessCell, Unit | Partial - needs ISA level overlay |
| Event (CogniteActivity) | WorkOrder, Batch | Partial - unified vs separate |
| Reel | Batch | Aligned |
| Roll | MaterialLot | Aligned |
| MfgTimeSeries | ISATimeSeries | Aligned |
| Material | Material | Aligned |
| RollQuality | QualityResult | Aligned |
| CogniteFile | ISAFile | Aligned |
| -- | Equipment | Not implemented |
| -- | Recipe | Not implemented |
| -- | ProductDefinition | Not implemented |

**Visual:** Entity mapping flowchart

**Discussion:** Which missing entities are priorities?

---

### 5. What's Deployed Today (10 min)
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 5](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#5-sylvamo_mfg_core-whats-deployed-today)

**Data Model Composition:**

| View | Nodes | Source |
|------|-------|--------|
| Asset | 44,898 | SAP Functional Locations |
| Event | 92,000+ | SAP, Proficy, Fabric |
| Reel | 83,600+ | Fabric PPR |
| Roll | 1,000+ | Fabric PPR |
| MfgTimeSeries | 3,532 | PI Extractor |
| Material | TBD | SAP |
| RollQuality | TBD | SharePoint |
| CogniteFile | 97 | CDF Files |

**Transformation Pipeline:** 17 active transformations from 5 source systems

**Asset Hierarchy:** 9 levels deep (Site → Area → ProcessCell → Unit → Equipment)

**Discussion:** Is the current data sufficient? What's missing?

---

### 6. Alignment Analysis (10 min)
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 7](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#7-alignment-analysis-core-model-vs-isa-extension)

**What Already Aligns (10 aspects):**
- Asset hierarchy (CDM) ✓
- Time Series (CDM) ✓
- Events / Activities (CDM) ✓
- Reel = Batch ✓
- Roll = MaterialLot ✓
- Material ✓
- Quality ✓
- Files ✓
- CDM interfaces ✓
- Toolkit deployment ✓

**What Needs to Change (Priority Order):**

| Gap | Effort | Priority |
|-----|--------|----------|
| Equipment entity | Medium | High |
| Recipe entity | Medium | High |
| ProductDefinition | Medium | High |
| ISA level annotations | Low | Medium |
| WorkOrder extraction | Medium | Medium |
| Package entity | Low | Medium |

**Discussion:** Confirm priority order.

---

### 7. Roadmap (10 min)
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 8](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#8-roadmap-path-to-full-isa-95-alignment)

**4 Phases:**

| Phase | Timeline | Focus |
|-------|----------|-------|
| **Phase 1** | Complete | Asset, Events, Reel/Roll, TimeSeries, Files |
| **Phase 2** | Feb-Apr 2026 | Equipment, ProductDefinition, Recipe, Package |
| **Phase 3** | Apr-Jun 2026 | ISA Level Overlay, WorkOrder Extraction |
| **Phase 4** | Jun-Oct 2026 | ISA-88 Procedural Model, ProductRequest/Segment |

**Visual:** Gantt chart with detailed tasks

**Discussion:** Confirm timeline and phase scope.

---

### 8. Impact Assessment & Recommendations (10 min)
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Sections 9-10](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#9-impact-assessment)

**What Stays the Same:**
- Asset hierarchy (44,898 assets)
- Reel/Roll data
- Event data (92K+)
- Time Series
- 17 transformations
- Location filter
- Toolkit deployment

**What Changes:**
- New entities (Equipment, ProductDefinition, Recipe) - Low risk, additive
- ISA level overlay on Assets - Low risk, property addition
- WorkOrder view extraction - Medium risk, view change

**Strategic Recommendations:**
1. Keep unified Event entity
2. Use ISA Extension as reference, not template
3. Overlay ISA levels, don't rebuild
4. Plan for multi-site (Sumpter)
5. Configure PI extractor for data modeling

**Discussion:** Confirm recommendations.

---

## Discussion Flow Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  1. Executive   │ → │  2. Current     │ → │  3. Architecture │
│     Summary     │    │     State       │    │     Decisions   │
│   (5 min)       │    │   (10 min)      │    │   (15 min)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ↓                                              ↓
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  6. Alignment   │ ← │  5. What's      │ ← │  4. Entity      │
│     Analysis    │    │     Deployed    │    │     Comparison  │
│   (10 min)      │    │   (10 min)      │    │   (10 min)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ↓
┌─────────────────┐    ┌─────────────────┐
│  7. Roadmap     │ → │  8. Impact &    │
│                 │    │  Recommendations│
│   (10 min)      │    │   (10 min)      │
└─────────────────┘    └─────────────────┘

Total: ~80 minutes
```

---

## Document Index

| Document | Description | Audience | Size |
|----------|-------------|----------|------|
| [**ARCHITECTURE_DECISIONS_AND_ROADMAP.md**](ARCHITECTURE_DECISIONS_AND_ROADMAP.md) | **Primary document** - 10 sections + 6 appendices covering model comparison, ISA-95 alignment, ADRs, roadmap, recommendations | All | 25KB |
| [DATA_MODEL_SPECIFICATION.md](DATA_MODEL_SPECIFICATION.md) | Complete technical spec with all containers, properties, relationships, and examples | Technical | 19KB |
| [DATA_MODEL_FOR_STAKEHOLDERS.md](DATA_MODEL_FOR_STAKEHOLDERS.md) | Non-technical overview with flow diagrams and business examples | Business | 8KB |
| [DATA_MODEL_WALKTHROUGH.md](DATA_MODEL_WALKTHROUGH.md) | Step-by-step traceability example from production to delivery | All | 16KB |
| [SYLVAMO_MFG_DATA_MODEL_DIAGRAM.md](SYLVAMO_MFG_DATA_MODEL_DIAGRAM.md) | Visual ER and flow diagrams with Mermaid | All | 10KB |
| [APPENDIX_MFG_CORE_MODEL.md](APPENDIX_MFG_CORE_MODEL.md) | CDM-integrated model details for sylvamo_mfg_core | Technical | 8KB |

---

## Quick Links by Topic

### Understanding the Current Model
| Topic | Link |
|-------|------|
| What entities exist? | [Section 5: What's Deployed Today](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#5-sylvamo_mfg_core-whats-deployed-today) |
| How many nodes? | [Data Model Composition Table](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#data-model-composition) |
| Asset hierarchy structure | [Asset Hierarchy Structure](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#asset-hierarchy-structure) |
| Transformation pipeline | [Transformation Pipeline Diagram](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#transformation-pipeline) |
| Container properties | [Appendix B: Container Properties](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-b-sylvamo_mfg_core-container-properties) |

### Architecture Decisions
| Topic | Link |
|-------|------|
| All 5 ADRs | [Section 3: Architecture Decisions Made](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#3-architecture-decisions-made) |
| Why CDM Asset vs ISA hierarchy? | [ADR-1](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#adr-1-cdm-asset--equipment-instead-of-isa-organizational-hierarchy) |
| Why unified Event entity? | [ADR-2](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#adr-2-unified-event-entity) |
| Johan's recommendations | [ADR-1 Rationale](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#adr-1-cdm-asset--equipment-instead-of-isa-organizational-hierarchy) |
| Strategic recommendations | [Section 10: Recommendations](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#10-recommendations) |

### ISA-95/ISA-88 Alignment
| Topic | Link |
|-------|------|
| Entity comparison diagram | [Section 4: Entity Comparison](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#4-entity-comparison-current-vs-isa-95-target) |
| Cognite ISA Extension overview | [Section 6: Target Framework](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#6-cognite-isa-manufacturing-extension-the-target-framework) |
| What aligns vs what needs work | [Section 7: Alignment Analysis](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#7-alignment-analysis-core-model-vs-isa-extension) |
| Full ISA entity list | [Appendix A: ISA Extension Entities](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-a-cognite-isa-manufacturing-extension-entities) |
| ISA-88 procedural model | [Key ISA Entities Not Yet Implemented](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#key-isa-entities-not-yet-in-sylvamo_mfg_core) |

### Roadmap and Planning
| Topic | Link |
|-------|------|
| Full roadmap Gantt chart | [Section 8: Roadmap](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#8-roadmap-path-to-full-isa-95-alignment) |
| Phase 1 (Complete) | [Phase 1: Foundation](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#phase-1-foundation-complete) |
| Phase 2 (Next) | [Phase 2: Equipment and Products](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#phase-2-equipment-and-products-next) |
| Phase 3 | [Phase 3: ISA Level Overlay](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#phase-3-isa-level-overlay) |
| Phase 4 | [Phase 4: Advanced ISA-88/95](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#phase-4-advanced-isa-8895) |
| Impact assessment | [Section 9: Impact Assessment](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#9-impact-assessment) |

### Technical Reference
| Topic | Link |
|-------|------|
| CDM interface diagram | [Appendix C: CDM Interface Implementation](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-c-cdm-interface-implementation) |
| Entity relationship diagram | [Appendix D: Entity Relationship Diagram](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-d-entity-relationship-diagram) |
| Toolkit module structure | [Appendix E: Module Structure](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-e-toolkit-module-structure) |
| Transformation summary | [Appendix F: Transformation Summary](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-f-transformation-summary) |

---

## Key Statistics (February 2026)

### sylvamo_mfg_core (Production Model)

| Entity | Count | Source System | CDM Interface |
|--------|-------|---------------|---------------|
| Asset | 44,898 | SAP Functional Locations | CogniteAsset |
| Event | 92,000+ | SAP, Proficy, Fabric | CogniteActivity |
| Reel | 83,600+ | Fabric PPR | CogniteDescribable |
| Roll | 1,000+ | Fabric PPR | CogniteDescribable |
| MfgTimeSeries | 3,532 | PI Server | CogniteTimeSeries |
| Material | TBD | SAP Materials | CogniteDescribable |
| RollQuality | TBD | SharePoint | CogniteDescribable |
| CogniteFile | 97 | CDF Files | CogniteFile |
| **Total** | **450,000+** | 5 source systems | Full CDM |

### Asset Hierarchy Breakdown

| Level | ISA-95 Equivalent | Count | Example |
|-------|-------------------|-------|---------|
| 1 | Site | 1 | Eastover Mill (0769) |
| 2 | Area | 12 | Bleaching Systems, Paper Machines |
| 3 | ProcessCell | 108 | Bleach Stock Storage, PM1 Systems |
| 4-5 | Unit | 3,118 | Individual process units |
| 6+ | Equipment | 41,659 | Equipment items |

### Transformation Summary

| Category | Count | Examples |
|----------|-------|----------|
| Asset population | 1 | populate_Asset |
| Production data | 2 | populate_Reel, populate_Roll |
| Events | 4 | populate_Event_Proficy, _WorkOrders, _ProductionOrders, _PPV |
| Time Series | 6 | populate_TimeSeries, Proficy TS (5) |
| Quality | 1 | populate_RollQuality |
| Files | 1 | populate_Files |
| Materials | 1 | populate_Material |
| **Total** | **17** | All scheduled, all running |

---

## Appendices in Main Document

The main [ARCHITECTURE_DECISIONS_AND_ROADMAP.md](ARCHITECTURE_DECISIONS_AND_ROADMAP.md) includes these appendices:

| Appendix | Content |
|----------|---------|
| **A** | Cognite ISA Manufacturing Extension - Full entity list by category |
| **B** | sylvamo_mfg_core Container Properties - MfgAsset, MfgEvent, MfgReel, MfgRoll |
| **C** | CDM Interface Implementation - Class diagram showing inheritance |
| **D** | Entity Relationship Diagram - Full ERD with all relationships |
| **E** | Toolkit Module Structure - Directory tree for toolkit modules |
| **F** | Transformation Summary - All 17 transformations with sources and targets |

---

## Related Documentation

| Document | Location | Description |
|----------|----------|-------------|
| ISA Alignment Analysis | [docs/internal/plans/COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md](../../../internal/plans/COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md) | Detailed ISA-95/88 alignment analysis |
| Johan's Guidance | [docs/internal/plans/JOHAN_ISA95_GUIDANCE_SUMMARY.md](../../../internal/plans/JOHAN_ISA95_GUIDANCE_SUMMARY.md) | Expert recommendations from Cognite |
| Sprint 2 Plan | [docs/internal/sprint-planning/SPRINT_2_PLAN.md](../../../internal/sprint-planning/SPRINT_2_PLAN.md) | Current sprint implementation plan |
| Extractors | [docs/reference/extractors/EXTRACTORS.md](../extractors/EXTRACTORS.md) | Extractor configurations and status |
| Use Cases | [docs/reference/use-cases/USE_CASES_AND_QUERIES.md](../use-cases/USE_CASES_AND_QUERIES.md) | Verified use case scenarios |

---

*For questions, contact the Cognite implementation team.*  
*Last updated: February 2026*
