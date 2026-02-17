# Presenter Package: Sylvamo IDL Pilot - Data Modeling

**Presentation:** Sylvamo Manufacturing Data Model (ISA-95/88 Aligned)  
**Duration:** 60 minutes (20 slides @ ~3 min each)  
**Last Updated:** February 2026

---

## Quick Links

| Document | Purpose |
|----------|---------|
| [SPEAKER_NOTES.md](SPEAKER_NOTES.md) | Full speaker notes (~3 min per slide, speaking script) |
| [DEMO_SCRIPT.md](DEMO_SCRIPT.md) | Step-by-step CDF Fusion demo (10–15 min) |
| [SLIDES_OUTLINE.md](SLIDES_OUTLINE.md) | Slide-by-slide content reference |
| [README.md](README.md) | Key data points, instance counts, quality stats |

---

## Pre-Presentation Checklist

### Environment

- [ ] Log into CDF Fusion: https://az-eastus-1.cognitedata.com
- [ ] Verify `sylvamo-dev` project selected
- [ ] Select "Sylvamo MFG Core" location filter
- [ ] Open GraphQL Explorer in a separate tab

### Sample IDs (for demos)

| Type | Example |
|------|---------|
| Asset (Eastover Mill) | `floc:0769` |
| Paper Machine | Search "PM1" |
| Reel | Get recent from search |
| Roll | Get one linked to reel |

### Setup

- [ ] Close unnecessary browser tabs
- [ ] Turn off notifications
- [ ] Have SPEAKER_NOTES.md and DEMO_SCRIPT.md open (or printed)

---

## Slide-to-Demo Mapping

| Slide | Topic | Demo |
|-------|-------|------|
| 13 | Quality Traceability | Demo 2: Quality Traceability |
| 15 | Search Experience | Demo 1: Location Filter & Basic Search |
| 16 | GraphQL Queries | Demo 3: GraphQL Explorer |

---

## Key Data Points (Verified Feb 16, 2026)

**Core model:** 7 views (Asset, Event, Material, MfgTimeSeries, Reel, Roll, RollQuality)  
**Extended:** WorkOrder, ProductionOrder, ProductionEvent, CostEvent (716)  
**Quality:** 180 records, 53 rejected (29.4%), 96 hours time lost  
**Top defect:** 006 - Curl (22.8%); Sheeter No.1 & No.2 = 87.7% of issues  
**Classic:** 30,952 assets, 3,864 time series

---

## Presentation Flow

1. **Slides 1–3:** Introduction (use SPEAKER_NOTES)
2. **Slides 4–8:** Data model (SLIDES_OUTLINE for tables)
3. **Slides 9–12:** Pipeline (DATA_PIPELINE_DEEP_DIVE for details)
4. **Slide 13:** Quality use case → **Run Demo 2**
5. **Slides 14–16:** PPV, Search, GraphQL → **Run Demo 1, Demo 3**
6. **Slides 17–20:** CI/CD, stats, roadmap, Q&A

---

## SharePoint Deck

- **Location:** DX-IndustrialDataLandscape-IDLEastoverPilot site
- **File:** IDL Pilot - Data Modeling (V2) (2026-02-15).pptx
- **Jira:** [SVQS-197](https://cognitedata.atlassian.net/browse/SVQS-197)
