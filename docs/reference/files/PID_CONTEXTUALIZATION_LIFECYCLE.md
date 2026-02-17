# P&ID Contextualization Lifecycle

> End-to-end lifecycle of how Cognite CDF ingests, parses, annotates, and maintains P&ID documents.

**Last updated:** February 17, 2026 (rev 3 - aligned with codebase)

---

## Table of Contents

- [Overview](#overview)
- [Lifecycle at a Glance](#lifecycle-at-a-glance)
- [Phase 1: Ingestion](#phase-1-ingestion)
- [Phase 2: Preparation](#phase-2-preparation)
- [Phase 3: Detection (Diagram Parsing)](#phase-3-detection-diagram-parsing)
- [Phase 4: Entity Matching](#phase-4-entity-matching)
- [Phase 5: Annotation Creation & Scoring](#phase-5-annotation-creation--scoring)
- [Phase 6: Review & Approval](#phase-6-review--approval)
- [Phase 7: Consumption](#phase-7-consumption)
- [Phase 8: Revision Handling](#phase-8-revision-handling)
- [What CDF Tracks Inside a P&ID](#what-cdf-tracks-inside-a-pid)
- [Cross-Document References](#cross-document-references)
- [Detection Capabilities by File Type](#detection-capabilities-by-file-type)
- [Three Approaches to P&ID Contextualization](#three-approaches-to-pid-contextualization)
- [Sylvamo Implementation (Approach 3)](#sylvamo-implementation-approach-3)
- [Why Annotations Are Not Auto-Updated (Design Rationale)](#why-annotations-are-not-auto-updated-design-rationale)
- [What Customers Should Do: Operational Playbook](#what-customers-should-do-operational-playbook)
- [Real-World Scenarios Explained Simply](#real-world-scenarios-explained-simply)
- [Known Limitations](#known-limitations)

---

## Overview

A P&ID (Piping and Instrumentation Diagram) is a static engineering document that shows equipment, instruments, piping, and their interconnections. CDF transforms these static documents into **interactive, contextualized diagrams** where every tag on the drawing is linked to the corresponding asset, time series, or related document in the data model.

This lifecycle document describes how CDF manages P&IDs from initial upload through contextualization, approval, consumption, and revision handling.

---

## Lifecycle at a Glance

```mermaid
graph TB
    subgraph "Phase 1: Ingestion"
        I1["P&ID uploaded<br/>(SharePoint / API)"]
        I2["File Extractor → CDF"]
        I3["CogniteFile node created"]
    end

    subgraph "Phase 2: Preparation"
        P1["Tag files with labels<br/>(e.g., PID)"]
        P2["Build entity list<br/>(assets, sortField, PI tags)"]
        P3["Configure scope<br/>(location, asset subset)"]
    end

    subgraph "Phase 3: Detection"
        D1["OCR / Text recognition"]
        D2["Symbol detection<br/>(vectorized only)"]
        D3["Connection tracing<br/>(vectorized only)"]
    end

    subgraph "Phase 4: Matching"
        M1["Equipment → Asset"]
        M2["Instrument → TimeSeries"]
        M3["Drawing ref → File"]
    end

    subgraph "Phase 5: Scoring"
        S1["Confidence calculation"]
        S2["Auto-approve / Review / Reject"]
    end

    subgraph "Phase 6: Review"
        R1["Domain expert review"]
        R2["Approve / Reject / Add tags"]
    end

    subgraph "Phase 7: Consumption"
        C1["Interactive diagram"]
        C2["Search & navigation"]
        C3["InField / Custom apps"]
    end

    subgraph "Phase 8: Revision"
        V1["Updated P&ID uploaded"]
        V2["Re-contextualize"]
    end

    I1 --> I2 --> I3 --> P1 --> P2 --> P3
    P3 --> D1 --> D2 --> D3
    D3 --> M1 & M2 & M3
    M1 & M2 & M3 --> S1 --> S2
    S2 -->|"Review queue"| R1 --> R2
    S2 -->|"Auto-approved"| C1
    R2 -->|"Approved"| C1
    C1 --> C2 & C3
    C1 -.->|"Document revised"| V1 --> V2 --> D1
```

---

## Phase 1: Ingestion

P&ID files enter CDF through one of several paths:

```mermaid
graph LR
    subgraph "Sources"
        SP["SharePoint<br/>Engineering Drawings folder"]
        API["Direct API Upload"]
        SDK["Python SDK Upload"]
    end

    subgraph "CDF File Service"
        FS["Binary stored<br/>PDF / PNG / TIFF / JPEG"]
    end

    subgraph "CDF Data Model"
        CF["CogniteFile Node<br/>in instance space"]
    end

    SP -->|"File Extractor<br/>(scheduled)"| FS
    API -->|"POST /files"| FS
    SDK -->|"client.files.upload_content()"| FS
    FS -->|"Transformation or<br/>instance_id link"| CF
```

**What happens:**
1. The file binary (e.g., `471-80-I-0026_05.pdf`) is uploaded to the CDF File Service
2. A CogniteFile node is created in the data model (either via transformation or direct SDK call)
3. The node captures metadata: `name`, `mimeType`, `directory`, `sourceId`
4. The binary is linked to the node via `instance_id`

**Supported formats for diagram parsing:** `application/pdf`, `image/jpeg`, `image/png`, `image/tiff`

---

## Phase 2: Preparation

Before running detection, the system must be configured with what to look for:

```mermaid
graph TB
    subgraph "File Preparation"
        F1["Tag P&ID files with labels<br/>(e.g., tag='PID')"]
        F2["Set mimeType on CogniteFile<br/>(required for parsing)"]
        F3["Filter: which files to process"]
    end

    subgraph "Entity Preparation"
        E1["Asset list<br/>(names, sortField, externalId)"]
        E2["Time series list<br/>(PI tags, names)"]
        E3["Other file names<br/>(for cross-references)"]
    end

    subgraph "Scope Configuration"
        S1["Select location / plant"]
        S2["Select symbol library"]
        S3["Configure matching thresholds"]
    end

    F1 --> F3
    F2 --> F3
    E1 & E2 & E3 --> S1
    S1 --> S2 --> S3
```

**Key principle:** Always pair a file subset with a matching asset subset from the same plant/area. This avoids false matches across different locations.

---

## Phase 3: Detection (Diagram Parsing)

CDF uses the **Diagrams API** to extract information from P&ID documents. The capabilities depend on whether the file is vectorized or rasterized:

```mermaid
graph TB
    FILE["P&ID File"]

    FILE --> CHECK{"File Type?"}

    CHECK -->|"Vectorized PDF"| VEC
    CHECK -->|"Rasterized / Scanned"| RAS

    subgraph VEC["Vectorized — Full Pipeline"]
        V1["1. Tag Detection<br/>OCR + text extraction"]
        V2["2. Symbol Detection<br/>Match vectors to library"]
        V3["3. Connection Tracing<br/>Follow lines between symbols"]
        V4["4. Merge<br/>Link tags to their symbols"]
        V1 --> V2 --> V3 --> V4
    end

    subgraph RAS["Rasterized — Limited Pipeline"]
        R1["1. Tag Detection<br/>OCR + text recognition"]
        R2["2. Tag Mapping<br/>Match text to entities"]
        R1 --> R2
    end
```

### Tag Detection

The Diagrams API performs OCR to find text on the drawing. For each detected text region, it records:

- **Text content** — what was read (e.g., "OIL TANK 471-5-8157")
- **Bounding box** — exact coordinates on the page (x, y, width, height)
- **Page number** — which page of the PDF

### Symbol Detection (Vectorized Only)

For vectorized PDFs, CDF can also detect **symbols** — standardized shapes representing equipment types (valves, pumps, instruments, etc.):

- Symbols are matched against a **symbol library** (project-specific or template)
- Each symbol has one or more **geometries** (visual variations)
- Detected symbols are classified by **asset class** and **asset type**

### Connection Tracing (Vectorized Only)

CDF traces lines and pipes between detected symbols to determine how equipment is connected in the process flow.

> **Limitation:** For vectorized files, only the **first page** is parsed. Multi-page PDFs should be split before parsing.

---

## Phase 4: Entity Matching

Detected tags are matched against the prepared entity list. CDF supports several matching strategies:

```mermaid
graph TB
    subgraph "Detected on P&ID"
        T1["Equipment Label<br/>'OIL TANK 471-5-8157'"]
        T2["Instrument Circle<br/>'LT' over '309'"]
        T3["Drawing Reference<br/>'SEE DWG 471-80-I-0025'"]
        T4["Generic Text<br/>'PROCESS WATER'"]
    end

    subgraph "Matching Logic"
        M1["Normalize equipment number<br/>471-5-8157 → 471058157<br/>Match against sortField"]
        M2["Combine area + tag<br/>471 + LT309 → 471LT309<br/>Match against PI tags"]
        M3["Match filename pattern<br/>against CDF files"]
        M4["No match possible<br/>(blacklist candidate)"]
    end

    subgraph "CDF Resources"
        A1["CogniteAsset<br/>sortField: 471058157"]
        TS1["CogniteTimeSeries<br/>externalId: 471LT309"]
        F1["CogniteFile<br/>471-80-I-0025_03.pdf"]
        NONE["Unlinked tag"]
    end

    T1 --> M1 --> A1
    T2 --> M2 --> TS1
    T3 --> M3 --> F1
    T4 --> M4 --> NONE
```

### Matching Models

CDF offers two matching models in the UI:

| Model | When to Use | Configuration |
|-------|-------------|---------------|
| **Standard** | Most P&IDs; uses default text similarity | None required |
| **Advanced** | Complex naming; partial matches needed | Token count, partial match settings, field matching |

### Matching via API (Programmatic)

```python
# CDF Diagrams Detect API
detect_job = client.diagrams.detect(
    entities=[
        {"name": "OIL TANK", "sortField": "471058157"},
        {"name": "471LT309"},
        # ... full entity list
    ],
    items=[{"fileId": 3851544762966265}],
    search_field="name",
    partial_match=True,
)
```

---

## Phase 5: Annotation Creation & Scoring

Each successful match becomes an **annotation** — a structured link between a specific region of the P&ID and a CDF resource.

### Annotation Structure

```mermaid
graph TB
    subgraph "Annotation"
        WHERE["WHERE on the document<br/>──────────────<br/>fileId: 3851544762966265<br/>page: 1<br/>region: x=342, y=156<br/>  width=89, height=42<br/>detectedText: 'OIL TANK 471-5-8157'"]

        WHAT["WHAT it links to<br/>──────────────<br/>type: diagrams.AssetLink<br/>targetId: asset_12345<br/>targetExternalId: floc:0769-06-...<br/>targetName: 'Oil Tank PM1'"]

        SCORE["QUALITY<br/>──────────────<br/>confidence: 0.92<br/>status: approved<br/>createdBy: workflow"]
    end

    WHERE --- WHAT
    WHERE --- SCORE
```

### Confidence Scoring & Thresholds

```mermaid
graph LR
    DETECT["Detected Tag +<br/>Matched Entity"]

    DETECT --> SCORE{"Confidence<br/>Score"}

    SCORE -->|">= 85%"| AUTO_APP["Auto-Approved<br/>Immediately active"]
    SCORE -->|"70% — 85%"| REVIEW["Queued for Review<br/>Domain expert decides"]
    SCORE -->|"< 70%"| AUTO_REJ["Auto-Rejected<br/>Discarded"]

    style AUTO_APP fill:#c8e6c9
    style REVIEW fill:#fff9c4
    style AUTO_REJ fill:#ffcdd2
```

> **Note:** These thresholds are configurable. The recommended best practice is a two-threshold system (reject/review/approve). A single low threshold (e.g., 0.20) will produce many false positives.

---

## Phase 6: Review & Approval

Annotations that fall in the review zone are presented to domain experts in the CDF UI:

```mermaid
graph TB
    subgraph "CDF Diagram Parsing UI"
        VIEW["Interactive P&ID View<br/>with detected tags"]

        subgraph "Tag Types"
            ASSET_TAG["Asset Tags<br/>(purple boxes)"]
            DIAGRAM_TAG["Diagram Tags<br/>(orange boxes — file links)"]
            UNLINKED["Unlinked Tags<br/>(need manual linking)"]
        end

        subgraph "Actions"
            APPROVE["Approve Tag<br/>(confirms the link)"]
            REJECT["Reject Tag<br/>(removes the link)"]
            ADD["Add New Tag<br/>(draw bounding box,<br/>link to resource)"]
            SAVE_SVG["Save as SVG<br/>(preserves annotations)"]
        end
    end

    VIEW --> ASSET_TAG & DIAGRAM_TAG & UNLINKED
    ASSET_TAG --> APPROVE & REJECT
    DIAGRAM_TAG --> APPROVE & REJECT
    UNLINKED --> ADD
    VIEW --> SAVE_SVG
```

### Review Workflow

1. Select a diagram with status **"Pending approval"**
2. Review each detected tag:
   - **Blue outline** = verified/approved link
   - **Orange outline** = suggested link (pending)
3. Approve or reject individual tags
4. Optionally add new tags by drawing bounding boxes and linking to CDF resources
5. Save changes

---

## Phase 7: Consumption

Once annotations are approved, the P&ID becomes an **interactive document**:

```mermaid
graph TB
    subgraph "Interactive P&ID"
        PID["Contextualized P&ID<br/>with clickable regions"]
    end

    subgraph "Navigation Paths"
        N1["Click equipment tag<br/>→ Opens asset details<br/>(time series, events, properties)"]
        N2["Click instrument tag<br/>→ Opens time series<br/>(live data, trends)"]
        N3["Click drawing reference<br/>→ Opens related P&ID"]
        N4["Asset search → P&ID<br/>Query: 'show me all P&IDs<br/>for this pump'"]
    end

    subgraph "Applications"
        APP1["CDF Search<br/>(preview + navigate)"]
        APP2["InField<br/>(field worker reference)"]
        APP3["Custom Apps<br/>(via GraphQL / SDK)"]
        APP4["SVG Export<br/>(offline use)"]
    end

    PID --> N1 & N2 & N3
    N4 --> PID
    PID --> APP1 & APP2 & APP3 & APP4
```

### Bidirectional Navigation

The annotation system enables queries in **both directions**:

| Direction | Query | How |
|-----------|-------|-----|
| **P&ID → Asset** | "What assets are on this P&ID?" | Follow annotations from file |
| **Asset → P&IDs** | "Which P&IDs show this pump?" | Reverse query: all annotations targeting this asset |
| **P&ID → Other P&IDs** | "What drawings does this P&ID reference?" | Follow `diagrams.FileLink` annotations |
| **Time Series → P&IDs** | "Which P&IDs show this instrument?" | Reverse query: annotations targeting this TS |

---

## Phase 8: Revision Handling

When a P&ID is revised (equipment moved, instruments added/removed, layout changed), the existing annotations reflect the **previous version** of the document. CDF handles this through a deliberate **detect-clean-reparse** cycle, described in detail below.

```mermaid
graph TB
    subgraph "Step 1: Current State"
        R5["P&ID Rev 05"]
        R5_A["60 Annotations<br/>(all approved)"]
        R5_L["Linked to PM1 asset"]
        R5 --- R5_A & R5_L
    end

    subgraph "Step 2: Revision Uploaded"
        R6["P&ID Rev 06 uploaded"]
        DETECT["CDF detects the change<br/>(lastUpdatedTime updated)"]
    end

    subgraph "Step 3: Controlled Re-Contextualization"
        RC1["Workflow identifies<br/>updated file"]
        RC2["Old annotations cleaned<br/>(workflow-owned only)"]
        RC3["Full re-detection runs<br/>(fresh OCR + matching)"]
        RC4["New annotations created<br/>against current document"]
        RC5["Review & approve"]
    end

    R5 -.->|"Document revised"| R6
    R6 --> DETECT
    DETECT -->|"Scheduled or triggered"| RC1
    RC1 --> RC2 --> RC3 --> RC4 --> RC5
```

### Re-Contextualization Sequence

```mermaid
sequenceDiagram
    participant ENG as Engineer
    participant SP as SharePoint
    participant EXT as File Extractor
    participant CDF as CDF
    participant WF as Annotation Workflow
    participant RAW as RAW State Table
    participant EXP as Domain Expert

    ENG->>SP: Upload revised P&ID (Rev 06)
    SP->>EXT: Extractor detects new/changed file
    EXT->>CDF: Upload new binary content
    Note over CDF: lastUpdatedTime changes

    WF->>RAW: Check state table<br/>(scheduled or manual trigger)
    RAW-->>WF: File updated since last run

    alt cleanOldAnnotations = true
        WF->>CDF: Remove previous annotations<br/>(only workflow-created ones)
    end

    WF->>CDF: Run Diagrams Detect<br/>(full OCR + entity matching)
    CDF-->>WF: New annotations with confidence scores

    alt confidence >= auto-approve threshold
        WF->>CDF: Auto-approve annotation
    else confidence in review range
        WF->>CDF: Create as suggestion
        CDF->>EXP: Appears in review queue
        EXP->>CDF: Approve / Reject
    end

    WF->>RAW: Update state (file processed)
    WF->>CDF: Log status to extraction pipeline
```

### What Changes and What Stays the Same

| Item | On Revision | Why |
|------|-------------|-----|
| **CogniteFile node** | Stays | The file's identity, space, and metadata persist |
| **CogniteFile.assets** (parent link) | Stays | The direct relation to the parent asset (e.g., PM1) is on the node, not tied to annotations |
| **Manually added tags** | Stays | Cleanup only removes workflow-owned annotations |
| **File labels/tags** | Stays | Metadata properties are not affected |
| **Workflow-created annotations** | Replaced | Old ones cleaned, new ones created from fresh detection |
| **Bounding box coordinates** | Regenerated | New detection produces coordinates matching the current layout |
| **Approved status** | Resets | New annotations go through the confidence scoring cycle again |

---

## Why Annotations Are Not Auto-Updated (Design Rationale)

A common question is: *"Why doesn't CDF just keep the old annotations and update them automatically when the document changes?"*

This is a **deliberate design choice**, not a limitation. Here's why:

### The Core Problem: Annotations Are Tied to Pixel Coordinates

Every annotation records the **exact position** on the document where a tag was found — down to pixel coordinates. When an engineer revises a P&ID:

- Equipment may move to a different location on the drawing
- New instruments may be added in empty spaces
- Old instruments may be removed entirely
- The entire layout may be restructured

There is **no reliable way** to automatically determine which tags on the new revision correspond to which tags on the old revision. The text may be the same, but the position is different. The position may be similar, but the text changed. Or both changed.

### Why a Fresh Detection Is the Right Approach

```mermaid
graph TB
    subgraph "Why NOT auto-update"
        N1["Old annotation says:<br/>'OIL TANK' is at (120, 300)"]
        N2["New revision moved it<br/>to (400, 150)"]
        N3["Auto-update would need to<br/>know these are the 'same' tag"]
        N4["But CDF cannot diff two PDFs<br/>at the pixel level"]
        N1 --> N3
        N2 --> N3
        N3 --> N4
    end

    subgraph "Why fresh detection works"
        Y1["Re-run OCR on new document"]
        Y2["Find all tags at their<br/>CURRENT positions"]
        Y3["Re-match against<br/>CURRENT asset list"]
        Y4["Result: annotations that<br/>accurately reflect the document"]
        Y1 --> Y2 --> Y3 --> Y4
    end

    style N4 fill:#fff9c4
    style Y4 fill:#c8e6c9
```

### The Design Guarantees

This approach provides several important guarantees:

| Guarantee | Explanation |
|-----------|-------------|
| **Accuracy** | Annotations always reflect what is actually on the current document — not a best-guess carry-over from an old version |
| **Completeness** | New equipment added in the revision is detected and matched — not missed because it didn't exist before |
| **No ghost links** | Removed equipment doesn't leave orphan annotations pointing to blank space |
| **Confidence is real** | The confidence score reflects the actual match quality on this document, not inherited from a different version |
| **Domain expert validation** | Human review happens on the actual current document, not on stale information |

### The Analogy

Think of it like a **building inspection**. When a building is renovated, the inspector doesn't update the old report with notes like "the kitchen moved to the second floor." They do a **new inspection** of the current building and produce a **new report**. The old report is still available for historical reference if needed, but the current report reflects reality.

CDF works the same way: each contextualization run produces a **fresh, accurate snapshot** of what's on the document right now.

---

## What Customers Should Do: Operational Playbook

### Setting Up the Revision Workflow

The recommended approach is to have the annotation workflow run on a **schedule** (daily or weekly), so revised P&IDs are automatically re-contextualized without anyone needing to remember to trigger it manually.

```mermaid
graph TB
    subgraph "One-Time Setup"
        S1["Deploy P&ID Annotation Workflow<br/>(via Cognite Toolkit)"]
        S2["Configure schedule<br/>(e.g., daily at 2 AM)"]
        S3["Set cleanOldAnnotations = true"]
        S4["Set confidence thresholds<br/>(e.g., 70% / 85%)"]
        S1 --> S2 --> S3 --> S4
    end

    subgraph "Ongoing Operation"
        O1["Engineers upload revised P&IDs<br/>to SharePoint as usual"]
        O2["File Extractor syncs to CDF<br/>(automatic)"]
        O3["Annotation Workflow detects changes<br/>(scheduled run)"]
        O4["Fresh annotations created"]
        O5["High-confidence: auto-approved"]
        O6["Medium-confidence: review queue"]
        O7["Domain expert reviews<br/>(only the flagged ones)"]
        O1 --> O2 --> O3 --> O4
        O4 --> O5
        O4 --> O6 --> O7
    end

    subgraph "Result"
        R1["Interactive diagrams always<br/>reflect current documents"]
    end

    O5 --> R1
    O7 --> R1
```

### Day-to-Day: What Each Role Does

| Role | What They Do | How Often |
|------|-------------|-----------|
| **Engineer** | Uploads revised P&IDs to SharePoint | As needed (normal workflow — no CDF steps required) |
| **File Extractor** | Automatically syncs files to CDF | Continuous (scheduled) |
| **Annotation Workflow** | Detects updated files, re-contextualizes | Scheduled (daily/weekly) |
| **Domain Expert** | Reviews annotations in the "Pending Approval" queue in CDF | After each workflow run (typically a few minutes) |
| **CDF Admin** | Monitors extraction pipeline logs, adjusts thresholds | Monthly or as needed |

### What to Do If Annotations Look Wrong

```mermaid
graph TB
    ISSUE["Annotations look wrong<br/>or incomplete"]
    ISSUE --> CHECK{"What's the situation?"}

    CHECK -->|"Tags point to<br/>wrong locations"| A["Document was revised<br/>but not re-contextualized"]
    CHECK -->|"New equipment<br/>has no tags"| B["Equipment added in revision;<br/>re-run needed"]
    CHECK -->|"Wrong asset<br/>linked"| C["Matching issue;<br/>check entity list"]
    CHECK -->|"OCR misread<br/>a tag"| D["Scan quality issue;<br/>add manual tag"]

    A --> FIX_A["Trigger re-contextualization<br/>(manual or wait for schedule)"]
    B --> FIX_B["Same: re-contextualize<br/>with updated asset list"]
    C --> FIX_C["Update entity list,<br/>then re-contextualize"]
    D --> FIX_D["Reject bad tag,<br/>add correct one manually"]

    style FIX_A fill:#e3f2fd
    style FIX_B fill:#e3f2fd
    style FIX_C fill:#e3f2fd
    style FIX_D fill:#e3f2fd
```

### Configuration Recommendations

| Setting | Recommended Value | Why |
|---------|-------------------|-----|
| **Schedule** | Daily (off-peak hours) | Catches revisions within 24 hours |
| **cleanOldAnnotations** | `true` | Prevents stale annotations from accumulating |
| **Auto-approve threshold** | >= 85% | High-confidence matches go live immediately |
| **Review threshold** | >= 70% | Catches plausible matches for expert validation |
| **Reject threshold** | < 70% | Avoids cluttering the review queue with bad matches |
| **Run mode** | Incremental | Only processes changed files (efficient) |

---

## Real-World Scenarios Explained Simply

These scenarios are written for people who work with P&IDs but may not be deeply familiar with how CDF handles them behind the scenes.

---

### Scenario 1: "The Engineer Updated a P&ID — What Happens?"

**The situation:** Sarah, a process engineer, updated P&ID `471-80-I-0026` to add a new pressure transmitter (PT 500) near the oil tank. She saved the new revision to SharePoint.

```mermaid
graph LR
    subgraph "What Sarah did"
        S1["Edited P&ID in CAD"]
        S2["Added PT 500"]
        S3["Saved Rev 06 to SharePoint"]
    end

    subgraph "What happens automatically"
        A1["File Extractor picks up<br/>the new file"]
        A2["CDF stores the new PDF"]
        A3["Annotation Workflow runs<br/>(next scheduled time)"]
        A4["Old annotations removed"]
        A5["New detection finds PT 500<br/>+ all existing equipment"]
        A6["New annotations created"]
    end

    subgraph "What the team sees"
        T1["Interactive diagram updates<br/>with PT 500 linked to<br/>its time series"]
        T2["All other equipment<br/>still linked correctly"]
    end

    S3 --> A1 --> A2 --> A3 --> A4 --> A5 --> A6 --> T1 & T2
```

**Key point for Sarah:** She doesn't need to do anything special in CDF. She updates the P&ID the same way she always does. The system handles the rest.

**What if she needs it immediately?** A CDF admin or the domain expert can manually trigger the workflow instead of waiting for the next scheduled run.

---

### Scenario 2: "Two P&IDs Show the Same Pump — One Was Updated"

**The situation:** P&ID A and P&ID B both show Pump P-4712. P&ID A was just revised, but P&ID B was not.

```mermaid
graph TB
    subgraph "P&ID A (REVISED)"
        A_OLD["Old annotations cleaned"]
        A_NEW["New detection runs"]
        A_PUMP["Pump P-4712 re-detected<br/>at its NEW position"]
    end

    subgraph "P&ID B (UNCHANGED)"
        B_ANN["Existing annotations<br/>remain exactly as they are"]
        B_PUMP["Pump P-4712 still annotated<br/>at its original position"]
    end

    subgraph "CDF Asset: Pump P-4712"
        ASSET["Querying this pump returns<br/>BOTH P&IDs"]
    end

    A_PUMP --> ASSET
    B_PUMP --> ASSET
```

**Key point:** Updating one P&ID does **not** affect the other. Each P&ID has its own independent set of annotations. If you search for Pump P-4712, CDF returns both drawings — each with annotations that accurately reflect their own content.

---

### Scenario 3: "An Instrument Was Removed from the Drawing"

**The situation:** The flow indicator FI 328 was removed from P&ID `471-80-I-0026` in the latest revision because the instrument was decommissioned.

**What happens:**

| Step | What Occurs |
|------|-------------|
| 1. Old state | FI 328 had an annotation linking it to time series `471FI328` |
| 2. New revision uploaded | The drawing no longer shows FI 328 |
| 3. Workflow runs | Old annotations (including FI 328's) are cleaned |
| 4. Fresh detection | OCR scans the new document — FI 328 is not found |
| 5. Result | No annotation is created for FI 328 — it's cleanly gone |

**Key point:** The system doesn't leave a "ghost" annotation pointing to empty space. Because detection runs fresh on the current document, removed equipment simply doesn't produce annotations. This is cleaner than trying to figure out "which annotations should I delete?" from the old set.

---

### Scenario 4: "We Added 50 New Assets to SAP — Will the P&IDs Pick Them Up?"

**The situation:** The maintenance team added 50 new equipment records to SAP. Some of this equipment appears on existing P&IDs but was never matched because CDF didn't know about it.

```mermaid
graph TB
    subgraph "Before"
        B1["P&ID shows 'PUMP P-5501'"]
        B2["CDF had no asset for P-5501"]
        B3["Annotation: Unlinked tag"]
    end

    subgraph "After SAP Update"
        A1["New asset 'Pump P-5501'<br/>ingested into CDF"]
        A2["Entity list now includes P-5501"]
    end

    subgraph "On Next Workflow Run"
        R1["P&ID re-contextualized<br/>(even if document didn't change)"]
        R2["OCR finds 'PUMP P-5501'"]
        R3["Matches to new asset"]
        R4["Annotation created:<br/>P-5501 → Asset"]
    end

    B3 -.->|"Asset added to SAP"| A1
    A1 --> A2
    A2 -->|"Run in ALL mode"| R1
    R1 --> R2 --> R3 --> R4

    style B3 fill:#fff9c4
    style R4 fill:#c8e6c9
```

**Key point:** This is one reason why fresh detection is powerful — it's not just about document changes. When the **asset list grows**, re-running detection on existing P&IDs can find matches that weren't possible before. To trigger this, run the workflow in **ALL mode** (rather than incremental, which only catches changed files).

---

### Scenario 5: "I Approved 60 Tags Last Week — Do I Have to Re-Approve Them All?"

**The situation:** A domain expert spent time reviewing and approving tags on a P&ID. Now the document was revised (minor change — one valve was added). Do they need to redo all their work?

**The honest answer:** The automated annotations will go through the confidence scoring cycle again. However:

- **High-confidence matches (>= 85%) are auto-approved** — if the same equipment is on the document and the match is strong, it goes live without human intervention
- **Only medium-confidence matches** appear in the review queue
- **Manually added tags are preserved** — they are not affected by the workflow cleanup

**In practice**, if the revision was minor (one valve added, rest unchanged):
- Most of the 60 tags will be re-detected with high confidence and auto-approved
- The new valve will appear as a new suggestion
- The expert only reviews a few items, not all 60

**How to minimize re-work:**
- Set auto-approve threshold appropriately (85% catches most stable matches)
- For tags that OCR consistently struggles with, add them manually — manual tags survive re-contextualization

---

### Scenario 6: "How Do I Know If a P&ID's Annotations Are Current?"

**The situation:** A field technician is looking at a P&ID in InField. How do they know the annotations are up to date?

**Check these two timestamps:**

| Timestamp | Where to Find It | What It Tells You |
|-----------|-------------------|-------------------|
| **File `lastUpdatedTime`** | CogniteFile node metadata | When the document content was last changed |
| **Annotation creation time** | On each annotation record | When the annotation was created |

**If annotations were created AFTER the file was last updated** — they're current.
**If annotations were created BEFORE the file was last updated** — the document was revised and annotations may not reflect the latest content.

The annotation workflow's RAW state table also tracks the last processing time for each file, which an admin can check.

---

## What CDF Tracks Inside a P&ID

For every tag detected on a P&ID, CDF stores a separate annotation. Here's what a fully annotated P&ID looks like:

```mermaid
graph TB
    PID["P&ID: 471-80-I-0026_05.pdf"]

    subgraph "Annotations (one per detected tag)"
        A1["#1 Equipment Tag<br/>────────────<br/>Text: 'OIL TANK 471-5-8157'<br/>Region: (120, 300, 90, 40)<br/>Type: diagrams.AssetLink<br/>Target: Asset floc:...-8157<br/>Confidence: 0.94"]

        A2["#2 Instrument Tag<br/>────────────<br/>Text: 'LT 309'<br/>Region: (450, 200, 40, 40)<br/>Type: diagrams.AssetLink<br/>Target: TS 471LT309<br/>Confidence: 0.88"]

        A3["#3 Instrument Tag<br/>────────────<br/>Text: 'FI 328'<br/>Region: (300, 500, 40, 40)<br/>Type: diagrams.AssetLink<br/>Target: TS 471FI328<br/>Confidence: 0.91"]

        A4["#4 Drawing Reference<br/>────────────<br/>Text: 'SEE DWG 471-80-I-0025'<br/>Region: (700, 50, 150, 25)<br/>Type: diagrams.FileLink<br/>Target: File 471-80-I-0025.pdf<br/>Confidence: 0.97"]

        A5["#5 Equipment Tag<br/>────────────<br/>Text: 'PUMP P-4712'<br/>Region: (600, 380, 80, 35)<br/>Type: diagrams.AssetLink<br/>Target: Asset pump_p4712<br/>Confidence: 0.85"]
    end

    PID --> A1 & A2 & A3 & A4 & A5
```

Each annotation is an **independent record** — it can be approved, rejected, or modified without affecting other annotations on the same file.

---

## Cross-Document References

When multiple P&IDs reference the same equipment, CDF maintains independent annotation sets on each file:

```mermaid
graph TB
    subgraph "P&ID A: 471-80-I-0026"
        PA_1["Annotation → Asset: Oil Tank"]
        PA_2["Annotation → TS: 471LT309"]
        PA_3["Annotation → File: P&ID B"]
    end

    subgraph "P&ID B: 471-80-I-0025"
        PB_1["Annotation → Asset: Oil Tank"]
        PB_2["Annotation → TS: 471PT346"]
        PB_3["Annotation → File: P&ID A"]
    end

    subgraph "CDF Resources"
        ASSET["Asset: Oil Tank<br/>(referenced by both P&IDs)"]
        TS1["TS: 471LT309"]
        TS2["TS: 471PT346"]
    end

    PA_1 & PB_1 -->|"AssetLink"| ASSET
    PA_2 -->|"AssetLink"| TS1
    PB_2 -->|"AssetLink"| TS2
    PA_3 -.->|"FileLink"| PB_1
    PB_3 -.->|"FileLink"| PA_1
```

**Key behaviors:**
- Each P&ID has its **own annotations** — they are independent
- Both P&IDs can link to the **same asset**; querying that asset returns both files
- `FileLink` annotations create **cross-references** between P&IDs
- Updating one P&ID does **not** affect annotations on the other

---

## Detection Capabilities by File Type

| Capability | Vectorized PDF | Rasterized / Scanned |
|-----------|---------------|---------------------|
| Tag detection (OCR) | Yes | Yes |
| Symbol detection | Yes | No |
| Symbol library matching | Yes | No |
| Connection tracing | Yes | No |
| Tag-symbol merge | Yes | No |
| Multi-page support | First page only | All pages (tag detection) |
| Output quality | High (precise vectors) | Medium (depends on scan quality) |

---

## Three Approaches to P&ID Contextualization

CDF provides three ways to contextualize P&IDs, from manual to fully automated:

### Approach 1: CDF UI (Diagram Parsing)

**Best for:** Small batches, initial setup, manual review

```mermaid
graph LR
    A["Select files<br/>in CDF UI"] --> B["Choose assets<br/>to match against"]
    B --> C["Select model<br/>(Standard/Advanced)"]
    C --> D["Run model"]
    D --> E["Review & approve<br/>in interactive view"]
    E --> F["Save as interactive<br/>diagram"]
```

### Approach 2: Diagrams API (Programmatic)

**Best for:** Custom matching logic, integration into scripts

```mermaid
graph LR
    A["Build entity list<br/>(Python)"] --> B["Call diagrams.detect()"]
    B --> C["Process results"]
    C --> D["Create annotations<br/>(SDK)"]
    D --> E["Validate"]
```

### Approach 3: Automated Workflow (Deployment Pack)

**Best for:** Production-scale, recurring processing, CI/CD integration

```mermaid
graph LR
    A["Deploy via<br/>Cognite Toolkit"] --> B["Configure extraction<br/>pipeline"]
    B --> C["Tagging transformations<br/>(file + asset labels)"]
    C --> D["CDF Workflow runs<br/>(scheduled or triggered)"]
    D --> E["Incremental processing<br/>(state in RAW)"]
    E --> F["Annotations created<br/>(threshold-based approval)"]
```

| Feature | CDF UI | Diagrams API | Deployment Pack |
|---------|--------|-------------|-----------------|
| **Ease of setup** | Click-through | Code required | Toolkit deploy |
| **Scale** | Small batches | Medium | Large (1000s of files) |
| **Incremental** | Manual | Manual | Automatic (RAW state) |
| **Auto-approval** | No (all manual) | Custom | Threshold-based |
| **Cleanup** | Manual | Custom | `cleanOldAnnotations` flag |
| **Scheduling** | Manual | Cron / external | CDF Workflows |
| **Symbol detection** | Yes | No (tags only) | No (tags only) |

### Sylvamo Implementation (Approach 3)

The Sylvamo codebase implements the automated workflow via:

| Component | Value |
|-----------|-------|
| **Extraction pipeline** | `ctx_files_pandid_annotater` |
| **CDF Function** | `contextualization_p_and_id_annotater` |
| **Module** | `cdf_p_and_id_parser` (Cognite Toolkit `tk:contextualization`) |
| **Entity views** | CogniteFile, CogniteEquipment, CogniteAsset, CogniteTimeSeries |
| **Search property** | `name` |
| **Supported mime types** | `application/pdf`, `image/jpeg`, `image/png`, `image/tiff` |
| **Auto-approval threshold** | 0.85 (configurable) |
| **Auto-reject threshold** | 0.25 (configurable) |

The pipeline uses the Cognite Diagrams API (`client.diagrams.detect`) and writes annotations to the data model. A separate **Direct Relation Writer** (`ctx_files_direct_relation_write`) syncs approved annotations to direct relations (e.g., `CogniteFile.assets`, `CogniteEquipment.files`).

---

## Known Limitations

These are platform characteristics to be aware of when planning your P&ID contextualization strategy:

| Characteristic | Description | What to Do |
|---------------|-------------|------------|
| **Vectorized: first page only** | Only page 1 is parsed for vectorized PDFs | Split multi-page PDFs before ingestion |
| **Re-contextualization is workflow-driven** | Updating a file does not auto-trigger re-parsing; the annotation workflow must run | Schedule the workflow daily/weekly, or trigger manually when needed |
| **Full re-detection per run** | CDF does not diff revisions — it re-parses the entire document | This is by design for accuracy; incremental mode ensures only changed files are processed |
| **Annotations reset on re-detection** | New annotations go through confidence scoring again | High-confidence matches auto-approve; only edge cases need review |
| **Manual annotations preserved** | Only workflow-owned annotations are cleaned | Use manual tags for equipment that OCR consistently misses |
| **Symbol libraries are project-specific** | Must build/maintain library per project | Start with CDF templates; refine over time |
| **OCR quality depends on source** | Scanned/rasterized documents have lower accuracy | Use vectorized PDFs where possible; set lower auto-approve thresholds for scans |
| **Entity list must be current** | Matches depend on what's in the entity list | Keep asset/time series lists in sync with source systems (SAP, PI, etc.) |

---

## Related Documents

- [CDF File Management](CDF_FILE_MANAGEMENT.md) — How CDF stores and organizes files
- [Annotation Workflow & Versioning](ANNOTATION_WORKFLOW_AND_VERSIONING.md) — Annotation states, confidence model, revision workflow
- [Contextualization Primer](../CONTEXTUALIZATION_PRIMER.md) — Best practices and architectural guidance
- [Contextualization Gap Analysis](../CONTEXTUALIZATION_GAP_ANALYSIS.md) — Current Sylvamo implementation vs. best practices

---

*This document describes Cognite CDF platform capabilities as of February 2026.*
