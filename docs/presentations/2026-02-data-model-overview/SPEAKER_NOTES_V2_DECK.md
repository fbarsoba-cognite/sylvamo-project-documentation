# Speaker Notes – IDL Pilot Data Model Review (V2 Deck)

**Deck:** IDL Pilot - Data Modeling (V2) (2026-02-15)  
**Date:** February 18, 2026  
**Total slides:** 22 (slide 13 is “WORKING SLIDES – TO BE DELETED”; consider skipping or removing)  
**Source:** Aligned with [sylvamo-project-documentation](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/tree/main/docs/presentations/2026-02-data-model-overview) and validated scenario docs.

> **Note:** Statistics (e.g. RollQuality counts, PPV) may change. Verify in CDF if citing current numbers.

---

## Slide 1: Title – IDL Pilot Data Model Review | February 18th, 2026

**Time:** ~1 min

**Key points**
- Welcome and set context for the IDL (Industrial Data Landscape) pilot.
- This session is the data model review for that pilot.

**Script**
- "Good morning/afternoon. Today we’re reviewing the **IDL Pilot Data Model** – how we’re organizing and connecting manufacturing data in Cognite Data Fusion for Sylvamo.
- By the end you’ll see how the model is structured, how data flows in, and how it’s already enabling discoveries from connected data."

**Transition:** "We’ll start with what a data model is and why it matters."

---

## Slide 2: What is a Data Model?

**Time:** ~2–3 min

**Key points**
- A data model is a **blueprint**: how data is organized, stored, and related.
- Analogy: floor plan → rooms (entities), hallways (relationships).
- Without a model: data scattered, duplicated, hard to navigate.
- With a model: data becomes **connected knowledge** (e.g. SAP, PI, SharePoint → unified view: Asset → Reel → Roll → Quality).

**Script**
- "A **data model** is the blueprint that defines how data is organized, stored, and related. Think of it like a building floor plan: rooms are entities, hallways are relationships.
- Without a data model, we have silos – SAP, PI, SharePoint – and no single place to trace a roll back to its reel and production conditions. With a model, we get a unified view: Asset → Reel → Roll → Quality, all connected."

**Transition:** "The platform we use to host this model is Cognite Data Fusion. Let me briefly show what CDF gives us."

---

## Slide 3: What is Cognite Data Fusion (CDF)?

**Time:** ~2 min

**Key points**
- **Time series at scale** – millions of tags (e.g. PI).
- **Flexible data modeling** – your domain, your structure (e.g. sylvamo_mfg_core).
- **Contextualization** – link assets to files, events, time series.
- **Industrial Tools** – out-of-the-box apps (Search, Canvas, InField) that understand the model.

**Script**
- "CDF gives us three things that matter for this pilot: **time series at scale** from systems like PI; **flexible data modeling** so we can define our own entities and relationships; and **contextualization** – linking assets to files, events, and time series. Because we build on CDF’s standard foundation, **Industrial Tools** – Search, Canvas, InField – work with our data out of the box."

**Transition:** "That foundation is the Cognite Data Model – CDM."

---

## Slide 4: The Cognite Data Model (CDM)

**Time:** ~2 min

**Key points**
- CDM is the **foundation** we build on.
- Core entities: **CogniteAsset** (hierarchy), **CogniteEquipment** (machines), **CogniteTimeSeries** (process data), **CogniteFile** (documents/drawings), **CogniteActivity** (events/work orders), **CogniteSourceSystem** (provenance).

**Script**
- "We don’t invent everything from scratch. The **Cognite Data Model** gives us standard core entities: Asset for the organizational hierarchy, Equipment for physical machines, TimeSeries for process data, File for documents and drawings, and Activity for events and work orders. We also use **CogniteSourceSystem** so we know where each piece of data came from. Sylvamo’s model extends these for paper manufacturing."

**Transition:** "Next we’ll see how that looks for Sylvamo – two models, one foundation."

---

## Slide 5: Sylvamo Data Model Architecture – Two Models, One Foundation

**Time:** ~3 min

**Key points**
- **Two models:** `sylvamo_mfg_core` (core manufacturing) and `sylvamo_mfg_extended` (ISA-95 extensions).
- Both built on **CDM** (CogniteAsset, CogniteTimeSeries, CogniteActivity, etc.).
- Core = Asset, Event, Material, MfgTimeSeries, Reel, Roll, RollQuality; Extended = WorkOrder, ProductionOrder, CostEvent, Equipment, etc.

