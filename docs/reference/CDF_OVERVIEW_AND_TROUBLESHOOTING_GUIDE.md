# CDF / Industrial Data Landscape (IDL) — Overview & Troubleshooting Guide

> **Purpose:** Help you understand the main components, how they interact, and how to independently investigate and diagnose issues. Use this to guide questions and walkthroughs with Cognite or internal teams.

---

## Table of Contents

1. [General Overview](#1-general-overview)
2. [Main Components & How They Interact](#2-main-components--how-they-interact)
3. [High-Level Troubleshooting Walkthrough](#3-high-level-troubleshooting-walkthrough)
4. [Advanced Monitoring & Troubleshooting](#4-advanced-monitoring--troubleshooting)
5. [What We Can Explain & Walk Through in CDF](#5-what-we-can-explain--walk-through-in-cdf)

---

## 1. General Overview

### What is the Industrial Data Landscape (IDL)?

The **IDL** is Sylvamo’s implementation of manufacturing data in **Cognite Data Fusion (CDF)**. It connects:

- **Source systems** (SAP, Fabric/PPR/PPV, Proficy, PI, SharePoint)
- **Extractors** (hosted on VMs or as CDF extraction pipelines)
- **RAW tables** (staging layer in CDF)
- **Transformations** (SQL that maps RAW → data model)
- **Data model views** (Asset, Reel, Roll, Event, RollQuality, etc.)

### High-Level Flow

```
Source Systems  →  Extractors  →  RAW Tables  →  Transformations  →  Data Model Views
     (SAP, Fabric, PI, etc.)      (raw_ext_*)    (populate_*)       (Asset, Roll, etc.)
```

---

## 2. Main Components & How They Interact

### 2.1 Component Map

| Component | What It Is | Where It Lives | Depends On |
|-----------|------------|----------------|------------|
| **Source Systems** | SAP, Fabric, Proficy, PI, SharePoint | External (on-prem / cloud) | Network, credentials |
| **Extractors** | Services that pull data into CDF | PAMIDL02 VM (Windows services, Task Scheduler) or CDF Extraction Pipelines | Source access, CDF credentials |
| **RAW Tables** | Staging databases in CDF (e.g. `raw_ext_fabric_ppr`) | CDF → Data Management → RAW | Extractors must run successfully |
| **Transformations** | SQL jobs that read RAW and write to data model | CDF → Transformations | RAW tables populated |
| **CDF Functions** | Code that runs on schedule (e.g. SharePoint → RollQuality) | CDF → Functions | Extraction pipeline config, auth |
| **Data Model** | Views (Asset, Reel, Roll, Event, RollQuality, etc.) | CDF → Data Models | Transformations / Functions |
| **Auth / Groups** | Who can access what | CDF → Access Management | Entra ID groups, CDF groups |
| **CI/CD** | Deploys config from ADO repo to CDF | Azure DevOps pipelines | `cdf build`, `cdf deploy` |

### 2.2 How Components Interact

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              EXTERNAL SOURCES                                            │
│  SAP Gateway │ Fabric (PPR/PPV/SAP ECC) │ Proficy GBDB │ PI Servers │ SharePoint        │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  EXTRACTORS (PAMIDL02 VM or CDF Extraction Pipelines)                                    │
│  • fabric-connector-ppr, fabric-connector-ppv, fabric-connector-sapecc                    │
│  • sap-odata-extractor, sql-extractor-proficy, pi-extractor-*, sharepoint-extractor       │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  RAW TABLES (CDF)                                                                        │
│  raw_ext_fabric_ppr, raw_ext_fabric_ppv, raw_ext_fabric_sapecc, raw_ext_sap,             │
│  raw_ext_sql_proficy, raw_ext_pi, raw_ext_sharepoint                                      │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
┌───────────────────────┐  ┌───────────────────────┐  ┌───────────────────────┐
│  TRANSFORMATIONS      │  │  CDF FUNCTIONS        │  │  WORKFLOWS            │
│  (SQL, scheduled)     │  │  (e.g. SharePoint →   │  │  (e.g. file annot.)   │
│  populate_Reel,       │  │  RollQuality)        │  │                       │
│  populate_Roll, etc.  │  │                       │  │                       │
└───────────────────────┘  └───────────────────────┘  └───────────────────────┘
                    │                   │                   │
                    └───────────────────┼───────────────────┘
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  DATA MODEL (sylvamo_mfg_core, sylvamo_mfg_extended)                                     │
│  Asset, Reel, Roll, Event, Material, RollQuality, MfgTimeSeries, WorkOrder, CostEvent…   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  USERS / APPS (Fusion, GraphQL, Search, Industrial Tools)                                │
│  Access controlled by CDF Groups + Capabilities                                           │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.3 Key Dependencies

- **No RAW data** → Transformations have nothing to read → Views stay empty.
- **Extractor down** → RAW stops updating → Data becomes stale.
- **Transformation error** → View not populated even if RAW has data.
- **Auth misconfigured** → User or app cannot see data even if it exists.

---

## 3. High-Level Troubleshooting Walkthrough

### Step 1: Define the Symptom

| Symptom | Example |
|---------|---------|
| **Missing data** | "RollQuality view is empty" or "No data for Sumter" |
| **Stale data** | "Reels haven’t updated in days" |
| **Access denied** | "User X can’t see Asset hierarchy" |
| **Pipeline failure** | "Transformation tr_populate_Roll failed" |
| **Extractor failure** | "Fabric PPR extractor is red" |

### Step 2: Locate the Component

Use this mapping to decide where to look:

| If the issue is… | Check… |
|------------------|--------|
| **A view has no data** | RAW table → Transformation → View |
| **A view has old data** | Extractor schedule and status |
| **User can’t access data** | CDF Groups, Capabilities, datasetScope |
| **Transformation failed** | Transformation logs, RAW table schema, SQL |
| **Extractor failed** | Extractor logs (VM or CDF), source connectivity |

### Step 3: Follow the Chain

**For missing/stale data:**

1. **RAW** – Does the RAW table exist and have rows?  
   - CDF → Data Management → RAW → pick database → table.
2. **Extractor** – Is the extractor running and succeeding?  
   - CDF → Extraction Pipelines, or VM logs for hosted extractors.
3. **Transformation** – Did the transformation run and succeed?  
   - CDF → Transformations → select job → Runs / Logs.
4. **View** – Does the view have instances?  
   - CDF → Data Models → Instances, or GraphQL / Search.

**For access issues:**

1. **User identity** – Is the user in the right Entra ID group?
2. **CDF group** – Does a CDF group exist and link to that Entra group (`sourceId`)?
3. **Capabilities** – Does the group have the right ACLs (e.g. `assetsAcl: READ`)?
4. **Scope** – Is access limited by `datasetScope` or `space`? Does the user need access to that dataset/space?

---

## 4. Advanced Monitoring & Troubleshooting

### 4.1 Missing Dataset or Table

**Question:** "Dataset X or table Y is missing — where is the problem?"

**Diagnosis path:**

| Step | Where to Check | What to Look For |
|------|----------------|------------------|
| 1 | **DATA_SOURCE_REGISTRY.md** | Master pipeline table: Source → Extractor → RAW → Transformation → View |
| 2 | **CDF → Data Management → RAW** | Does the RAW database exist? Does the table exist? |
| 3 | **CDF → Extraction Pipelines** | Is the extractor configured? Status = Running / Failed? |
| 4 | **Extractor config (VM or CDF)** | Correct database/table name? Permissions? |
| 5 | **CDF → Transformations** | Is there a transformation that reads this RAW table? |
| 6 | **Transformation SQL** | Does it reference the correct `raw_ext_*.table`? |

**Reference:** [DATA_SOURCE_REGISTRY.md](extractors/DATA_SOURCE_REGISTRY.md) — full Source → RAW → Transformation → View mapping.

**Common causes:**

- Extractor not deployed or disabled.
- Wrong RAW database/table name in config.
- Source system or credentials issue (e.g. Fabric SP, SAP Gateway).
- Transformation reads a different table than the one populated.

### 4.2 User Does Not Have Access

**Question:** "User X says they can’t see data — where do I check permissions?"

**Diagnosis path:**

| Step | Where to Check | What to Look For |
|------|----------------|------------------|
| 1 | **CDF → Access Management → Groups** | Groups the user should be in |
| 2 | **Group → sourceId** | Does it match an Entra ID group that contains the user? |
| 3 | **Group → Capabilities** | Does it have e.g. `assetsAcl: READ`, `dataModelInstancesAcl: READ`? |
| 4 | **Capability scope** | `datasetScope`, `space`, or `all`? If scoped, is the user’s data in that scope? |
| 5 | **CDF Audit / Logs** | Access denied events, failed API calls |

**Reference:** [CDF_SECURITY_BRIEFING.md](security/CDF_SECURITY_BRIEFING.md), [CDF_SECURITY_LIVE_DEMO_WALKTHROUGH.md](security/CDF_SECURITY_LIVE_DEMO_WALKTHROUGH.md)

**Validation script:** `scripts/validate_file_annotation_permissions.py` — example of checking group, capabilities, and extraction config access.

**Common causes:**

- User not in the correct Entra ID group.
- CDF group `sourceId` not linked to the right Entra group.
- Group missing required capabilities (e.g. `dataModelInstancesAcl: READ`).
- Access limited by `datasetScope` but data lives in a different dataset.

### 4.3 Transformation Failed

**Question:** "Transformation tr_populate_X failed — how do I debug?"

**Diagnosis path:**

| Step | Where to Check | What to Look For |
|------|----------------|------------------|
| 1 | **CDF → Transformations → [transformation] → Runs** | Last run status, error message |
| 2 | **Run details / Logs** | SQL error, timeout, permission error |
| 3 | **RAW table** | Does it exist? Does it have rows? Schema match the SQL? |
| 4 | **Transformation SQL** | Column names, types, `dataSetExternalId` |
| 5 | **Schedule** | Is it enabled? Does it run after the extractor? |

**Reference:** [TRANSFORMATIONS.md](data-model/TRANSFORMATIONS.md), [CDF_PIPELINE_OVERVIEW.md](CDF_PIPELINE_OVERVIEW.md)

### 4.4 Extractor Failed

**Question:** "Extractor Y is failing — where are the logs?"

**Diagnosis path:**

| Step | Where to Check | What to Look For |
|------|----------------|------------------|
| 1 | **CDF → Extraction Pipelines** | Pipeline status, last run, error |
| 2 | **Hosted extractors (VM)** | Windows Event Log, extractor log files, Task Scheduler |
| 3 | **Source connectivity** | Can the extractor reach SAP, Fabric, PI, SharePoint? |
| 4 | **Credentials** | Service principal, client secret, expiration |
| 5 | **DATA_SOURCE_REGISTRY** | Which SP is used? Which workspace/lakehouse? |

**Reference:** [EXTRACTORS.md](extractors/EXTRACTORS.md), [DATA_SOURCE_REGISTRY.md](extractors/DATA_SOURCE_REGISTRY.md)

### 4.5 Quick Reference: Error → Likely Cause

| Error / Symptom | Likely Cause | Where to Look |
|-----------------|--------------|---------------|
| "Unknown field argument 'limit'" | GraphQL uses `first`, not `limit` | Query syntax |
| "Variable group could not be found" | Pipeline not authorized for variable group | ADO → Library → Variable groups → Pipeline permissions |
| "Invalid client secret" | Expired or wrong secret | Azure AD → App registration → Certificates & secrets |
| "Project name mismatch" | Config project ≠ CDF_PROJECT in variable group | config.\<env\>.yaml vs variable group |
| "Failed (4xx): [ep_X, _]" | Group missing extractionConfigsAcl or wrong sourceId | CDF Groups, validate_file_annotation_permissions.py |
| View empty but RAW has data | Transformation not running or failing | CDF Transformations → Runs |
| RAW empty | Extractor not running or failing | Extraction Pipelines, VM logs |

---

## 5. What We Can Explain & Walk Through in CDF

### 5.1 CDF Concepts We Can Demo

| Topic | What to Show | Where in CDF |
|-------|--------------|--------------|
| **Data model** | Views, relationships, instance counts | Data Models → sylvamo_mfg_core |
| **Pipeline flow** | Source → RAW → Transform → View | RAW, Transformations, Data Models |
| **Search** | Find assets, rolls, quality by name/ID | Search (Fusion) |
| **GraphQL** | Query RollQuality, Reel→Roll, Asset hierarchy | GraphQL Explorer |
| **Traceability** | Roll → Reel → Asset → Quality | GraphQL or Fusion navigation |
| **Security** | Groups, capabilities, scope | Access Management |
| **Extractors** | Status, config, runs | Extraction Pipelines |
| **Transformations** | SQL, schedule, run history | Transformations |

### 5.2 Suggested Walkthroughs

| Walkthrough | Duration | Audience | Key Points |
|-------------|----------|----------|------------|
| **Pipeline overview** | 15 min | Technical | Source → Extractor → RAW → Transform → View; DATA_SOURCE_REGISTRY |
| **Data model in action** | 15 min | Mixed | Search, GraphQL, traceability (Roll → Reel → Quality) |
| **Security & access** | 10 min | Security / ops | IdP → CDF groups → capabilities → scope |
| **Troubleshooting missing data** | 20 min | Ops / support | RAW → Extractor → Transform → View chain |
| **Troubleshooting access** | 15 min | Ops / support | Groups, sourceId, capabilities, datasetScope |

### 5.3 Questions to Ask When Investigating

**For missing data:**

- Which view or table is missing?
- When did it last have data (if ever)?
- Is the RAW table populated?
- Is the extractor running?
- Did the transformation run successfully?

**For access issues:**

- What exactly can’t the user see (e.g. assets, a specific dataset)?
- Which Entra ID group is the user in?
- Which CDF group should grant that access?
- Does that group have the right capabilities and scope?

**For pipeline failures:**

- What is the exact error message?
- Which component failed (extractor, transformation, function)?
- When did it last succeed?
- Did anything change (config, credentials, source)?

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [CDF_PIPELINE_OVERVIEW.md](CDF_PIPELINE_OVERVIEW.md) | End-to-end pipeline, extractors, transformations |
| [DATA_SOURCE_REGISTRY.md](extractors/DATA_SOURCE_REGISTRY.md) | Master table: Source → RAW → Transform → View |
| [CICD_PIPELINE_TROUBLESHOOTING.md](cicd/CICD_PIPELINE_TROUBLESHOOTING.md) | CI/CD and deployment issues |
| [CDF_SECURITY_BRIEFING.md](security/CDF_SECURITY_BRIEFING.md) | Security model, groups, capabilities |
| [CDF_SECURITY_LIVE_DEMO_WALKTHROUGH.md](security/CDF_SECURITY_LIVE_DEMO_WALKTHROUGH.md) | Live demo of security controls |
| [TRANSFORMATIONS.md](data-model/TRANSFORMATIONS.md) | Transformation SQL and data flow |
| [EXTRACTORS.md](extractors/EXTRACTORS.md) | Extractor configuration and status |

---

*Last updated: February 2026*
