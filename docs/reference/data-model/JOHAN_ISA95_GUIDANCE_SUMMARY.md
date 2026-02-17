# Johan Stabekk's ISA-95 Guidance Summary

**Source:** ISA-95 & Sylvamo Data Model Alignment Transcript (Jan 28, 2026)  
**Participants:** Johan Stabekk (Cognite), Fernando Barsoba, Max Tollefsen  
**Duration:** ~48 min

---

## Executive Summary

Johan Stabekk, with 6 years of paper & pulp plant experience and 3.5 years at Cognite (including the International Paper quick start project), provided guidance on how to align Sylvamo's data model with ISA-95/ISA-88 standards while avoiding over-complication.

**Key Message:** Start simple with what fits, extend later. Use the Core Data Model (CDM) for organizational hierarchy and extend with ISA concepts only where they add value.

> **ADR-001 Update (Feb 2026):** Johan recommended Equipment as a separate CDM entity. We adopted the QuickStart pattern instead: Equipment is modeled as Asset nodes with `assetType='Equipment'` rather than a separate Equipment view. See [ADR-001](decisions/ADR-001-ASSET-EQUIPMENT.md).

---

## 1. ISA-95/ISA-88 Overview

### What Johan Said:
> "ISA 95 and 88 is kind of industry standard data models that are utilized by some companies... We internally in Cognite are trying to standardize a bit more on how we structure things. These are good buckets to use."

> "ISA 95 ISA 88 is two basically different ways to look at a plant. It's a standard for integrating ERP with MES basically."

### Key Insight:
- ISA standards are general industry standards, not specific to paper
- Companies are free to adopt them partially
- Cognite wants standardization for building reusable solutions

---

## 2. Hierarchy Approach - SIMPLIFY

### Johan's Strong Recommendation:
> "I think we can drop the concept of site and unit. We can rather say just what we have inside of the hierarchy in the core data model. Let's call it an **asset** and the asset then is the highest top level node in SAP which is then Eastover and then Sumpter."

> "Inside of ISA 95 you would want to create an enterprise type, a site type, an area type, a process cell type. **We don't want that. That's over complicating it.** We want an **asset type** and we want an **equipment type** and these two basically."

### Recommendation:
| ISA-95 Concept | Johan's Recommendation |
|----------------|------------------------|
| Enterprise | ❌ Skip |
| Site | ❌ Skip → Use **Asset** (top level = Eastover, Sumpter) |
| Area | ❌ Skip |
| Process Cell | ❌ Skip |
| Unit | ❌ Skip → Use **Equipment** |

### Why:
> "The reason we want that is because it fits the need we have and the functional location that they have in SAP fits the asset type."

---

## 3. Production Entities - What to Keep

### Johan's Recommended Entities:

| Entity | Description | Johan's Notes |
|--------|-------------|---------------|
| **Asset** | Top-level hierarchy from SAP | "Highest top level node in SAP - Eastover, Sumpter" |
| **Equipment** | Bottom of functional location | "Equipment that is being switched out on and off" |
| **Batch/Reel** | Production run on machine | "The thing that takes the entire reel of paper" |
| **Roll** | Cut from reel | "Gets cut into a roll" |
| **Package** | Set of rolls for delivery | "A package is a set of rolls being delivered from one plant to another" |
| **Product Definition** | Grade/specs | "Could be valuable" |
| **Quality Result** | Lab/scanner data | "Quality result is something we have" |
| **Material** | Material tracking | "Material lot we are tracking" |

### On Batch vs Reel:
> "A batch here isn't necessarily a reel... you can think about the entire grade run that you have as a batch which creates a lot of reels, which again creates a lot of rolls."

> "A batch is a reel and an extension of that batch is a roll."

---

## 4. Package Entity - CRITICAL Addition

### Johan's Specific Guidance:
> "Package we probably need to include because we need to track the package."

> "Package is a set of rolls that are being delivered from [one plant to another]."

### Production Flow:
```
Reel (on machine) → Cut into Rolls → Packaged → Shipped → Received at destination → Unpackaged → Roll → Sheeted
```

### Why Package Matters:
> "Here we're trying to go beyond what we have right here. We want to go further. At IP we are inside of the four walls of a production plant. Here we're going to go between two production plants."

---

## 5. Recipe Concept

### Johan's Explanation:
> "You can think about a recipe like you're trying to bake something. These are the ingredients I need to have. So if I'm producing this grade, these are the specs - the quality specs I need to have."

> "Recipe can come from bleaching, from other pieces on how much hydrogen peroxide they use to bleach the paper, how much they refine them, how long it goes through, what kappa measurement."

### In ISA Terms:
> "In ISA standard a recipe is the production order that goes to the machine and how you should operate to be able to get this quality or this batch execution."

### Recommendation:
> "Some pieces here are relevant for us, not everything. Let's like toss out some of this and keep what's necessary."

---

## 6. Proficy Quality Data - Records & Streams

### Johan's Strong Recommendation:
> "Records and streams is the best [for Proficy data]."

