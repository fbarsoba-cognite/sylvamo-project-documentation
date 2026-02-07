# Contextualization Gap Analysis: Sylvamo Implementation vs Best Practices

> **Date:** February 7, 2026
> **Reference:** [Contextualization Primer - Best Practices](CONTEXTUALIZATION_PRIMER.md) (Darren Downtain, Feb 6, 2026)
> **Scope:** All P&ID and file contextualization work performed on the Sylvamo project
> **Audience:** Fernando Barsoba, Max, Santiago, Arvan, and the Sylvamo delivery team

---

## Executive Summary

This document compares the Sylvamo contextualization implementation against the best practices established in the Contextualization Primer. Each of the 12 best practice areas is evaluated with a status of **Aligned**, **Partial**, or **Gap**, along with specific evidence from the codebase and actionable recommendations.

### Overall Alignment Scorecard

| # | Best Practice Area | Status | Priority |
|---|---|---|---|
| 1 | Data Model Layering | Partial | Medium |
| 2 | Asset Tags vs Equipment | Partial | Medium |
| 3 | Entity Matching | Partial (Correct Direction) | Low |
| 4 | Key Extraction & Alias Generation | **Gap - Critical** | **P0** |
| 5 | P&ID / File Annotation Pipeline | **Gap - Significant** | **P0** |
| 6 | Confidence Scoring & Validation | Partial | P1 |
| 7 | OCR & Text Extraction Layering | Aligned (implicit) | Low |
| 8 | Large File Handling | **Gap** | P2 |
| 9 | Multi-Site Expansion Strategy | **Gap** | P1 |
| 10 | Three-Tier Environment Strategy | **Gap** | P1 |
| 11 | Toolkit Module Guidance | **Gap** | P1 |
| 12 | Files Transformation & Asset Relationships | **Gap** | P1 |

**Top 3 Findings:**

1. **No alias generation pipeline exists.** `sortField` is used as-is from SAP RAW without cleanup, normalization, or alias creation. This is the single most critical gap and will block scalable multi-site contextualization.
2. **Pattern Mode is completely missing.** We run Diagram Detection (known asset matching) but have no unknown tag discovery, no contextualization quality scoring, and no virtual tag creation.
3. **Confidence scoring relies on Diagrams API defaults** with a very permissive 0.20 threshold. No custom scoring, no two-threshold system, no blacklisting.

---

## Detailed Gap Analysis

---

### 1. Data Model Layering (Source -> Enterprise -> Solution)

**Best Practice (Primer):**
- Three distinct layers: Source Model (raw, siloed), Enterprise Model (gold layer, knowledge graph), Solution Model (specific views/standards).
- Enterprise model is where all cleanup, normalization, and contextualization occurs.
- Candidate key extraction and alias generation happen during the transformation from source to enterprise.

**What We Implemented:**

The asset transformation pulls from RAW tables into the enterprise model:

```14:68:sylvamo/modules/mfg_core/transformations/populate_Asset.Transformation.sql
-- Step 1a: Create Eastover root node (floc:0769)
SELECT
    'floc:0769' as externalId,
    // ... root node creation ...

-- Step 2a: Populate Eastover assets from RAW table with hierarchy
SELECT
    concat('floc:', cast(`functional_location` as STRING)) as externalId,
    // ...
    cast(`sort_field` as STRING) as sortField,
    // ...
FROM `raw_ext_sap`.`sap_floc_eastover`
```

**Status: Partial**

| What's Working | What's Missing |
|---|---|
| Source-to-Enterprise flow exists (RAW -> `sylvamo_mfg_core_schema.Asset`) | `sortField` is passed through as-is -- no cleanup or normalization |
| Hierarchy is correctly derived (parent from FLOC segments) | No candidate key extraction during transformation |
| Root nodes properly created for both sites | No `alias` field populated -- primer says this is mandatory |
| No solution model layer, but none needed yet | Enterprise model does not represent a "gold layer" for matching purposes |

