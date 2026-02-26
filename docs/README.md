# Sylvamo Cognite Project - Documentation Index

> CDF implementation for Sylvamo paper manufacturing operations

## Shareable Content Tree

**[→ Content Tree (for screenshare)](CONTENT_TREE_SHAREABLE.md)** – Clean hierarchy to share with customers.

---

## Quick Navigation (by topic)

### 📊 Data & Pipeline
- [**CDF Pipeline Overview**](reference/CDF_PIPELINE_OVERVIEW.md) — End-to-end: extractors, RAW, transformations, CDF functions
- **Data Model**
  - [MFG Core Data Model](reference/data-model/MFG_CORE_DATA_MODEL.md) — 7 core views, Quality Traceability
  - [Data Model Specification](reference/data-model/DATA_MODEL_SPECIFICATION.md) — Containers, properties, examples
  - [Data Model for Stakeholders](reference/data-model/DATA_MODEL_FOR_STAKEHOLDERS.md) — Non-technical overview
  - [Data Model Walkthrough](reference/data-model/DATA_MODEL_WALKTHROUGH.md) — Step-by-step example
  - [Data Model Diagram](reference/data-model/SYLVAMO_MFG_DATA_MODEL_DIAGRAM.md) — Visual Mermaid diagrams
  - [Transformations](reference/data-model/TRANSFORMATIONS.md) — SQL transformations, data flow
  - [MFG Core + PPV (Proposed)](reference/data-model/MFG_CORE_WITH_PPV.md) — PPV integration proposal
  - [MFG Core Model Appendix](reference/data-model/APPENDIX_MFG_CORE_MODEL.md) — CDM-integrated model (draft)
- **Extractors & Sources**
  - [Extractors](reference/extractors/EXTRACTORS.md) — Extractor configurations and status
  - [Data Pipeline & Sources](reference/extractors/DATA_PIPELINE_AND_SOURCES.md) — Data flow, refresh schedules
  - [Data Source Registry](reference/extractors/DATA_SOURCE_REGISTRY.md) — Source system registry

### 🏗️ Architecture & Governance
- [Architecture Decisions & Roadmap](reference/data-model/ARCHITECTURE_DECISIONS_AND_ROADMAP.md) — ISA-95 alignment, roadmap
- [ADR-001: Asset/Equipment Modeling](reference/data-model/decisions/ADR-001-ASSET-EQUIPMENT.md) — Equipment as Asset subtypes
- [Changelog](reference/data-model/changelog/CHANGELOG-0001.md) — Chronological record of changes

### 🔒 Security
- [CDF Security Briefing](reference/security/CDF_SECURITY_BRIEFING.md) — Identity, access, responsibility split; meeting-ready with diagrams
- [CDF Security Briefing (Customer-Facing)](reference/security/CDF_SECURITY_CUSTOMER_BRIEFING.md) — Shareable meeting version with visual aids and detail callout boxes

### 🔧 Operations & CI/CD
- [CI/CD Overview](reference/cicd/CICD_OVERVIEW.md) — Pipeline setup for CDF deployments
- [ADO Clone Repo](reference/cicd/ADO_CLONE_REPO.md) — How to clone the ADO repository
- [ADO Pipeline Setup](reference/cicd/ADO_PIPELINE_SETUP.md) — Pipeline configuration guide
- [CI/CD Complete Setup Guide](reference/cicd/CICD_COMPLETE_SETUP_GUIDE.md) — Full setup walkthrough
- [CI/CD System Explanation](reference/cicd/CICD_SYSTEM_EXPLANATION.md) — Architecture explanation
- [CI/CD Testing Guide](reference/cicd/CICD_TESTING_GUIDE.md) — Testing procedures
- [Pipeline Troubleshooting](reference/cicd/CICD_PIPELINE_TROUBLESHOOTING.md) — Common issues and fixes

### 📁 Content & Contextualization
- **Files & P&ID**
  - [CDF File Management](reference/files/CDF_FILE_MANAGEMENT.md) — Storage, CogniteFile CDM, file-to-asset linking
  - [P&ID Contextualization Lifecycle](reference/files/PID_CONTEXTUALIZATION_LIFECYCLE.md) — Ingestion, detection, matching
  - [Annotation Workflow & Versioning](reference/files/ANNOTATION_WORKFLOW_AND_VERSIONING.md) — Annotation model
- **Contextualization**
  - [Contextualization Primer](reference/CONTEXTUALIZATION_PRIMER.md) — CDF contextualization capabilities
  - [Contextualization Gap Analysis](reference/CONTEXTUALIZATION_GAP_ANALYSIS.md) — Gaps and recommendations

### 📋 Use Cases & Workflows
- [Use Cases & Queries](reference/use-cases/USE_CASES_AND_QUERIES.md) — Verified scenarios with real data
- [Expert Scenarios](reference/use-cases/USE_CASE_VALIDATION_EXPERT_SCENARIOS.md) — Industry use cases
- [Code Change Workflow](reference/workflows/CODE_CHANGE_WORKFLOW.md) — Code changes, validation, Jira, changelog

### 📅 Planning
- [Sprint 3 Plan](internal/sprint-planning/SPRINT_3_PLAN.md) — Current sprint (Feb 16–Mar 2, 2026)

### 📚 Reference & Historical
- [ISA Extension & Sylvamo Alignment](reference/data-model/COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md) — ISA-95/88 analysis
- [Johan ISA95 Guidance Summary](reference/data-model/JOHAN_ISA95_GUIDANCE_SUMMARY.md) — Expert recommendations
- [SortField Analysis Report](reference/SORTFIELD_ANALYSIS_REPORT.md) — SAP sortField mapping
- [MFG Extended Data Model](reference/data-model/MFG_EXTENDED_DATA_MODEL.md) — Secondary model (de-emphasized)
- [Presentations](presentations/README.md) — Demo materials index
- [2026-02 Data Model Overview](presentations/2026-02-data-model-overview/INDEX.md) — Feb 2026 deep dive

### 📦 Archive
- [Archive Index](archive/README.md) — Deprecated docs, completed sprint artifacts
- [Sprint 2 Completed](archive/2026-02-sprint2-completed/) — Sprint 2 plan and story mapping
- [Deprecated Designs](archive/2026-02-deprecated/) — Superseded data model proposals

---

## Directory Structure

```
docs/
├── reference/                      # Polished, customer-ready documentation
│   ├── data-model/                 # Data model specifications
│   │   ├── changelog/              # Chronological change records
│   │   ├── decisions/              # Architecture Decision Records (ADRs)
│   │   └── archive/               # Superseded model docs
│   ├── extractors/                 # Extractor and pipeline docs
│   ├── security/                   # CDF security, identity, access management
│   ├── cicd/                       # CI/CD pipeline setup and guides
│   ├── files/                      # CDF file management, P&ID lifecycle
│   ├── use-cases/                  # Use case documentation
│   └── workflows/                  # Development workflows
│
├── internal/                       # Working documents (internal use)
│   └── sprint-planning/            # Current sprint planning
│
├── presentations/                  # Demo and presentation materials
│   ├── README.md                  # Section index (start here)
│   └── 2026-02-data-model-overview/  # Sprint 2 demo (Feb 2026)
│
└── archive/                        # Deprecated/historical content
    ├── 2026-02-deprecated/         # Superseded design docs
    └── 2026-02-sprint2-completed/  # Sprint 2 artifacts
```

---

*Last updated: February 2026*
