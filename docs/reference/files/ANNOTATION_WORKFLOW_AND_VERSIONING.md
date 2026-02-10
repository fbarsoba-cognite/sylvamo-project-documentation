# Annotation Workflow & File Versioning

> How CDF manages annotations on engineering diagrams: creation, scoring, approval, and behavior across file revisions.

**Last updated:** February 10, 2026

---

## Table of Contents

- [Overview](#overview)
- [What Is an Annotation?](#what-is-an-annotation)
- [Annotation Types](#annotation-types)
- [Annotation Lifecycle (State Machine)](#annotation-lifecycle-state-machine)
- [Confidence Scoring Model](#confidence-scoring-model)
- [Approval Workflow](#approval-workflow)
- [Annotation Storage & Ownership](#annotation-storage--ownership)
- [File Versioning: What CDF Does and Does Not Do](#file-versioning-what-cdf-does-and-does-not-do)
- [Revision Scenarios](#revision-scenarios)
- [Re-Contextualization Pipeline](#re-contextualization-pipeline)
- [What Survives a Revision](#what-survives-a-revision)
- [Best Practices](#best-practices)
- [Annotation API Reference](#annotation-api-reference)
- [Frequently Asked Questions](#frequently-asked-questions)

---

## Overview

When CDF parses a P&ID or engineering diagram, it creates **annotations** — precise, structured links between specific regions on the document and CDF resources (assets, time series, other files). This document covers how those annotations are managed throughout their lifecycle, including what happens when the underlying document is revised.

---

## What Is an Annotation?

An annotation is a record that says:

> "At this exact location on this document, there is a tag that refers to this specific resource in CDF."

```mermaid
graph TB
    subgraph "Annotation Record"
        subgraph "Source (WHERE)"
            S1["annotatedResourceId: file_3851544762966265"]
            S2["annotatedResourceType: file"]
            S3["page: 1"]
            S4["region: x=342, y=156, w=89, h=42"]
            S5["detectedText: 'OIL TANK 471-5-8157'"]
        end

        subgraph "Target (WHAT)"
            T1["type: diagrams.AssetLink"]
            T2["targetResourceId: asset_12345"]
            T3["targetExternalId: floc:0769-06-...-8157"]
        end

        subgraph "Quality"
            Q1["confidence: 0.92"]
            Q2["status: approved"]
            Q3["createdBy: pid_annotation_workflow"]
        end
    end
```

**Key properties:**
- **Bounding box** — pixel coordinates on the specific page
- **Detected text** — what OCR read at that location
- **Target** — the CDF resource this tag links to
- **Confidence** — how certain the match is (0.0 to 1.0)
- **Status** — whether the annotation is approved, suggested, or rejected

---

## Annotation Types

CDF uses three annotation types for engineering diagrams:

```mermaid
graph LR
    subgraph "diagrams.AssetLink"
        AL_DESC["Links a region on a P&ID<br/>to a CDF Asset or TimeSeries"]
        AL_EX["Example:<br/>'OIL TANK 471-5-8157'<br/>→ Asset: Oil Tank PM1"]
    end

    subgraph "diagrams.FileLink"
        FL_DESC["Links a reference on a P&ID<br/>to another P&ID or file"]
        FL_EX["Example:<br/>'SEE DWG 471-80-I-0025'<br/>→ File: 471-80-I-0025.pdf"]
    end

    subgraph "images.AssetLink"
        IL_DESC["Links a region on an image<br/>to a CDF Asset"]
        IL_EX["Example:<br/>Photo region<br/>→ Asset: Pump P-4712"]
    end
```

| Type | Use Case | Created By |
|------|----------|-----------|
| `diagrams.AssetLink` | Equipment/instrument tag → asset or time series | Diagrams API, Workflow, Manual |
| `diagrams.FileLink` | Drawing reference → other P&ID | Diagrams API, Workflow, Manual |
| `images.AssetLink` | Photo/image region → asset | Vision API, Manual |

---

## Annotation Lifecycle (State Machine)

Each annotation goes through a defined lifecycle:

```mermaid
stateDiagram-v2
    [*] --> Detected: Diagram parsing runs<br/>(OCR + entity matching)

    state "Confidence Check" as CC
    Detected --> CC

    CC --> AutoApproved: confidence >= 85%
    CC --> Suggested: confidence 70% — 85%
    CC --> AutoRejected: confidence < 70%

    Suggested --> Approved: Domain expert approves
    Suggested --> Rejected: Domain expert rejects

    state "Active Annotation" as ACTIVE
    AutoApproved --> ACTIVE
    Approved --> ACTIVE

    ACTIVE --> Stale: File content updated<br/>(new revision uploaded)

    Stale --> Deleted: Re-contextualization<br/>cleans old annotations
    Stale --> CC: Re-contextualization<br/>re-detects and re-scores

    AutoRejected --> [*]: Discarded
    Rejected --> [*]: Discarded
    Deleted --> [*]: Cleaned up

    note right of Suggested
        Shown in CDF UI with
        orange highlight. Requires
        human review.
    end note

    note right of Stale
        Bounding box may point
        to wrong location.
        Must re-contextualize.
    end note
```

### State Definitions

| State | Description | Visible in UI? | Navigable? |
|-------|-------------|----------------|------------|
| **Detected** | Just created by detection; confidence not yet evaluated | No (transient) | No |
| **Auto-Approved** | High confidence; immediately active | Yes (blue outline) | Yes |
| **Suggested** | Medium confidence; needs review | Yes (orange outline) | No |
| **Approved** | Expert confirmed the link | Yes (blue outline) | Yes |
| **Auto-Rejected** | Low confidence; discarded | No | No |
| **Rejected** | Expert rejected the link | No | No |
| **Stale** | Document changed; annotation may be wrong | Yes (still shows) | Yes (but unreliable) |

---

## Confidence Scoring Model

### How Confidence Is Calculated

The Diagrams API calculates confidence based on:

1. **Text similarity** — how well the detected text matches the entity name/identifier
2. **Token overlap** — shared tokens between detection and entity
3. **Uniqueness** — whether the match is ambiguous (multiple candidates) or clear

### Recommended Two-Threshold System

```mermaid
graph TB
    subgraph "Confidence Scale (0.0 → 1.0)"
        direction LR
        REJ["0.0 ─── 0.70<br/>AUTO-REJECT<br/>Too uncertain"]
        REV["0.70 ─── 0.85<br/>REVIEW QUEUE<br/>Expert decides"]
        APP["0.85 ─── 1.0<br/>AUTO-APPROVE<br/>High confidence"]
    end

    style REJ fill:#ffcdd2
    style REV fill:#fff9c4
    style APP fill:#c8e6c9
```

| Range | Action | Rationale |
|-------|--------|-----------|
| **< 70%** | Auto-reject | Too many false positives at lower thresholds |
| **70% — 85%** | Queue for review | Plausible but needs human confirmation |
| **>= 85%** | Auto-approve | High confidence; reliable for production use |

> **Anti-pattern:** Using a single low threshold (e.g., 0.20) for auto-approval produces many false positives and undermines trust in the interactive diagrams.

### Quality Metric

The overall quality of a parsed P&ID can be measured as:

```
Contextualization Quality = Matched Tags / Total Detected Tags
```

A well-contextualized P&ID typically achieves 70-90% quality, with the remainder being generic text (e.g., "PROCESS WATER", "NOTES") that should not link to any resource.

---

## Approval Workflow

### In the CDF UI

```mermaid
graph TB
    START["Open diagram in<br/>Diagram Parsing UI"]
    START --> STATUS{"Diagram Status?"}

    STATUS -->|"Pending Approval"| REVIEW["Review detected tags"]
    STATUS -->|"All Approved"| DONE["Interactive diagram ready"]

    REVIEW --> TAG{"Select a tag"}

    TAG --> APPROVE["Approve Tag<br/>(blue outline)"]
    TAG --> REJECT["Reject Tag<br/>(removed)"]
    TAG --> ADD["Add New Tag<br/>(draw box, link resource)"]

    APPROVE --> SAVE["Save Changes"]
    REJECT --> SAVE
    ADD --> SAVE

    SAVE --> MORE{"More tags?"}
    MORE -->|"Yes"| TAG
    MORE -->|"No"| DONE
```

### Via the Automated Workflow (Deployment Pack)

```mermaid
graph TB
    TRIGGER["Workflow triggered<br/>(scheduled or manual)"]

    TRIGGER --> STATE["Check RAW state table<br/>(which files are new/updated?)"]

    STATE --> PROCESS["For each unprocessed file:"]

    PROCESS --> DETECT["Run Diagrams Detect"]
    DETECT --> SCORE["Score all matches"]

    SCORE --> HIGH{"Score >= threshold?"}
    HIGH -->|"Yes"| AUTO["Create annotation<br/>(auto-approved)"]
    HIGH -->|"No"| SUGGEST["Create annotation<br/>(suggested)"]

    AUTO --> LOG["Log to extraction pipeline"]
    SUGGEST --> LOG

    LOG --> UPDATE["Update RAW state:<br/>file = processed"]
    UPDATE --> NEXT{"More files?"}
    NEXT -->|"Yes"| PROCESS
    NEXT -->|"No"| COMPLETE["Workflow complete"]
```

### Bulk Operations

The CDF UI supports bulk actions on diagrams:

| Action | Effect |
|--------|--------|
| **Approve All** | Approves all pending tags on selected diagrams |
| **Reject Pending** | Rejects all pending tags |
| **Clear All Tags** | Removes all annotations |
| **Recontextualize** | Re-runs detection from scratch |

---

## Annotation Storage & Ownership

### Where Annotations Live

Annotations are stored as CDF resources associated with a file:

```mermaid
graph LR
    FILE["CogniteFile<br/>(data model node)"]
    FS["File Service<br/>(binary content)"]
    ANN_SET["Annotation Set<br/>(all annotations on this file)"]

    subgraph "Individual Annotations"
        A1["Annotation #1<br/>diagrams.AssetLink"]
        A2["Annotation #2<br/>diagrams.AssetLink"]
        A3["Annotation #3<br/>diagrams.FileLink"]
    end

    FILE --> ANN_SET
    FS --> ANN_SET
    ANN_SET --> A1 & A2 & A3
```

### Ownership and Cleanup Rules

When re-contextualizing, it's critical to know **who created** each annotation:

```mermaid
graph TB
    subgraph "Annotation Sources"
        WF["Workflow-created<br/>(automated pipeline)"]
        UI["UI-created<br/>(interactive diagram parsing)"]
        MAN["Manually-created<br/>(expert drew bounding box)"]
        API["API-created<br/>(custom script)"]
    end

    subgraph "Cleanup Behavior"
        CLEAN["cleanOldAnnotations = true"]
    end

    WF -->|"DELETED by cleanup"| CLEAN
    UI -->|"PRESERVED"| CLEAN
    MAN -->|"PRESERVED"| CLEAN
    API -->|"Depends on createdBy tag"| CLEAN
```

**Rule:** The automated workflow only deletes annotations **it created** (identified by the `createdBy` field). Manually created annotations and annotations from other tools are preserved.

---

## File Versioning: What CDF Does and Does Not Do

### What CDF Provides

| Feature | Available? | Details |
|---------|-----------|---------|
| Store file binary | Yes | Upload via File Service |
| Replace file content | Yes | Re-upload to same externalId |
| Track file metadata changes | Yes | `lastUpdatedTime` updates |
| Maintain revision history | **No** | Old content overwritten |
| Compare revisions (diff) | **No** | No built-in comparison |
| Auto-carry annotations to new revision | **No** | Must re-detect |
| Version numbering | **No** | Manual via metadata/externalId |

### The Versioning Gap

```mermaid
graph TB
    subgraph "What Exists in CDF"
        E1["File binary storage"]
        E2["Metadata with timestamps"]
        E3["Overwrite capability"]
        E4["Detection re-run capability"]
    end

    subgraph "What Does NOT Exist"
        N1["Revision chain<br/>(Rev 05 → Rev 06 → Rev 07)"]
        N2["Content diff<br/>(what changed between revisions)"]
        N3["Annotation migration<br/>(carry approved tags forward)"]
        N4["Version browser<br/>(view old versions)"]
    end

    style N1 fill:#ffcdd2
    style N2 fill:#ffcdd2
    style N3 fill:#ffcdd2
    style N4 fill:#ffcdd2
```

---

## Revision Scenarios

### Scenario 1: Minor Layout Change (Equipment Repositioned)

```mermaid
graph LR
    subgraph "Rev 05"
        R5_TANK["Oil Tank at (120, 300)"]
        R5_ANN["Annotation: (120, 300) → Asset X"]
    end

    subgraph "Rev 06"
        R6_TANK["Oil Tank at (200, 450)"]
        R6_ANN_OLD["Old annotation: (120, 300)<br/>⚠️ WRONG POSITION"]
        R6_ANN_NEW["New annotation needed:<br/>(200, 450) → Asset X"]
    end

    R5_TANK -.->|"Tank moved"| R6_TANK
    R5_ANN -.->|"Now stale"| R6_ANN_OLD

    style R6_ANN_OLD fill:#ffcdd2
    style R6_ANN_NEW fill:#c8e6c9
```

**Result:** Same asset link, but bounding box is wrong. Must re-detect to get correct coordinates.

### Scenario 2: Equipment Added

```mermaid
graph LR
    subgraph "Rev 05"
        R5_EQ["2 equipment items<br/>2 annotations"]
    end

    subgraph "Rev 06"
        R6_EQ["3 equipment items<br/>New valve added"]
        R6_ANN["Old: 2 annotations<br/>Missing: annotation for new valve"]
    end

    style R6_ANN fill:#fff9c4
```

**Result:** New equipment has no annotation. Must re-detect to find the new tag.

### Scenario 3: Equipment Removed

```mermaid
graph LR
    subgraph "Rev 05"
        R5_EQ["3 equipment items<br/>3 annotations"]
    end

    subgraph "Rev 06"
        R6_EQ["2 equipment items<br/>Pump removed from drawing"]
        R6_ANN["Old: 3 annotations<br/>Orphan: annotation for removed pump"]
    end

    style R6_ANN fill:#ffcdd2
```

**Result:** An annotation exists for equipment no longer on the drawing. Must re-detect and clean old annotations.

### Scenario 4: Cross-Reference Changed

```mermaid
graph LR
    subgraph "Rev 05"
        R5_REF["Reference: 'SEE DWG 471-80-I-0025'<br/>FileLink → 471-80-I-0025.pdf"]
    end

    subgraph "Rev 06"
        R6_REF["Reference changed to: 'SEE DWG 471-80-I-0030'<br/>Old FileLink points to wrong file"]
    end

    style R6_REF fill:#ffcdd2
```

**Result:** FileLink annotation points to the wrong document. Must re-detect.

---

## Re-Contextualization Pipeline

### Full Sequence

```mermaid
sequenceDiagram
    participant SRC as Source System
    participant CDF as CDF File Service
    participant DM as Data Model
    participant WF as Annotation Workflow
    participant RAW as RAW State Table
    participant DA as Diagrams API
    participant EXP as Domain Expert

    Note over SRC,EXP: File Revision Uploaded

    SRC->>CDF: Upload revised P&ID content
    CDF->>DM: lastUpdatedTime updated

    Note over WF: Workflow triggered (schedule / manual)

    WF->>RAW: Query state table
    RAW-->>WF: Files updated since last run

    loop For each updated file
        WF->>WF: Check cleanOldAnnotations setting

        opt cleanOldAnnotations = true
            WF->>CDF: Delete annotations where<br/>createdBy = this workflow
            Note over CDF: Manual annotations preserved
        end

        WF->>DA: diagrams.detect(<br/>  fileId, entities, searchField)
        DA-->>WF: Detection results:<br/>tags + bounding boxes + matches

        loop For each detected tag
            WF->>WF: Calculate confidence score

            alt score >= auto_approve_threshold
                WF->>CDF: Create annotation (status: approved)
            else score >= suggest_threshold
                WF->>CDF: Create annotation (status: suggested)
            else score < suggest_threshold
                WF->>WF: Discard (auto-reject)
            end
        end

        WF->>RAW: Update state: file processed
        WF->>CDF: Log run status to extraction pipeline
    end

    Note over EXP: Review suggested annotations

    EXP->>CDF: Open diagram in CDF UI
    EXP->>CDF: Approve / Reject suggested tags
    EXP->>CDF: Optionally add manual tags
```

### Run Modes

| Mode | Behavior | When to Use |
|------|----------|-------------|
| **Incremental** | Only processes files with `lastUpdatedTime` newer than last run | Default; for ongoing operations |
| **ALL** | Clears RAW state and reprocesses every file | After major data model changes or bulk re-ingestion |
| **Full Cleanup** | Sets `cleanOldAnnotations = true` + ALL mode | When annotation quality needs full reset |

---

## What Survives a Revision

Summary of what persists and what is lost when a P&ID is revised:

```mermaid
graph TB
    subgraph "SURVIVES Revision"
        S1["CogniteFile node<br/>(metadata, space, externalId)"]
        S2["CogniteFile.assets<br/>(direct relation to parent asset)"]
        S3["Manually created annotations<br/>(not owned by workflow)"]
        S4["File labels/tags"]
        S5["Data model properties"]
    end

    subgraph "LOST on Revision (if same externalId)"
        L1["Previous binary content<br/>(old PDF overwritten)"]
        L2["Bounding box accuracy<br/>(coordinates may be wrong)"]
        L3["Workflow-created annotations<br/>(deleted by cleanup)"]
        L4["Approved status<br/>(new annotations start as suggested)"]
        L5["Detection results cache"]
    end

    style S1 fill:#c8e6c9
    style S2 fill:#c8e6c9
    style S3 fill:#c8e6c9
    style S4 fill:#c8e6c9
    style S5 fill:#c8e6c9
    style L1 fill:#ffcdd2
    style L2 fill:#ffcdd2
    style L3 fill:#ffcdd2
    style L4 fill:#ffcdd2
    style L5 fill:#ffcdd2
```

---

## Best Practices

### 1. Revision Strategy

| Approach | Pros | Cons | Recommended When |
|----------|------|------|------------------|
| **Overwrite (same ID)** | Simple; one file node | No history; annotations lost | Minor revisions; history not needed |
| **New ID per revision** | Full history preserved | Must manage revision chain; double annotations | Major revisions; audit trail required |

### 2. Annotation Quality

- **Use two thresholds** (reject < 70%, review 70-85%, approve >= 85%)
- **Blacklist generic terms** (e.g., "NOTES", "PROCESS WATER", "SCALE") to avoid false matches
- **Scope entity lists** to the same plant/area as the P&ID
- **Track quality metrics**: `Matched Tags / Total Detected Tags` per file

### 3. Operational Process

- **Schedule the annotation workflow** to run periodically (e.g., daily or weekly)
- **Use incremental mode** by default; run ALL mode only for resets
- **Always enable `cleanOldAnnotations`** when re-processing to avoid stale links
- **Monitor extraction pipeline logs** for failed files and low-confidence batches

### 4. Domain Expert Review

- Prioritize review of files with many **suggested** annotations
- Use the **"Recontextualize"** option in the UI if detection results look poor
- Add manual tags for equipment that OCR consistently misses
- Save approved diagrams as **SVG** for offline reference

---

## Annotation API Reference

### Create Annotation (Python SDK)

```python
from cognite.client.data_classes import Annotation

annotation = Annotation(
    annotated_resource_type="file",
    annotated_resource_id=file_id,
    annotation_type="diagrams.AssetLink",
    status="suggested",
    creating_app="pid_annotation_workflow",
    creating_app_version="1.0",
    creating_user=None,
    data={
        "fileRef": {"fileId": file_id},
        "assetRef": {"id": asset_id},
        "pageNumber": 1,
        "textRegion": {
            "xMin": 0.15,
            "yMin": 0.30,
            "xMax": 0.25,
            "yMax": 0.35,
        },
        "text": "OIL TANK 471-5-8157",
        "confidence": 0.92,
    },
)

client.annotations.create(annotation)
```

### Query Annotations for a File

```python
# Get all annotations on a specific file
annotations = client.annotations.list(
    filter={
        "annotated_resource_type": "file",
        "annotated_resource_ids": [{"id": file_id}],
        "annotation_type": "diagrams.AssetLink",
        "status": "approved",
    },
    limit=100,
)
```

### Query Files Linked to an Asset (Reverse)

```python
# Find all files annotated to a specific asset
annotations = client.annotations.list(
    filter={
        "annotation_type": "diagrams.AssetLink",
        "data": {"assetRef": {"id": asset_id}},
        "status": "approved",
    },
    limit=100,
)

file_ids = [a.annotated_resource_id for a in annotations]
```

### Delete Workflow Annotations

```python
# Delete only annotations created by a specific workflow
annotations = client.annotations.list(
    filter={
        "annotated_resource_type": "file",
        "annotated_resource_ids": [{"id": file_id}],
        "creating_app": "pid_annotation_workflow",
    },
    limit=-1,
)

if annotations:
    client.annotations.delete([a.id for a in annotations])
```

---

## Frequently Asked Questions

### Q: If I update a P&ID, do the annotations update automatically?
**No.** Annotations are a snapshot from the time of detection. When the document changes, you must re-run the contextualization pipeline to generate new annotations.

### Q: What happens to manually-added tags when I re-contextualize?
**They are preserved.** The automated cleanup only deletes annotations it created (identified by `creatingApp`). Manually added annotations are not touched.

### Q: Can I carry approved annotations forward to a new revision?
**Not automatically.** CDF does not compare revisions or migrate annotations. After re-detection, all annotations start fresh. The domain expert must re-approve suggested ones.

### Q: What if two P&IDs reference the same equipment?
**Both get their own annotations.** Querying that asset returns both files. The annotations are independent — updating one P&ID does not affect the other.

### Q: How do I know if annotations are stale?
**Check `lastUpdatedTime` on the file** vs. the annotation creation time. If the file was updated after the annotations were created, they may be stale.

### Q: Can I diff two versions of a P&ID?
**Not in CDF.** There is no built-in comparison tool for file content changes. You would need external tooling to compare PDFs.

---

## Related Documents

- [CDF File Management](CDF_FILE_MANAGEMENT.md) — File storage architecture and CogniteFile CDM
- [P&ID Contextualization Lifecycle](PID_CONTEXTUALIZATION_LIFECYCLE.md) — End-to-end lifecycle phases
- [Contextualization Primer](../CONTEXTUALIZATION_PRIMER.md) — Best practices and conceptual guidance
- [Contextualization Gap Analysis](../CONTEXTUALIZATION_GAP_ANALYSIS.md) — Sylvamo implementation vs. best practices

---

*This document describes Cognite CDF platform capabilities as of February 2026.*
