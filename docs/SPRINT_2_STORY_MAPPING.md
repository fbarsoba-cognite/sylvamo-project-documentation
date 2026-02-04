# Sprint 2 User Story Mapping

**Updated:** February 4, 2026  
**Purpose:** Map Sprint 2 plan phases to Jira user stories

---

## Story Mapping Overview

| Plan Phase | Work Item | Jira Story | Status |
|------------|-----------|------------|--------|
| **Phase 1: Event Contextualization** | | | |
| 1.1 | Proficy Events → Asset | [SVQS-148](https://cognitedata.atlassian.net/browse/SVQS-148) | Created |
| 1.2 | Production Orders → Asset | BLOCKED - No plant field in source | N/A |
| 1.3 | WorkOrder Extended → Asset | [SVQS-146](https://cognitedata.atlassian.net/browse/SVQS-146) (SVQS-149 closed as duplicate) | Existing |
| 1.4 | ProductionEvent → Asset | [SVQS-150](https://cognitedata.atlassian.net/browse/SVQS-150) | Created |
| 1.5 | Verify Event Type Field | [SVQS-145](https://cognitedata.atlassian.net/browse/SVQS-145) | Existing |
| **Phase 2: Time Series Contextualization** | | | |
| 2.1 | TimeSeries → Asset | [SVQS-143](https://cognitedata.atlassian.net/browse/SVQS-143) | Existing |
| **Phase 3: File Contextualization** | | | |
| 3.1 | Add files reverse relation | [SVQS-151](https://cognitedata.atlassian.net/browse/SVQS-151) | Created |
| 3.2 | Files → Asset link | [SVQS-152](https://cognitedata.atlassian.net/browse/SVQS-152) | Created |
| 3.3 | P&ID Entity Matching | [SVQS-144](https://cognitedata.atlassian.net/browse/SVQS-144) | Existing |
| **Phase 4: Validation** | | | |
| 4.1-4.2 | End-to-End Demo | [SVQS-159](https://cognitedata.atlassian.net/browse/SVQS-159) | Created |
| **Phase 5: UC2 Data Quality** | | | |
| 5.1 | Reel/Roll Scheduling | [SVQS-153](https://cognitedata.atlassian.net/browse/SVQS-153) | Created |
| 5.2 | turnupTime Property | [SVQS-154](https://cognitedata.atlassian.net/browse/SVQS-154) | Created |
| 5.3 | Property Naming | Discussion with Anvar | No story needed |
| 5.4 | Sumter Quality Data | Part of [SVQS-147](https://cognitedata.atlassian.net/browse/SVQS-147) investigation | Existing |
| **Phase 6: Data Completeness** | | | |
| 6.1 | PPR Roll Limit | [SVQS-155](https://cognitedata.atlassian.net/browse/SVQS-155) | Created |
| 6.2 | Missing PPR Tables | [SVQS-156](https://cognitedata.atlassian.net/browse/SVQS-156) | Created |
| 6.3 | PPV Wrong Source | BLOCKED - SAP freeze until Thursday | N/A |
| 6.4 | Sumter Assets | [SVQS-157](https://cognitedata.atlassian.net/browse/SVQS-157) | Created |
| 6.5 | Asset Search Field | [SVQS-158](https://cognitedata.atlassian.net/browse/SVQS-158) | Created |

---

## Existing Stories (SVQS-142 to SVQS-147)

### SVQS-142: Deliver Data Model V1 to support Use Case 2 development
**Mapping:** Epic/parent story covering UC2 data model work
**Dependencies:** Phase 1-3 contextualization must complete for full model

### SVQS-143: Contextualize PI scanner tags for Use Case 2
**Mapping:** Phase 2.1 - TimeSeries → Asset
**Implementation:** Update `populate_TimeSeries.Transformation.sql` with PI tag prefix parsing

### SVQS-144: Contextualize 2-3 P&ID documents (major equipment only)
**Mapping:** Phase 3.3 - P&ID Entity Matching
**Implementation:** Run `annotate_files.py` with tokenization fix

### SVQS-145: Add type field to Events for filtering in Search
**Mapping:** Phase 1.5 - Verify Event Type Field
**Implementation:** Verify `eventType` values in all event transformations

### SVQS-146: Contextualize work orders to major equipment assets
**Mapping:** Phase 1.3 - WorkOrder Extended → Asset
**Implementation:** Enable FUNCTIONAL_LOCATION in `populate_WorkOrder.Transformation.sql`

### SVQS-147: Demonstrate Use Case 2 progress via Streamlit diagnostic app
**Mapping:** UC2 Demo (Anvar's Streamlit app)
**Dependencies:** Needs Phase 5 data quality issues resolved

---

## New Stories Created (11 active, 1 duplicate closed)

### Phase 1: Event Contextualization (2 active stories)
1. [SVQS-148](https://cognitedata.atlassian.net/browse/SVQS-148) - Contextualize Proficy Events to Paper Machine Assets
2. ~~[SVQS-149](https://cognitedata.atlassian.net/browse/SVQS-149) - Enable WorkOrder Extended Asset Relation~~ **CLOSED as duplicate of SVQS-146**
3. [SVQS-150](https://cognitedata.atlassian.net/browse/SVQS-150) - Enable ProductionEvent Asset Relation (mfg_extended)

### Phase 3: File Contextualization (2 stories)
4. [SVQS-151](https://cognitedata.atlassian.net/browse/SVQS-151) - Add Files Reverse Relation to Asset View
5. [SVQS-152](https://cognitedata.atlassian.net/browse/SVQS-152) - Link Files to Assets via Metadata Parsing

### Phase 4: Validation (1 story)
6. [SVQS-159](https://cognitedata.atlassian.net/browse/SVQS-159) - Validate Search Experience: End-to-End Demo

### Phase 5: UC2 Data Quality (2 stories)
7. [SVQS-153](https://cognitedata.atlassian.net/browse/SVQS-153) - UC2: Add Schedule Configuration for Reel/Roll Transformations
8. [SVQS-154](https://cognitedata.atlassian.net/browse/SVQS-154) - UC2: Investigate and Add turnupTime Property to Reel

### Phase 6: Data Completeness (4 stories)
9. [SVQS-155](https://cognitedata.atlassian.net/browse/SVQS-155) - Data Completeness: Fix PPR Roll Extractor Limit
10. [SVQS-156](https://cognitedata.atlassian.net/browse/SVQS-156) - Data Completeness: Add Missing PPR Tables to Extractor
11. [SVQS-157](https://cognitedata.atlassian.net/browse/SVQS-157) - Data Completeness: Add Sumter Assets to Hierarchy
12. [SVQS-158](https://cognitedata.atlassian.net/browse/SVQS-158) - Data Completeness: Add Asset Search Field for P&ID Matching

---

## Blocked Items

| Item | Reason | Resolution |
|------|--------|------------|
| Production Orders → Asset | No plant/work_center field in `raw_ext_sap.production_orders` | Check if SAP OData can expose these fields |
| PPV Data Source | SAP freeze until Thursday | Wait for freeze to end, then update source |

---

## Demo Readiness Checklist

For Sprint 2 demo (Feb 13, 2026), must have:

- [ ] Work orders linked to assets (SVQS-146)
- [ ] Proficy events linked to assets (new story)
- [ ] Time series linked to assets (SVQS-143)
- [ ] 2-3 P&IDs contextualized (SVQS-144)
- [ ] Event type filtering working (SVQS-145)
- [ ] UC2 Streamlit progress (SVQS-147)
- [ ] Search experience validated (new story)

---

## Related Documents

- [Sprint 2 Plan (GitHub)](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/SPRINT_2_PLAN.md)
- [Sprint 2 Tasks Breakdown JSON](./sprint_2_tasks_breakdown.json)
- [Original User Stories](./sprint_2_user_stories.md)