**Script**
- "Sylvamo’s architecture is **two models, one foundation**. The foundation is CDM. On top we have **sylvamo_mfg_core** – Asset, Event, Reel, Roll, RollQuality, MfgTimeSeries, Material – and **sylvamo_mfg_extended** – WorkOrder, ProductionOrder, CostEvent, Equipment, and related ISA-95 concepts. Same foundation, so Industrial Tools and APIs work across both."

**Transition:** "Here’s how the core manufacturing flow actually connects."

---

## Slide 6: The Manufacturing Flow – sylvamo_mfg_core

**Time:** ~3 min

**Key points**
- **Organizational:** Asset is the base (sites, areas, equipment – e.g. Eastover Mill, PM1, Winder). Everything links back to *where* it happened.
- **Support:** Event (work orders, production events) links to assets.
- **Production:** Reel → Roll; both link to Asset and ProductDefinition.
- **Quality:** RollQuality links to roll and asset. From any roll you can trace to reel, asset, events, quality.

**Script**
- "In **sylvamo_mfg_core** the flow is: (1) **Organizational** – Asset is the base – Eastover Mill, PM1, Winder. All other data links back to the asset where it happened. (2) **Support** – Event captures work orders and production events tied to those assets. (3) **Production** – Reel is produced on an asset, then cut into Rolls. (4) **Quality** – RollQuality links to both roll and asset. So from any roll you can trace back to reel, asset, events, and quality reports. That’s the value of the connected model."

**Transition:** "Let me walk a concrete scenario – a reel produced on PM1 – to show how properties and relationships work."

---

## Slide 7: Entity Properties & Attributes – Scenario (Reel on PM1)

**Time:** ~3 min

**Key points**
- **Scenario:** A paper reel is produced on Paper Machine 1 (PM1).
- **Asset (PM1)** = where it happens.
- **MfgTimeSeries** = sensors (caliper, moisture, speed) from that asset.
- **Reel** = record created and linked to PM1 (and product).
- **Roll** = cut from reel; **RollQuality** = test at equipment (e.g. where defect was found). From a quality report you can trace: Roll → Reel → Asset, plus events and time series.

**Script**
- "Imagine a reel produced on **Paper Machine 1**. The **Asset** PM1 is where it happens. **MfgTimeSeries** from that asset collect caliper, moisture, speed. A **Reel** record is created and linked to PM1. When the reel is cut, **Roll** records link back to that reel. When we run a quality check, **RollQuality** is recorded at the equipment – e.g. Sheeter No.2. From that one report we can trace: Roll → Reel → Asset, plus all related events and time series. That’s the power of a connected data model."

**Transition:** "So how does data actually get into this model? Our data pipeline."

---

## Slide 8: Data Pipeline Overview – How Data Gets into mfg_core

**Time:** ~3 min

**Key points**
- Data comes from **multiple source systems**.
- **Fabric PPR** (e.g. 16 tables) – reels, rolls from the lakehouse.
- **Fabric SAP ECC** (many tables) – work orders, notifications.
- **SAP Gateway**, **PI**, **Proficy**, **SharePoint** – each feeds extractors → **RAW** → **transformations** → data model views.

**Script**
- "Data lands in **mfg_core** from several sources. **Fabric PPR** brings reels and rolls from the lakehouse. **Fabric SAP ECC** brings work orders and related SAP data. We also have **SAP Gateway**, **PI Server**, **Proficy**, and **SharePoint**. Extractors load into **RAW** databases; then **SQL transformations** map RAW into our data model. So we have a clear path: source systems → extractors → RAW → transformations → Asset, Reel, Roll, RollQuality, Event, and so on."

**Transition:** "I’ll show you a real discovery that came from this connected data."

---

## Slide 9: The Sylvamo Data Model in Action – A Real Discovery from Connected Data

**Time:** ~4 min

**Key points**
- **Equipment:** Sheeter No.2.
- **Defect:** Baggy Edges (e.g. 15–22 incidents in validation).
- **Time lost:** e.g. 27.6 hours (slide) vs 92.7 hours (all Sheeter No.2 reports in CDF – different scope).
- **Root cause:** e.g. "Jams in pockets 6, 7, and 8".
- **Flow:** RollQuality → Roll → Reel → Asset; quality and equipment linked so we can see patterns by asset.

