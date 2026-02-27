# Change Log - Page 0003

Data model changes for Sylvamo MFG Core. ~10 entries per page.

---

### [SVQS-173] PPV Step 2: Area-level asset linkage via material-to-area mapping
**Date:** 2026-02-26
**Jira:** [SVQS-173](https://cognitedata.atlassian.net/browse/SVQS-173)
**ADO PR:** [PR #1025](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/1025)

**Changes:**
- New `tr_generate_PPV_Material_Area_Mapping` transformation: RESB + AUFK + FLOC join → `raw_ext_manual.ppv_material_area_mapping` (daily 01:00 UTC)
- New RAW database `raw_ext_manual` and table `ppv_material_area_mapping`
- Modified `populate_Event_PPV`: LEFT JOIN mapping table; COALESCE(area_ref, site_ref) for asset linkage
- Added `scripts/validate_ppv_material_area_mapping.py` for post-deploy validation
- Updated `docs/contextualization/SVQS-173_STEP2_*.md` with Option B approach

**Why:**
- Move PPV CostEvent linkage from site-level only to area-level where RESB/AUFK data allows
- Separate mapping transform enables debugging, performance, and manual overrides

---

### [SVQS-173] PPV unblocked hardening - transform, validator, search docs
**Date:** 2026-02-26
**Jira:** [SVQS-173](https://cognitedata.atlassian.net/browse/SVQS-173)
**ADO PR:** [PR #1020](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/1020)

**Changes:**
- Hardened `populate_Event_PPV.Transformation.sql`: only create asset ref when plant is non-null and non-empty (avoid invalid floc: references)
- Added `scripts/validate_event_ppv_asset_relation.py` for CostEvent->asset linkage quality validation
- Added `docs/contextualization/EVENT_PPV_SEARCH_VERIFICATION.md` documenting Event search path for PPV
- Updated `docs/contextualization/SVQS-173_NEXT_ACTIONS.md` with done-now vs Cam-dependent deferred items

**Why:**
- SVQS-173 unblocked delivery: PPV CostEvent remains searchable by asset; validator reports linkage confidence; BOM/MB51/railcar/PI completeness deferred on Cam.

---

### [SVQS-282] Virtual Instrumentation Tags + File Annotation Fix
**Date:** 2026-02-24
**Jira:** [SVQS-282](https://cognitedata.atlassian.net/browse/SVQS-282) (implements [SVQS-235](https://cognitedata.atlassian.net/browse/SVQS-235))
**ADO PR:** [PR #992](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/992)

**Changes:**
- Created ~3,468 virtual instrumentation tag assets (vtag:) from PI time series, each with DetectInDiagrams tag and PI tag name aliases for P&ID matching
- Fixed file annotation config bug: targetEntityVersion and viewVersion v1 -> v11 (Asset view)
- New transformations: populate_VirtualInstrumentationTags, generate_VirtualTag_Aliases, recontextualize_TimeSeries (for Anvar's 210 curated tags)
- Added scripts/load_anvar_sheet_to_raw.py for loading Anvar's 210-row curated PI tag-to-FLOC sheet into raw_ext_pi.pi_tag_to_floc

**Why:**
- PI and SAP are separate systems with no direct mapping (per Cam/Sylvamo). Prefix-based mapping is the ceiling for automation. Virtual tags enable P&ID diagram matching and search-by-PI-tag-name. Anvar's sheet provides deeper FLOC for 210 curated tags.

---

### [SVQS-256] Fix tr_file_to_asset_from_annotations - use cdf_raw for RAW table schema
**Date:** 2026-02-24
**Jira:** [SVQS-256](https://cognitedata.atlassian.net/browse/SVQS-256)
**ADO PR:** [PR #985](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/985)

**Changes:**
- Updated `file_to_asset.Transformation.sql` to use `cdf_raw()` and `get_json_object(columns, '$.field')` instead of direct column access
- CDF RAW tables use schema (key, lastUpdatedTime, columns) where columns is JSON

**Why:**
- Link Files to Assets step failed with "Column 'status' does not exist"
- Transformation assumed flat columns; RAW tables store data in `columns` JSON string

---

### [SVQS-256] Point gp_file_annotation to cognite_toolkit_service_principal for extractionConfigsAcl
**Date:** 2026-02-23
**Jira:** [SVQS-256](https://cognitedata.atlassian.net/browse/SVQS-256)
**ADO PR:** [PR #983](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/983)

**Changes:**
- Set `groupSourceId` for cdf_file_annotation module to `cogniteToolkitServicePrincipalSourceId` (94188b6a-9bf6-4550-a649-47597db59e66) instead of `${adminToolkitSourceId}`
- Added `cogniteToolkitServicePrincipalSourceId` variable in config.dev.yaml

**Why:**
- Prepare step failed with "Failed (4xx): [ep_file_annotation, _]" because gp_file_annotation used unresolved `${adminToolkitSourceId}`, so the group had no Azure AD link and no members
- Workflow service principal could not read extraction pipeline config without extractionConfigsAcl
- cognite_toolkit_service_principal group has extractionConfigsAcl; reusing it allows Prepare to succeed

---

### [SVQS-256] Add sp_file_annotation_functions space for File Annotation function deploy
**Date:** 2026-02-24
**Jira:** [SVQS-256](https://cognitedata.atlassian.net/browse/SVQS-256)
**ADO PR:** [PR #982](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/982)

**Changes:**
- Added `sp_file_annotation_functions` space definition to `hdm.space.yaml` in cdf_file_annotation module
- Space is used for File Annotation function code storage (Prepare, Launch, Finalize, Promote)

**Why:**
- Function deploy failed with "One or more spaces do not exist: sp_file_annotation_functions"
- Deploy pipeline uses continueOnError for functions, so the failure was silent
- Adding the space to the data model ensures it is created before function deploy runs

---

### [SVQS-256] Align file annotation fileInstanceSpace to sylvamo_mfg_core_instances
**Date:** 2026-02-24
**Jira:** [SVQS-256](https://cognitedata.atlassian.net/browse/SVQS-256)
**ADO PR:** [PR #978](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/978)

**Changes:**
- Set fileInstanceSpace from cdf_cdm to sylvamo_mfg_core_instances in config.dev.yaml
- Pipeline Prepare step now queries the space where populate_Files writes file nodes

**Why:**
- Pipeline was selecting zero files because it queried cdf_cdm; files live in sylvamo_mfg_core_instances
- Enables File Annotation dashboard to show non-zero KPIs when files are tagged ToAnnotate

---

### [SVQS-256] Fix File Annotation Streamlit system/user space error
**Date:** 2026-02-24
**Jira:** [SVQS-256](https://cognitedata.atlassian.net/browse/SVQS-256)
**ADO PR:** [PR #977](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/977)

**Changes:**
- Use `annotationStateInstanceSpace` (sp_hdm_file_annotation) for annotation state view instead of `fileInstanceSpace` (cdf_cdm)
- Added `annotationStateInstanceSpace` to ep_file_annotation.config.yaml, config.dev.yaml, default.config.yaml

**Why:**
- Resolves CogniteAPIError: "Query is targeting both system spaces and user spaces"
- Annotation states live in user space; files (CogniteFile) in system space cdf_cdm — mixing them in one query was not allowed

---

### [SVQS-256] Add File Annotation pipeline and Streamlit dashboard (Darren recommendation)
**Date:** 2026-02-23
**Jira:** [SVQS-256](https://cognitedata.atlassian.net/browse/SVQS-256)
**ADO PR:** [PR #976](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/976)

**Changes:**
- Added File Annotation accelerator module (`cdf_file_annotation`) from Cognite library
- Annotation execution pipeline: prepare, launch, finalize, promote functions; extraction pipelines; workflows
- Streamlit dashboard for monitoring annotation runs and quality metrics
- Config wired for dev environment with required variables (file schema, target entity Asset, raw DB, etc.)
- Excluded vendored module from ruff in pyproject.toml

**Why:**
- Per Darren Downtain (SA Lead) Feb 19 review: File Annotation pipeline with Streamlit dashboard enables progress tracking and quality scoring for contextualization
- Enables pilot subset runs (3 → 20 → full) with validation of annotations and deduplication behavior

---

### [SVQS-266] Apply LVORM filter to MaterialValuation and re-enable schedule
**Date:** 2026-02-20 09:26 (EST)
**Jira:** [SVQS-266](https://cognitedata.atlassian.net/browse/SVQS-266)
**ADO PR:** [PR #943](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/943)

**Changes:**
- Added LVORM filter to `populate_MaterialValuation.Transformation.sql`: `AND (LVORM IS NULL OR LVORM = '')`
- Re-enabled `populate_MaterialValuation` schedule (isPaused: false)
- Started one-off deletion of old Roll nodes (cutDate < 2024-01-01) via SDK (~1.03M instances)

**Why:**
- MaterialValuation is SAP master data; date cutoff inappropriate — LVORM (deletion flag) is the correct signal
- 56.8% of MBEW records are deletion-flagged → ~630K instances freed
- Roll deletions free ~1.03M instances from 2022-2023 data no longer needed

---

### [SVQS-266] Pause Package/MaterialValuation schedules, add Roll date filter for instance limit
**Date:** 2026-02-20 09:03 (EST)
**Jira:** [SVQS-266](https://cognitedata.atlassian.net/browse/SVQS-266)
**ADO PR:** [PR #943](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/943)

**Changes:**
- Paused `populate_Package` schedule (isPaused: true)
- Paused `populate_MaterialValuation` schedule (isPaused: true)
- Added date filter to `populate_Roll`: keep only rolls from 2024-01-01 onward

**Why:**
- CDF instance limit (5M) causing space pressure
- Package (~927K) and MaterialValuation (1M+) paused to free capacity
- Roll date filter frees ~1.03M instances when old rolls (cutDate < 2024) are deleted

---

### [SVQS-267] Enable search-config alpha flag for SearchConfig deployment
**Date:** 2026-02-19 22:15 (EST)
**Jira:** [SVQS-267](https://cognitedata.atlassian.net/browse/SVQS-267)
**ADO PR:** [PR #941](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/941)

**Changes:**
- Added `search-config = true` to `[alpha_flags]` in cdf.toml

**Why:**
- SearchConfig resources require the search-config alpha flag to be deployed by the toolkit
- Enables Equipment and MaterialValuation to appear as search categories in Industrial Tools (with PR #939)

---

### [SVQS-267] Add view version to Equipment and MaterialValuation SearchConfig for Industrial Tools search
**Date:** 2026-02-19 21:55 (EST)
**Jira:** [SVQS-267](https://cognitedata.atlassian.net/browse/SVQS-267)
**ADO PR:** [PR #939](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/939)

**Changes:**
- Added `version: "{{ mfgCoreModelVersion }}"` to Equipment.SearchConfig.yaml view reference
- Added `version: "{{ mfgCoreModelVersion }}"` to MaterialValuation.SearchConfig.yaml view reference

**Why:**
- Equipment (136K) and MaterialValuation (1M+) were not appearing as search categories in Industrial Tools
- SearchConfig view references lacked explicit version, preventing correct resolution against LocationFilter data model (v10)

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

---

### CI/CD pipeline setup for CDF Toolkit deployment
**Date:** 2026-02-08 / 2026-02-09
**ADO PRs:** [PR #842](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/842) (validation), multiple direct commits

**Changes:**
- Added `deploy-pipeline.yml` and `dry-run-pipeline.yml` for Azure DevOps CI/CD
- Split deployment: Dev+Staging on merge to main, Prod on weekly schedule
- Added PR validation pipeline with dry-run for Dev and Staging
- Configured `config.dev.yaml`, `config.staging.yaml`, `config.prod.yaml`
- Fixed annotationsAcl in auth groups for sylvamo-test (staging) compatibility

**Why:**
- Establish automated CI/CD for CDF Toolkit deployments across Dev, Staging, and Prod
- Enable PR validation with dry-run to catch issues before merge

---

### Add Sylvamo MFG modules and admin to toolkit deployment
**Date:** 2026-02-09
**ADO PR:** [PR #844](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/844)

**Changes:**
- Added `mfg_core` module: 7 containers (MfgAsset, MfgRoll, MfgReel, MfgEvent, Material, RollQuality, MfgTimeSeries), 7 views, SylvamoMfgCore data model, 15 transformations, location filter
- Added `mfg_extended` module: 8 containers (WorkOrder, Operation, ProductionOrder, ProductionEvent, CostEvent, Notification, MaintenanceActivity, MfgEquipment), 8 views, 5 transformations, location filter
- Added `mfg_data` module: Full CDM-aligned manufacturing data model with 15 containers and views
- Added `mfg_location` module: Location configuration
- Added `admin` module: auth groups (admin, all-read, service principal), data sets, source system transformation
- Updated Dev/Staging/Prod config files to include all modules (138 files, ~10,000 lines)

**Why:**
- Foundational deployment of the complete Sylvamo manufacturing data model to CDF
- Enables all subsequent transformations, extraction pipelines, and data ingestion

---

### [SVQS-251] Add Package entity and OrderItem transformation from PPR tables
**Date:** 2026-02-18 16:00 (EST)
**Jira:** [SVQS-251](https://cognitedata.atlassian.net/browse/SVQS-251)
**ADO PR:** [PR #906](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/906)

**Changes:**
- New `MfgPackage` container with 11 properties (packageNumber, numberOfRolls, assembledDate, shipDate, loadDate, grossWeight, netWeight, inventoryPoint, deliveryNumber, orderItem, status)
- New `Package` view (v1) implementing CogniteDescribable + CogniteSourceable
- Updated `SylvamoMfgCore` DataModel to include Package view (7 → 8 entities)
- New `populate_Package` transformation: `raw_ext_fabric_ppr.ppr_hist_package` → Package view (hourly schedule)
- New `populate_Event_OrderItems` transformation: `raw_ext_fabric_ppr.ppr_hist_order_item` → Event view with eventType=OrderItem (daily at 03:00)

**Why:**
- Of 18 PPR tables in raw_ext_fabric_ppr, only ppr_hist_reel (→ Reel) and ppr_hist_roll (→ Roll) had transformations
- Package entity is documented in Use Case 2 (Paper Quality Association) and Phase 2 roadmap
- Order items enable tracking customer order fulfillment alongside manufacturing events

---

### [SVQS-252] CDF-Local Alignment: Add missing transformations, fix RollQuality version
**Date:** 2026-02-18 18:00 (EST)
**Jira:** [SVQS-252](https://cognitedata.atlassian.net/browse/SVQS-252)
**ADO PR:** [PR #907](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/907)

**Changes:**
- Added 7 active transformations to `ado/main` that were running in CDF but missing from version control:
  - `create_ProficyTimeSeries_CDF` / `create_ProficyEventIdTimeSeries_CDF` (Proficy classic time series)
  - `populate_ProficyTimeSeries` / `populate_ProficyEventIdTimeSeries` (MfgTimeSeries CDM nodes)
  - `populate_ProficyReelsDatapoints` (string datapoints for reel event IDs)
  - `populate_Files` (CogniteFile nodes from CDF Files API)
  - `populate_RollQuality` (RollQuality v2 nodes from SharePoint)
- Fixed RollQuality version reference in `SylvamoMfgCore` DataModel: `v1` → `v2` (matching deployed view)
- Cleaned up 71 inactive legacy transformations from CDF (backed up SQL before deletion)

**Why:**
- Drift analysis revealed 7 transformations deployed from feature branches that were never merged to `main`
- RollQuality view was deployed as v2 but data model still referenced v1, causing inconsistency
- Legacy transformations from past experiments cluttered the CDF project

---

### [SVQS-253] Cleanup 14K duplicate legacy time series and fix populate_TimeSeries filter
**Date:** 2026-02-18 19:30 (EST)
**Jira:** [SVQS-253](https://cognitedata.atlassian.net/browse/SVQS-253)
**ADO PR:** [PR #908](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/908)

**Changes:**
- Updated `populate_TimeSeries.Transformation.sql`: require `externalId IS NOT NULL AND externalId != ''`
- Removed synthetic `ts:` prefix fallback for time series without externalId
- Deleted 14,147 orphaned `ts:` prefix MfgTimeSeries CDM nodes from CDF
- MfgTimeSeries node count reduced from ~17.9K to ~3.7K

**Why:**
- 14,441 legacy PI time series (no externalId, 329 unique names duplicated ~44x each, zero datapoints) were being ingested into the CDM, inflating the count from 3.5K to 17.9K

---

### [SVQS-251] Add Package SearchConfig for Industrial Tools search
**Date:** 2026-02-18 21:45 (EST)
**Jira:** [SVQS-251](https://cognitedata.atlassian.net/browse/SVQS-251)
**ADO PR:** [PR #909](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/909)

**Changes:**
- Added `Package.SearchConfig.yaml` to `mfg_core/cdf_applications/`
- Configured columns: packageNumber, status, numberOfRolls, shipDate, deliveryNumber
- Configured filters: status, shipDate, inventoryPoint
- Full properties layout: all 11 Package properties

**Why:**
- Package entity (1.4M+ nodes) was deployed but not visible in CDF Industrial Tools search sidebar
- SearchConfig makes it discoverable alongside other entities (Roll, Reel, Asset, etc.)

---

### [SVQS-251] Fix location filter version for Package visibility in Industrial Tools
**Date:** 2026-02-18 22:00 (EST)
**Jira:** [SVQS-251](https://cognitedata.atlassian.net/browse/SVQS-251)
**ADO PR:** [PR #910](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/910)

**Changes:**
- Updated `sylvamo_mfg_core.LocationFilter.yaml` data model version from `v1` to `v3`
- Root cause: location filter referenced `SylvamoMfgCore:v1` which predates the Package view (added in v2) and RollQuality:v2 (added in v3)

**Why:**
- Package entity (1.4M+ nodes) and its SearchConfig were deployed but invisible in Industrial Tools because the location filter pointed to an older data model version

---

### [SVQS-186] Phase 1: Alias generation pipeline for contextualization
**Date:** 2026-02-18 23:00 (EST)
**Jira:** [SVQS-186](https://cognitedata.atlassian.net/browse/SVQS-186)
**ADO PR:** [PR #911](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/911)

**Changes:**
- Added `aliases` text[] property to `MfgAsset` and `MfgTimeSeries` containers
- Exposed `aliases` in `Asset` and `MfgTimeSeries` views
- New `generate_Asset_Aliases` transformation: extracts 5 alias variants per asset (sortField cleaned, FLOC, last segment, hyphen-stripped, space-stripped)
- New `generate_TimeSeries_Aliases` transformation: extracts 5 alias variants per time series (cleaned PI tag, tag prefix, full ID, name, prefix without underscores)
- Both transformations scheduled every 6h (30min offset after populate transformations)

**Why:**
- Foundation for Phase 1 of contextualization improvement (SVQS-186)
- Aliases enable entity matching between time series and assets at equipment/sensor level
- Current contextualization only maps to Paper Machine level; aliases support deeper matching

---

### [SVQS-244] Fix MaterialValuation transformation - use null for currency (Fabric MBEW has no WAERS)
**Date:** 2026-02-19 (EST)
**Jira:** [SVQS-244](https://cognitedata.atlassian.net/browse/SVQS-244)
**ADO PR:** [PR #936](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/936)

**Changes:**
- Updated `populate_MaterialValuation.Transformation.sql`: replace `cast(WAERS as STRING)` with `cast(null as STRING)` for currency
- Fabric MBEW table does not have WAERS column; transformation was failing with "Column 'WAERS' does not exist"

**Why:**
- Enable MaterialValuation transformation to run against Fabric MBEW source

---

### [SVQS-244] Fix LocationFilter version so Equipment and MaterialValuation show in Industrial Tools search
**Date:** 2026-02-19 (EST)
**Jira:** [SVQS-244](https://cognitedata.atlassian.net/browse/SVQS-244)
**ADO PR:** [PR #937](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/937)

**Changes:**
- Updated `sylvamo_mfg_core.LocationFilter.yaml`: use `{{ mfgCoreModelVersion }}` instead of hardcoded `v6`
- LocationFilter now resolves to v10 (dev/staging) or v7 (prod) per config

**Why:**
- Equipment and MaterialValuation were not appearing in Industrial Tools search sidebar
- Root cause: LocationFilter pointed to SylvamoMfgCore:v6, which does not include these views. Industrial Tools only shows views that exist in the data model version referenced by the location filter.

---

### [SVQS-266] Remove mfg_extended module to reduce instance count
**Date:** 2026-02-19 (EST)
**Jira:** [SVQS-266](https://cognitedata.atlassian.net/browse/SVQS-266)
**ADO PR:** [PR #938](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/938)

**Changes:**
- Removed `modules/mfg_extended/` (WorkOrder, Operation, ProductionOrder, ProductionEvent, CostEvent, Notification, MaintenanceActivity, Equipment)
- Removed mfg_extended from selected modules in dev, staging, prod configs
- Removed mfgExtended* variables from configs

**Why:**
- Project hit 5M instance limit; mfg_extended removal frees capacity for mfg_core entities (Equipment, MaterialValuation, etc.)

---

### [SVQS-261] Virtual Instrumentation Tags for Time Series Contextualization
**Date:** 2026-02-19 23:30 (EST)
**Jira:** [SVQS-261](https://cognitedata.atlassian.net/browse/SVQS-261)
**ADO PR:** [PR #940](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/940)

**Changes:**
- New transformation `populate_VirtualInstrumentationTags` creates a virtual asset node (vtag:) for each of ~3,468 PI time series tags, placed under the appropriate functional location based on prefix mapping
- Modified `populate_TimeSeries` to reference vtag: assets instead of coarse PM-level FLOCs, enabling discrete tag-level contextualization
- Added 7 validation tests verifying virtual tag creation, parent references, aliases, TS mapping, orphan detection, diagram detection compatibility, and entity matching compatibility
- ADR-002 documenting the architectural decision
- Implementation guide for data engineers

**Why:**
- SAP does not track instrumentation (transmitters, sensors, control valves), leaving PI time series with no discrete asset to contextualize against
- Per Darren Downtain (SA Lead, Americas) Feb 19 review: virtual tags give ~100% discrete TS match rate, become P&ID annotation candidates, and enable gap analysis for the client
