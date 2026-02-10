# P&ID Contextualization Lifecycle

> End-to-end lifecycle of how Cognite CDF ingests, parses, annotates, and maintains P&ID documents.

**Last updated:** February 10, 2026

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

When a P&ID is revised (e.g., equipment moved, instruments added/removed), the existing annotations become stale:

```mermaid
graph TB
    subgraph "Before Revision"
        R5["P&ID Rev 05"]
        R5_A["60 Annotations<br/>(all approved)"]
        R5_L["Linked to PM1 asset"]
        R5 --- R5_A & R5_L
    end

    subgraph "After Revision Upload"
        R6["P&ID Rev 06 uploaded"]
        STALE["Old annotations STALE<br/>────────────────<br/>Bounding boxes may be wrong<br/>Deleted tags still have annotations<br/>New tags have no annotations<br/>Cross-references may be broken"]
    end

    subgraph "Re-Contextualization"
        RC1["Detect updated file<br/>(lastUpdatedTime changed)"]
        RC2["Clean old annotations<br/>(if configured)"]
        RC3["Re-run full detection"]
        RC4["Create new annotations"]
        RC5["Review & approve"]
    end

    R5 -.->|"Document revised"| R6
    R6 --> STALE
    STALE -->|"Must re-process"| RC1
    RC1 --> RC2 --> RC3 --> RC4 --> RC5

    style STALE fill:#ffcdd2
```

### Re-Contextualization Process

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
        WF->>CDF: Delete stale annotations<br/>(only workflow-created ones)
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

### What Is Lost on Revision

| Item | Behavior | Mitigation |
|------|----------|------------|
| **Bounding box positions** | Stale if layout changed | Re-detect regenerates all positions |
| **Approved annotation status** | Lost — new annotations start as suggested | Domain expert must re-approve |
| **Manually added tags** | Preserved (only workflow annotations are cleaned) | Manual annotations survive |
| **File-to-asset direct relation** | Preserved (on CogniteFile node) | Not affected by re-detection |
| **Previous revision content** | Lost if same externalId (overwrite) | Use unique IDs per revision |

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

---

## Known Limitations

| Limitation | Description | Impact |
|-----------|-------------|--------|
| **Vectorized: first page only** | Only page 1 is parsed for vectorized PDFs | Critical info on later pages is missed; split files first |
| **No automatic re-contextualization** | Updating a file does NOT trigger re-parsing | Stale annotations until pipeline re-runs |
| **No diff/change tracking** | Cannot compare what changed between revisions | Full re-parse required; no delta |
| **Approved status lost on re-detect** | New annotations start as suggested | Domain expert must re-approve |
| **No built-in annotation carry-over** | Unchanged tags are not preserved across revisions | All annotations regenerated from scratch |
| **Symbol libraries are project-specific** | Must build/maintain library per project | Initial effort to set up; templates help |
| **OCR quality varies** | Scanned documents may have recognition errors | Lower confidence scores; more manual review |
| **No cross-site matching** | Entity list must be scoped to the same location | Prevents false matches but requires careful setup |

---

## Related Documents

- [CDF File Management](CDF_FILE_MANAGEMENT.md) — How CDF stores and organizes files
- [Annotation Workflow & Versioning](ANNOTATION_WORKFLOW_AND_VERSIONING.md) — Annotation states, confidence model, revision workflow
- [Contextualization Primer](../CONTEXTUALIZATION_PRIMER.md) — Best practices and architectural guidance
- [Contextualization Gap Analysis](../CONTEXTUALIZATION_GAP_ANALYSIS.md) — Current Sylvamo implementation vs. best practices
- [P&ID Annotation Plan](../../../docs/reference/sylvamo-pid-sortfield-call/PLAN-pid-annotation-and-asset-linkage.md) — Sylvamo-specific POC results

---

*This document describes Cognite CDF platform capabilities as of February 2026.*
