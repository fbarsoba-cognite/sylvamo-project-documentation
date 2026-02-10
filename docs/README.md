# Sylvamo Cognite Project

> CDF implementation for Sylvamo paper manufacturing operations

## Quick Navigation

### Reference Documentation (Polished)
- **Data Model**
  - [Data Model Specification](reference/data-model/DATA_MODEL_SPECIFICATION.md)
  - [Data Model for Stakeholders](reference/data-model/DATA_MODEL_FOR_STAKEHOLDERS.md)
  - [Data Model Walkthrough](reference/data-model/DATA_MODEL_WALKTHROUGH.md)
  - [Data Model Diagram](reference/data-model/SYLVAMO_MFG_DATA_MODEL_DIAGRAM.md)
  - [MFG Core Model Appendix](reference/data-model/APPENDIX_MFG_CORE_MODEL.md)
- **Extractors & Pipeline**
  - [Extractors](reference/extractors/EXTRACTORS.md)
  - [Data Pipeline & Sources](reference/extractors/DATA_PIPELINE_AND_SOURCES.md)
  - [CI/CD Overview](reference/extractors/CICD_OVERVIEW.md)
- **Files & P&ID Contextualization**
  - [CDF File Management](reference/files/CDF_FILE_MANAGEMENT.md) — Storage architecture, CogniteFile CDM, file-to-asset linking
  - [P&ID Contextualization Lifecycle](reference/files/PID_CONTEXTUALIZATION_LIFECYCLE.md) — Ingestion, detection, matching, approval, revision handling
  - [Annotation Workflow & Versioning](reference/files/ANNOTATION_WORKFLOW_AND_VERSIONING.md) — Annotation model, confidence scoring, file revision behavior
- **Use Cases**
  - [Use Cases & Queries](reference/use-cases/USE_CASES_AND_QUERIES.md)
  - [Expert Scenarios](reference/use-cases/USE_CASE_VALIDATION_EXPERT_SCENARIOS.md)

### Internal Working Documents
- **Sprint Planning**
  - [Sprint 2 Plan](internal/sprint-planning/SPRINT_2_PLAN.md)
  - [Sprint 2 Story Mapping](internal/sprint-planning/SPRINT_2_STORY_MAPPING.md)
- **Plans & Alignment**
 - [**Architecture Decisions & Roadmap**](internal/plans/ARCHITECTURE_DECISIONS_AND_ROADMAP.md) – Meeting prep: model comparison, ISA-95 alignment, roadmap
 - [ISA Extension & Sylvamo Alignment](internal/plans/COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md)
 - [Johan ISA95 Guidance Summary](internal/plans/JOHAN_ISA95_GUIDANCE_SUMMARY.md)

### Project Documents
- Coming soon

### Archive
- Historical/deprecated content

---

## Directory Structure

```
docs/
├── reference/              # Polished, customer-ready documentation
│   ├── data-model/         # Data model specifications
│   ├── extractors/         # Extractor and pipeline docs
│   ├── files/              # CDF file management, P&ID lifecycle, annotations
│   ├── use-cases/          # Use case documentation
│   └── getting-started/    # Onboarding guides
│
├── internal/               # Working documents (internal use)
│   ├── sprint-planning/    # Sprint planning artifacts
│   └── plans/              # Active project plans
│
├── project-docs/           # Official project artifacts
│
└── archive/                # Deprecated/historical content
```

---

*Last updated: February 10, 2026*
