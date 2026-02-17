> **ARCHIVED - Sprint 2 Completed (Feb 2-13, 2026).** This is a historical record. See [Sprint Planning README](../../internal/sprint-planning/README.md) for current sprint.

# Sprint 2 User Story Mapping

**Updated:** February 4, 2026  
**Status:** 🟢 6 Done | 🟡 7 Pending | 🔴 2 Blocked | ⚫ 2 Closed

---

## Sprint 2 Demo Goal

The Sprint 2 demo showcases the **CDF Search Experience** - enabling users to navigate from an Asset to all its related data in one place.

### Target Experience

```
User searches for "Paper Machine 1" in CDF Search
    └── Asset: PM1 (#1 Paper Machine)
        ├── Events: Work orders, production events (filter by type)
        ├── Time Series: PI scanner data, Proficy readings
        ├── Files: P&IDs, engineering drawings
        └── Child Assets: Winders, equipment hierarchy
```

### Experience Breakdown

#### 1. Events on Assets
**User Experience:** When viewing PM1 or PM2, the user sees a list of related events (work orders, production orders) in the Events panel.

| What's Needed | Story | Status | Implementation |
|---------------|-------|--------|----------------|
| Work orders linked to assets | [SVQS-146](https://cognitedata.atlassian.net/browse/SVQS-146) | 🟢 Done | Parse `FUNCTIONAL_LOCATION` field (e.g., `0769-06-01-010` → PM1) |
| Production events linked to assets | [SVQS-148](https://cognitedata.atlassian.net/browse/SVQS-148) | 🟢 Done | Map Proficy `PU_Id` (4 → PM1, 5 → PM2) |
| Filter events by type | [SVQS-145](https://cognitedata.atlassian.net/browse/SVQS-145) | 🟢 Done | Populate `eventType` property in all event transformations |

#### 2. Time Series on Assets
**User Experience:** When viewing PM1 or PM2, the user sees linked time series (PI scanner data, Proficy readings) with sparkline previews.

| What's Needed | Story | Status | Implementation |
|---------------|-------|--------|----------------|
| PI tags linked to assets | [SVQS-143](https://cognitedata.atlassian.net/browse/SVQS-143) | 🟢 Done | Parse PI tag prefix (`471*` → PM1, `472*` → PM2) |
| Proficy/lab data linked | [SVQS-143](https://cognitedata.atlassian.net/browse/SVQS-143) | 🟢 Done | Parse name pattern ("Paper Machine 1/2" in name) |

**Result:** 3,492 time series now linked to PM1/PM2.

#### 3. Files on Assets
**User Experience:** When viewing Eastover Mill or child assets, the user sees P&IDs and engineering drawings in the Files panel.

| What's Needed | Story | Status | Implementation |
|---------------|-------|--------|----------------|
| Asset view shows files | [SVQS-151](https://cognitedata.atlassian.net/browse/SVQS-151) | 🟢 Done | Add `files` reverse relation to Asset view |
| Files linked to assets | [SVQS-152](https://cognitedata.atlassian.net/browse/SVQS-152) | 🟢 Done | Parse directory path (`/Eastover/` → Eastover Mill) |

**Result:** 45 files now linked to Eastover Mill.

#### 4. P&ID Navigation (Blocked)
**User Experience:** When viewing a P&ID, the user can click on equipment labels to navigate directly to the asset.

| What's Needed | Story | Status | Implementation |
|---------------|-------|--------|----------------|
| Asset "search field" for matching | [SVQS-158](https://cognitedata.atlassian.net/browse/SVQS-158) | 🟡 Pending | Valmir's query → Rashad materializes → add to asset hierarchy |
| P&ID entity extraction | [SVQS-144](https://cognitedata.atlassian.net/browse/SVQS-144) | 🔴 Blocked | Run `annotate_files.py` on P&IDs (needs SVQS-158 first) |

**Blocker:** P&ID codes don't match current asset external IDs. Need new "search field" column from Valmir's SAP query.

---

## Story Status

| Story | Description | Status | Notes |
|-------|-------------|--------|-------|
| ~~[SVQS-143](https://cognitedata.atlassian.net/browse/SVQS-143)~~ | PI Time Series → Assets | 🟢 Done | 3,492 linked (PM1/PM2) |
| ~~[SVQS-145](https://cognitedata.atlassian.net/browse/SVQS-145)~~ | Event Type Field | 🟢 Done | Filtering works |
| ~~[SVQS-146](https://cognitedata.atlassian.net/browse/SVQS-146)~~ | Work Orders → Assets | 🟢 Done | Via FUNCTIONAL_LOCATION |
| ~~[SVQS-148](https://cognitedata.atlassian.net/browse/SVQS-148)~~ | Proficy Events → Assets | 🟢 Done | PU_Id mapping |
| ~~[SVQS-151](https://cognitedata.atlassian.net/browse/SVQS-151)~~ | Files Reverse Relation | 🟢 Done | Asset.files enabled |
| ~~[SVQS-152](https://cognitedata.atlassian.net/browse/SVQS-152)~~ | Files → Assets | 🟢 Done | 45 files linked |
| [SVQS-144](https://cognitedata.atlassian.net/browse/SVQS-144) | P&ID Contextualization | 🔴 Blocked | Needs SVQS-158 first |
| [SVQS-147](https://cognitedata.atlassian.net/browse/SVQS-147) | UC2 Streamlit Demo | 🟡 Pending | Anvar owns |
| [SVQS-153](https://cognitedata.atlassian.net/browse/SVQS-153) | Reel/Roll Scheduling | 🟡 Pending | Use CDF Transformation Schedules |
| [SVQS-154](https://cognitedata.atlassian.net/browse/SVQS-154) | turnupTime Property | 🟡 Pending | Investigate PPR data |
| [SVQS-155](https://cognitedata.atlassian.net/browse/SVQS-155) | PPR Roll Limit | 🟡 Pending | Rashad/Max - need 2M rows |
| [SVQS-156](https://cognitedata.atlassian.net/browse/SVQS-156) | Missing PPR Tables | 🟡 Pending | Rashad/Max |
| [SVQS-157](https://cognitedata.atlassian.net/browse/SVQS-157) | Sumter Assets | 🔴 Blocked | No RAW data yet |
| [SVQS-158](https://cognitedata.atlassian.net/browse/SVQS-158) | Asset Search Field | 🟡 Pending | Valmir query → Rashad |
| [SVQS-159](https://cognitedata.atlassian.net/browse/SVQS-159) | Validation Demo | 🟡 Pending | Can start now |
| ~~[SVQS-149](https://cognitedata.atlassian.net/browse/SVQS-149)~~ | ~~WorkOrder Extended~~ | ⚫ Closed | Duplicate of SVQS-146 |
| ~~[SVQS-150](https://cognitedata.atlassian.net/browse/SVQS-150)~~ | ~~ProductionEvent~~ | ⚫ Closed | Duplicate of SVQS-148 |

---

## Demo Readiness (Feb 13, 2026)

- [x] Work orders → assets (SVQS-146)
- [x] Proficy events → assets (SVQS-148)
- [x] Time series → assets (SVQS-143)
- [x] Event type filtering (SVQS-145)
- [x] Files → assets (SVQS-151/152)
- [ ] P&ID contextualization (SVQS-144) - **Blocked**
- [ ] UC2 Streamlit (SVQS-147)
- [ ] Search validation (SVQS-159)

**Progress: 6/8 complete**

---

## Blockers

| Item | Reason | Owner | Resolution |
|------|--------|-------|------------|
| [SVQS-144](https://cognitedata.atlassian.net/browse/SVQS-144) (P&ID) | Missing "search field" for matching | Valmir | Complete [SVQS-158](https://cognitedata.atlassian.net/browse/SVQS-158) first |
| [SVQS-157](https://cognitedata.atlassian.net/browse/SVQS-157) (Sumter) | No data in RAW (only Eastover 0769) | Rashad/Max | Run SAP query with plant 0519 |
| PPV Data | SAP freeze | Cam | Wait until Thursday |

---

## Related Documents

- [Sprint 2 Plan](./SPRINT_2_PLAN.md)
- [Data Completeness Meeting (Feb 4)](./meetings/2026-02-04_data_completeness_summary.md)
