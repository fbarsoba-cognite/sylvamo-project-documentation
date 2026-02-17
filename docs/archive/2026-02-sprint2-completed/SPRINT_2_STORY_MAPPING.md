> **ARCHIVED - Sprint 2 Completed (Feb 2-13, 2026).** This is a historical record. See [Sprint Planning README](../../internal/sprint-planning/README.md) for current sprint.

# Sprint 2 User Story Mapping

**Updated:** February 2026 (Jira-verified)  
**Original:** February 4, 2026  
**Final Status:** 🟢 14 Done | 🟡 1 In Progress | ⬜ 3 To Do | ⚫ 2 Closed (duplicates)

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

#### 4. P&ID Navigation
**User Experience:** When viewing a P&ID, the user can click on equipment labels to navigate directly to the asset.

| What's Needed | Story | Status | Implementation |
|---------------|-------|--------|----------------|
| Asset "search field" for matching | [SVQS-158](https://cognitedata.atlassian.net/browse/SVQS-158) | 🟢 Done | Added to asset hierarchy |
| P&ID entity extraction | [SVQS-144](https://cognitedata.atlassian.net/browse/SVQS-144) | 🟡 In Progress | 2-3 P&IDs, major equipment |

---

## Story Status (Jira-verified Feb 2026)

| Story | Description | Status | Notes |
|-------|-------------|--------|-------|
| ~~[SVQS-142](https://cognitedata.atlassian.net/browse/SVQS-142)~~ | Deliver Data Model V1 for UC2 | 🟢 Done | Foundation |
| ~~[SVQS-143](https://cognitedata.atlassian.net/browse/SVQS-143)~~ | PI Time Series → Assets | 🟢 Done | 3,492 linked (PM1/PM2) |
| [SVQS-144](https://cognitedata.atlassian.net/browse/SVQS-144) | P&ID Contextualization | 🟡 In Progress | 2-3 P&IDs, major equipment |
| ~~[SVQS-145](https://cognitedata.atlassian.net/browse/SVQS-145)~~ | Event Type Field | 🟢 Done | Filtering works |
| ~~[SVQS-146](https://cognitedata.atlassian.net/browse/SVQS-146)~~ | Work Orders → Assets | 🟢 Done | Via FUNCTIONAL_LOCATION |
| ~~[SVQS-147](https://cognitedata.atlassian.net/browse/SVQS-147)~~ | UC2 Streamlit Demo | 🟢 Done | Anvar |
| ~~[SVQS-148](https://cognitedata.atlassian.net/browse/SVQS-148)~~ | Proficy Events → Assets | 🟢 Done | PU_Id mapping |
| ~~[SVQS-149](https://cognitedata.atlassian.net/browse/SVQS-149)~~ | WorkOrder Extended | ⚫ Closed | Duplicate of SVQS-146 |
| ~~[SVQS-150](https://cognitedata.atlassian.net/browse/SVQS-150)~~ | ProductionEvent | ⚫ Closed | Duplicate of SVQS-148 |
| ~~[SVQS-151](https://cognitedata.atlassian.net/browse/SVQS-151)~~ | Files Reverse Relation | 🟢 Done | Asset.files enabled |
| ~~[SVQS-152](https://cognitedata.atlassian.net/browse/SVQS-152)~~ | Files → Assets | 🟢 Done | 45 files linked |
| [SVQS-153](https://cognitedata.atlassian.net/browse/SVQS-153) | Reel/Roll Scheduling | ⬜ To Do | Schedule configuration |
| ~~[SVQS-154](https://cognitedata.atlassian.net/browse/SVQS-154)~~ | turnupTime Property | 🟢 Done | Added to Reel |
| ~~[SVQS-155](https://cognitedata.atlassian.net/browse/SVQS-155)~~ | PPR Roll Limit | 🟢 Done | Extractor fix |
| [SVQS-156](https://cognitedata.atlassian.net/browse/SVQS-156) | Missing PPR Tables | ⬜ To Do | Add to extractor |
| ~~[SVQS-157](https://cognitedata.atlassian.net/browse/SVQS-157)~~ | Sumter Assets | 🟢 Done | Hierarchy (0519) |
| ~~[SVQS-158](https://cognitedata.atlassian.net/browse/SVQS-158)~~ | Asset Search Field | 🟢 Done | P&ID matching |
| [SVQS-159](https://cognitedata.atlassian.net/browse/SVQS-159) | Validation Demo | ⬜ To Do | End-to-end demo |

---

## Demo Readiness (Jira-verified)

- [x] Work orders → assets (SVQS-146)
- [x] Proficy events → assets (SVQS-148)
- [x] Time series → assets (SVQS-143)
- [x] Event type filtering (SVQS-145)
- [x] Files → assets (SVQS-151/152)
- [x] UC2 Streamlit (SVQS-147)
- [x] Sumter assets (SVQS-157)
- [x] Asset search field (SVQS-158)
- [x] turnupTime property (SVQS-154)
- [ ] P&ID contextualization (SVQS-144) — In Progress
- [ ] Reel/Roll scheduling (SVQS-153) — To Do
- [ ] Search validation (SVQS-159) — To Do

**Progress: 9/12 complete** (3 remaining)

---

## Blockers (Resolved)

| Item | Status | Resolution |
|------|--------|------------|
| [SVQS-157](https://cognitedata.atlassian.net/browse/SVQS-157) (Sumter) | ✅ Resolved | Sumter assets in hierarchy |
| [SVQS-158](https://cognitedata.atlassian.net/browse/SVQS-158) (Search field) | ✅ Resolved | Asset search field added |

---

## Related Documents

- [Sprint 2 Plan](./SPRINT_2_PLAN.md)
- [Completed Stories](./COMPLETED_STORIES.md) — Jira-verified list
- [Sprint 3 Plan](../../internal/sprint-planning/SPRINT_3_PLAN.md) — Remaining stories
- [Changelog](../../reference/data-model/changelog/CHANGELOG-0001.md)
- [Changelog 0002](../../reference/data-model/changelog/CHANGELOG-0002.md)
- [Changelog 0003](../../reference/data-model/changelog/CHANGELOG-0003.md)

---

> **Note:** Status verified from Jira SVQS project via REST API, February 2026.
