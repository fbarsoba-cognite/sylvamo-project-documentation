# Sprint 2 Completed Stories (Jira-verified)

**Source:** Jira SVQS project  
**Verified:** February 2026  
**Sprint:** Feb 2–13, 2026

---

## Overview

| Metric | Count |
|--------|-------|
| **Completed (Done)** | 14 |
| **In Progress** | 1 |
| **To Do** | 3 |

---

## Completed Stories (14)

### Search Experience

| Jira | Summary | Implementation |
|------|---------|----------------|
| [SVQS-142](https://cognitedata.atlassian.net/browse/SVQS-142) | Deliver Data Model V1 to support Use Case 2 development | Foundation |
| [SVQS-143](https://cognitedata.atlassian.net/browse/SVQS-143) | Contextualize PI time series (scanner, lab, Proficy) for Use Case 2 | 3,492 time series linked to PM1/PM2 |
| [SVQS-145](https://cognitedata.atlassian.net/browse/SVQS-145) | Add type field to Events for filtering in Search | `eventType` populated |
| [SVQS-146](https://cognitedata.atlassian.net/browse/SVQS-146) | Contextualize work orders to major equipment assets | Via FUNCTIONAL_LOCATION |
| [SVQS-148](https://cognitedata.atlassian.net/browse/SVQS-148) | Contextualize Proficy Events to Paper Machine Assets | PU_Id mapping (4→PM1, 5→PM2) |
| [SVQS-151](https://cognitedata.atlassian.net/browse/SVQS-151) | Add Files Reverse Relation to Asset View | Asset.files enabled |
| [SVQS-152](https://cognitedata.atlassian.net/browse/SVQS-152) | Link Files to Assets via Metadata Parsing | 45 files linked to Eastover Mill |

### UC2 Data Quality

| Jira | Summary | Implementation |
|------|---------|----------------|
| [SVQS-147](https://cognitedata.atlassian.net/browse/SVQS-147) | Demonstrate Use Case 2 progress via Streamlit diagnostic app | Anvar |
| [SVQS-154](https://cognitedata.atlassian.net/browse/SVQS-154) | UC2: Investigate and Add turnupTime Property to Reel | PPR data |

### Data Completeness

| Jira | Summary | Implementation |
|------|---------|----------------|
| [SVQS-155](https://cognitedata.atlassian.net/browse/SVQS-155) | Data Completeness: Fix PPR Roll Extractor Limit | Extractor config |
| [SVQS-157](https://cognitedata.atlassian.net/browse/SVQS-157) | Data Completeness: Add Sumter Assets to Hierarchy | Sumter FLOCs (0519) |
| [SVQS-158](https://cognitedata.atlassian.net/browse/SVQS-158) | Data Completeness: Add Asset Search Field for P&ID Matching | Valmir query → asset hierarchy |

### Duplicates (Closed)

| Jira | Summary |
|------|---------|
| [SVQS-149](https://cognitedata.atlassian.net/browse/SVQS-149) | [Duplicate of SVQS-146] Enable WorkOrder Asset Relation |
| [SVQS-150](https://cognitedata.atlassian.net/browse/SVQS-150) | [Duplicate of SVQS-148] ProductionEvent Asset Relation |

---

## Not Completed (4)

| Jira | Summary | Jira Status |
|------|---------|-------------|
| [SVQS-144](https://cognitedata.atlassian.net/browse/SVQS-144) | Contextualize 2-3 P&ID documents (major equipment only) | In Progress |
| [SVQS-153](https://cognitedata.atlassian.net/browse/SVQS-153) | UC2: Add Schedule Configuration for Reel/Roll Transformation | To Do |
| [SVQS-156](https://cognitedata.atlassian.net/browse/SVQS-156) | Data Completeness: Add Missing PPR Tables to Extractor | To Do |
| [SVQS-159](https://cognitedata.atlassian.net/browse/SVQS-159) | Validate Search Experience: End-to-End Demo | To Do |

---

*Last verified: February 2026 via Jira REST API*
