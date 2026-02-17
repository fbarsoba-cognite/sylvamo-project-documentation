# Deck Comparison Checklist: SharePoint vs SLIDES_OUTLINE

**Purpose:** Use this checklist when comparing the SharePoint deck (IDL Pilot - Data Modeling V2) with the repo outline.  
**SharePoint deck:** [IDL Pilot - Data Modeling (V2) (2026-02-15).pptx](https://sylvamo.sharepoint.com/:p:/r/sites/DX-IndustrialDataLandscape-IDLEastoverPilot/_layouts/15/Doc.aspx?sourcedoc=%7BADC5D8A7-9853-40FE-A087-6A6BC8DAD66A%7D&file=IDL%20Pilot%20-%20Data%20Modeling%20(V2)%20(2026-02-15).pptx&action=edit&mobileredirect=true)  
**Repo outline:** [SLIDES_OUTLINE.md](SLIDES_OUTLINE.md)

---

## How to Use

1. Open the SharePoint deck and SLIDES_OUTLINE.md side-by-side.
2. For each slide, check the boxes as you verify content alignment.
3. Note any gaps or differences in the "Notes" column.
4. Use the Content Sync Guide to copy missing content into the deck.

---

## Section 1: Introduction (Slides 1–3)

| Slide | Expected Title | Checklist | Notes |
|-------|----------------|-----------|-------|
| 1 | Sylvamo Manufacturing Data Model | ☐ Title matches | |
| 1 | Subtitle: ISA-95/88 Aligned for Paper Manufacturing | ☐ Subtitle present | |
| 1 | Presenter name, date Feb 2026 | ☐ Metadata present | |
| 2 | What We'll Cover Today | ☐ Agenda slide | |
| 2 | 6 agenda items (Business Context, Data Model, Pipeline, Use Cases, CI/CD, Roadmap) | ☐ All items listed | |
| 3 | Why This Matters for Sylvamo | ☐ Business context | |
| 3 | Challenge: Data silos (SAP, PI, Proficy, SharePoint) | ☐ Challenge stated | |
| 3 | Goals: traceability, quality, cost, inter-plant | ☐ Goals listed | |

---

## Section 2: Data Model Overview (Slides 4–8)

| Slide | Expected Content | Checklist | Notes |
|-------|-----------------|-----------|-------|
| 4 | sylvamo_mfg_core - Overview | ☐ Title | |
| 4 | Model evolution table (PoC → Core → Extended) | ☐ Table present | |
| 4 | Core model: 7 views, instance counts | ☐ Counts match README | |
| 4 | Extended model: WorkOrder, ProductionOrder, etc. | ☐ Extended views listed | |
| 4 | Data verified: February 16, 2026 | ☐ Date stamp | |
| 5 | How Entities Connect (ERD) | ☐ ERD diagram | |
| 5 | Asset → Equipment → Reel → Roll → Package flow | ☐ Relationships shown | |
| 6 | Standards-Based Design (ISA-95/88) | ☐ ISA alignment | |
| 6 | Mapping table: Our Model ↔ ISA ↔ CDM | ☐ Table present | |
| 7 | Production Entities (Asset, Equipment, Recipe) | ☐ Content | |
| 7 | Eastover Mill, Sumpter Facility | ☐ Plant names | |
| 8 | Material Flow (Reel, Roll, Package, QualityResult) | ☐ Content | |

---

## Section 3: Data Pipeline (Slides 9–12)

| Slide | Expected Content | Checklist | Notes |
|-------|-----------------|-----------|-------|
| 9 | Where Data Comes From | ☐ Source systems | |
| 9 | SAP, PPR, Proficy, PI, SharePoint listed | ☐ All 5 sources | |
| 10 | Data Flow to CDF (pipeline diagram) | ☐ Diagram | |
| 10 | Extractors → RAW → Transformations → Model | ☐ Flow correct | |
| 11 | Extractors table (Fabric, PI, SharePoint, SAP, SQL) | ☐ Table present | |
| 11 | RAW database names (raw_ext_*) | ☐ Naming shown | |
| 12 | RAW to Data Model (24 transformations) | ☐ Count correct | |
| 12 | Example SQL transformation | ☐ Example shown | |

---

## Section 4: Use Cases (Slides 13–16)

| Slide | Expected Content | Checklist | Notes |
|-------|-----------------|-----------|-------|
| 13 | Quality Traceability | ☐ Use case 1 | |
| 13 | Real data: 180 records, 53 rejected (29.4%) | ☐ Stats match ACTUAL_DATA_WALKTHROUGH | |
| 13 | Top defects: 006-Curl (22.8%), etc. | ☐ Defect table | |
| 13 | Sheeter No.1 & No.2 = 87.7% of issues | ☐ Equipment insight | |
| 14 | Material Cost & PPV | ☐ Use case 2 | |
| 14 | PPV by material type (FIBR, RAWM, PKNG) | ☐ Table | |
| 14 | GraphQL query example | ☐ Query shown | |
| 15 | Industrial Tools Search | ☐ Search experience | |
| 15 | Location filter, Events/Files/TimeSeries | ☐ Demo points | |
| 16 | GraphQL Queries | ☐ API access | |
| 16 | listReel example with nested rolls | ☐ Query shown | |

---

## Section 5: Implementation (Slides 17–18)

| Slide | Expected Content | Checklist | Notes |
|-------|-----------------|-----------|-------|
| 17 | CI/CD Pipeline | ☐ Deployment | |
| 17 | cdf-tk build, cdf deploy | ☐ Commands | |
| 17 | Feature branch → main flow | ☐ Flow diagram | |
| 18 | Production Data Summary | ☐ Statistics | |
| 18 | Classic: 30,952 assets, 3,864 time series | ☐ Counts | |
| 18 | Core + Extended instance counts | ☐ Tables | |
| 18 | Quality insights (180, 53 rejected, 96 hrs) | ☐ Quality stats | |

---

## Section 6: Roadmap (Slides 19–20)

| Slide | Expected Content | Checklist | Notes |
|-------|-----------------|-----------|-------|
| 19 | What's Next / Sprint Progress | ☐ Roadmap | |
| 19 | Search enhancements, P&ID, Sumpter | ☐ Upcoming items | |
| 20 | Key Takeaways | ☐ Summary | |
| 20 | 5 bullet summary | ☐ All points | |
| 20 | Resources (GitHub, CDF Fusion, docs) | ☐ Links | |
| 20 | Q&A | ☐ Closing | |

---

## Backup Slides (Optional)

| Backup | Content | Checklist | Notes |
|--------|---------|-----------|-------|
| A | Traceability GraphQL query | ☐ | |
| B | RAW to Model mapping table | ☐ | |
| C | Johan ISA-95 quotes | ☐ | |
| D | PPV deep dive | ☐ | |
| E | Quality defect analysis | ☐ | |
| F | Search architecture | ☐ | |
| G | Documentation index | ☐ | |

---

## Summary

- **Total slides to verify:** 20 (+ 7 backup)
- **Key data to cross-check:** Instance counts, quality stats (180, 53, 29.4%), equipment (Sheeter No.1/2)
- **Source for verified data:** [ACTUAL_DATA_WALKTHROUGH.md](ACTUAL_DATA_WALKTHROUGH.md), [README.md](README.md)
