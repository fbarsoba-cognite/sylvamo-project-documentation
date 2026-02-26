# Sylvamo Data Model Documentation

> **Purpose:** Comprehensive guide for navigating Sylvamo data model documentation  
> **Audience:** Sylvamo stakeholders, Cognite implementation team  
> **Last Updated:** February 2026

---

## Overview

This folder contains **all** documentation for Sylvamo's CDF data models, consolidated in one location:

- **Architecture & Roadmap** - Main comprehensive document for architecture decisions
- **ISA-95/ISA-88 Reference** - Alignment analysis and expert guidance
- **Data Model Specifications** - Technical specs and business overviews
- **Visual Diagrams** - Mermaid diagrams and appendices

**Primary Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md](ARCHITECTURE_DECISIONS_AND_ROADMAP.md) - The main comprehensive document (56KB, 1,664 lines).

---

## Document Index

All data model documentation is now consolidated in this folder.

### Primary Architecture Documentation

| Document | Description | Size |
|----------|-------------|------|
| [**ARCHITECTURE_DECISIONS_AND_ROADMAP.md**](ARCHITECTURE_DECISIONS_AND_ROADMAP.md) | **Main document** - 15 sections + 8 appendices: model comparison, ISA-95 alignment, 10 ADRs, roadmap, use cases, multi-site planning, implementation details, glossary | 56KB |

### ISA-95/ISA-88 Reference

| Document | Description | Size |
|----------|-------------|------|
| [COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md](COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md) | Detailed ISA-95/88 alignment analysis with property-level comparison | 36KB |
| [JOHAN_ISA95_GUIDANCE_SUMMARY.md](JOHAN_ISA95_GUIDANCE_SUMMARY.md) | Expert recommendations from Cognite ISA specialist (Johan Stabekk, Jan 28 2026) | 11KB |

### Transformations and Data Pipeline

| Document | Description | Size |
|----------|-------------|------|
| [**TRANSFORMATIONS.md**](TRANSFORMATIONS.md) | **Complete transformation documentation** - 24 SQL transformations, data flow diagrams, SQL examples, troubleshooting | 25KB |

### Training

| Document | Description | Size |
|----------|-------------|------|
| [**TRAINING_DATA_MODEL_GUIDELINE.md**](TRAINING_DATA_MODEL_GUIDELINE.md) | **Training curriculum** – audience tracks (business, technical, ops, presenters), document order, checklists | 12KB |

### Data Model Specifications

| Document | Description | Size |
|----------|-------------|------|
| [DATA_MODEL_SPECIFICATION.md](DATA_MODEL_SPECIFICATION.md) | Complete technical spec with containers, properties, relationships, and examples | 19KB |
| [MFG_CORE_DATA_MODEL.md](MFG_CORE_DATA_MODEL.md) | sylvamo_mfg_core - Asset with assetType (ADR-001), 7 views | 10KB |
| [MFG_EXTENDED_DATA_MODEL.md](MFG_EXTENDED_DATA_MODEL.md) | sylvamo_mfg_extended - WorkOrder, CostEvent, Equipment (CogniteEquipment) | 9KB |
| [DATA_MODEL_FOR_STAKEHOLDERS.md](DATA_MODEL_FOR_STAKEHOLDERS.md) | Non-technical overview with flow diagrams and business examples | 8KB |
| [DATA_MODEL_WALKTHROUGH.md](DATA_MODEL_WALKTHROUGH.md) | Step-by-step traceability example from production to delivery | 16KB |

### Visual Diagrams and Appendices

| Document | Description | Size |
|----------|-------------|------|
| [SYLVAMO_MFG_DATA_MODEL_DIAGRAM.md](SYLVAMO_MFG_DATA_MODEL_DIAGRAM.md) | Visual ER and flow diagrams with Mermaid | 10KB |
| [APPENDIX_MFG_CORE_MODEL.md](APPENDIX_MFG_CORE_MODEL.md) | CDM-integrated model details for sylvamo_mfg_core | 8KB |

---

## Meeting Discussion Order

For architecture discussions and stakeholder meetings, follow this recommended order using the main [ARCHITECTURE_DECISIONS_AND_ROADMAP.md](ARCHITECTURE_DECISIONS_AND_ROADMAP.md):

