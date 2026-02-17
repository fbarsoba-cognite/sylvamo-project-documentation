# Change Log - Page 0002

Data model changes for Sylvamo MFG Core. ~10 entries per page.

---

### [SVQS-239] Add mfg_core transformation schedules and update extraction pipeline
**Date:** 2026-02-17 15:43 UTC
**Jira:** [SVQS-239](https://cognitedata.atlassian.net/browse/SVQS-239)
**ADO PR:** [PR #899](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/899)

**Changes:**
- Rewrote populate_Operation.Transformation.sql to use Gold table sapecc_wo_operations instead of 3-way JOIN on AUFK+AFKO+AFVC (AFVC removed per SVQS-245)
- Added 18 Schedule.yaml files for mfg_core and mfg_extended transformations
- Updated fabric_sapecc_daily extraction pipeline: corrected "324 tables" to "16 tables"
- Deleted 300 stale RAW tables from raw_ext_fabric_sapecc via SDK

**Why:**
- AFVC table removed from extractor list (SVQS-245), breaking old populate_Operation
- Only Roll and Reel had schedules; other transformations never ran automatically
- Orphaned RAW tables needed cleanup

---

### [SVQS-245] Revamp Fabric SAP extractors to match IDL Pilot table list
**Date:** 2026-02-17 14:07 UTC
**Jira:** [SVQS-245](https://cognitedata.atlassian.net/browse/SVQS-245)
**ADO PR:** _(in same PR as SVQS-239)_

**Changes:**
- Replaced auto-discovery of ~320 SAP ECC Silver tables with 17 specific tables from IDL Pilot
- LH_SILVER_sapecc (12 tables): AFKO, AFPO, AFRU, AUFK, MAKT, MARA, MARC, MARD, MAST, RESB, STKO, STPO
- lh_gold_pm (4 tables): iw28, iw38, sap_hierarchy, wo_operations
- lh_gold_enterprise (1 table): purchase_order_gr_na
- Removed AFVC (superseded by wo_operations from Gold layer)

**Why:**
- Align with Cam SAP Tables in Fabric (02-15-26) specification
- Reduce extraction scope from 320+ to 17 tables

---

### [SVQS-242] Migrate Equipment entity into Asset hierarchy (ISA-95)
**Date:** 2026-02-16 22:26 UTC
**Jira:** [SVQS-242](https://cognitedata.atlassian.net/browse/SVQS-242)
**ADO PR:** [PR #892](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/892)
**ADR:** [ADR-001-ASSET-EQUIPMENT.md](../decisions/ADR-001-ASSET-EQUIPMENT.md)

**Changes:**
- Added equipmentType, equipmentNumber properties to MfgAsset container
- Renamed transformation: populate_Equipment to populate_Asset_Equipment (targets Asset with assetType=Equipment)
- Updated populate_RollQuality to use asset relation instead of equipmentRef
- Removed Equipment.View.yaml and MfgEquipment.Container.yaml from mfg_core
- Data model now 7 entities (Equipment merged into Asset hierarchy)

**Why:**
- ISA-95: equipment as specialized Asset nodes, not separate entity
- Cognite QuickStart pattern alignment
- Simpler navigation via single parent/children traversal

---

### [SVQS-241] Update RollQuality transformation column names
**Date:** 2026-02-16 21:59 UTC
**Jira:** [SVQS-241](https://cognitedata.atlassian.net/browse/SVQS-241)
**ADO PR:** [PR #891](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/891)

**Changes:**
- Updated populate_RollQuality.Transformation.sql to match current SharePoint RAW schema (CamelCase)
- Column mappings: date to Date, equipment to Equipment, location to Location

**Why:**
- SharePoint form schema changed; transformation was failing on old column names

---

### fix(mfg_core): Bump RollQuality view from v1 to v2
**Date:** 2026-02-16 19:46 UTC
**ADO PR:** [PR #890](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/890)

**Changes:**
- Bumped RollQuality view from v1 to v2
- CDF does not allow changing property source on published view; Equipment PR added equipmentRef, requiring version bump

**Why:**
- Enable equipmentRef property on RollQuality while v1 continues to serve existing consumers

---

### [SVQS-240] Add Equipment container for RollQuality linkage
**Date:** 2026-02-16 16:48 UTC
**Jira:** [SVQS-240](https://cognitedata.atlassian.net/browse/SVQS-240)
**ADO PR:** [PR #889](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/889)

**Changes:**
- Added MfgEquipment.Container.yaml and Equipment.View.yaml
- Added populate_Equipment transformation (4 equipment instances: Sheeter No.1/2/3, Roll Prep)
- Enabled GraphQL traversal from quality reports to equipment

**Why:**
- Enable pattern discovery from quality reports to equipment (superseded by SVQS-242 Equipment to Asset migration)

---

### Adding property and modifying material transformation
**Date:** 2026-02-16 21:23 UTC
**ADO PR:** [PR #887](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/887)

**Changes:**
- Added created_on property to Material container from SAP
- Updated populate_Material transformation for live data handling
- Added is_new for future live ingestion

**Why:**
- Support material creation timestamp and live ingestion patterns

---

### [SVQS-229] Add CDF Extraction Pipelines for all VM extractors
**Date:** 2026-02-17 (merged)
**Jira:** [SVQS-229](https://cognitedata.atlassian.net/browse/SVQS-229)
**ADO PR:** [PR #883](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/883)

**Changes:**
- Created cdf_extractor_pipelines module with pipeline definitions for 10 extractors on PAMIDL02 VM
- 3 PI extractors (continuous, native heartbeat)
- 5 Fabric extractors (PPR hourly/daily, PPV daily, SAP ECC daily, hist_reel)
- 1 DB extractor (SAP OData + Proficy)
- 1 File extractor (SharePoint)
- Enables heartbeat monitoring and email notifications through CDF

**Why:**
- Centralize extractor pipeline config in CDF for dev/staging/prod
- Enable VM-side monitoring via CDF Fusion

---

**See also:** [CHANGELOG-0001](CHANGELOG-0001.md) — Doc review, SVQS-243, SVQS-244

