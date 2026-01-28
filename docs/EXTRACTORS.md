# Extractors Configuration

**Date:** 2026-01-28  
**Purpose:** Documentation of all extractors feeding data into the `sylvamo_mfg` model

---

## Overview

Data flows from source systems into CDF through a set of configured extractors:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SOURCE SYSTEMS                                     │
├─────────────────┬─────────────────┬─────────────────┬──────────────────────┤
│   PI Server     │   Fabric        │   SharePoint    │   Proficy GBDB       │
│   (Time Series) │   (Lakehouse)   │   (Documents)   │   (Lab Data)         │
└────────┬────────┴────────┬────────┴────────┬────────┴──────────┬───────────┘
         │                 │                 │                   │
    PI Extractor     Fabric Connector   SharePoint Extractor  SQL Extractor
         │                 │                 │                   │
         ▼                 ▼                 ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CDF                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐                    │
│  │ Time Series   │  │ RAW Databases │  │ Files         │                    │
│  │ sylvamo_assets│  │ raw_sylvamo_* │  │ SharePoint    │                    │
│  └───────────────┘  └───────────────┘  └───────────────┘                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Extractor Status Summary

| Extractor | Source | Status | Data Target | Use Case |
|-----------|--------|--------|-------------|----------|
| **Fabric Connector** | Microsoft Fabric Lakehouse | ✅ Running | RAW: `raw_sylvamo_fabric` | UC1, UC2 |
| **PI Extractor** | PI Server (S769PI01) | ✅ Running | Time Series | Process Data |
| **SharePoint Extractor** | SharePoint Online | ⚠️ Blocked | Files/RAW | UC2 (Quality) |
| **SQL Extractor** | Proficy GBDB | ⏳ Configured | RAW: `raw_sylvamo_proficy` | UC2 (Lab) |

---

## 1. Fabric Connector ✅

**Status:** RUNNING  
**Purpose:** Extract data from Microsoft Fabric Lakehouse into CDF RAW

### Configuration

**File:** `config.fabric-connector.minimal.yml`

```yaml
version: 1
type: local

cognite:
  project: sylvamo-dev
  host: https://az-eastus-1.cognitedata.com
  idp-authentication:
    tenant: eb4154c5-1e81-4c3c-9e5d-a8a547806c8e
    client-id: 73a40d42-8cf4-4048-80d1-54c8d28cb58d
    secret: <redacted>
    scopes:
      - https://az-eastus-1.cognitedata.com/.default

source:
  abfss-prefix: "abfss://ws_enterprise_prod@onelake.dfs.fabric.microsoft.com/LH_SILVER_ppreo.Lakehouse"
  data-set-id: "2565293360230286"
  
  raw-tables:
    # PPR Production Data
    - table-name: ppr_hist_reel
      db-name: raw_sylvamo_fabric
      raw-path: "Tables/HIST_REEL"
    
    - table-name: ppr_hist_roll
      db-name: raw_sylvamo_fabric
      raw-path: "Tables/HIST_ROLL"
    
    - table-name: ppr_hist_package
      db-name: raw_sylvamo_fabric
      raw-path: "Tables/HIST_PACKAGE"
    
    # SAP Cost Data
    - table-name: ppv_snapshot
      db-name: raw_sylvamo_fabric
      raw-path: "Tables/enterprise/ppv_snapshot"
```

### Extracted Tables

| Table | RAW Database | Records | Use Case |
|-------|--------------|---------|----------|
| `ppr_hist_reel` | `raw_sylvamo_fabric` | 100+ | UC2: Reel production |
| `ppr_hist_roll` | `raw_sylvamo_fabric` | 19+ | UC2: Roll production |
| `ppr_hist_package` | `raw_sylvamo_fabric` | 100+ | UC2: Package tracking |
| `ppv_snapshot` | `raw_sylvamo_fabric` | 200+ | UC1: Material costs |

### Service Principal

| Property | Value |
|----------|-------|
| Name | `sp-cdf-fabric-extractor-dev` |
| App ID | `73a40d42-8cf4-4048-80d1-54c8d28cb58d` |
| CDF Group | `extractor-fabric-dev` |

### Run Command

```bash
# Windows
.\fabric-connector-standalone-0.3.4-win32.exe config\fabric-connector.minimal.yml

# Linux/Mac
./fabric-connector-standalone-0.3.4-linux-amd64 config/fabric-connector.minimal.yml
```

---

## 2. PI Extractor ✅

**Status:** RUNNING  
**Purpose:** Extract time series data from PI Server into CDF

### Configuration

**File:** `config.pi-extractor.minimal.yml`

