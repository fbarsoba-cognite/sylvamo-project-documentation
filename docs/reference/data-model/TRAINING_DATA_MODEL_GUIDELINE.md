# Training Data Model Guideline

> **Purpose:** Structured training curriculum for the Sylvamo Manufacturing Data Model in CDF. Use this to onboard new team members, run training sessions, or self-study. All content links to existing documentation.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Audience Tracks](#2-audience-tracks)
3. [Track A: Business Stakeholders](#3-track-a-business-stakeholders)
4. [Track B: Data Engineers & Developers](#4-track-b-data-engineers--developers)
5. [Track C: Operations & Support](#5-track-c-operations--support)
6. [Track D: Presenters & Trainers](#6-track-d-presenters--trainers)
7. [Training Checklist](#7-training-checklist)
8. [Quick Reference](#8-quick-reference)

---

## 1. Overview

### What This Guideline Covers

| Topic | Description |
|-------|-------------|
| **Data model** | Asset, Reel, Roll, Event, RollQuality, Material, MfgTimeSeries |
| **Pipeline** | Source systems → Extractors → RAW → Transformations → Views |
| **Use cases** | Quality traceability, PPV/cost analysis, inter-plant logistics |
| **Operations** | Troubleshooting, access, monitoring |

### Prerequisites

| Track | Prerequisites |
|-------|---------------|
| Business | None – start with [DATA_MODEL_FOR_STAKEHOLDERS.md](DATA_MODEL_FOR_STAKEHOLDERS.md) |
| Technical | Basic SQL, familiarity with APIs or data pipelines |
| Ops | CDF access, basic troubleshooting mindset |
| Presenters | Completion of Track A or B, access to presentation materials |

---

## 2. Audience Tracks

| Track | Audience | Duration | Goal |
|-------|----------|----------|------|
| **A** | Business stakeholders, SMEs, analysts | 1–2 hours | Understand what the model captures and what questions it answers |
| **B** | Data engineers, developers, architects | 3–4 hours | Understand structure, pipeline, and how to query/extend |
| **C** | Ops, support, platform teams | 2–3 hours | Troubleshoot issues, verify access, diagnose pipeline failures |
| **D** | Presenters, trainers | 2–3 hours | Deliver 30-min deep dive or extended sessions |

---

## 3. Track A: Business Stakeholders

**Goal:** Understand what the model captures and what business questions it answers.

### Recommended Order

| Step | Document | Time | Focus |
|------|----------|------|-------|
| 1 | [DATA_MODEL_FOR_STAKEHOLDERS.md](DATA_MODEL_FOR_STAKEHOLDERS.md) | 30 min | Entities, flow, traceability example |
| 2 | [USE_CASES_AND_QUERIES.md](../use-cases/USE_CASES_AND_QUERIES.md) | 20 min | Quality traceability, PPV analysis – real examples |
| 3 | [ARCHITECTURE_DECISIONS_AND_ROADMAP.md](ARCHITECTURE_DECISIONS_AND_ROADMAP.md) – Sections 1, 5, 11 | 20 min | Executive summary, what’s deployed, use cases enabled |

### Key Concepts to Retain

- **Asset** = Mills, plants, equipment (with `assetType`)
- **Reel** = Paper batch from a machine
- **Roll** = Cut roll from a reel (sellable unit)
- **RollQuality** = Quality test results linked to roll and asset
- **Event** = Work orders, production events, PPV snapshots
- **Traceability** = Roll → Reel → Asset → Quality

### Self-Check

- [ ] Can you explain the flow: Asset → Reel → Roll → Quality?
- [ ] Can you name 2–3 business questions the model answers?
- [ ] Do you know where Eastover and Sumter fit in the model?

---

## 4. Track B: Data Engineers & Developers

**Goal:** Understand model structure, pipeline, and how to query or extend it.

### Recommended Order

| Step | Document | Time | Focus |
|------|----------|------|-------|
| 1 | [MFG_CORE_DATA_MODEL.md](MFG_CORE_DATA_MODEL.md) | 30 min | Views, relationships, ERD |
| 2 | [CDF_PIPELINE_OVERVIEW.md](../CDF_PIPELINE_OVERVIEW.md) | 25 min | End-to-end flow, extractors, transformations |
| 3 | [DATA_MODEL_SPECIFICATION.md](DATA_MODEL_SPECIFICATION.md) | 45 min | Containers, properties, examples |
| 4 | [TRANSFORMATIONS.md](TRANSFORMATIONS.md) | 45 min | SQL transformations, data flow |
| 5 | [DATA_SOURCE_REGISTRY.md](../extractors/DATA_SOURCE_REGISTRY.md) | 30 min | Source → RAW → Transform → View mapping |
| 6 | [USE_CASES_AND_QUERIES.md](../use-cases/USE_CASES_AND_QUERIES.md) | 30 min | GraphQL examples, verified queries |

### Key Concepts to Retain

- **Spaces:** `sylvamo_mfg_core_schema`, `sylvamo_mfg_core_instances`
- **RAW naming:** `raw_ext_fabric_ppr`, `raw_ext_sap`, etc.
- **Transformation pattern:** `populate_<View>` reads RAW, writes to data model
- **GraphQL:** Use `first`, not `limit`; list views via `listRoll`, `listReel`, etc.

### Hands-On (Optional)

1. **CDF Fusion** – Search for a roll number, navigate to Reel → Asset.
2. **GraphQL Explorer** – Run `listRollQuality(first: 10)` and inspect structure.
3. **Transformations** – Open one transformation in CDF, review SQL and schedule.

### Self-Check

- [ ] Can you trace data from a RAW table to a view?
- [ ] Can you write a simple GraphQL query for RollQuality with asset?
- [ ] Do you know which transformation populates Roll?

---

## 5. Track C: Operations & Support

**Goal:** Troubleshoot issues, verify access, and diagnose pipeline failures.

### Recommended Order

| Step | Document | Time | Focus |
|------|----------|------|-------|
| 1 | [CDF_OVERVIEW_AND_TROUBLESHOOTING_GUIDE.md](../CDF_OVERVIEW_AND_TROUBLESHOOTING_GUIDE.md) | 45 min | Components, interactions, troubleshooting flow |
| 2 | [DATA_SOURCE_REGISTRY.md](../extractors/DATA_SOURCE_REGISTRY.md) – Master table | 30 min | Where to look when data is missing |
| 3 | [CDF_SECURITY_BRIEFING.md](../security/CDF_SECURITY_BRIEFING.md) | 30 min | Groups, capabilities, scope |
| 4 | [CICD_PIPELINE_TROUBLESHOOTING.md](../cicd/CICD_PIPELINE_TROUBLESHOOTING.md) | 30 min | CI/CD errors, variable groups, auth |

### Key Concepts to Retain

- **Missing data:** RAW → Extractor → Transformation → View (follow the chain)
- **Access denied:** Entra ID group → CDF group `sourceId` → Capabilities → Scope
- **Transformation failed:** CDF Transformations → Runs → Logs
- **Extractor failed:** CDF Extraction Pipelines or VM logs

### Diagnostic Scripts

- `scripts/validate_file_annotation_permissions.py` – Example permission validation (sylvamo repo)

### Self-Check

- [ ] If a view is empty, what are the 4 places to check?
- [ ] Where do you look when a user says they can’t see data?
- [ ] What does “Variable group could not be found” mean and how do you fix it?

---

## 6. Track D: Presenters & Trainers

**Goal:** Deliver the 30-min deep dive or extended sessions.

### Recommended Order

| Step | Document | Time | Focus |
|------|----------|------|-------|
| 1 | [presentations/2026-02-data-model-overview/INDEX.md](../../presentations/2026-02-data-model-overview/INDEX.md) | 15 min | 30-min flow, document index |
| 2 | [SPEAKER_NOTES_V2_DECK.md](../../presentations/2026-02-data-model-overview/SPEAKER_NOTES_V2_DECK.md) | 45 min | Full speaker notes for 22 slides |
| 3 | [DEMO_SCRIPT.md](../../presentations/2026-02-data-model-overview/DEMO_SCRIPT.md) | 30 min | Step-by-step CDF Fusion demo |
| 4 | [MFG_CORE_DIAGRAM_PRESENTATION_GUIDE.md](../../presentations/2026-02-data-model-overview/MFG_CORE_DIAGRAM_PRESENTATION_GUIDE.md) | 20 min | Diagram walkthrough |
| 5 | [PRESENTER_PACKAGE.md](../../presentations/2026-02-data-model-overview/PRESENTER_PACKAGE.md) | 15 min | Pre-presentation checklist |

### 30-Minute Flow (from INDEX)

| Time | Topic | Doc |
|------|-------|-----|
| 0–2 min | Intro, what is a data model | SPEAKER_NOTES – Slides 1–2 |
| 2–5 min | CDF, CDM, architecture | SPEAKER_NOTES – Slides 3–5 |
| 5–8 min | Manufacturing flow | MFG_CORE_DIAGRAM_PRESENTATION_GUIDE |
| 8–12 min | Model in action (Sheeter No.2, quality) | SCENARIO_MODEL_IN_ACTION_VALIDATION |
| 12–16 min | Data pipeline | DATA_PIPELINE_DEEP_DIVE |
| 16–22 min | Demo – GraphQL, Search | DEMO_SCRIPT |
| 22–28 min | More discoveries | SCENARIO_MORE_DISCOVERIES_VALIDATION |
| 28–30 min | Wrap-up, Q&A | PRESENTER_PACKAGE |

### Self-Check

- [ ] Can you run the 30-min flow without notes?
- [ ] Have you rehearsed the live demo (Search, GraphQL)?
- [ ] Do you know the current instance counts (MFG_CORE_NODE_DISTRIBUTION)?

---

## 7. Training Checklist

### By End of Training, Trainees Should Be Able To…

| Track | Outcome |
|-------|---------|
| **A** | Explain Asset → Reel → Roll → Quality flow; name 2+ business questions the model answers |
| **B** | Trace data from RAW to view; write a basic GraphQL query; name key transformations |
| **C** | Follow troubleshooting flow for missing data; locate where to check permissions |
| **D** | Deliver 30-min presentation; run live demo; answer common Q&A |

### Validation Questions (for trainers)

| Question | Expected Answer |
|----------|-----------------|
| "What is a Reel?" | Paper batch from a machine; parent of Rolls |
| "Where does RollQuality data come from?" | SharePoint (roll_quality), CDF Function |
| "If Roll view is empty, where do you look?" | RAW (ppr_hist_roll), Extractor, Transformation |
| "User can’t see assets – where to check?" | CDF Groups, sourceId, capabilities, datasetScope |

---

## 8. Quick Reference

### Document Index by Topic

| Topic | Primary Doc | Backup / Deep Dive |
|-------|-------------|---------------------|
| Business overview | [DATA_MODEL_FOR_STAKEHOLDERS.md](DATA_MODEL_FOR_STAKEHOLDERS.md) | [ARCHITECTURE_DECISIONS_AND_ROADMAP.md](ARCHITECTURE_DECISIONS_AND_ROADMAP.md) |
| Technical model | [MFG_CORE_DATA_MODEL.md](MFG_CORE_DATA_MODEL.md) | [DATA_MODEL_SPECIFICATION.md](DATA_MODEL_SPECIFICATION.md) |
| Pipeline | [CDF_PIPELINE_OVERVIEW.md](../CDF_PIPELINE_OVERVIEW.md) | [DATA_SOURCE_REGISTRY.md](../extractors/DATA_SOURCE_REGISTRY.md) |
| Transformations | [TRANSFORMATIONS.md](TRANSFORMATIONS.md) | [CDF_PIPELINE_OVERVIEW.md](../CDF_PIPELINE_OVERVIEW.md) |
| Use cases | [USE_CASES_AND_QUERIES.md](../use-cases/USE_CASES_AND_QUERIES.md) | [USE_CASE_VALIDATION_EXPERT_SCENARIOS.md](../use-cases/USE_CASE_VALIDATION_EXPERT_SCENARIOS.md) |
| Troubleshooting | [CDF_OVERVIEW_AND_TROUBLESHOOTING_GUIDE.md](../CDF_OVERVIEW_AND_TROUBLESHOOTING_GUIDE.md) | [CICD_PIPELINE_TROUBLESHOOTING.md](../cicd/CICD_PIPELINE_TROUBLESHOOTING.md) |
| Security / access | [CDF_SECURITY_BRIEFING.md](../security/CDF_SECURITY_BRIEFING.md) | [CDF_SECURITY_LIVE_DEMO_WALKTHROUGH.md](../security/CDF_SECURITY_LIVE_DEMO_WALKTHROUGH.md) |
| Presentation | [presentations/INDEX.md](../../presentations/2026-02-data-model-overview/INDEX.md) | [DEMO_SCRIPT.md](../../presentations/2026-02-data-model-overview/DEMO_SCRIPT.md) |

### Data Model Index

Full data model documentation: [data-model/README.md](README.md)

---

*Last updated: February 2026*
