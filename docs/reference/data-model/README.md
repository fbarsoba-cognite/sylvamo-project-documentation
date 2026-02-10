# Data Model Documentation

> **Purpose:** Guide for navigating Sylvamo data model documentation  
> **Audience:** Sylvamo stakeholders, Cognite implementation team  
> **Last Updated:** January 31, 2026

---

## Recommended Reading Order

For architecture discussions and stakeholder meetings, follow this order:

### 1. Executive Summary
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 1](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#1-executive-summary)

- Three model layers: PoC, Production, ISA Target
- Key question: How to evolve toward full ISA-95 alignment
- Production model stats: 44,898 assets, 92K+ events, 83K+ reels

### 2. Current State: Three Model Layers
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 2](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#2-current-state-three-model-layers)

- PoC Model (sylvamo_mfg) vs Production Model (sylvamo_mfg_core)
- Comparison table: entities, data, CDM integration, transformations
- Visual diagram of model evolution

### 3. Entity Comparison: Current vs ISA-95 Target
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 4](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#4-entity-comparison-current-vs-isa-95-target)

- Entity mapping diagram (Current to ISA Extension)
- Detailed mapping table with alignment status
- Migration notes for each entity

### 4. Alignment Analysis
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 7](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#7-alignment-analysis-core-model-vs-isa-extension)

- What already aligns (10 aspects)
- What needs to change (9 gaps with effort/priority)
- Clear path forward

### 5. Architecture Decisions
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 3](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#3-architecture-decisions-made)

- ADR-1: CDM Asset + Equipment Instead of ISA Organizational Hierarchy
- ADR-2: Unified Event Entity
- ADR-3: Reel = ISA Batch, Roll = ISA MaterialLot
- ADR-4: Schema/Instance Space Separation
- ADR-5: MfgTimeSeries with `timeseries` Property Type

### 6. Roadmap and Next Steps
**Document:** [ARCHITECTURE_DECISIONS_AND_ROADMAP.md - Section 8](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#8-roadmap-path-to-full-isa-95-alignment)

- Phase 1: Foundation (Complete) - Asset, Events, Reel/Roll, TimeSeries
- Phase 2: Equipment and Products (Feb-Apr 2026)
- Phase 3: ISA Level Overlay (Apr-Jun 2026)
- Phase 4: Advanced ISA-88/95 (Jun-Oct 2026)
- Impact Assessment and Recommendations

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
| [**ARCHITECTURE_DECISIONS_AND_ROADMAP.md**](ARCHITECTURE_DECISIONS_AND_ROADMAP.md) | **Main document** - Model comparison, ISA-95 alignment, 5 ADRs, roadmap, recommendations | All |
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
- [Architecture Decisions](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#3-architecture-decisions-made) - All 5 ADRs
- [Recommendations](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#10-recommendations) - Strategic guidance

### For ISA-95 Alignment
- [Entity Comparison](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#4-entity-comparison-current-vs-isa-95-target) - Current vs Target
- [Cognite ISA Extension](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#6-cognite-isa-manufacturing-extension-the-target-framework) - Target framework
- [Alignment Analysis](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#7-alignment-analysis-core-model-vs-isa-extension) - What aligns, what needs work

### For Roadmap
- [Phase Overview](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#8-roadmap-path-to-full-isa-95-alignment) - Full roadmap with Gantt chart
- [Impact Assessment](ARCHITECTURE_DECISIONS_AND_ROADMAP.md#9-impact-assessment) - What stays, what changes

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