```yaml
version: 3

cognite:
  project: sylvamo-dev
  host: https://az-eastus-1.cognitedata.com
  idp-authentication:
    tenant: eb4154c5-1e81-4c3c-9e5d-a8a547806c8e
    client-id: b7671a6c-8680-4b10-b8d0-141767de9877
    secret: <redacted>
    scopes:
      - https://az-eastus-1.cognitedata.com/.default

pi:
  host: S769PI01.sylvamo.com
  username: sp-cdf-pi-extractor-dev
  native-authentication: true

time-series:
  external-id-prefix: 'pi:'
  space-id: sylvamo_assets

extractor:
  include-tags:
    # PI demo tag
    - SINUSOID
    # Level indicators
    - 321LI411
    - 321LI411.C
    # O2 Reactor / Bleaching area
    - 401AB148
    - 401AC146
    - 401FC105
    - 401FC106
    # ... 75 total tags
    
backfill:
  to: 365d-ago
  step-size-hours: 168
```

### Extracted Tags

| Category | Tag Examples | Count |
|----------|-------------|-------|
| Level Indicators | 321LI411, 401LC100, 401LC140 | 12 |
| O2 Reactor | 401AB148, 401AC146, 401FC105 | 45 |
| Temperature | 401TC125, 401TC126, 401TI143 | 10 |
| Calculated | Combined TRP Production Rate | 8 |
| **Total** | | **75 tags** |

### Service Principal

| Property | Value |
|----------|-------|
| Name | `sp-cdf-pi-extractor-dev` |
| App ID | `b7671a6c-8680-4b10-b8d0-141767de9877` |
| CDF Group | `extractor-pi-dev` |

### Backfill Settings

| Setting | Value |
|---------|-------|
| Backfill Period | 365 days |
| Step Size | 168 hours (1 week) |
| Update Frequency | Real-time streaming |

---

## 3. SharePoint Extractor ⚠️

**Status:** BLOCKED (Waiting for Permissions)  
**Purpose:** Extract quality documents and lists from SharePoint Online

### Configuration

**File:** `config.sharepoint-extractor.minimal.yml`

```yaml
version: 1
type: local

cognite:
  project: sylvamo-dev
  host: https://az-eastus-1.cognitedata.com
  idp-authentication:
    tenant: eb4154c5-1e81-4c3c-9e5d-a8a547806c8e
    client-id: 4050f0ee-519e-4485-ac2b-f3221071c92e
    secret: <redacted>
    scopes:
      - https://az-eastus-1.cognitedata.com/.default

files:
  file-provider:
    type: sharepoint_online
    tenant-id: eb4154c5-1e81-4c3c-9e5d-a8a547806c8e
    client-id: 4050f0ee-519e-4485-ac2b-f3221071c92e
    client-secret: <redacted>
    
    paths:
      - url: "https://sylvamo.sharepoint.com/sites/Sumter/Shared%20Documents"
        recursive: true
  
  max-file-size: 100MB
  with-metadata: true
```

### Blocking Issue

**Problem:** App Registration has Delegated permissions instead of Application permissions.

**Current Permissions (WRONG):**
- Files.Read.All (Delegated)
- Sites.Read.All (Delegated)

**Required Permissions:**
- Sites.Read.All (**Application**)
- Files.Read.All (**Application**)
- Admin consent granted

### Action Required

1. Go to Azure Portal → App Registrations → `sp-cdf-file-extractor-dev`
2. Navigate to **API permissions**
3. Click **Add a permission** → **Microsoft Graph** → **Application permissions**
4. Add: `Sites.Read.All` and `Files.Read.All`
5. Click **Grant admin consent for Sylvamo**

### Service Principal

| Property | Value |
|----------|-------|
| Name | `sp-cdf-file-extractor-dev` |
| App ID | `4050f0ee-519e-4485-ac2b-f3221071c92e` |
| CDF Group | `extractor-file-dev` |

### Target Data

| SharePoint Site | List/Library | Purpose |
|-----------------|-------------|---------|
| Sumter | Roll Quality Reporting | Quality defect reports |
| Sumter | Shared Documents | Quality documentation |

---

## 4. SQL Extractor (Proficy) ⏳

**Status:** CONFIGURED (Pending Execution)  
**Purpose:** Extract lab test data from Proficy GBDB SQL Server

### Configuration

**File:** `config.sql-proficy-dev.yml`

