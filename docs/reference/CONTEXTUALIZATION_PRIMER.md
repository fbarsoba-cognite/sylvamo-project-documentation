# Contextualization Primer - Best Practices & Reference Guide

> **Source:** Contextualization Primer session led by Darren Downtain, February 6, 2026.
> **Audience:** Data Engineers (DEs), US Advisors (USAs), and implementation teams.
> **Purpose:** Provide a single reference for contextualization concepts, architectural guidance, pipeline design, and best practices applicable across all Cognite implementations.

---

## Table of Contents

1. [What Is Contextualization?](#1-what-is-contextualization)
2. [Data Model Layering: Source, Enterprise, Solution](#2-data-model-layering-source-enterprise-solution)
3. [Asset Tags vs Equipment](#3-asset-tags-vs-equipment)
4. [Entity Matching](#4-entity-matching)
5. [Key Extraction and Alias Generation Pipeline](#5-key-extraction-and-alias-generation-pipeline)
6. [P&ID / File Annotation Pipeline](#6-pid--file-annotation-pipeline)
7. [Confidence Scoring and Validation](#7-confidence-scoring-and-validation)
8. [OCR and Text Extraction Layering](#8-ocr-and-text-extraction-layering)
9. [Large File Handling](#9-large-file-handling)
10. [Multi-Site Expansion Strategy](#10-multi-site-expansion-strategy)
11. [Three-Tier Environment Strategy](#11-three-tier-environment-strategy)
12. [Toolkit Module Guidance](#12-toolkit-module-guidance)
13. [Quick Reference: Do's and Don'ts](#13-quick-reference-dos-and-donts)

---

## 1. What Is Contextualization?

Contextualization is the process of taking siloed data from multiple systems (SAP, historians, document control systems, SharePoint, etc.) and tying it together into a unified, easily accessible knowledge graph that drives value.

**Value is subjective.** For some customers, unifying their data is the value. For others, value means demonstrable savings -- shaving time and money off processes or surfacing new insights that drive financial returns. Our implementation, however, is more standardized ("cookie-cutter") than we often assume.

**Contextualization is not a single activity.** It is commonly used as a blanket term, but it encompasses several discrete processes:

- **File/document annotation** -- detecting tags and references within P&ID content and creating Cognite annotations with bounding boxes and occurrence counts.
- **Entity matching** -- using attributes on individual rows of data to establish relationships between entities.
- **Direct linking via transformations** -- deterministic joins using cleaned keys and aliases.
- **Diagram detection** -- scanning drawings for known asset aliases and pattern-based tag discovery.

Each of these produces different entity types in CDF (annotations vs. nodes/edges) and should be understood as separate stages, not one monolithic step.

---

## 2. Data Model Layering: Source, Enterprise, Solution

Every implementation should enforce a clear separation between three model layers:

```
Source Model --> Enterprise Model --> Solution Model
(raw, siloed)    (gold layer,         (specific views,
                  knowledge graph)     standards)
```

### Source Model

- Data as it arrives from each individual system (SAP, historian, document control, etc.).
- Still disconnected and independent.
- Stored in CDF Raw or equivalent staging.

### Enterprise Model

- The **gold layer** -- the unified knowledge graph.
- Where all cleanup, normalization, and standardization happens during transformation from raw.
- Where **all** contextualization and association creation occurs.
- Candidate key extraction: identify actual key values from asset names (e.g., strip descriptive text, extract tag numbers).
- Alias generation: cleaned, normalized values written to the `alias` field.
- Should be **generic and reusable** -- not dictated by any single standard or solution requirement.

### Solution Model

- Specific views or representations of enterprise data tailored to a standard (e.g., ISA-95, UBL) or a particular application.
- Built on top of the enterprise model, never replacing it.
- Example: a customer wants ISA-95 compliance. Use ISA-95 to *inform* enterprise model structure, but build the ISA-95 representation as a solution model view. If the customer later needs UBL representation as well, both solution models can draw from the same enterprise model.

### Key Principle

> Do not force solution-level requirements into the enterprise model. The enterprise model should be flexible enough to satisfy multiple downstream solution models without being locked to any single standard.

---

## 3. Asset Tags vs Equipment

This distinction is critical and frequently misunderstood in implementations.

### Asset Tag (Conceptual / Design-Time)

- Represents the **conceptual location** where equipment is installed -- the "socket."
- Created at design time, before physical equipment exists.
- **Static and consistent** throughout the facility's lifetime (unless the design itself changes).
- All design documentation (P&IDs, data sheets) references the asset tag, not the equipment.
- Example: `P-1234` represents "there is a pump at this location."

### Equipment (Physical Instance)

- The **physical hardware** -- the "light bulb."
- Has a specific serial number, model number, manufacturer, purchase date, installation date.
- **Can be swapped out** -- pumps fail, get refurbished, get replaced.
- Multiple pieces of equipment may occupy the same asset tag location over time.

### The Socket and Light Bulb Analogy

When a light bulb burns out, you replace the bulb, not the socket. Similarly, when a pump is replaced, the asset tag (`P-1234`) remains. All documentation, time series, and contextualization tied to the asset tag persist without rework. Only the equipment record (serial number) changes.

### Default Rule for Contextualization

> **Always contextualize against the asset tag, not the equipment.** Equipment associations should only be created when you have specific instance data (purchase orders, work orders, serial number information) and need to maintain that specificity.

### SAP Functional Location Hierarchy Hydration

There are two common SAP structures, and both must result in the same asset hierarchy:

**Scenario A -- SAP has full hierarchy to tag level:**
- Functional locations include the tag representation at the leaf level.
- Equipment is mapped to the leaf level functional location.
- Hydrate assets from functional locations; create separate equipment entities with associations.

**Scenario B -- SAP stops at system level:**
- Functional locations go down to the system level only.
- Equipment and instrumentation are listed directly under the system.
- Hydrate the upper asset hierarchy from functional locations, then use equipment data to populate the leaf-level asset tags.
- Equipment still goes to equipment entities with an association.

**In both cases, the result is the same:** asset hierarchy always has a tag representation at the leaf level. The stage between raw and the enterprise model is where you rectify these structural differences -- not downstream with case logic.

### CDM Gap: Temporal Equipment Tracking

The current CDM does not model the temporal relationship of which equipment was installed at which asset tag location and when. This means:

- No way to track installation history (which serial numbers served at `P-101A` over time).
- Cannot calculate operational hours per physical equipment across location changes.
- Workaround: derive from work orders for installation/repair, but this is incomplete.
- This is a known gap being considered for the foundational model.

---

## 4. Entity Matching

### How It Works

Entity matching uses **tokenization** to break values into comparable units:

1. Split on delimiters (dashes, underscores, spaces, etc.).
2. If no delimiters, split at alpha-numeric boundaries.
3. Each segment becomes a token.
4. Configure a minimum token match count (e.g., 2 or 3 tokens must match).
5. Calculate a confidence score for the match quality.

### Two Models

| Model | How It Works | Weakness |
|---|---|---|
| **Supervised** | Trained on known matches; can be dialed in with effort | Overfits if data is too clean -- if aliases are already exact matches, the model has no differentiation; any small deviation (dash vs. underscore) gets rejected |
| **Unsupervised** | No training required; applied on quick starts | Too generous -- produces too many false positives ("garbage matches") |

### Built-In Handling

Entity matching does handle some normalization automatically:

- Leading zero removal (strips from both sides before comparison).
- Token count flexibility (e.g., asset has 3 tokens, P&ID reference has 2 -- a 2-token match requirement can still succeed by ignoring the prefix).

### Reality Check

> In practice, **nobody ends up using entity matching in its current state** for production contextualization. Implementations consistently converge on: key extraction + alias generation + direct comparison (transformation-based linking) + diagram detection for files.

The confidence scoring from entity matching is not accurate enough to allow reliable validation of results. The typical outcome is "if it matched, put it in front of someone until they complain."

---

## 5. Key Extraction and Alias Generation Pipeline

This is arguably the most critical pipeline in the entire contextualization workflow.

### Core Principle

> **Every entity you contextualize against must go through key extraction and aliasing.** This applies to assets, files, time series -- anything involved in matching or association creation.

### Two Outputs

For any given row of data, the pipeline produces:

1. **Candidate Key / Alias** -- a value representative of that specific entity.
   - Example: a file's candidate key might be extracted from its filename (minus extension and path).
   - An asset's candidate key is the cleaned tag number.
   - Written to the `alias` field.

2. **Foreign Key References** -- occurrences of references to other entities found within the data.
   - Example: a file's description field contains a pump tag number -- extract that as a foreign key reference for entity matching or direct linking.
   - Feeds into the contextualization phase for relationship creation.

### Alias Generation Rules

The pipeline applies configurable rules to transform raw values into normalized aliases:

| Rule | Example |
|---|---|
| **Type expansion** | `P` --> `pump`, `FV` --> `flow valve` (semantic aliases) |
| **Separator standardization** | `P-0001`, `P_0001`, `P 0001` --> normalized form |
| **Leading zero removal** | `P-00001` --> `P-1` |
| **Fixed-width parsing** | Extract specific character ranges from structured identifiers |
| **Regex extraction** | Apply patterns to pull candidate keys from complex strings |
| **Format cleanup** | Remove file extensions, path prefixes, extraneous text |

### Architecture: Separate Pipeline, Not In Transformations

This is a firm best practice:

> **Alias generation must be a separate pipeline, not embedded in data transformations.** This is the single most important architectural decision for maintainability during multi-site expansion.

**Why?** Consider the expansion scenario:

1. Site A uses `sort_field` from SAP as the asset name. Tags follow `P-00001` format.
2. Site B uses a different SAP field. Tags follow `PMP_1` format.
3. Site C has yet another convention.

If alias generation is inside your transformation SQL:
- You end up with `CASE WHEN site = 'A' THEN ... WHEN site = 'B' THEN ...` logic.
- Every new site adds more branches.
- The transformation becomes unmaintainable.

If alias generation is a separate pipeline:
- Transformations do a simple, uniform hydration from raw to enterprise model.
- The alias pipeline picks up new/changed entities and applies site-specific rules through configuration.
- Downstream processes (contextualization, annotation) always consume the `alias` field -- no case logic needed.

### Field Usage Convention

| Field | Contains | Used For |
|---|---|---|
| `name` | Original value from source system (as-is) | Display, traceability |
| `alias` | Cleaned, normalized value from alias pipeline | All downstream contextualization and matching |

### Pipeline Behavior

- Runs after enterprise model hydration (not during).
- Uses a state store to track which entities have been added or changed since the last run.
- Reprocesses only changed entities.
- Produces consistent aliasing regardless of source system variation.

---

## 6. P&ID / File Annotation Pipeline

The file annotation pipeline has two processes, currently bundled together in the **File Annotation** deployment pack (accelerator).

### Process 1: Diagram Detection (Known Asset Matching)

**Input:**
- A scoped subset of files (e.g., all P&IDs for Site A, Area 1).
- A corresponding scoped subset of asset aliases.

**Process:**
1. Pass the asset alias list into the diagram detect endpoint.
2. The endpoint scans each document for occurrences of those alias values.
3. Returns: locations found (bounding boxes), number of occurrences, confidence score per match.

**Scoping is critical:**
- If asset tag `P-1234` exists at both Site A and Site B, you cannot contextualize all documents against all assets.
- You would incorrectly link Site A documents to Site B assets (and vice versa).
- Define how to isolate and segment files, group them, and pair each group with its corresponding asset subset.

This process also runs for **file-to-file links** -- detecting references to other documents within P&IDs.

### Process 2: Pattern Mode (Unknown Tag Discovery)

**Input:**
- The same asset alias list used in diagram detection.

**Process:**
1. Analyze the aliases to determine naming patterns (e.g., 1-3 alpha characters followed by 3-4 digits).
2. Generate pattern templates from those patterns.
3. Scan the same documents for **anything** matching those patterns, regardless of whether it exists in the asset hierarchy.

**Why this matters:**
- Instrumentation is rarely in SAP but appears on P&IDs.
- Pattern mode discovers tags that exist on drawings but have no asset hierarchy match.
- These become the **unmatched tag list**.

### Contextualization Quality Scoring

Pattern mode enables a quality metric:

```
Contextualization Score = Matched Tags / Total Detected Tags
```

- **Denominator:** total tags detected via pattern mode.
- **Numerator:** tags successfully matched to known assets via diagram detection.
- This score is really measuring **how representative the asset hierarchy is** of what exists in the documentation.

**Continuous improvement loop:**
1. Run annotation pipeline.
2. Review unmatched tags -- are patterns missing? (e.g., need a 4-alpha + 3-digit pattern).
3. Add patterns, rerun, detect more tags, improve denominator accuracy.
4. Feed unmatched tag list back to customer for action.

### Virtual Tags

For detected tags with no asset hierarchy match:

- Present the unmatched list to the customer: "Do you want to add these to SAP?"
- For tags the customer does **not** want in SAP, create **virtual tags** -- entities that exist only in CDF.
- Virtual tags allow contextualization of time series and documents to these detected values.
- Used extensively on Celanese for time series association.

### Reverse Use Case: Documentation as Source of Truth

Some customers (e.g., LyondellBasell) know their SAP data is poor and want to use P&ID detection as the **starting point** for building their asset hierarchy:

1. Run pattern mode against P&IDs.
2. Extract all detected tags.
3. Use document metadata (system, unit, site) to populate hierarchy structure.
4. Customer corrects/validates and feeds back into SAP.
5. Regulatory documents (P&IDs) are often the most up-to-date data source.

---

## 7. Confidence Scoring and Validation

### Do Not Trust Built-In Confidence Scoring

The confidence scores returned by entity matching and diagram detection are not reliable enough for automated acceptance. Always implement custom validation.

### Custom Scoring Approach (Recommended)

Build a progressive scoring algorithm with penalties:

| Match Type | Score | Rationale |
|---|---|---|
| Exact match (`equals`) | 100% | No ambiguity |
| Starts-with / ends-with match | ~95% | Minor variation, still high confidence |
| Contains match (with context) | ~85-90% | Likely correct but needs structural validation |
| Token-ratio match (e.g., 3/10 tokens) | Calculated % | Usually low; most of these get rejected |

The more complex the logic required to achieve a match, the more penalties are applied.

### Two-Threshold System

Define two thresholds to categorize results into three buckets:

| Range | Action | Representation in CDF |
|---|---|---|
| **Below lower threshold** (e.g., < 70%) | Reject / blacklist | Not created |
| **Between thresholds** (e.g., 70-85%) | Recommended -- requires manual approval | Created as suggested annotation |
| **Above upper threshold** (e.g., > 85%) | Auto-approve | Created as approved annotation |

### Blacklisting

Maintain a blacklist of known overly generic terms that cause false-positive matches:

- Single-token matches on common words: "pump," "valve," "tank," "flow."
- If minimum token match is set to 1, a match on "pump" contextualizes every pump document to every pump asset.
- Add these to the blacklist or increase minimum token requirements.

### Validation Best Practices

- **Accuracy over quantity.** Always prioritize match quality.
- Start at 100% confidence threshold (only exact matches), then progressively relax.
- Validate results before presenting to the customer.
- Document the acceptance criteria: "We accept matches above X% and reject below Y%."
- When no formal acceptance criteria exist, starting at 100% and walking down is a safe default.

### File Versioning Considerations

A historical pain point: when a new version of a file is ingested without proper version tracking:

- All previous annotations (approved, rejected, manually added) are lost.
- Customer has to re-validate everything.
- With revision tracking (now available), there is an opportunity to carry over previous decisions -- but this requires validation:
  - Check if the bounding box location still contains the same value in the new version.
  - If yes, carry over the annotation and its approval status.
  - If no (content moved/changed), discard and re-annotate.

---

## 8. OCR and Text Extraction Layering

The system uses a layered approach for extracting text from documents:

### Layer 1: Embedded Text (Highest Accuracy)

- Available when a PDF was derived from a DWG file and renditioned with embedded text or overlays.
- The text is exact -- no interpretation or inference required.
- Position information (where text sits on the document) is also available.
- **Always preferred** when available.

### Layer 2: Text Overlays

- PDF text layers that were added as overlays.
- Generally accurate but may have positioning issues.

### Layer 3: OCR Fallback (Lowest Accuracy)

- Used when the document is essentially an image: scanned document, screenshot, print-to-PDF without text embedding, or handwritten P&IDs.
- Introduces potential errors:
  - Character confusion: `B`, `O`, `D` may be misread as each other.
  - Artifacts from scanning cause phantom characters.
  - Handwriting recognition is inherently unreliable.

### Critical Warning for OCR Scenarios

> When OCR is the text extraction method, it becomes **even more important** to validate the output of pattern detection before creating assets. A single misread character (`B-1234` read as `O-1234`) could create phantom assets that propagate through the knowledge graph.

---

## 9. Large File Handling

### The Problem

Engineering companies (EPCM firms) commonly deliver bundled documents at the end of engagements -- single PDFs containing thousands of pages that aggregate all data sheets, P&IDs, operating manuals, and purchase order documentation.

### Why Large Files Are Problematic

1. **System performance:** Anything over 50 pages becomes difficult to process. Memory issues are common with very large files.
2. **Meaningless contextualization:** A single document linked to everything provides no value. By one degree of separation, everything becomes related to everything -- this is not an insight.
3. **Processing failures:** Very large files may fail annotation entirely, bringing down the processing queue.

### Best Practices

1. **Ask the customer first.** "Do you have individual representations of these documents?" The answer is often yes -- they just gave you the bundle because it was easier.
2. **If individual files are unavailable:**
   - Check for an embedded index/table of contents in the PDF.
   - Use the index to split the document programmatically (e.g., pages 1-20 are P&IDs, pages 21-40 are data sheets).
   - LLMs can assist with intelligent splitting when no index exists.
3. **Default rule:** Do not add a `to_annotate` flag to files exceeding the size threshold. Flag them for manual review and splitting.
4. **Watch for duplicates:** If the customer provides both individual files and the bundled version, you now have two instances of the same content. Never process the bundled version when individual representations are available.

---

## 10. Multi-Site Expansion Strategy

### The Core Challenge

Variability exists not just between companies but **within a single company's CDF implementation**. A single project may span 50 sites, each with different:

- Tag naming conventions.
- SAP configurations (which fields populate what).
- Equipment vs. functional location hierarchy structures.
- Data quality levels.

### Quick Start Foundation

> Take as few shortcuts as possible during the quick start. Every shortcut taken during the initial site implementation becomes technical debt during expansion.

Specifically:
- Set up proper group configurations and spaces from day one to support multi-site data segmentation.
- Ensure row-level security can be applied when new sites are added.
- Build reusable, generic pipelines -- not site-specific monoliths.

### Single Responsibility Principle

Each pipeline stage should have one job:

| Stage | Responsibility |
|---|---|
| **Ingestion** | Pull data from source systems into CDF Raw. Potentially hydrate enterprise model. Independent activity. |
| **Digestion** | Key extraction and alias generation. Make data usable. Separate pipeline. |
| **Contextualization** | Diagram detection, entity matching, direct linking, annotation. Consumes aliases. |
| **Validation** | Confidence scoring, blacklisting, approval workflows. |

### Avoid Case Logic in Transformations

This is the most common anti-pattern in multi-site implementations:

```sql
-- DON'T DO THIS
CASE
  WHEN site = 'ClearLake' THEN extract_alias_v1(sort_field)
  WHEN site = 'Houston' THEN extract_alias_v2(tag_name)
  WHEN site = 'Richmond' THEN extract_alias_v3(equipment_id)
END AS alias
```

Instead, each site's data flows through the **same pipeline** with **site-specific configuration** (not code branches). The alias generation pipeline handles the variation through configurable rules, not conditional SQL.

---

## 11. Three-Tier Environment Strategy

### The Three Environments

| Environment | Purpose | Rules |
|---|---|---|
| **Development** | "Wild west" -- experimentation, prototyping, breaking things | Can be a catastrophe; no one cares |
| **Testing** | Validation of packaged deployments | Same CI/CD process as production; no "god mode" |
| **Production** | Customer-facing, locked down | Only promoted after testing validation |

### Key Rules

1. **Start with all three environments from the quick start.** It is dramatically harder to add a test environment later than to start with it. Teams that try to add testing later can never get it to accurately represent production.

2. **What deploys to testing must be the same artifact that promotes to production.** No manual tweaks, no ad-hoc changes, no "just this once" direct modifications.

3. **No god mode for testing.** No one should be able to bypass the CI/CD process to make changes directly in the test environment. Testing must have the same deployment rigor as production.

4. **Use configuration, not code, for environment differences.** If the test environment pulls from a different data source (e.g., a customer's test SAP instance), manage that through configuration files -- not by including/excluding modules in your toolkit deployment commands.

5. **Test data should be representative of production.** Customers validate against real data. If you give them test data, they will say "this isn't the data I know, so it's wrong." Options for managing data volume:
   - Use a subset of time series data (e.g., last 6 months instead of 30 years).
   - Implement a representative site subset (not all 50 sites).
   - If applying filters for test data, ensure there is a documented step where those filters are removed before production promotion.

### Warning: Filter Management

If you reduce data volume in testing via filters:

- Document every filter applied.
- Have an explicit promotion step that removes or adjusts filters.
- Verify that the filter removal doesn't introduce risk (e.g., accidentally promoting filtered-down data to production).
- Best practice: manage filters through configuration, not hardcoded in transformation logic.

---

## 12. Toolkit Module Guidance

### File Annotation Module (Recommended)

- **Always use the File Annotation module**, even for demos.
- Provides the contextualization quality scoring capability (pattern mode + match ratio).
- Customers always ask "how good is our contextualization?" -- this module can answer that question.
- Previous approach ("we contextualized 900 of 1,000 documents") was insufficient -- customers want quality, not just coverage.

### P&ID Annotation Module (Avoid)

- Legacy module without the quality scoring and pattern mode capabilities.
- Do not use unless there is a specific, justified reason.

### Entity Matching Module

- Has two parts:
  1. Sending data to the entity matching endpoint (matching process).
  2. Writing aliases (alias generation -- but this implementation is rigid and less robust than the dedicated alias pipeline).
- The alias-writing component produces poor results for varied data structures.
- Prefer the dedicated key extraction and alias generation pipeline instead.

---

## 13. Quick Reference: Do's and Don'ts

### Do

- Separate your data model into Source, Enterprise, and Solution layers.
- Always contextualize against the **asset tag**, not equipment (unless you have specific serial number data).
- Build a **separate alias generation pipeline** -- never embed alias logic in transformations.
- Populate `name` with the source value; populate `alias` with the cleaned/normalized value.
- Scope file annotation by site/area -- pair file subsets with corresponding asset subsets.
- Implement custom confidence scoring with a two-threshold system (reject / review / approve).
- Maintain a blacklist of overly generic terms.
- Validate all results before presenting to the customer.
- Ask the customer for individual document files before trying to process bundled PDFs.
- Start with three environments (dev/test/prod) from day one.
- Use configuration (not code) to manage environment differences.
- Use the **File Annotation** module (not P&ID Annotation).
- Prioritize **accuracy over quantity** in all matching.

### Don't

- Don't force solution-level requirements (ISA-95, UBL) into the enterprise model.
- Don't use entity matching as your primary contextualization method -- it is unreliable in production.
- Don't put alias generation logic inside transformations -- this creates unmaintainable case logic during expansion.
- Don't contextualize all documents against the full asset hierarchy without site/area scoping.
- Don't process documents over 50 pages without splitting them first.
- Don't trust built-in confidence scores without custom validation.
- Don't auto-approve matches below your confidence threshold just to show quantity.
- Don't try to add a test environment after the fact -- start with it.
- Don't make direct changes to the test environment outside the CI/CD process.
- Don't create bespoke, one-off implementations as your first instinct -- start with the standard, deviate only when justified.

---

## Appendix: Contextualization Pipeline Flow

The full contextualization pipeline, from data ingestion through validated annotations:

```
Ingestion Phase
  |
  v
[Source Systems] --> [CDF Raw] --> [Enterprise Model Hydration]
                                         |
                                         v
                                   Digestion Phase
                                         |
                                         v
                              [Key Extraction Pipeline]
                                    /            \
                                   v              v
                          [Candidate Keys/    [Foreign Key
                           Aliases]            References]
                                   \              /
                                    v            v
                              Contextualization Phase
                                         |
                       +-----------------+-----------------+
                       |                 |                 |
                       v                 v                 v
                [Diagram          [Entity            [Direct Linking
                 Detection]        Matching]          via Transforms]
                       |                 |                 |
                       v                 v                 v
                              Validation Phase
                                         |
                       +-----------------+-----------------+
                       |                 |                 |
                       v                 v                 v
                [Confidence       [Blacklist        [Manual Review
                 Scoring]          Filtering]        Queue]
                                         |
                                         v
                              [Approved Annotations / Edges]
                                         |
                                         v
                              [Knowledge Graph (Enterprise Model)]
```

---

*Last updated: February 7, 2026*
