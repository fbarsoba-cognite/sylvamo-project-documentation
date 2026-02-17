# Properties & Attributes Diagram — CDF/Documentation Validation

Validation of the "Properties & Attributes" diagram against the mfg_core data model (YAML + CDF).

**CDF verification:** `python scripts/inspect_cdf_model_relations.py` — relationships confirmed against sylvamo-dev.

---

## Summary

| Entity | Diagram | Actual (mfg_core) | Status |
|--------|---------|-------------------|--------|
| Asset | name (PK), description, assetType, parent, children | externalId (PK), name, description, assetType, parent, + sapFunctionalLocation, plantCode, etc. | ⚠️ PK is externalId, not name |
| Material | materialCode (PK), description, materialType | materialCode (PK), materialDescription, materialType, materialGroup, unitOfMeasure, isActive | ✓ Mostly correct |
| MfgTimeSeries | externalId (PK), name, unit | externalId (PK), name, unit, + measurementType, piTagName, timeSeries | ✓ Correct + more props |
| CogniteFile | externalId (PK), name, mimeType | (CDM) externalId, name, mimeType | ✓ Correct |
| Reel | reelNumber (PK), productionDate, weight, asset (FK) | reelNumber (PK), productionDate, weight, width, diameter, status, gradeCode, asset (FK) | ✓ Correct |
| Roll | rollNumber (PK), width, diameter, reel (FK), **asset (FK)** | rollNumber (PK), width, diameter, reel (FK) | ❌ Roll has NO asset relation |
| Event | externalId (PK), eventType, sourceId, asset, reel, roll | externalId (PK), eventType, sourceId, sourceSystem, asset, reel, roll | ✓ Correct |
| RollQuality | externalId (PK), defectCode, isRejected, roll, asset | externalId (PK), defect, wasRollRejected, roll, asset | ⚠️ defectCode→defect, isRejected→wasRollRejected |

---

## Corrections Needed

### 1. Primary Keys
- **CDF nodes use `(space, externalId)`** as identifier, not `name` or `materialCode` for display. For Asset, the logical key is often `sapFunctionalLocation` or hierarchy path; `externalId` is the node ID.
- **Reel**: PK is `(space, externalId)`; `reelNumber` is a unique business key.
- **Roll**: Same — `rollNumber` is unique, but node ID is `externalId`.

### 2. Roll — Remove `relation asset (FK)`
- **MfgRoll container has NO `asset` relation.** Roll links only to Reel. Asset is reached via Reel → Asset.
- **Action:** Remove `relation asset` from the Roll box.

### 3. Material — No relation to Reel
- **Material has NO relations** to Reel, Roll, or Asset in mfg_core. It is reference/master data only.
- **Action:** Remove the "Material produces Reel" relationship from the diagram.

### 4. RollQuality property names
- Use `defect` (not `defectCode`) and `wasRollRejected` (not `isRejected`).

### 5. MfgTimeSeries ↔ Event
- **No direct relation** between MfgTimeSeries and Event. They connect through Asset (TimeSeries → assets → Asset; Event → asset → Asset).
- **Action:** Remove "MfgTimeSeries has Event" if shown as direct.

### 6. CogniteFile ↔ Event
- **No direct relation** between CogniteFile and Event in mfg_core.
- **Action:** Remove "CogniteFile events" if shown as direct.

---

## Validated Entity List (for corrected diagram)

### Asset
- `externalId` (PK), `name`, `description`, `assetType`, `sapFunctionalLocation`, `plantCode`
- `parent` (FK), `children` (FK reverse)

### Material
- `materialCode` (PK), `materialDescription`, `materialType`, `materialGroup`, `unitOfMeasure`, `isActive`
- No relations to other mfg_core entities

### MfgTimeSeries
- `externalId` (PK), `name`, `unit`, `measurementType`, `piTagName`, `timeSeries`
- `assets` (FK to Asset, from CDM)

### CogniteFile
- `externalId` (PK), `name`, `mimeType`
- `assets` (FK to Asset, from CDM)

### Reel
- `reelNumber` (PK), `productionDate`, `weight`, `width`, `diameter`, `status`, `gradeCode`
- `asset` (FK)

### Roll
- `rollNumber` (PK), `width`, `diameter`, `weight`, `status`, `qualityGrade`, `cutDate`
- `reel` (FK) — **no asset**

### Event
- `externalId` (PK), `eventType`, `eventSubtype`, `sourceId`, `sourceSystem`
- `asset` (FK), `reel` (FK), `roll` (FK)

### RollQuality
- `externalId` (PK), `defect`, `wasRollRejected`, `reportDate`, `reportedBy`
- `roll` (FK), `asset` (FK)

---

## Validated Relationships

| From | To | Property | Valid |
|------|-----|----------|-------|
| Asset | MfgTimeSeries | timeSeries (reverse) | ✓ |
| Asset | CogniteFile | files (reverse) | ✓ |
| Asset | Reel | reels (reverse) | ✓ |
| Asset | Event | events (reverse) | ✓ |
| Asset | RollQuality | qualityReports (reverse) | ✓ |
| Reel | Asset | asset | ✓ |
| Reel | Roll | rolls (reverse) | ✓ |
| Roll | Reel | reel | ✓ |
| Roll | RollQuality | qualityResults (reverse) | ✓ |
| Event | Asset, Reel, Roll | asset, reel, roll | ✓ |
| RollQuality | Roll, Asset | roll, asset | ✓ |
| Material | Reel | — | ❌ No relation |
| MfgTimeSeries | Event | — | ❌ No direct relation |
| CogniteFile | Event | — | ❌ No direct relation |
| Roll | Asset | — | ❌ No relation |

---

## Text for explanation box

Use this alongside the corrected diagram:

> **Asset** — Hierarchy of sites, areas, and equipment. Each asset has `externalId` (e.g. `floc:0769-06-PM1`), `name`, `description`, `assetType`, `sapFunctionalLocation`, and `plantCode`. The `parent` and `children` relations form the tree. Assets are the anchor for time series, files, reels, events, and quality reports.
>
> **Reel** — A paper reel (batch) produced at a winder. Key properties: `reelNumber`, `productionDate`, `weight`, `width`, `gradeCode`, `status`. Linked to `asset` (where it was produced). Reels are the parent unit for rolls.
>
> **Roll** — Individual roll cut from a reel. Key properties: `rollNumber`, `width`, `diameter`, `status`, `qualityGrade`, `cutDate`. Linked only to `reel` — to reach the asset, traverse Reel → Asset. No direct asset relation.
>
> **Event** — Work orders, PPV events, production milestones, and other occurrences. Relations: `asset` (where), `reel` (which reel), `roll` (which roll). Used for traceability and operational context.
>
> **RollQuality** — Quality inspection results for a roll. Key properties: `defect`, `wasRollRejected`, `reportDate`, `reportedBy`. Linked to `roll` and `asset` (where inspected).
>
> **Material** — SAP material master (grades, specs). Properties: `materialCode`, `materialDescription`, `materialType`, `materialGroup`, `unitOfMeasure`. Reference data only — no relations to Reel or Roll in mfg_core.
>
> **MfgTimeSeries** — Sensor and process data (PI tags). Linked to assets via CDM. No direct relation to Event.
>
> **CogniteFile** — Documents, images, PDFs. Linked to assets via CDM. No direct relation to Event.