```yaml
version: 1
type: local

cognite:
  project: sylvamo-dev
  host: https://az-eastus-1.cognitedata.com
  idp-authentication:
    tenant: eb4154c5-1e81-4c3c-9e5d-a8a547806c8e
    client-id: 3ec90782-5f9f-482d-9da2-46567276519b
    secret: <redacted>
    scopes:
      - https://az-eastus-1.cognitedata.com/.default

source:
  type: odbc
  connection-string: "Driver={ODBC Driver 17 for SQL Server};Server=<proficy-server>;Database=GBDB;Trusted_Connection=yes"
  
  queries:
    - name: tests
      database: raw_sylvamo_proficy
      table: tests
      query: |
        SELECT [Test_Id], [Canceled], [Result_On], [Entry_On], [Entry_By],
               [Sample_Id], [Var_Id], [Event_Num], [Result], [Result_String]
        FROM [GBDB].[dbo].[Tests]
        WHERE [Result_On] >= DATEADD(day, -7, GETDATE())
```

### Target Tables

| GBDB Table | RAW Table | Purpose |
|------------|-----------|---------|
| `Tests` | `raw_sylvamo_proficy.tests` | Lab test results |
| `Events` | `raw_sylvamo_proficy.events` | Production events |
| `Samples` | `raw_sylvamo_proficy.samples` | Sample tracking |

### Service Principal

| Property | Value |
|----------|-------|
| Name | `sp-cdf-sql-extractor-dev` |
| App ID | `3ec90782-5f9f-482d-9da2-46567276519b` |
| CDF Group | `extractor-sql-dev` |

### Next Steps

1. Run extractor on Windows VM with ODBC drivers
2. Verify SQL Server connectivity
3. Execute discovery queries
4. Define full extraction queries

---

## Service Principal Summary

| Name | App ID | Purpose | Status |
|------|--------|---------|--------|
| sp-cdf-fabric-extractor-dev | `73a40d42-8cf4-4048-80d1-54c8d28cb58d` | Fabric Lakehouse | ✅ Active |
| sp-cdf-pi-extractor-dev | `b7671a6c-8680-4b10-b8d0-141767de9877` | PI Server | ✅ Active |
| sp-cdf-file-extractor-dev | `4050f0ee-519e-4485-ac2b-f3221071c92e` | SharePoint | ⚠️ Blocked |
| sp-cdf-sql-extractor-dev | `3ec90782-5f9f-482d-9da2-46567276519b` | Proficy SQL | ⏳ Pending |

All service principals are members of Azure AD Group: `93463766-2320-429d-8736-e417cba1b805`

---

## Data Flow to Model

```
Extractor                 RAW Database                    Model Entity
─────────────────────────────────────────────────────────────────────────
Fabric Connector    →     raw_sylvamo_fabric
                            ├── ppv_snapshot         →    MaterialCostVariance
                            ├── ppr_hist_reel        →    Reel
                            ├── ppr_hist_roll        →    Roll
                            └── ppr_hist_package     →    Package

SharePoint Extractor →    raw_sylvamo_pilot
                            └── sharepoint_roll_quality → QualityResult

SQL Extractor       →     raw_sylvamo_proficy
                            └── tests                →    QualityResult (lab)

PI Extractor        →     Time Series (sylvamo_assets)
                            └── 75 tags              →    Process monitoring
```

---

## Troubleshooting

### Fabric Connector Issues

**Issue:** Table not found  
**Solution:** Verify Fabric table path with Fabric team, check path casing

**Issue:** Connector crash after first table  
**Workaround:** Run one table at a time (known bug)

### PI Extractor Issues

**Issue:** Authentication failed  
**Solution:** Verify PI native authentication credentials

**Issue:** Backfill timeout  
**Solution:** Reduce `step-size-hours` to smaller chunks

### SharePoint Issues

**Issue:** 403 Forbidden  
**Solution:** Change to Application permissions (not Delegated)

### SQL Extractor Issues

**Issue:** ODBC connection failed  
**Solution:** Install ODBC Driver 17, verify network connectivity

---

## Configuration Files Location

All configuration files are stored in the project:

```
docs/04-extractors/
├── configs/
│   ├── config.fabric-connector.minimal.yml
│   ├── config.pi-extractor.minimal.yml
│   ├── config.sharepoint-extractor.minimal.yml
│   ├── config.sql-proficy-dev.yml
│   └── ... (additional configs)
├── guides/
│   ├── EXTRACTOR_SETUP_GUIDE.md
│   ├── FABRIC_CONNECTOR_SETUP_GUIDE.md
│   ├── PI_EXTRACTOR_INSTALLATION_STEPS.md
│   └── STATUS_SUMMARY.md
└── troubleshooting/
    ├── CHECK_IF_EXTRACTOR_RUNNING.md
    └── TROUBLESHOOTING_DB_EXTRACTOR_STUCK.md
```

---

*Document created: January 28, 2026*
