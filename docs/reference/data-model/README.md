# Data Model Documentation

> **Purpose:** Guide for navigating Sylvamo data model documentation  
> **Audience:** Sylvamo stakeholders, Cognite implementation team  
> **Last Updated:** January 31, 2026

---

## Recommended Reading Order

For architecture discussions and stakeholder meetings, follow this order:

### 1. Current State Overview
**Document:** [ARCHITECTURE_DECISION_RECORD.md - Section 1](ARCHITECTURE_DECISION_RECORD.md#1-current-state)

- Two models exist: `sylvamo_mfg` (POC) vs `sylvamo_mfg_core` (Production)
- Instance counts: 365,000+ nodes in production
- Establishes baseline for discussion

### 2. Data Model Comparison
**Document:** [ARCHITECTURE_DECISION_RECORD.md - Section 2](ARCHITECTURE_DECISION_RECORD.md#2-data-model-comparison)

- Entity mapping diagram (sylvamo_mfg vs sylvamo_mfg_core)
- Key differences table
- CDM interface implementation benefits

### 3. ISA-95/ISA-88 Alignment
**Document:** [ARCHITECTURE_DECISION_RECORD.md - Section 3](ARCHITECTURE_DECISION_RECORD.md#3-isa-95isa-88-alignment)

- ISA-95 hierarchy mapping diagram
- What's implemented vs what's planned
- Reel = Batch, Roll = MaterialLot alignment

### 4. Gap Analysis
**Document:** [ARCHITECTURE_DECISION_RECORD.md - Section 5](ARCHITECTURE_DECISION_RECORD.md#5-gap-analysis)

- Current gaps (Equipment, ProductDefinition, Recipe, Package)
- Data quality gaps
- Resolution plan

### 5. Architecture Decisions
**Document:** [ARCHITECTURE_DECISION_RECORD.md - Section 7](ARCHITECTURE_DECISION_RECORD.md#7-architecture-decisions)

- ADR-001: CDM Interfaces
- ADR-002: Unified Event Entity
- ADR-003: SAP Functional Location as Asset Hierarchy
- ADR-004: Reel as ISA-95 Batch
- ADR-005: Separate Schema/Instance Spaces

### 6. Roadmap and Next Steps
**Document:** [MODEL_EVOLUTION_ROADMAP.md](MODEL_EVOLUTION_ROADMAP.md)

- Phase 2: Equipment, Activity specializations (Feb 2026)
- Phase 3: Package, ProductDefinition, consolidation (Q1-Q2 2026)
- Phase 4: Full ISA alignment (Q3 2026)
- Success metrics and risks

---

## Discussion Flow

```
Current State → Model Comparison → ISA Alignment → Gaps → Decisions → Roadmap
     ↓              ↓                  ↓            ↓         ↓          ↓
  "Where we      "What we          "Industry     "What's   "Why we    "Where we're
   are now"       have"            standards"    missing"   chose"      going"
```

---

## Document Index

| Document | Description | Audience |
|----------|-------------|----------|
| [**ARCHITECTURE_DECISION_RECORD.md**](ARCHITECTURE_DECISION_RECORD.md) | Model comparison, ISA-95 alignment, 5 ADRs | Technical + Stakeholders |
| [**MODEL_EVOLUTION_ROADMAP.md**](MODEL_EVOLUTION_ROADMAP.md) | Phased roadmap with timelines and metrics | All |
| [**DATA_MODEL_SPECIFICATION.md**](DATA_MODEL_SPECIFICATION.md) | Complete technical spec with containers and properties | Technical |
| [**DATA_MODEL_FOR_STAKEHOLDERS.md**](DATA_MODEL_FOR_STAKEHOLDERS.md) | Non-technical overview with business examples | Business |
| [**DATA_MODEL_WALKTHROUGH.md**](DATA_MODEL_WALKTHROUGH.md) | Step-by-step traceability example | All |
| [**SYLVAMO_MFG_DATA_MODEL_DIAGRAM.md**](SYLVAMO_MFG_DATA_MODEL_DIAGRAM.md) | Visual ER and flow diagrams | All |
| [**APPENDIX_MFG_CORE_MODEL.md**](APPENDIX_MFG_CORE_MODEL.md) | CDM-integrated model details | Technical |

---

## Quick Links by Topic

### For Understanding the Model
- [Data Model Specification](DATA_MODEL_SPECIFICATION.md) - Full technical details
- [Stakeholder Guide](DATA_MODEL_FOR_STAKEHOLDERS.md) - Business overview
- [Walkthrough](DATA_MODEL_WALKTHROUGH.md) - End-to-end example

### For Architecture Decisions
- [Architecture Decision Record](ARCHITECTURE_DECISION_RECORD.md) - All ADRs
- [Model Evolution Roadmap](MODEL_EVOLUTION_ROADMAP.md) - Future plans

### For ISA-95 Alignment
- [Architecture Decision Record - ISA Section](ARCHITECTURE_DECISION_RECORD.md#3-isa-95isa-88-alignment)
- [Roadmap - ISA Compliance Checklist](MODEL_EVOLUTION_ROADMAP.md#isa-compliance-checklist)

---

## Key Statistics (January 2026)

### sylvamo_mfg_core (Production)

| Entity | Count |
|--------|-------|
| Asset | 45,953 |
| Event | 100,000+ |
| Material | 58,342 |
| MfgTimeSeries | 3,532+ |
| Reel | 61,335 |
| Roll | 100,000+ |
| RollQuality | 180 |
| CogniteFile | 97 |
| **Total** | **365,000+** |

---

*For questions, contact the Cognite implementation team.*