**Script**
- "Here’s a real example from **your data**. At **Sheeter No.2** we saw multiple **Baggy Edges** defects – dozens of quality reports and significant time lost. Root cause notes mentioned things like **jams in pockets 6, 7, and 8**. Without the model, that would mean pulling from SharePoint, SAP, and maybe PI separately. With the model, **RollQuality** is linked to **Roll**, **Reel**, and **Asset**. We can filter by Sheeter No.2 and see defect type, time lost, and root cause in one place. That’s the model in action."

**Backup:** For validation methodology and CDF numbers (e.g. RollQuality at Sheeter No.2, Baggy Edges counts), see scenario validation docs in this folder or the main repo [presentations/2026-02-data-model-overview](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/tree/main/docs/presentations/2026-02-data-model-overview).

**Transition:** "There are more discoveries when we query across the whole dataset."

---

## Slide 10: (Visual / continuation)

**Time:** ~0–1 min

**Key points**
- If this slide is a visual or duplicate of slide 9, use it only to pause and point at the diagram or repeat the “RollQuality → Roll → Reel → Asset” flow.
- If it’s blank, skip or use for a one-line recap: "So from one quality report we trace back to reel, asset, and events."

---

## Slide 11: More Discoveries – Without vs With Connected Data

**Time:** ~2 min

**Key points**
- **Without connected data:** 5+ systems to check, hours to find patterns, reactive maintenance.
- **With connected data:** one query, seconds to find patterns, **proactive maintenance**.

**Script**
- "Without connected data you’re checking five or more systems and spending hours to find patterns – and you’re mostly **reactive**. With the model, one query can surface patterns in seconds, so you can move toward **proactive** maintenance and root cause analysis. The next slide shows concrete numbers we found."

**Transition:** "Here’s what we actually found in the data."

---

## Slide 12: More Discoveries – What We Found

**Time:** ~3 min

**Key points**
- **Total quality issues:** e.g. 180 records (slide subset) – full CDF may show more (e.g. 750 RollQuality).
- **Rejected rolls:** e.g. 53 (slide) vs 285 (full dataset) – slide often reflects a subset/time window.
- **Total time lost:** e.g. 96 hours (subset) vs 346+ hours (full).
- **#1 defect:** Curl (e.g. 60 in subset; Curl still #1 in full data).
- **#2 defect:** Baggy Edges (e.g. 28 in subset).
- **Equipment:** Sheeter No.1 has the most incidents (e.g. 107 in subset; pattern holds in full data).
- **Cost improvement:** e.g. $1.3M PPV improvement (if on slide – from PPV/cost use case).

**Script**
- "When we queried the full quality dataset we saw: hundreds of quality records, dozens of rejected rolls, and many hours of time lost. The **top defect** was **Curl**, then **Baggy Edges**. The equipment with the most issues was **Sheeter No.1**. We also see **cost improvement** from Purchase Price Variance analysis. The exact numbers on the slide may be from a subset or time window; the full CDF dataset can show more records, but the **rankings and patterns** hold – and that’s what drives prioritization and proactive action."

**Transition:** "If we have time, we can open CDF and run a query, or we can move to Q&A."

---

## Slide 13: WORKING SLIDES (TO BE DELETED)

**Time:** 0 min (do not present)

**Key points**
- This is a placeholder. **Skip in delivery** or remove from the deck before the meeting.
- If someone asks: "That slide marks internal working content we don’t present to stakeholders."

---

## Slide 14: What is a Data Model (backup / duplicate)

**Time:** ~0–1 min (only if you need a backup)

**Key points**
- Same content as Slide 2: blueprint, floor plan analogy, without vs with model (SAP/PI/SP → unified view).
- Use only if you need to re-explain “what is a data model” (e.g. after a question). Otherwise skip.

---

## Slide 15: Cognite Data Fusion – Key Capabilities (backup)

**Time:** ~0–1 min (backup)

**Key points**
- Same as Slide 3: Time Series at scale, Flexible Data Modeling, Contextualization, Industrial Tools.
- Use only if asked “what is CDF?” or to reinforce capabilities.

---

## Slide 16: Cognite Data Model (CDM) (backup)

**Time:** ~0–1 min (backup)

**Key points**
- Same as Slide 4: CDM as foundation; CogniteAsset, CogniteEquipment, CogniteTimeSeries, CogniteFile, CogniteActivity, CogniteSourceSystem.
- Use only if someone asks for the “standard entities” we build on.

---

## Slide 17: Sylvamo Data Model Architecture – Two Models, One Foundation (backup)

**Time:** ~0–1 min (backup)

