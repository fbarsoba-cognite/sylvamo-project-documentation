# Change Log - Page 0002

Data model changes for Sylvamo MFG Core. ~10 entries per page.

---

### [SVQS-254] Fix Time Series alias gap for equipment-level contextualization
**Date:** 2026-02-19 (EST)
**Jira:** [SVQS-254](https://cognitedata.atlassian.net/browse/SVQS-254)
**ADO PR:** [PR #925](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/925)

**Changes:**
- Added "no hyphens" alias variant (Alias 6) to `generate_TimeSeries_Aliases.Transformation.sql`
- PI tag `pi:471-PT-101.PV` now produces alias `471PT101` in addition to `471-PT-101`
- This aligns with asset alias `471PT101` (sortField `471 PT 101` with spaces stripped)

**Why:**
- PI time series were only contextualized to Paper Machine level (PM1/PM2) because the entity matcher couldn't find equipment-level matches
- TS aliases had hyphens (`471-PT-101`) while asset aliases stripped spaces (`471PT101`) — no common normalized form existed
- This fix enables the ML entity matcher to find exact equipment-level matches, a prerequisite for deeper PI tag → SAP FLOC contextualization

---

### [SVQS-186] Fix remaining _UnknownType errors: object3D, unit, CogniteFile
**Date:** 2026-02-19 (EST)
**Jira:** [SVQS-186](https://cognitedata.atlassian.net/browse/SVQS-186)
**ADO PR:** [PR #923](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/923)

**Changes:**
- **Asset view:** Removed typed `source` from `object3D` override (Cognite3DObject not in data model). Field becomes an untyped direct relation so the UI no longer tries to sub-select into it. Updated `files` reverse relation to reference the new custom File view.
- **MfgTimeSeries view:** Removed typed `source` from `object3D` and `unit` overrides (Cognite3DObject, CogniteUnit not in data model). Fields become untyped direct relations.
- **File view (NEW):** Created custom `File.View.yaml` implementing CogniteFile. Overrides `assets` to point to our Asset view, and makes `source`, `category`, `object3D` untyped. Replaces the raw CDM CogniteFile entry in the data model.
- **Data model:** Replaced CDM CogniteFile with custom File view; bumped to v7.
- **Config:** Bumped `mfgCoreModelVersion` v3 → v5 (all environments) since property definition changes require new view versions.

**Why:**
- On data model v6, the Data Models UI showed `SubselectionNotAllowed` / `_UnknownType` errors on Asset (object3D), MfgTimeSeries (unit, object3D), and CogniteFile (source, assets, category). The relation fields pointed to CDM types (Cognite3DObject, CogniteUnit, CogniteSourceSystem, CogniteFileCategory) not included in the data model, so the auto-generated GraphQL schema could not resolve them. Making unused CDM relations untyped and wrapping CogniteFile with a custom view fixes type resolution for all views.

**Model changes (v3 → v5):**
- Asset/v5: `object3D` untyped, `files` → File view
- MfgTimeSeries/v5: `object3D` untyped, `unit` untyped
- File/v5 (new): wraps CogniteFile, `assets` → Asset, `source`/`category`/`object3D` untyped
- DataModel v7 (replaces v6)

---

### [SVQS-186] Data Models UI: fix SubselectionNotAllowed / UnknownType for Asset, MfgTimeSeries, Event
**Date:** 2026-02-19 (EST)
**Jira:** [SVQS-186](https://cognitedata.atlassian.net/browse/SVQS-186)
**ADO PR:** [PR #920](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/920)

**Changes:**
- **Asset view:** Overrode CogniteAsset relation fields so they resolve in this space: `root`, `path` (source → Asset view); `assetClass`, `type` (mapped to MfgAsset.assetType for UI compatibility); `equipment`, `mfgEquipment` (connection to child assets via parent). Fixes "Subselection not allowed on leaf type 'UnknownType'" and "Unknown field argument 'First'" when listing Asset in CDF Data Models.
- **MfgTimeSeries view:** Added `source` to `assets` property pointing to Asset view so the relation type resolves when the UI lists MfgTimeSeries.
- **Event view:** Added `source` to `assets` property pointing to Asset view so the relation type resolves when the UI lists Event.
- **Roll view:** Overrode CogniteSourceable `source` relation to point to Asset view so the Data Models UI can load the Roll list without "An unexpected error occurred while loading your data."
- **Reel, Package, Material, RollQuality views:** Added the same CogniteSourceable `source` override (→ Asset view) so all views that implement CogniteSourceable resolve in the Data Models UI and list loading works for every model.

**Why:**
- Users opening any model (Asset, MfgTimeSeries, Event, Roll, Reel, Package, Material, RollQuality) in CDF Data Models were getting "An unexpected error occurred while loading your data" because inherited CDM relation fields (e.g. CogniteSourceable `source`, or root/path/assetClass/type/equipment/assets on Asset) had no resolved type in this project (UnknownType) or the UI sent connection arguments the backend rejected. Explicit overrides with correct `source` (or scalar mapping) fix type resolution and allow the list view to load for all views.

---

### [SVQS-186] Entity matching fixes, deep contextualization docs, and code rules
**Date:** 2026-02-19 (EST)
**Jira:** [SVQS-186](https://cognitedata.atlassian.net/browse/SVQS-186)
**ADO PR:** [PR #919](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/919)

**Changes:**
- **Entity matching pipeline:** Fixed manual mapping lookup to use `Entity` column (not `key`) for asset resolution; accept `Contextualized` as boolean `True` or string `"True"` so CSV-uploaded rows are applied; added `equipment_demo` manual row (472CP558 → PM2) and set `Contextualized=True` on all manual input rows
- **Validation app:** Configurable `ENTITY_MATCHING_RAW_DB` (env); sidebar shows entity matching RAW DB name; SKIP remediation hints for T4.7c/T4.7d when table not found; added `list_ts_with_equipment.py` script to list time series linked to equipment-level assets for Search testing
- **Docs:** Added `docs/contextualization/equipment-and-sensor-level-contextualization.md` with testing via Search examples (by asset, by time series) and §4.3 "See deep contextualization in action (step-by-step)"
- **Code development rules:** Documented validation app exception to Cognite client rule; fixed Ruff findings (bare `except` → `except Exception`, unused variables, E712 truth checks, import order, f-string); applied `ruff format` to entity matching and validation app

**Why:**
- Manual mappings were never applied due to lookup-by-key bug and strict `Contextualized is True` check; empty/descriptive Contextualized values in CSV caused all rows to be skipped
- Enables seeing deep contextualization in CDF Search once manual table is populated and workflow runs; changelog and code-quality updates follow project rules for code updates

---

### [SVQS-186] Fix TimeSeries alias transformation required properties
**Date:** 2026-02-18 (EST)
**Jira:** [SVQS-186](https://cognitedata.atlassian.net/browse/SVQS-186)
**ADO PR:** [PR #916](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/916)

**Changes:**
- Added `isStep` and `type` columns to `generate_TimeSeries_Aliases.Transformation.sql`
- `CogniteTimeSeries` container requires these properties; omitting them caused transformation failure
- Maps `isString` boolean to the `type` enum (`numeric`/`string`)

**Why:**
- `tr_generate_TimeSeries_Aliases` was failing with "Could not find required properties: [isStep, type]" because the parent CDM container enforces these as mandatory

---

### [SVQS-186] Fix alias generation SQL and Reel column name
**Date:** 2026-02-18 (EST)
**Jira:** [SVQS-186](https://cognitedata.atlassian.net/browse/SVQS-186)
**ADO PRs:** [PR #914](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/914), [PR #915](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/915)

**Changes:**
- Replaced `array_remove_nulls()` with `filter(array(...), x -> x IS NOT NULL)` in Asset and TimeSeries alias transformations (CDF Spark compatibility)
- Corrected `populate_Reel` to use `REEL_MANUFACTURING_PMP` instead of non-existent `REEL_PAPER_MACHINE` column
- Added use-case framing to the Streamlit validation dashboard

**Why:**
- `array_remove_nulls` is not a valid Spark SQL function, causing both alias transformations to fail
- Reel transformation referenced a column that doesn't exist in the RAW table

---

### [SVQS-186] Contextualization improvement — Phases 1-4
**Date:** 2026-02-18 (EST)
**Jira:** [SVQS-186](https://cognitedata.atlassian.net/browse/SVQS-186)
**ADO PRs:** [PR #911](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/911), [PR #912](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/912), [PR #913](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/913)

**Changes:**
- **Phase 1 — Alias Generation:** Added `aliases` (text list) property to `MfgAsset` and `MfgTimeSeries` containers/views. Created `generate_Asset_Aliases` and `generate_TimeSeries_Aliases` transformations with hourly schedules
- **Phase 2 — Entity Matching:** Integrated `cdf_entity_matching` accelerator module, configured for Sylvamo schema with alias-based matching. Seeded rule-based and manual matching tables
- **Phase 3 — P&ID Annotation:** Configured `cdf_p_and_id_parser` and `cdf_common` modules to target Sylvamo `Asset` view for file annotation and direct relation writing
- **Phase 4 — Relationship Gap Closure:** Added `asset` (direct relation) to `MfgReel` and `MfgRoll` containers/views, mapping PM1/PM2. Extended Work Order contextualization to include Sumter plant (`0519%`)
- **Validation App:** Created Streamlit-based validation dashboard (`tests/validation_app/`) with 7 test phases covering schema, alias quality, PI mapping, entity matching, relationship gaps, file annotation, and end-to-end health

**Model changes (v3 → v4):**
- `MfgAsset`: added `aliases` (text list)
- `MfgTimeSeries`: added `aliases` (text list)
- `MfgReel`: added `asset` (direct relation to Asset)
- `MfgRoll`: added `asset` (direct relation to Asset)

---

### [SVQS-239] Transformation fixes, schedules, and CDF alignment
**Date:** 2026-02-17 (EST)
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
