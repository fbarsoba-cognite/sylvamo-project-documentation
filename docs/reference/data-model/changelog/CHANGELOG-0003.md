# Change Log - Page 0003

Data model changes for Sylvamo MFG Core. ~10 entries per page.

---

### Adjust PPR transformations and add Roll/Reel schedules
**Date:** 2026-02-12
**ADO PR:** [PR #866](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/866)

**Changes:**
- Removed `populate_ProficyDatapoints` and `populate_ProficyEventIdDatapoints` transformations (SQL + YAML)
- Added `populate_Reel.Schedule.yaml` and `populate_Roll.Schedule.yaml` (hourly cron)
- Minor fixes to `populate_Reel` and `populate_Roll` transformation SQL

**Why:**
- Proficy datapoint transformations replaced by CDF Functions approach
- Roll and Reel transformations needed automated schedules

---

### [SVQS-223] Add CDF search categories for Industrial Tools
**Date:** 2026-02-12
**Jira:** [SVQS-223](https://cognitedata.atlassian.net/browse/SVQS-223)
**ADO PR:** [PR #867](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/867), [PR #868](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/868)

**Changes:**
- Added 9 SearchConfig.yaml files for mfg_core views: Roll, RollQuality, CostEvent, Equipment, Notification, Operation, ProductionEvent, ProductionOrder, WorkOrder
- Added 5 SearchConfig.yaml files for mfg_extended views
- Fixed MFG Core location filter data model reference (PR #868)

**Why:**
- Enable search and filtering in CDF Fusion Industrial Tools for all data model entities

---

### Proficy/SharePoint functions and code quality enforcement
**Date:** 2026-02-13
**ADO PR:** [PR #869](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/869)

**Changes:**
- Added SharePoint function implementation with schedule
- Added Proficy datapoints function with numeric/string schedules
- Added common injection to CDF Functions
- Added pre-commit checks for code quality (ruff, YAML lint, trailing whitespace)
- Various transformation YAML cleanups (removed unused fields)

**Why:**
- Migrate Proficy datapoint ingestion from transformations to CDF Functions
- Add SharePoint file ingestion as CDF Function
- Enforce code quality standards across the repository

---

### [SVQS-224] Grant Canvas write access to read-only group
**Date:** 2026-02-13
**Jira:** [SVQS-224](https://cognitedata.atlassian.net/browse/SVQS-224)
**ADO PR:** [PR #876](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/876)

**Changes:**
- Updated `cdf-sylvamo-all-read.Group.yaml` with Canvas write permissions (comments, industrial canvas instances)
- Added `CommentInstanceSpace.Space.yaml` and `IndustrialCanvasInstanceSpace.Space.yaml`

**Why:**
- Read-only users need write access to Canvas for annotations and collaboration
- Canvas spaces must be provisioned before group ACLs can reference them

---

### Fix Proficy schedule and deploy pipeline
**Date:** 2026-02-13
**ADO PR:** [PR #878](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/878)

**Changes:**
- Fixed `writeProficy.Schedule.yaml` cron expression and configuration
- Updated deploy and dry-run pipeline YAML with correct working directory

**Why:**
- Proficy CDF Function was not running on schedule due to misconfigured cron
- Pipeline needed working directory correction for toolkit commands

---

### [SVQS-222] Fix scientific notation in work order number fields
**Date:** 2026-02-14
**Jira:** [SVQS-222](https://cognitedata.atlassian.net/browse/SVQS-222)
**ADO PR:** [PR #880](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/880)

**Changes:**
- Updated `populate_Event_WorkOrders.Transformation.sql`: cast work order numbers to prevent scientific notation
- Updated `populate_Operation.Transformation.sql`: cast numeric fields to string
- Updated `populate_WorkOrder.Transformation.sql`: cast order number fields

**Why:**
- Large numeric work order numbers were being rendered in scientific notation (e.g., 1.2E+7 instead of 12000000)
- CDF Fusion displayed unreadable values; explicit CAST to STRING fixes the display