**Recommendation:**
- The transformation itself does not need alias logic (the primer explicitly says alias generation should be a **separate pipeline**). However, the enterprise model should have an `alias` field that a downstream pipeline populates.
- Ensure the `MfgAsset` container includes an `alias` property if it does not already.

---

### 2. Asset Tags vs Equipment

**Best Practice (Primer):**
- Asset tag = conceptual "socket" (static, design-time). Equipment = physical "light bulb" (serial number, swappable).
- **Always contextualize against the asset tag**, not equipment.
- Equipment records should exist for serial-number-level associations (work orders, purchase orders).
- SAP functional location hierarchy -> asset tags; equipment entities linked separately.

**What We Implemented:**

- All contextualization targets functional location assets (`floc:*` external IDs), which is the correct approach -- these represent asset tags, not physical equipment.
- The data model defines equipment types:
  - `sylvamo/modules/mfg_extended/data_modeling/containers/MfgEquipment.Container.yaml`
  - `sylvamo/modules/mfg_extended/data_modeling/views/Equipment.View.yaml`
- However, no equipment records are populated. No transformation creates equipment instances.

**Status: Partial**

| What's Working | What's Missing |
|---|---|
| Contextualization targets `floc:*` assets (the "socket") -- correct | Equipment entity is defined but never populated |
| SAP functional locations form the hierarchy backbone | No serial-number-level associations possible |
| Work orders link to assets via FUNCTIONAL_LOCATION | Work orders cannot link to specific equipment instances |

**Recommendation:**
- This is acceptable for the quick start phase. Equipment population can be deferred.
- When work order accuracy matters, populate equipment from SAP equipment master data and associate to asset tags.
- Document that the current model follows the "always contextualize to asset tag" principle.

---

### 3. Entity Matching

**Best Practice (Primer):**
- Entity matching (supervised/unsupervised) is unreliable in production.
- Unsupervised is "too generous" and produces garbage.
- Real implementations converge on: key extraction + alias generation + direct comparison + diagram detection.
- Nobody ends up using entity matching in its current state.

**What We Implemented:**

`annotate_files.py` contains an entity matching implementation:

```737:767:scripts/07-contextualization/annotate_files.py
    try:
        # Prepare sources and targets
        sources = [{"id": i, "text": text} for i, text in enumerate(detected_texts)]
        targets = [
            {
                "id": a["id"],
                "name": a["name"],
                "description": a.get("description", ""),
            }
            for a in assets
        ]

        # Fit unsupervised model
        model = client.entity_matching.fit(
            sources=sources,
            targets=targets,
            match_fields=[("text", "name")],
        )
        // ...
        job = model.predict(num_matches=3, score_threshold=0.5)
```

**Status: Partial (Correct Direction)**

| What's Working | What's Missing |
|---|---|
| Entity matching exists but is not the primary method | N/A -- the primer says don't rely on it |
| Team pivoted to Diagrams API + sortField lookup (correct) | Entity matching code should be marked as fallback/deprecated |
| Direct comparison via sortField is the primary approach | |

**Recommendation:**
- No action required. The team is already doing the right thing by using Diagrams API + direct comparison rather than relying on entity matching.
- Consider removing or clearly marking the entity matching code as experimental/deprecated to avoid future confusion.

---

### 4. Key Extraction & Alias Generation Pipeline

**Best Practice (Primer):**
> "Every entity you contextualize against must go through key extraction and aliasing."

- Separate pipeline (NOT in transformations).
- Two outputs: candidate key/alias (representing the entity) and foreign key references (references to other entities).
- Rules: type expansion (`P` -> `pump`), separator standardization, leading zero removal, regex extraction.
- Populate `name` with source value; populate `alias` with cleaned/normalized value.
- All downstream contextualization targets the `alias` field.

**What We Implemented:**