| # | Topic | Section | Time |
|---|-------|---------|------|
| 1 | Executive Summary | [Section 1](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#1-executive-summary) | 5 min |
| 2 | Current State: Three Model Layers | [Section 2](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#2-current-state-three-model-layers) | 10 min |
| 3 | Architecture Decisions (10 ADRs) | [Section 3](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#3-architecture-decisions-made) | 15 min |
| 4 | Entity Comparison: Current vs ISA | [Section 4](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#4-entity-comparison-current-vs-isa-95-target) | 10 min |
| 5 | What's Deployed Today | [Section 5](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#5-sylvamo_mfg_core-whats-deployed-today) | 10 min |
| 6 | ISA Manufacturing Extension | [Section 6](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#6-cognite-isa-manufacturing-extension-the-target-framework) | 5 min |
| 7 | Alignment Analysis | [Section 7](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#7-alignment-analysis-core-model-vs-isa-extension) | 10 min |
| 8 | Roadmap (4 Phases) | [Section 8](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#8-roadmap-path-to-full-isa-95-alignment) | 10 min |
| 9 | Impact Assessment | [Section 9](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#9-impact-assessment) | 5 min |
| 10 | Recommendations | [Section 10](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#10-recommendations) | 5 min |
| 11 | Use Cases Enabled | [Section 11](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#11-use-cases-enabled) | Optional |
| 12 | Multi-Site Considerations | [Section 12](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#12-multi-site-considerations) | Optional |

**Total: ~85 minutes** (core sections) + optional deep-dives

---

## Quick Links by Topic

### Understanding the Current Model

| Topic | Link |
|-------|------|
| What entities exist? | [Section 5: What's Deployed](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#5-sylvamo_mfg_core-whats-deployed-today) |
| How many nodes? | [Data Model Composition Table](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#data-model-composition) |
| Asset hierarchy structure | [Asset Hierarchy Structure](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#asset-hierarchy-structure) |
| Transformation pipeline | [Transformation Pipeline](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#transformation-pipeline) |
| Container properties | [Appendix B](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-b-sylvamo_mfg_core-container-properties) |

### Architecture Decisions

| Topic | Link |
|-------|------|
| All 10 ADRs | [Section 3](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#3-architecture-decisions-made) |
| Why CDM Asset vs ISA hierarchy? | [ADR-1](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#adr-1-cdm-asset--equipment-instead-of-isa-organizational-hierarchy) |
| Why unified Event entity? | [ADR-2](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#adr-2-unified-event-entity) |
| Johan's recommendations | [JOHAN_ISA95_GUIDANCE_SUMMARY.md](JOHAN_ISA95_GUIDANCE_SUMMARY.md) |
| Strategic recommendations | [Section 10](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#10-recommendations) |

### ISA-95/ISA-88 Alignment

| Topic | Link |
|-------|------|
| Entity comparison diagram | [Section 4](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#4-entity-comparison-current-vs-isa-95-target) |
| Cognite ISA Extension overview | [Section 6](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#6-cognite-isa-manufacturing-extension-the-target-framework) |
| What aligns vs what needs work | [Section 7](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#7-alignment-analysis-core-model-vs-isa-extension) |
| Full ISA entity list | [Appendix A](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-a-cognite-isa-manufacturing-extension-entities) |
| Detailed property comparison | [COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md](COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md) |
| Glossary | [Section 15](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#15-glossary) |

### Roadmap and Planning

| Topic | Link |
|-------|------|
| Full roadmap Gantt chart | [Section 8](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#8-roadmap-path-to-full-isa-95-alignment) |
| Phase 1 (Complete) | [Phase 1: Foundation](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#phase-1-foundation-complete) |
| Phase 2 (Next) | [Phase 2: Equipment and Products](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#phase-2-equipment-and-products-next) |
| Phase 3 | [Phase 3: ISA Level Overlay](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#phase-3-isa-level-overlay) |
| Phase 4 | [Phase 4: Advanced ISA-88/95](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#phase-4-advanced-isa-8895) |
| Impact assessment | [Section 9](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#9-impact-assessment) |

### Technical Reference

| Topic | Link |
|-------|------|
| **Complete transformation docs** | [TRANSFORMATIONS.md](TRANSFORMATIONS.md) |
| Transformation SQL examples | [TRANSFORMATIONS.md - Section 4](TRANSFORMATIONS.md#4-transformation-details-by-entity) |
| Data flow diagrams | [TRANSFORMATIONS.md - Section 2](TRANSFORMATIONS.md#2-architecture) |
| Use cases enabled | [Section 11](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#11-use-cases-enabled) |
| Multi-site planning | [Section 12](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#12-multi-site-considerations) |
| Implementation details | [Section 13](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#13-technical-implementation-details) |
| Data quality rules | [Section 14](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#14-data-quality-and-governance) |
| External ID conventions | [Appendix G](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-g-external-id-conventions) |
| Data lineage | [Appendix H](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-h-data-lineage-by-entity) |
| CDM interface diagram | [Appendix C](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-c-cdm-interface-implementation) |
| Entity relationship diagram | [Appendix D](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-d-entity-relationship-diagram) |
| Toolkit module structure | [Appendix E](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-e-toolkit-module-structure) |
| Transformation summary | [Appendix F](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#appendix-f-transformation-summary) |

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

### Transformations

| Category | Count |
|----------|-------|
| Asset population | 1 |
| Production data (Reel, Roll) | 2 |
| Events (4 types) | 4 |
| Time Series | 6 |
| Quality, Files, Materials | 3 |
| **Total** | **17** |

---

## Related Documentation

| Document | Location | Description |
|----------|----------|-------------|
| Extractors | [../extractors/EXTRACTORS.md](../extractors/EXTRACTORS.md) | Extractor configurations and status |
| Use Cases | [../use-cases/USE_CASES_AND_QUERIES.md](../use-cases/USE_CASES_AND_QUERIES.md) | Verified use case scenarios |
| Sprint 2 Plan | [../../archive/2026-02-sprint2-completed/SPRINT_2_PLAN.md](../../archive/2026-02-sprint2-completed/SPRINT_2_PLAN.md) | Completed |
| Sprint 3 Plan | [../../internal/sprint-planning/SPRINT_3_PLAN.md](../../internal/sprint-planning/SPRINT_3_PLAN.md) | Current sprint (Feb 16 - Mar 2, 2026) |

---

*For questions, contact the Cognite implementation team.*  
*Last updated: February 2026*

## Deprecated (Archived)

- **MFG_CORE_WITH_EQUIPMENT.md** — Superseded by [ADR-001](decisions/ADR-001-ASSET-EQUIPMENT.md). Equipment is now modeled as Asset subtypes.

