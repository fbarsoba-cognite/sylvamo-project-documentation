# Change Log - Page 0001

Data model changes for Sylvamo MFG Core. ~10 entries per page.

---

### 2026-02-17 — Documentation tree review and reorganization

**Changes:**
- Archive: Moved `MFG_CORE_WITH_EQUIPMENT.md` to `docs/archive/2026-02-deprecated/` (superseded by ADR-001)
- Archive: Moved Sprint 2 plan artifacts to `docs/archive/2026-02-sprint2-completed/`
- Extractors: Updated EXTRACTORS.md with current extraction pipeline list
- Data Pipeline: Updated DATA_PIPELINE_AND_SOURCES.md with mfg_core/mfg_extended split and current instance counts
- Sprint: Updated README and docs to Sprint 3 (Feb 16 – Mar 2, 2026)
- MFG Extended: Added ADR-001 note re Equipment deprecation


### [SVQS-243] Add ISA-95 assetType classification to Asset hierarchy
**Date:** 2026-02-17 04:08 UTC
**Jira:** [SVQS-243](https://cognitedata.atlassian.net/browse/SVQS-243)
**ADO PR:** [feature/SVQS-243-asset-type-classification](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/893)
**ADR:** [ADR-001-ASSET-EQUIPMENT.md](../decisions/ADR-001-ASSET-EQUIPMENT.md)

**Changes:**
- Updated `populate_Asset.Transformation.sql` with ISA-95 aligned assetType classification
- Level 2: Area, Level 3: System, Level 4: SubSystem, Level 5: Unit, Level 6: EquipmentModule, Level 7+: Equipment
- Added `equipmentType` derivation for leaf-level equipment (Motor, Pump, Valve, etc.)
- 33,072 assets now classified as `assetType='Equipment'`

**Why:**
- Align with ISA-95 Equipment hierarchy standard
- Enable filtering by asset type in CDF Fusion
- Follow Cognite QuickStart Pattern (Equipment as Asset subtypes)

---

### [SVQS-244] Cleanup legacy Equipment instances and fix RollQuality asset links
**Date:** 2026-02-17 08:15 UTC
**Jira:** [SVQS-244](https://cognitedata.atlassian.net/browse/SVQS-244)
**ADO PR:** [PR #896](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/896)

**Changes:**
- Updated `populate_RollQuality.Transformation.sql` to link to SAP FLOC Asset nodes:
  - Sheeter No.1 -> `floc:0519-07-05-020-010`
  - Sheeter No.2 -> `floc:0519-07-05-020-020`
  - Sheeter No.3 -> `floc:0519-07-05-020-030`
  - Roll Prep -> `floc:0519-07-05-010`
- Deleted `populate_Asset_Equipment` transformation (no longer needed)
- Deleted 4 legacy `equip:*` Equipment instances (Feb 17, 2026)
- Deleted Equipment view and MfgEquipment container from sylvamo_mfg_core_schema (Feb 17, 2026)
- SDK migration: Added asset links to 180 existing RollQuality instances (Feb 17, 2026)
  - Instances created by SharePoint function now linked to SAP FLOC Assets
  - Total RollQuality with asset links: 349/750

**Why:**
- Complete ISA-95 Equipment migration (SVQS-243)
- Remove orphaned Equipment instances causing "Equipment: 4" in CDF Fusion
- Properly link RollQuality to SAP Asset hierarchy

---

### [Documentation] Documentation tree review and reorganization
**Date:** 2026-02-02
**Repo:** [sylvamo-project-documentation](https://github.com/fbarsoba-cognite/sylvamo-project-documentation)

**Changes:**
- Created `docs/deprecated/` folder for superseded content
- Moved `MFG_CORE_WITH_EQUIPMENT.md` to deprecated (superseded by ADR-001)
- Moved `SPRINT_2_PLAN.md` and `SPRINT_2_STORY_MAPPING.md` to deprecated (Sprint 2 completed)
- Added `SPRINT_3_PLAN.md` (Feb 16–Mar 2, 2026)
- Updated README: Sprint 3, Asset 45,900+, RollQuality 750+, Equipment as Asset subtypes
- Updated data-model, extractors, presentations with current stats and links
- Reorganized docs/README.md structure and deprecated section

**Why:**
- Keep documentation current with model, extractors, and sprint status
- Archive superseded content for reference without confusion

---

### [SVQS-240] Bump RollQuality view from v1 to v2
**Date:** 2026-02-16 19:46 EST
**Jira:** [SVQS-240](https://cognitedata.atlassian.net/browse/SVQS-240)
**ADO PR:** [PR #890](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/890)

**Changes:**
- Bumped `RollQuality` view from v1 to v2 in `RollQuality.View.yaml`
- Updated `populate_RollQuality.Transformation.yaml` to target v2
- DataModel and Roll view intentionally NOT updated to avoid cascading version bumps

**Why:**
- Equipment PR (PR #889) added `equipmentRef` to RollQuality, which changes the property source
- CDF does not allow changing property sources on published views without a version bump
- Roll/v1 kept as-is to avoid cascading to Reel, Event, and the entire data model

---

### [SVQS-245] Revamp Fabric SAP extractors to match IDL Pilot table list
**Date:** 2026-02-17 10:00 EST
**Jira:** [SVQS-245](https://cognitedata.atlassian.net/browse/SVQS-245)
**ADO PR:** VM-only change (no code PR). Extraction pipeline update included in [PR #899](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/899)

**Changes:**
- Replaced auto-discovery of ~320 SAP ECC Silver tables with 12 specific tables per Cam's definitive list
- Added 10 new hardcoded SAP ECC Silver tables: AFPO, AFRU, MAKT, MARA, MARC, MARD, MAST, RESB, STKO, STPO
- Removed AFVC (superseded by `wo_operations` from Gold layer)
- Updated `Setup-FabricExtractors.ps1` with new table definitions and status tracking
- Updated `DATA_SOURCE_REGISTRY.md` to reflect the 17-table (12 Silver + 4 Gold + 1 PPV) definitive list
- Added Cam's Excel reference document to `docs/reference/extractors/`

**Why:**
- Cam provided the definitive list of SAP tables needed for the IDL Pilot in "SAP Tables in Fabric (02-15-26).xlsx"
- Previous approach (extracting all 320 tables) was wasteful — only 12 Silver tables are needed
- Gold-layer tables (iw28, iw38, sap_hierarchy, wo_operations) already pre-joined by Valmir in Fabric
- CDF Transformations will replicate Valmir's SQL query logic for Silver tables

---

### [SVQS-239] Transformation fixes, schedules, and CDF alignment
**Date:** 2026-02-17 EST
**Jira:** [SVQS-239](https://cognitedata.atlassian.net/browse/SVQS-239)
**ADO PR:** [PR #899](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/899)

**Changes:**
- Updated `fabric_sapecc_daily.ExtractionPipeline.yaml`: corrected "324 tables" to "16 tables" and refreshed documentation (SVQS-245 follow-up)
- Added 13 new Schedule.yaml files for all mfg_core transformations that lacked schedules:
  RollQuality, Material, Event_PPV, Event_ProductionOrders, Event_WorkOrders, Asset, Files, TimeSeries, ProficyTimeSeries, ProficyEventIdTimeSeries, ProficyReelsDatapoints, create_ProficyTimeSeries_CDF, create_ProficyEventIdTimeSeries_CDF
- Deleted 300 stale RAW tables from `raw_ext_fabric_sapecc` via SDK (Phase 1 cleanup)

**Why:**
- Only Roll and Reel had transformation schedules; the other 13 mfg_core transformations would never run automatically
- 300 orphaned RAW tables in CDF from the old 320-table auto-discovery needed cleanup
- Extraction pipeline documentation was stale (still referenced 324 tables)

**Schedule intervals:**
- Hourly (`0 * * * *`): PPR/Proficy-based transformations (Roll, Reel, RollQuality, TimeSeries, Proficy*)
- Every 6 hours (`0 */6 * * *`): SAP/Fabric-based transformations (Material, Events, Asset, Files)

---

### Correct reel link and UTC/cut date handling
**Date:** 2026-02-10
**ADO PR:** [PR #851](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/851), [PR #852](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/852)

**Changes:**
- Fixed reel link in `populate_Roll.Transformation.sql` to include year
- Added UTC timezone handling and cut date assignment for Roll transformation

**Why:**
- Reel-to-Roll links were broken due to missing year in join key
- Timestamps needed UTC normalization for consistent date handling

---

### [SVQS-209] Remove duplicate Proficy Event transformation
**Date:** 2026-02-11
**Jira:** [SVQS-209](https://cognitedata.atlassian.net/browse/SVQS-209)
**ADO PR:** [PR #853](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/853)

**Changes:**
- Removed duplicate `populate_Event_Proficy` transformation (SQL + YAML)
- Proficy events now handled exclusively by the main Event transformations

**Why:**
- Duplicate transformation was creating redundant event instances in CDF

---

### [SVQS-210] Fix Proficy reels_timeseries timestamp alignment
**Date:** 2026-02-11
**Jira:** [SVQS-210](https://cognitedata.atlassian.net/browse/SVQS-210)
**ADO PR:** [PR #854](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/854)

**Changes:**
- Added `populate_ProficyReelsDatapoints` transformation (SQL + YAML)
- Implemented Eastern to UTC timezone conversion for Proficy timestamps

**Why:**
- Proficy reels_timeseries timestamps were in Eastern time, causing misalignment with CDF's UTC-based data