There is no alias generation pipeline. The closest equivalent is a one-off function in the P&ID POC script:

```61:104:scripts/07-contextualization/annotate_pid_471.py
def normalize_to_sortfield(equip_num: str) -> list[str]:
    """
    Normalize a P&ID equipment number to possible sortField formats.

    The call established that sortField is typically 9 digits.
    Example: '321-5-068' -> '321005068'
    Example: '471-5-8157' -> '471058157'

    Returns a list of candidate sortField values to try.
    """
    # Strip letters and extra characters, keep digits and dashes
    digits_only = re.sub(r'[^0-9]', '', equip_num)

    # Split on dashes for structured normalization
    parts = re.split(r'[-/]', re.sub(r'[A-Za-z]', '', equip_num))
    parts = [p for p in parts if p]  # remove empties

    candidates = set()

    # Try: just all digits concatenated
    candidates.add(digits_only)

    # Try: zero-pad to 9 digits
    if len(digits_only) < 9:
        candidates.add(digits_only.zfill(9))

    # Try: area (3) + zero-padded rest to make 9
    if len(parts) >= 2:
        area = parts[0]
        rest = ''.join(parts[1:])
        padded = rest.zfill(9 - len(area))
        candidates.add(area + padded)
    // ...
    return sorted(candidates)
```

The `SORTFIELD_ANALYSIS_REPORT.md` reveals the scale of the problem:

- **Eastover**: 3,350 sortField values -- 50.1% alphanumeric (`31200L16B`, `471LP490`), 48.5% numeric (`4710052317`)
- **Sumter**: 83 sortField values -- 79.3% alphanumeric but descriptive (`1DUSTFAN`, `2BWRAPPER`)

These radically different patterns across two sites within the same project are exactly the scenario the primer warns about.

**Status: GAP - CRITICAL**

| What's Working | What's Missing |
|---|---|
| `sortField` is stored on assets as a property | No dedicated alias generation pipeline |
| One-off normalization function exists (POC only) | No `alias` field on assets |
| Pattern analysis was performed (SORTFIELD report) | No reusable normalization rules (type expansion, separator standardization, leading zero removal) |
| | No foreign key reference extraction |
| | No state store tracking processed entities |
| | `normalize_to_sortfield()` is hardcoded, not configurable |
| | Sumter's descriptive names (`1DUSTFAN`) cannot be matched without alias expansion |

**Impact of this gap:**
- Without normalized aliases, every contextualization script must implement its own matching logic.
- Adding Sumter (or any new site) requires writing new normalization code per site -- the exact anti-pattern the primer warns about.
- No way to do type expansion (e.g., `P` -> `pump`) which would dramatically improve matching coverage.

**Recommendation:**
1. **Immediate:** Add an `alias` property to the `MfgAsset` container (list type to support multiple aliases).
2. **Short-term:** Build a configurable alias generation pipeline as a separate CDF Function or Python workflow that:
   - Reads new/changed assets from the enterprise model.
   - Applies site-specific normalization rules via configuration (not code branches).
   - Writes normalized aliases back to the `alias` field.
3. **Reference:** Request Darren's key extraction and aliasing pipeline documentation and repository (he mentioned sending it after the session).

---

### 5. P&ID / File Annotation Pipeline

**Best Practice (Primer):**

Two bundled processes in the File Annotation deployment pack:
1. **Diagram Detection:** Pass known asset aliases for a scoped file subset; detect tag locations with bounding boxes and confidence scores.
2. **Pattern Mode:** Generate regex-like pattern templates from aliases, scan for anything matching those patterns (catches instrumentation not in SAP), provides contextualization quality scoring.

Additional: subset-to-subset scoping, virtual tag creation, file-to-file links, continuous improvement loop.

**What We Implemented:**

Diagram Detection is partially implemented across multiple scripts:

```105:109:scripts/07-contextualization/test_hybrid_3files.py
            search_field="name",  # Match against the 'name' field (sortField value)
            partial_match=True,
            min_tokens=1,  # Allow single token matches for numeric sortFields
```

```370:376:scripts/07-contextualization/annotate_files.py
        job = client.diagrams.detect(
            entities=assets,
            file_ids=[file_id],
            search_field="name",
            partial_match=True,
            min_tokens=2,
        )
```

Scoping uses area code prefix matching:

```50:52:scripts/07-contextualization/test_hybrid_3files.py
def get_assets_by_sortfield_prefix(client, area_code: str, limit: int = 100) -> list[dict]:
    """
    Get assets whose sortField starts with the given area code.
```

**Status: GAP - SIGNIFICANT**

| Capability | Primer Expectation | Current State |
|---|---|---|
| Diagram Detection (known assets) | Pass alias list, get bounding boxes + confidence | Implemented via Diagrams API with sortField values |
| Scoping (subset-to-subset) | Configuration-driven file/asset pairing | Hardcoded area prefixes (471, 472, 311, 321) |
| Pattern Mode (unknown tags) | Regex templates from aliases, scan for all matches | **Not implemented at all** |
| Quality Scoring | Matched / Detected ratio | **Not implemented** |
| Virtual Tags | CDF-only tags for unmatched detections | **Not implemented** |
| File-to-File Links | Detect document cross-references | **Not implemented** |
| Continuous Improvement | Add patterns, rerun, improve denominator | **No mechanism exists** |
| Unmatched Tag Feedback | Surface unmatched list to customer | Tags logged but not surfaced |

**Evidence of what's missing -- the P&ID POC results:**

The `annotate_pid_471.py` POC found 60 annotations but only 24 could be resolved to CDF assets. The remaining 36 are unmatched detections that would be surfaced via Pattern Mode and either:
- Added to the asset hierarchy after customer review, or
- Created as virtual tags

Without Pattern Mode, we have no way to:
- Know how many tags exist on a P&ID (the denominator for quality scoring).
- Report a contextualization quality percentage to the customer.
- Discover instrumentation tags that don't exist in SAP.

**Recommendation:**
1. **Adopt the File Annotation deployment pack** (accelerator/toolkit module) instead of custom scripts. It bundles both diagram detection and pattern mode.
2. If custom scripts must be used, implement Pattern Mode:
   - Analyze alias patterns to generate regex templates.
   - Scan documents for all pattern matches (not just known aliases).
   - Calculate quality score: `matched_count / total_detected_count`.
   - Output unmatched tag list for customer review.
3. Move scoping configuration out of hardcoded values into a YAML config file.

---

### 6. Confidence Scoring & Validation

**Best Practice (Primer):**
- Do NOT trust built-in confidence scoring.
- Implement custom scoring: exact match = 100%, starts-with/ends-with = ~95%, progressive penalties.
- Two-threshold system: below lower = reject, between = needs review, above upper = auto-approve.
- Example: < 70% reject, 70-85% review, > 85% approve.
- Maintain a blacklist of generic terms.
- Start at 100% and walk down.

**What We Implemented:**

A single threshold at 0.20:

```53:55:scripts/07-contextualization/create_pid_471_annotations.py
# Minimum confidence threshold (0.0 - 1.0)
MIN_CONFIDENCE = 0.20
```

A custom similarity function exists in `annotate_files.py` but uses character-level matching rather than the token-based progressive approach recommended:

```566:596:scripts/07-contextualization/annotate_files.py
def calculate_text_similarity(text1: str, text2: str) -> float:
    // ...
    if t1 == t2:
        return 1.0

    # Check if one contains the other
    if t1 in t2 or t2 in t1:
        shorter = min(len(t1), len(t2))
        longer = max(len(t1), len(t2))
        return shorter / longer

    # Character-level matching
    common = sum(1 for c in t1 if c in t2)
    return (2.0 * common) / (len(t1) + len(t2))
```

