# Sylvamo CDF Data Model - Presentation Materials

**Presentation Title:** Sylvamo Manufacturing Data Model  
**Subtitle:** ISA-95/ISA-88 Aligned Data Model for Paper Manufacturing  
**Duration:** 60 minutes (20 slides @ ~3 min each)  
**Target Audience:** Technical stakeholders, data engineers, manufacturing SMEs  
**Last Updated:** February 2026

---

## Overview

This presentation covers the Sylvamo Manufacturing Data Model implemented in Cognite Data Fusion (CDF). It explains the data architecture, integration patterns, use cases, and roadmap for the project.

## Presentation Objectives

By the end of this presentation, attendees will understand:

1. **Data Model Architecture** - How the sylvamo_mfg_core model is structured
2. **ISA-95/ISA-88 Alignment** - Why we chose CDM + ISA standards
3. **Data Pipeline** - How data flows from source systems to CDF
4. **Use Cases** - Quality traceability and cost analysis capabilities
5. **Implementation** - CI/CD and deployment practices
6. **Roadmap** - What's next for the data model

## Files in This Folder

| File | Description |
|------|-------------|
| [SLIDES_OUTLINE.md](SLIDES_OUTLINE.md) | Detailed slide-by-slide outline with content |
| [SPEAKER_NOTES.md](SPEAKER_NOTES.md) | Full speaker notes for each slide (~3 min per slide) |
| [DEMO_SCRIPT.md](DEMO_SCRIPT.md) | Step-by-step demo walkthrough for CDF Fusion |
| `assets/` | Screenshots and diagrams for slides |

## Presentation Structure

| Section | Slides | Time | Topics |
|---------|--------|------|--------|
| **1. Introduction** | 1-3 | 9 min | Title, Agenda, Business Context |
| **2. Data Model Overview** | 4-8 | 15 min | Architecture, ERD, ISA alignment, Entities |
| **3. Data Pipeline** | 9-12 | 12 min | Sources, Integration, Extractors, Transformations |
| **4. Use Cases** | 13-16 | 12 min | Quality, PPV, Search, GraphQL |
| **5. Implementation** | 17-18 | 6 min | CI/CD, Statistics |
| **6. Roadmap & Wrap-up** | 19-20 | 6 min | Sprint progress, Q&A |

## Key Data Points to Reference

- **Space:** sylvamo_mfg_core_schema / sylvamo_mfg_core_instances
- **Total Nodes:** 365,000+ real production data
- **Views:** Asset, Event, Material, MfgTimeSeries, Reel, Roll, RollQuality, CogniteFile
- **Transformations:** 24 SQL transformations
- **Extractors:** Fabric, PI, SharePoint, SAP OData, SQL

## Demo Environment

- **CDF Project:** sylvamo-dev
- **Cluster:** az-eastus-1
- **URL:** https://az-eastus-1.cognitedata.com

## Prerequisites for Presenter

1. Access to CDF Fusion (sylvamo-dev project)
2. Location filter "Sylvamo MFG Core" selected
3. Sample data loaded (Eastover Mill assets, reels, time series)
4. GraphQL Explorer access for live queries

## Related Documentation

### Data Model
- [Data Model Specification](../../reference/data-model/DATA_MODEL_SPECIFICATION.md) - Complete container and property specs
- [Architecture Decisions & Roadmap](../../reference/data-model/ARCHITECTURE_DECISIONS_AND_ROADMAP.md) - ADRs and phase planning
- [Data Model Walkthrough](../../reference/data-model/DATA_MODEL_WALKTHROUGH.md) - Step-by-step traceability example
- [Johan ISA-95 Guidance](../../reference/data-model/JOHAN_ISA95_GUIDANCE_SUMMARY.md) - Expert recommendations
- [ISA Alignment Analysis](../../reference/data-model/COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md) - Standards mapping

### Data Pipeline
- [Transformations](../../reference/data-model/TRANSFORMATIONS.md) - 24 SQL transformations documented
- [Extractors](../../reference/extractors/EXTRACTORS.md) - Extractor configurations
- [Data Source Registry](../../reference/extractors/DATA_SOURCE_REGISTRY.md) - RAW table inventory
- [Data Pipeline & Sources](../../reference/extractors/DATA_PIPELINE_AND_SOURCES.md) - Source system details

### Use Cases
- [Use Cases & Queries](../../reference/use-cases/USE_CASES_AND_QUERIES.md) - Verified queries with real data
- [Expert Scenarios](../../reference/use-cases/USE_CASE_VALIDATION_EXPERT_SCENARIOS.md) - Industry use cases

### CI/CD
- [CI/CD Overview](../../reference/cicd/CICD_OVERVIEW.md) - Pipeline setup
- [Complete Setup Guide](../../reference/cicd/CICD_COMPLETE_SETUP_GUIDE.md) - Step-by-step guide

### Sprint Planning
- [Sprint 2 Plan](../../internal/sprint-planning/SPRINT_2_PLAN.md) - Current sprint work
- [Story Mapping](../../internal/sprint-planning/SPRINT_2_STORY_MAPPING.md) - Jira story mapping

---

*Presentation materials prepared for Sylvamo CDF implementation team.*
