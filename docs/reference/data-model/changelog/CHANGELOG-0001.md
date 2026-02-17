# Change Log - Page 0001

Data model changes for Sylvamo MFG Core. ~10 entries per page.

---

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

**Why:**
- Complete ISA-95 Equipment migration (SVQS-243)
- Remove orphaned Equipment instances causing "Equipment: 4" in CDF Fusion
- Properly link RollQuality to SAP Asset hierarchy

---