Validation rules exist and are well-structured:

```29:86:scripts/07-contextualization/contextualization_rules.py
def validate_pi_tag_prefix_match(
    pi_tag: str, asset_sort_field: Optional[str]
) -> ValidationResult:
    """
    Validate that PI tag prefix matches asset sortField prefix.
    Rule: PI tags like 'pi:471*' should link to assets with sortField starting with '471'.
    """
    // ...
```

**Status: Partial**

| What's Working | What's Missing |
|---|---|
| Validation rules are well-structured and meaningful | No two-threshold system (only single lower bound at 0.20) |
| Post-hoc validation framework exists (8,055 links validated) | No custom confidence scoring algorithm (relies on Diagrams API score) |
| Character similarity function exists | No blacklisting mechanism for generic terms |
| | Threshold is extremely permissive (0.20 vs recommended 0.70+) |
| | No annotation status workflow (suggested -> review -> approved/rejected) in production |

**Recommendation:**
1. Implement a two-threshold system:
   - `REJECT_THRESHOLD = 0.70` -- anything below is discarded.
   - `AUTO_APPROVE_THRESHOLD = 0.85` -- anything above is auto-approved.
   - Between 0.70 and 0.85: created as `suggested` status for manual review.
2. Replace `calculate_text_similarity` with a token-based progressive scoring algorithm per the primer.
3. Create a `BLACKLIST` set of generic terms (e.g., "PUMP", "VALVE", "TANK", "FLOW", single-token matches).
4. Start validation at 100% and progressively relax.

---

### 7. OCR & Text Extraction Layering

**Best Practice (Primer):**
- Layer 1: Embedded text from DWG-derived PDFs (most accurate).
- Layer 2: Text overlays.
- Layer 3: OCR fallback (introduces error risk -- validate before creating assets).

**What We Implemented:**

The Diagrams API handles this internally. Our code simply calls:

```369:376:scripts/07-contextualization/annotate_files.py
        job = client.diagrams.detect(
            entities=assets,
            file_ids=[file_id],
            search_field="name",
            partial_match=True,
            min_tokens=2,
        )
```

**Status: Aligned (Implicit)**

The Diagrams API implements the layered extraction (embedded text -> OCR) automatically. No custom OCR handling is needed.

**Risk:** Since we use a very low confidence threshold (0.20), OCR errors that would normally be filtered out may be accepted. The low threshold compounds the risk of OCR misreads (e.g., `B-1234` read as `O-1234`).

