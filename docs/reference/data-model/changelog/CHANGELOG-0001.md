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