> "The prophecy data... it fits quite well [with records and streams]."

### Why NOT Time Series per Reel:
> "That would be like 200,000 time series. I don't even know how useful it is."

### How It Should Work:
> "Each data point [in these quality measurements] is a different reel."

> "It's better to have it as a **record that points the Proficy data to a reel** that was produced at that time."

> "We know that this reel had these quality measurements through Proficy and then you have other things that come through Omega as well."

### Immutable vs Mutable:
> "Based on the expected amount of data you can have it as immutable or mutable streams."

Max asked: "It would be immutable, wouldn't it? Because once the data point's read, why would we ever change it?"

Johan agreed: "Yes... then it's just a record and we have it there because we need to build things that access that record."

---

## 7. Sylvamo vs International Paper

### Key Distinction:
> "Sylvamo use cases are more in need of a good mapping of this than at IP."

> "What we learn here is more important for the IP team in the future than vice versa."

> "At IP we are inside of the four walls of a production plant. Here [Sylvamo] we're going to go **between two production plants**."

### What IP Did (as Reference):
> "At IP we made it time series because records and streams wasn't available. Data models would have been overflowing and events would work but it's not as nice."

---

## 8. Core Data Model Integration

### Johan's Approach:
> "Use the core data model structure that you have. It basically does the same. But we can take inspiration from [ISA]."

> "The core data model really supplies to the out-of-the-box pieces. That's why it's nice to have this asset, these different things."

> "The extensions that we do on roll, package, lab result or quality result etc. is [where we extend beyond CDM]."

### What's Already in CDM:
- Asset
- Equipment
- Time Series
- Work Order
- Files
- Notification

---

## 9. Guiding Principles

### On Simplicity:
> "We don't want to over complicate it but we don't want to make it so simple that we sit with something that doesn't give them anything."

> "Go with the simpler version that creates velocity over complex pieces."

> "Are we over complicating it for ourselves, Fernando?"

### On Functional Requirements:
> "Think about the functional requirements we have for the use cases that we're trying to support."

> "We need two sites. We need to be able to trace the roll and reel and package. We need to be able to select location - Sumpter or Eastover."

### On Scalability:
> "We start with what we know we can already define... and then we build from there."

Max: "We can always from that just scale the rest out, right? Like we're never... far away from the full ISA standard if we ever wanted to reach it?"

Johan: "Exactly."

---

## 10. Recommended Data Model Structure

Based on Johan's guidance, here's the recommended model:

### Core (from CDM):
```
Asset (Hierarchy)
├── Eastover Mill
│   ├── PM1 (Equipment)
│   ├── PM2 (Equipment)
│   ├── Winders (Equipment)
│   └── ...
└── Sumpter Facility
    ├── Sheeters (Equipment)
    └── ...
```

### ISA Extensions (Custom):
```
ProductDefinition
├── Grades, specs, quality targets

Batch/Reel
├── Production run on machine
├── Links to ProductDefinition
└── Links to Equipment

Roll
├── Cut from Reel
├── Quality results
└── Belongs to Package

Package
├── Set of Rolls
├── Source Plant
├── Destination Plant
└── Tracking info

QualityResult
├── Links to Reel or Roll
├── Test results
└── Source (Proficy, Omega, etc.)
```

### Data Types:
```
Time Series → Equipment sensors (continuous)
Records & Streams → Proficy quality data (per-reel readings)
```

---

## 11. Next Steps (Johan's Recommendations)

1. **Document Point of View**
   > "Let's actually have a point of view and document it and then we can discuss over it."

2. **Build Visual Diagram**
   > "Build up in Miro or similar... where you have a visual view of asset connects to files, connects to work orders, connects to equipment... and then how it connects to time series."

3. **Make it Sylvamo-Specific**
   > "That way we take the pieces that we have here but make them Sylvamo specific. It's easier then to talk with Sylvamo about what these concepts are."

4. **Get Feedback**
   > "Show [Sylvamo] this is how we think. Is that correct? Give us feedback. And then we can either challenge them or say 'Yeah, that's a good point.'"

5. **Root in Standards**
   > "We root this in a data model. We root this in a standard to some degree... think about scalability."

---

## Summary of What to Implement

### ✅ Keep/Implement:
- **Asset** (CDM) - For hierarchy (Eastover, Sumpter)
- **Equipment** (CDM) - For machines (PM1, PM2, Winders)
- **ProductDefinition** (ISA) - For grades/specs
- **Batch/Reel** (ISA) - For production runs
- **Roll** (Custom) - For cut products
- **Package** (Custom) - For inter-plant tracking
- **QualityResult** (ISA) - For quality data
- **Records & Streams** - For Proficy data

### ❌ Skip (for now):
- Enterprise, Site, Area, Process Cell, Unit (ISA hierarchy)
- Recipe/Procedure (complex ISA concepts)
- Full procedural model

### 🔄 Consider Later:
- Recipe when production order integration is needed
- Full ISA hierarchy if complexity is justified
- Material lot vs Roll distinction

---

*Document created: Jan 28, 2026*