**Key points**
- Same as Slide 5: two models, one CDM foundation; core vs extended views.
- Use if you need to re-show the architecture slide (e.g. after a question).

---

## Slide 18: The Manufacturing Flow (backup)

**Time:** ~0–1 min (backup)

**Key points**
- Same as Slide 6: organizational (Asset), support (Event), production (Reel → Roll), quality (RollQuality); traceability from roll to reel, asset, events, quality.

---

## Slide 19: Entity Properties & Attributes (backup)

**Time:** ~0–1 min (backup)

**Key points**
- Same as Slide 7: scenario of reel on PM1, MfgTimeSeries, Reel, Roll, RollQuality, and tracing from a quality report back through the model.

---

## Slide 20: Data Pipeline Overview (backup)

**Time:** ~0–1 min (backup)

**Key points**
- Same as Slide 8: source systems, Fabric PPR/SAP ECC, other sources, extractors → RAW → transformations → mfg_core.

---

## Slide 21: Data Model in Action – A Real Discovery (backup / detail)

**Time:** ~1–2 min (if you use it)

**Key points**
- Same story as Slide 9: Sheeter No.2, Baggy Edges, 15 quality reports, 27.6 hours lost, root cause “Jams in pockets 6, 7, and 8”; timeline (e.g. Dec 17 cluster, Jan 21 cluster). Use if you want to emphasize the timeline or repeat the story.

**Script**
- "Same discovery we saw earlier: Sheeter No.2, Baggy Edges, with clusters in December and January and a clear root cause. The model let us go from a quality report to equipment and pattern in one place."

---

## Slide 22: More Discoveries from Your Data (summary table)

**Time:** ~2 min

**Key points**
- Table: Total Quality Issues, Total Time Lost, #1/#2 Defect Type, Equipment Needing Attention, Cost Improvement.
- Emphasize that these are **real findings from connected data** and that the model makes this kind of summary possible in one place.

**Script**
- "This table summarizes what we found in **your data**: total quality issues, time lost, top defect types, which equipment needs attention, and cost improvement. All of this comes from **one connected model** – no manual stitching across SAP, SharePoint, and PI. That’s the IDL pilot data model in practice."

**Transition:** "That’s the end of the deck. Happy to take questions or dive into CDF live if useful."

---

## Presentation tips

- **Timing:** Slides 1–9 and 11–12 drive the narrative; allow ~2–4 min each. Backup slides (14–20, 21–22) use only as needed.
- **Numbers:** If you cite counts (e.g. 180 vs 750 RollQuality), briefly note that “slide numbers may be from a subset; full CDF has more – patterns and rankings are what we use.”
- **Demo:** If you show CDF: open Fusion, apply “Sylvamo MFG Core” (or equivalent) location filter, search for an asset (e.g. PM1 or Sheeter No.2), then show linked events and/or RollQuality. See [DEMO_SCRIPT.md](DEMO_SCRIPT.md) in this folder for steps.
- **Docs:** Point people to: [sylvamo-project-documentation – docs/presentations/2026-02-data-model-overview](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/tree/main/docs/presentations/2026-02-data-model-overview) for outline, speaker notes, and scenario validations.

---

## Quick reference – slide order (V2 deck)

| # | Title / content | Use |
|---|----------------------------------|-----|
| 1 | IDL Pilot Data Model Review, Feb 18, 2026 | Title |
| 2 | What is a Data Model? | Core |
| 3 | What is CDF? | Core |
| 4 | The Cognite Data Model (CDM) | Core |
| 5 | Sylvamo Data Model Architecture – Two Models, One Foundation | Core |
| 6 | The Manufacturing Flow (sylvamo_mfg_core) | Core |
| 7 | Entity Properties & Attributes (scenario) | Core |
| 8 | Data Pipeline Overview | Core |
| 9 | Model in Action – Real Discovery (Sheeter No.2, Baggy Edges) | Core |
| 10 | Visual / continuation | Optional |
| 11 | More Discoveries – With/Without connected data | Core |
| 12 | More Discoveries – What We Found | Core |
| 13 | WORKING SLIDES (TO BE DELETED) | Skip |
| 14–20 | Backup: What is a Data Model, CDF, CDM, Architecture, Flow, Properties, Pipeline | Backup |
| 21 | Data Model in Action (duplicate/detail) | Optional |
| 22 | More Discoveries from Your Data (table) | Core / closing |

---

*Speaker notes for IDL Pilot Data Model Review (V2 deck), aligned with sylvamo-project-documentation and scenario validation docs. Last updated February 2026.*
