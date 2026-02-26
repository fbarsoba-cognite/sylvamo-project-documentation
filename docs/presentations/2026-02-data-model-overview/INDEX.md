# Data Model Deep Dive – 30 Minute Presentation Index

**Purpose:** Entry point for a 30-minute deep dive on the Sylvamo Manufacturing Data Model in CDF.  
**Source of truth for counts:** [MFG_CORE_NODE_DISTRIBUTION.md](MFG_CORE_NODE_DISTRIBUTION.md) (from live CDF).

---

## Quick reference – current model state

| View | Instances | % of total |
|------|-----------|------------|
| Roll | 2,361,739 | 84.7% |
| Event | 224,961 | 8.1% |
| Reel | 62,436 | 2.2% |
| Material | 58,342 | 2.1% |
| Asset | 45,953 | 1.6% |
| MfgTimeSeries | 6,260 | 0.2% |
| RollQuality | 750 | 0.0% |
| **Total** | **2,787,005** | |

---

## 30-minute flow (recommended)

| Time | Topic | Use this doc |
|------|-------|--------------|
| 0–2 min | Intro, what is a data model | [SPEAKER_NOTES_V2_DECK.md](SPEAKER_NOTES_V2_DECK.md) – Slides 1–2 |
| 2–5 min | CDF, CDM, Sylvamo architecture | [SPEAKER_NOTES_V2_DECK.md](SPEAKER_NOTES_V2_DECK.md) – Slides 3–5 |
| 5–8 min | Manufacturing flow, entities | [MFG_CORE_DIAGRAM_PRESENTATION_GUIDE.md](MFG_CORE_DIAGRAM_PRESENTATION_GUIDE.md) |
| 8–12 min | **Model in action** – Real discovery (Sheeter No.2, quality) | [SPEAKER_NOTES_V2_DECK.md](SPEAKER_NOTES_V2_DECK.md) – Slide 9; [SCENARIO_MODEL_IN_ACTION_VALIDATION.md](SCENARIO_MODEL_IN_ACTION_VALIDATION.md) |
| 12–16 min | Data pipeline | [DATA_PIPELINE_DEEP_DIVE.md](DATA_PIPELINE_DEEP_DIVE.md) |
| 16–22 min | Demo – GraphQL, Search, traceability | [DEMO_SCRIPT.md](DEMO_SCRIPT.md) |
| 22–28 min | More discoveries, quality/PPV stats | [SCENARIO_MORE_DISCOVERIES_VALIDATION.md](SCENARIO_MORE_DISCOVERIES_VALIDATION.md); [SPEAKER_NOTES_V2_DECK.md](SPEAKER_NOTES_V2_DECK.md) – Slide 12 |
| 28–30 min | Wrap-up, Q&A | [PRESENTER_PACKAGE.md](PRESENTER_PACKAGE.md) |

---

## Document index

| Document | Purpose | When to use |
|----------|---------|-------------|
| **[INDEX.md](INDEX.md)** | This file – entry point for 30 min deep dive | Start here |
| **[README.md](README.md)** | Overview, key data points, file list | General reference |
| **[SPEAKER_NOTES_V2_DECK.md](SPEAKER_NOTES_V2_DECK.md)** | Speaker notes for V2 deck (22 slides, IDL Pilot) | Primary script for presentation |
| **[SPEAKER_NOTES.md](SPEAKER_NOTES.md)** | Speaker notes for 60 min deck (20 slides) | Extended version |

### Demo & how-to

| Document | Purpose | When to use |
|----------|---------|-------------|
| **[DEMO_SCRIPT.md](DEMO_SCRIPT.md)** | Step-by-step CDF Fusion demo | Live demo |
| **HOW_TO_SHOW_MODEL_IN_ACTION_IN_CDF.md** | GraphQL queries, Fusion paths, roll-quality viewer | Showing "Real Discovery" in CDF *(in sylvamo repo: docs/presentations/2026-02-data-model-overview/)* |

### Data & validation

| Document | Purpose | When to use |
|----------|---------|-------------|
| **[MFG_CORE_NODE_DISTRIBUTION.md](MFG_CORE_NODE_DISTRIBUTION.md)** | **Source of truth** – instance counts, pie chart | Citing current numbers |
| **[ACTUAL_DATA_WALKTHROUGH.md](ACTUAL_DATA_WALKTHROUGH.md)** | Step-by-step data walkthrough | Explaining data flow |
| **[SCENARIO_MODEL_IN_ACTION_VALIDATION.md](SCENARIO_MODEL_IN_ACTION_VALIDATION.md)** | Sheeter No.2, Baggy Edges validation | Slide scenario backup |
| **[SCENARIO_MORE_DISCOVERIES_VALIDATION.md](SCENARIO_MORE_DISCOVERIES_VALIDATION.md)** | Quality stats, defect types, equipment | Slide 16 backup |
| **[PROPERTIES_DIAGRAM_VALIDATION.md](PROPERTIES_DIAGRAM_VALIDATION.md)** | Property vs CDF alignment | Technical reference |

### Architecture & pipeline

| Document | Purpose | When to use |
|----------|---------|-------------|
| **[MFG_CORE_DIAGRAM_PRESENTATION_GUIDE.md](MFG_CORE_DIAGRAM_PRESENTATION_GUIDE.md)** | Diagram walkthrough, Org/Support/Prod/Quality | Explaining flow |
| **[DATA_PIPELINE_DEEP_DIVE.md](DATA_PIPELINE_DEEP_DIVE.md)** | 35 tables, Fabric, transformations | Pipeline details |

### Supporting

| Document | Purpose | When to use |
|----------|---------|-------------|
| **[SLIDES_OUTLINE.md](SLIDES_OUTLINE.md)** | Slide-by-slide content | Slide content reference |
| **[PRESENTER_PACKAGE.md](PRESENTER_PACKAGE.md)** | Checklist, links | Pre-presentation |
| **[DECK_COMPARISON_CHECKLIST.md](DECK_COMPARISON_CHECKLIST.md)** | Deck vs outline alignment | Deck sync |
| **[CONTENT_SYNC_GUIDE.md](CONTENT_SYNC_GUIDE.md)** | Copy-paste from repo to deck | Slide authoring |

---

## Data verification note

> **Slide numbers vs full CDF:** Some slides cite "180 quality records" or "96 hours" – these reflect a **subset** (e.g. time window). Full CDF has **750 RollQuality**, **346.6 hours** total time lost, **285 rejected rolls**. Use [MFG_CORE_NODE_DISTRIBUTION.md](MFG_CORE_NODE_DISTRIBUTION.md) and validation docs for current numbers. Patterns (Curl #1, Baggy #2, Sheeter No.1 most issues) hold.

---

## Related

- **Repo:** [sylvamo-project-documentation](https://github.com/fbarsoba-cognite/sylvamo-project-documentation)
- **Folder:** [docs/presentations/2026-02-data-model-overview](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/tree/main/docs/presentations/2026-02-data-model-overview)