**Recommendation:**
- No action needed on OCR layering itself.
- Raising the confidence threshold (see Gap #6) will mitigate OCR error propagation.

---

### 8. Large File Handling

**Best Practice (Primer):**
- Anything over 50 pages is problematic (memory issues, processing failures).
- A single large document linked to everything provides no value (everything related to everything by one degree of separation).
- Default: do not add `to_annotate` flag to oversized files.
- Ask the customer for individual document representations before processing bundles.

**What We Implemented:**

No file size or page count checks exist in any script. The annotation scripts process whatever file ID is passed in:

```329:355:scripts/07-contextualization/annotate_files.py
def extract_text_from_pdf(
    client,
    file_id: int,
    assets: list[dict] | None = None,
    max_assets: int = 100,
    timeout: int = 300,
) -> dict:
    """
    Extract text and detect entities from a PDF file using Diagrams API.
    // ... no page count check ...
    """
```

**Status: Gap**

| What's Working | What's Missing |
|---|---|
| N/A | No page count or file size validation |
| | No warning for documents over 50 pages |
| | No mechanism to flag or skip oversized files |
| | No guidance to customers about bundled documents |

**Recommendation:**
1. Add a pre-flight check before processing any file:
   - Retrieve file metadata (page count if available, file size).
   - Warn or skip files exceeding 50 pages or a configurable size threshold.
   - Log a message: "File X has Y pages -- consider splitting before annotation."
2. Document the large file policy for the Sylvamo team.

---

### 9. Multi-Site Expansion Strategy

**Best Practice (Primer):**
- Quick start should take as few shortcuts as possible.
- Separate alias generation from transformations to avoid per-site case logic.
- Each site's data flows through the same pipeline with site-specific **configuration**, not code branches.
- Single responsibility principle for each pipeline stage.

**What We Implemented:**

The asset transformation handles two sites with two `UNION ALL` blocks:

```48:94:sylvamo/modules/mfg_core/transformations/populate_Asset.Transformation.sql
-- Step 2a: Populate Eastover assets from RAW table with hierarchy
SELECT
    // ...
FROM `raw_ext_sap`.`sap_floc_eastover`

UNION ALL

-- Step 2b: Populate Sumter assets from RAW table with hierarchy
SELECT
    // ...
FROM `raw_ext_sap`.`sap_floc_sumter`
```

The contextualization scripts hardcode site-specific values:

```43:45:scripts/07-contextualization/annotate_pid_471.py
TARGET_PID_NAME = "471-80-1-0026"  # P&ID discussed in the call
AREA_PREFIX = "471"                # Paper Machine 1
PM1_FLOC_PREFIX = "0769-06"        # SAP functional location prefix for PM area
```

```31:47:scripts/07-contextualization/test_hybrid_3files.py
TEST_FILES = [
    {
        "id": 208203205663205,
        "name": "311-80-G-0004_6.pdf",
        "area_code": "311",
    },
    // ...
]
```

**Status: Gap**

| What's Working | What's Missing |
|---|---|
| Transformation logic is identical for both sites (just different tables) | Contextualization scripts hardcode area codes and site prefixes |
| Sites are in separate RAW tables (good isolation) | No configuration file drives site-specific parameters |
| | `normalize_to_sortfield()` is site-specific logic embedded in a script |
| | Adding a new site requires duplicating and modifying scripts |
| | No single-responsibility separation between ingestion, digestion, and contextualization |

**Evidence of the problem (from SORTFIELD_ANALYSIS_REPORT.md):**

Eastover sortField values are structured numeric codes (`4710052317`, `31200L16B`). Sumter sortField values are descriptive names (`1DUSTFAN`, `2BWRAPPER`). If we were to contextualize Sumter P&IDs with the same `normalize_to_sortfield()` function used for Eastover, it would produce entirely wrong results. This is exactly the case logic anti-pattern the primer warns about.

**Recommendation:**
1. Create a site configuration YAML file that defines per-site:
   - RAW table names
   - Area code prefixes
   - sortField patterns and normalization rules
   - File scoping rules
2. Refactor contextualization scripts to read from this configuration rather than hardcoded values.
3. Separate pipeline stages: Ingestion -> Digestion (alias generation) -> Contextualization -> Validation.

---

### 10. Three-Tier Environment Strategy

**Best Practice (Primer):**
- Dev -> Test -> Prod from day one.
- Much harder to add test environment later.
- Test environment uses the same CI/CD process as production.
- No "god mode" for test.
- Configuration-driven environment differences.

**What We Implemented:**

Only a development environment exists:
- `sylvamo/config.dev.yaml`
- `sylvamo/build_info.dev.yaml`
- Git branch: `setup/uv-cognite-project`

No evidence of test or production configurations.

**Status: Gap**

| What's Working | What's Missing |
|---|---|
| Dev environment exists with proper config files | No test environment configuration |
| | No production environment configuration |
| | No CI/CD pipeline for promotion |
| | No configuration-driven environment switching |

**Recommendation:**
1. Create `config.test.yaml` and `config.prod.yaml` alongside the existing `config.dev.yaml`.
2. Establish a CI/CD pipeline that deploys from dev -> test -> prod using the same toolkit deployment process.
3. Start now -- the primer is emphatic that retrofitting this is dramatically harder than starting with it.

---

### 11. Toolkit Module Guidance

**Best Practice (Primer):**
- Use the **File Annotation** module (not P&ID Annotation) -- even for demos.
- File Annotation includes pattern mode and contextualization quality scoring.
- Customers always ask "how good is our contextualization?" -- this module answers that question.

**What We Implemented:**

All contextualization is performed via custom Python scripts calling the Diagrams API directly:
- `annotate_files.py` -- general file annotation
- `annotate_pid_471.py` -- P&ID 471 POC
- `create_pid_471_annotations.py` -- annotation creation
- `test_hybrid_3files.py` -- hybrid test

No toolkit deployment pack or accelerator is referenced anywhere in the codebase.

**Status: Gap**

| What's Working | What's Missing |
|---|---|
| Custom scripts demonstrate the capability | Not using the File Annotation deployment pack/accelerator |
| Diagrams API is called correctly | Missing pattern mode (bundled in the module) |
| | Missing quality scoring (bundled in the module) |
| | Missing the reusable, deployable pipeline structure |
| | Custom scripts are not CI/CD-deployable artifacts |

**Recommendation:**
1. Evaluate the File Annotation deployment pack for Sylvamo.
2. If the deployment pack is available for our toolkit version, adopt it. It provides diagram detection + pattern mode + quality scoring out of the box.
3. If not yet available, the custom scripts are a reasonable interim approach, but pattern mode and quality scoring should be added (see Gap #5).

---

### 12. Files Transformation & Asset Relationships

**Best Practice (Primer):**
- File annotations should link to specific Equipment/Unit level assets, not root/site assets.
- Associations should go through the asset tag (always contextualize to asset tag).
- All associations should be through your asset -- time series to asset, annotations to asset. One degree of separation is sufficient.

**What We Implemented:**

The validation report shows a 0% file contextualization rate:

From `CONTEXTUALIZATION_VALIDATION_REPORT.md`:
- All 45 linked files go to root asset (`floc:0769`).
- Root asset has no `sortField` (appropriate for site level, but useless for matching).
- Filenames don't follow area code patterns (general documents, reports).

From `FILES_CONTEXTUALIZATION_INVESTIGATION_REPORT.md`:
- The Files transformation (`populate_Files.Transformation.sql`) does not populate the `assets` property on CogniteFile nodes.
- The Asset view does not have a `files` reverse relation.
- No bidirectional navigation is possible between files and assets through the data model.

**Status: Gap**

| What's Working | What's Missing |
|---|---|
| Files exist in CDF with proper metadata | Files transformation doesn't populate `assets` property |
| P&ID annotations are being created via custom scripts | Asset view lacks `files` reverse relation |
| | All CDF Files API links point to root asset |
| | No file categorization (equipment-specific vs general documents) |
| | No strategy for general documents vs equipment-specific P&IDs |

**Recommendation:**
1. Update `populate_Files.Transformation.sql` to populate the `assets` property by joining with `_cdf.assets` to resolve asset IDs to external IDs.
2. Add a `files` reverse relation to the Asset view (following the same pattern as `timeSeries`).
3. Categorize files: P&IDs and equipment-specific documents should link to Equipment/Unit level; general documents linking to site root is acceptable but should be documented as intentional.

---

## Priority Matrix

### P0 - Critical (Block scalable contextualization)

| Gap | Impact | Effort | Action |
|---|---|---|---|
| #4 - Alias Generation Pipeline | Without it, every script reimplements matching logic; new sites require new code | Medium-High | Build configurable alias pipeline; add `alias` property to MfgAsset |
| #5 - Pattern Mode & Quality Scoring | Cannot report contextualization quality; miss instrumentation tags; no virtual tags | Medium | Adopt File Annotation module or implement pattern mode in scripts |

### P1 - High (Affect quality and operations)

| Gap | Impact | Effort | Action |
|---|---|---|---|
| #6 - Confidence Scoring | 0.20 threshold lets bad matches through; no blacklisting | Low | Implement two-threshold system + blacklist |
| #9 - Multi-Site Expansion | Hardcoded values prevent site reuse; Sumter will fail | Medium | Create site config YAML; refactor scripts |
| #10 - Three-Tier Environments | No test/prod environments; risky promotion | Medium | Create config files; establish CI/CD |
| #11 - Toolkit Module | Custom scripts not deployable; missing bundled features | Low-Medium | Evaluate and adopt File Annotation module |
| #12 - Files Transformation | 0% file contextualization; no bidirectional navigation | Low | Update SQL transformation; add reverse relation |

### P2 - Medium (Best practice compliance)

| Gap | Impact | Effort | Action |
|---|---|---|---|
| #8 - Large File Handling | Could crash annotation pipeline on large bundles | Low | Add pre-flight size/page check |
| #1 - Data Model Cleanup | sortField not normalized in enterprise model | Low | Addressed by alias pipeline (P0 #4) |
| #2 - Equipment Entity | No serial-number associations | Low | Defer until needed for predictive maintenance |

---

## Recommended Next Steps (Ordered)

### Immediate (This Sprint)

1. **Request Darren's alias generation pipeline documentation and repository.** He mentioned sending it after the session. This is the foundation for addressing the most critical gap.

2. **Raise the confidence threshold from 0.20 to at least 0.70** in `create_pid_471_annotations.py`. Create a two-threshold configuration:
   ```python
   REJECT_THRESHOLD = 0.70
   AUTO_APPROVE_THRESHOLD = 0.85
   ```

3. **Create a blacklist** of generic terms that produce false positives:
   ```python
   BLACKLIST = {"PUMP", "VALVE", "TANK", "FLOW", "MOTOR", "PIPE", "LINE"}
   ```

4. **Update the Files transformation** to populate the `assets` property and add the `files` reverse relation to the Asset view.

### Short-Term (Next 2 Sprints)

5. **Add an `alias` property** (list of strings) to the `MfgAsset` container.

6. **Build a site configuration YAML** that externalizes area codes, sortField patterns, and normalization rules out of Python scripts.

7. **Evaluate the File Annotation deployment pack** -- determine if it is available for our toolkit version and if it can replace the custom scripts.

8. **Create `config.test.yaml` and `config.prod.yaml`** alongside `config.dev.yaml`. Establish a basic CI/CD promotion path.

### Medium-Term (Next Quarter)

9. **Implement pattern mode** (either via the deployment pack or custom):
   - Generate regex templates from known aliases.
   - Scan P&IDs for all matching patterns.
   - Calculate contextualization quality scores.
   - Surface unmatched tag lists for customer review.

10. **Build the alias generation pipeline** as a separate process:
    - Configurable normalization rules per site.
    - Type expansion, separator standardization, leading zero removal.
    - State store for incremental processing.
    - Writes to `alias` field on assets.

11. **Implement virtual tags** for detected values that don't exist in the asset hierarchy.

---

## What We're Doing Right

It is important to acknowledge what aligns with best practices:

1. **Contextualizing against asset tags, not equipment** -- the `floc:*` approach is correct.
2. **Using Diagrams API instead of entity matching** -- the team correctly identified that entity matching is unreliable and pivoted.
3. **Area-based scoping** -- even though hardcoded, the concept of pairing file subsets with asset subsets is correct.
4. **Post-hoc validation framework** -- the `contextualization_rules.py` and validation report with 8,055 links checked is excellent practice.
5. **Hybrid approach** -- Phase 1 (area matching) + Phase 2 (Diagrams API) is a sound strategy.
6. **Dry-run mode** -- scripts default to dry-run and require `--apply` to write, which is good practice.
7. **OCR layering** -- handled by the Diagrams API, which is the recommended approach.

---

*Last updated: February 7, 2026*
