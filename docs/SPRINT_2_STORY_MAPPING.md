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

### How Stories Enable This

| Capability | Stories | What It Enables |
|------------|---------|-----------------|
| **Events on Assets** | SVQS-146, SVQS-148 | See work orders and production events when viewing PM1/PM2 |
| **Event Filtering** | SVQS-145 | Filter events by type (maintenance vs. production) |
| **Time Series on Assets** | SVQS-143 | See PI scanner data and Proficy readings on PM1/PM2 |
| **Files on Assets** | SVQS-151, SVQS-152 | See P&IDs and documents when viewing Eastover Mill |
| **P&ID Navigation** | SVQS-144 | Click equipment in P&ID → jump to asset (blocked) |

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
