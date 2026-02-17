# ADR-001: ISA-95 Asset and Equipment Modeling Approach

## Status

**Accepted** - February 17, 2026

## Context

When implementing the Sylvamo data model, we needed to decide how to model Equipment within the asset hierarchy. This decision has significant implications for:

1. Navigation and discovery in CDF Fusion
2. Alignment with ISA-95 and Cognite CDM standards
3. Data relationships (RollQuality to Equipment to Asset)

### Research Conducted

We analyzed three authoritative sources:

#### 1. ISA-95 Standard

ISA-95 defines **two separate models**:

| ISA-95 Concept | Purpose | Key Characteristics |
|----------------|---------|---------------------|
| **Equipment** | Logical/functional roles | Hierarchical (Enterprise to Site to Area to Unit), stable over time |
| **Physical Asset** | Actual physical devices | Serial numbers, vendors, can be replaced without changing Equipment |

From ISA-95 8.2.1:
> "The ISA-95 Equipment Model is an abstract model that describes classes of **logical equipment**. The **physical equipment is defined by physical assets**. In the ISA-95 model, a logical device (equipment) usually does not change, but a physical device may change over time."

#### 2. Cognite Core Data Model (CDM)

Cognite CDM maps to ISA-95 with **inverted terminology**:

| ISA-95 Term | Cognite CDM Equivalent |
|-------------|------------------------|
| Equipment (logical hierarchy) | **CogniteAsset** |
| Physical Asset (physical device) | **CogniteEquipment** |

- CogniteAsset: Hierarchical with parent, children, path properties
- CogniteEquipment: Has asset relation, serialNumber, manufacturer

#### 3. Cognite QuickStart / Pump Example

The Pump Example extends CogniteAsset (not CogniteEquipment) for pumps.
This is the **QuickStart Pattern**: Model equipment-level items as Asset subtypes within the hierarchy.

## Decision

**We adopt the QuickStart Pattern (Asset subtypes) for Sylvamo.**

### Implementation

1. **Asset Hierarchy** follows ISA-95 Equipment hierarchy levels:
   - Level 1: Site (Eastover Mill, Sumter Converting)
   - Level 2: Area
   - Level 3: System
   - Level 4: SubSystem
   - Level 5: Unit
   - Level 6: EquipmentModule
   - Level 7+: Equipment (leaf nodes)

2. **assetType property** classifies assets by hierarchy level
3. **equipmentType property** identifies equipment category (Motor, Pump, Valve, etc.)
4. **No separate Equipment entity** - everything is in unified Asset hierarchy

### What This Means

| Question | Answer |
|----------|--------|
| Are Sheeters modeled as Equipment? | No - They are Asset nodes with assetType=Unit |
| Where are physical devices? | Asset nodes at level 7+ with assetType=Equipment |
| How many equipment items? | 33,072 assets with assetType=Equipment |
| Is this ISA-95 compliant? | Yes - Matches ISA-95 Equipment hierarchy (not Physical Asset) |

### When to Use CogniteEquipment

Use CogniteEquipment (separate entity) only if you need:
- Serial number tracking
- Manufacturer information
- Physical device replacement history
- Asset assignment tracking over time

Sylvamo does not currently require these capabilities.

## Consequences

### Benefits

1. **Unified hierarchy** - Single Asset tree for all navigation
2. **Simpler model** - No separate Equipment entity to manage
3. **ISA-95 aligned** - Follows logical Equipment hierarchy pattern
4. **QuickStart compatible** - Matches Cognite recommended approach
5. **InField ready** - Industrial Tools work with Asset hierarchy

### Tradeoffs

1. **No physical asset tracking** - Cannot track serial numbers or replacements
2. **Equipment sidebar gone** - Users filter by assetType=Equipment instead
3. **Future migration** - If physical tracking needed, will require adding CogniteEquipment

### Data Model Impact

Before (proposed separate Equipment):
- Asset (45K) + Equipment (4) = Two entities

After (QuickStart pattern):
- Asset (45K, including 33K with assetType=Equipment) = One unified entity

## References

- **Jira**: [SVQS-243](https://cognitedata.atlassian.net/browse/SVQS-243)
- **ISA-95 Equipment Model**: https://reference.opcfoundation.org/ISA-95/v100/docs/8.2
- **ISA-95 Physical Asset Model**: https://reference.opcfoundation.org/ISA-95/v100/docs/8.3
- **Cognite CDM Reference**: https://docs.cognite.com/cdf/dm/dm_reference/dm_core_data_model
- **Cognite Asset Hierarchy Guide**: https://docs.cognite.com/cdf/dm/dm_guides/dm_cdm_build_asset_hierarchy
- **Cognite Pump Example**: https://docs.cognite.com/cdf/deploy/cdf_toolkit/references/packages/example_pump

## Terminology Mapping

| ISA-95 Term | Cognite CDM | Sylvamo Implementation |
|-------------|-------------|------------------------|
| Equipment hierarchy (logical) | CogniteAsset | Asset view with assetType classification |
| Physical Asset (physical device) | CogniteEquipment | Not used (future consideration) |

---

*Decision documented: February 17, 2026*

## Additional References

### Sylvamo Project Documentation
- **Cognite ISA Extension & Sylvamo Alignment**: [COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/blob/main/docs/reference/data-model/COGNITE_ISA_EXTENSION_AND_SYLVAMO_ALIGNMENT.md)
  - Comprehensive alignment analysis with Johan Stabekk guidance (Jan 28, 2026)
  - Key Decision: "Use CDM Asset + Equipment instead of ISA Site/Unit for organizational hierarchy"
  - Deployed model details and entity mappings

### Cognite Reference Implementations
- **QuickStart Module Foundation**: [github.com/cognitedata/quickstart-module-foundation](https://github.com/cognitedata/quickstart-module-foundation)
  - Cognite's reference implementation for industrial data models
  - Demonstrates Asset hierarchy patterns for manufacturing
  
- **ISA Manufacturing Extension**: [github.com/cognitedata/library/modules/models/isa_manufacturing_extension](https://github.com/cognitedata/library/tree/main/modules/models/isa_manufacturing_extension)
  - Cognite's ISA-95/ISA-88 extension specification
  - Used as basis for Sylvamo data model design
