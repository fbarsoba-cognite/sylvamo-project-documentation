# CI/CD System Explanation: How It Works, Use Case, and Code Flow

## Use Case and Business Context

### What Problem Does This Solve?

Sylvamo needs to deploy Cognite Data Fusion (CDF) configurations across three environments (dev, staging, production) in a controlled, repeatable way. Without CI/CD:

- **Manual deployments** are error-prone and time-consuming
- **No validation** before changes reach production
- **Inconsistent deployments** across environments
- **No audit trail** of what was deployed when
- **Risk of breaking production** with untested changes

### The Solution: Automated CI/CD Pipelines

This CI/CD system automates the deployment of CDF Toolkit modules (data models, transformations, access groups, etc.) with:

- **Automatic validation** before code is merged
- **Controlled promotion** from dev → staging → production
- **Approval gates** for staging and production deployments
- **Dry-run validation** before every actual deployment
- **Consistent process** across all environments

### What Gets Deployed?

The system deploys **Cognite Toolkit modules** which include:

- **Data Models**: Spaces, containers, views (e.g., `sp_admin_instances`, `CogniteSourceSystem`)
- **Transformations**: SQL queries that populate CDF from RAW data (e.g., `tr_populate_SourceSystems`)
- **Access Groups**: Security groups for CDF access
- **Data Sets**: Organizational units for data governance
- **Location Filters**: Geographic filters for data access

Example: The `admin` module creates reference data like `CogniteSourceSystem` nodes that other transformations depend on.

---

## How the Pipelines Work: Architecture and Flow

### Pipeline Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AZURE DEVOPS PIPELINES                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. PR Validation Pipeline (dry-run-pipeline.yml)                  │
│     └─> Runs on every PR to main                                  │
│         └─> Validates configs, shows what WOULD change             │
│                                                                     │
│  2. Deployment Pipeline (deploy-pipeline.yml)                      │
│     └─> Runs on merge to main                                      │
│         ├─> Stage 1: DeployDev (auto, no approval)                │
│         ├─> Stage 2: DeployStaging (requires approval)            │
│         └─> Stage 3: DeployProd (requires approval)                │
│                                                                     │
│  3. Test Pipeline (test-all-environments.yml)                      │
│     └─> Manual trigger only                                        │
│         └─> Validates all environments with dry-run                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Complete Workflow: From Code Change to Production

```
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 1: DEVELOPER CREATES FEATURE BRANCH                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Developer:                                                         │
│    1. Creates branch: git checkout -b feature/add-new-module        │
│    2. Edits YAML files in sylvamo/modules/                         │
│    3. Commits: git commit -m "Add new transformation"               │
│    4. Pushes: git push origin feature/add-new-module                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 2: CREATE PULL REQUEST                                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Developer creates PR targeting 'main' branch                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 3: PR VALIDATION PIPELINE TRIGGERS AUTOMATICALLY              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Pipeline: dry-run-pipeline.yml                                     │
│  Trigger: PR created targeting main                                 │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ Job: Validate PR Changes                                      │  │
│  ├─────────────────────────────────────────────────────────────┤  │
│  │                                                              │  │
│  │ Step 1: cdf build                                            │  │
│  │   └─> Validates YAML syntax                                 │  │
│  │   └─> Checks for missing variables                          │  │
│  │   └─> Compiles templates                                    │  │
│  │   └─> Creates build/ directory                              │  │
│  │                                                              │  │
│  │ Step 2: cdf deploy --dry-run --env dev                      │  │
│  │   └─> Connects to CDF dev project                           │  │
│  │   └─> Compares build/ with current CDF state                │  │
│  │   └─> Shows what WOULD be created/updated/deleted           │  │
│  │   └─> Does NOT make any actual changes                      │  │
│  │                                                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  Result:                                                            │
│    ✓ Pass → PR can be merged                                       │
│    ✗ Fail → PR blocked, developer fixes issues                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (if passed)
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 4: PR APPROVED AND MERGED TO MAIN                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Reviewer approves PR, merges to main branch                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 5: DEPLOYMENT PIPELINE TRIGGERS AUTOMATICALLY                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Pipeline: deploy-pipeline.yml                                      │
│  Trigger: Push to main branch                                       │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ STAGE 1: DeployDev                                           │  │
│  ├─────────────────────────────────────────────────────────────┤  │
│  │ Type: Normal job (no approval gate)                          │  │
│  │ Variable Group: dev-toolkit-credentials                      │  │
│  │ Target CDF Project: sylvamo-dev                              │  │
│  │                                                              │  │
│  │ Steps:                                                       │  │
│  │   1. cdf build                                               │  │
│  │   2. cdf deploy --dry-run --env dev                          │  │
│  │   3. cdf deploy --env dev                                    │  │
│  │      └─> Actually creates/updates resources in CDF           │  │
│  │                                                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼ (if successful)                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ STAGE 2: DeployStaging                                       │  │
│  ├─────────────────────────────────────────────────────────────┤  │
│  │ Type: Deployment job with approval gate                      │  │
│  │ Environment: staging (ADO Environment)                        │  │
│  │ Variable Group: staging-toolkit-credentials                 │  │
│  │ Target CDF Project: sylvamo-test                             │  │
│  │                                                              │  │
│  │ ⏸️  PIPELINE PAUSES - WAITING FOR APPROVAL                  │  │
│  │                                                              │  │
│  │ Approver receives notification in ADO                        │  │
│  │ Approver reviews dry-run output from Stage 1                 │  │
│  │ Approver clicks "Approve" in ADO UI                           │  │
│  │                                                              │  │
│  │ Steps (after approval):                                      │  │
│  │   1. cdf build                                               │  │
│  │   2. cdf deploy --dry-run --env staging                      │  │
│  │   3. cdf deploy --env staging                                │  │
│  │      └─> Actually creates/updates resources in CDF           │  │
│  │                                                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼ (if successful and approved)         │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ STAGE 3: DeployProd                                          │  │
│  ├─────────────────────────────────────────────────────────────┤  │
│  │ Type: Deployment job with approval gate                      │  │
│  │ Environment: production (ADO Environment)                     │  │
│  │ Variable Group: prod-toolkit-credentials                    │  │
│  │ Target CDF Project: sylvamo-prod                             │  │
│  │                                                              │  │
│  │ ⏸️  PIPELINE PAUSES - WAITING FOR APPROVAL                  │  │
│  │                                                              │  │
│  │ Approver receives notification in ADO                        │  │
│  │ Approver reviews dry-run output from Stage 2                 │  │
│  │ Approver clicks "Approve" in ADO UI                           │  │
│  │                                                              │  │
│  │ Steps (after approval):                                      │  │
│  │   1. cdf build                                               │  │
│  │   2. cdf deploy --dry-run --env prod                         │  │
│  │   3. cdf deploy --env prod                                   │  │
│  │      └─> Actually creates/updates resources in CDF           │  │
│  │                                                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## How the Code Works: Technical Deep Dive

### Pipeline File Structure

Each pipeline file is a YAML configuration that defines:

1. **When it runs** (triggers)
2. **What environment it uses** (container image, VM pool)
3. **What credentials it needs** (variable groups)
4. **What commands it runs** (steps)

### Pipeline 1: PR Validation (`dry-run-pipeline.yml`)

**Purpose**: Validate changes before they're merged to main.

**How it works**:

```yaml
trigger:
  - none  # Never runs on push - only via PR validation

pr:
  branches:
    include:
      - main  # Runs when PR targets main

variables:
  - group: dev-toolkit-credentials  # Loads CDF credentials

container:
  image: cognite/toolkit:0.5.35  # Pre-built Docker image with CDF CLI

steps:
  - script: cdf build
    # What this does:
    #   1. Reads sylvamo/config.dev.yaml
    #   2. Validates all YAML files in selected modules
    #   3. Substitutes template variables ({{ variable }})
    #   4. Creates build/ directory with compiled resources
    #   5. Exits with error if validation fails
    
  - script: cdf deploy --dry-run --env dev
    # What this does:
    #   1. Reads build/ directory
    #   2. Connects to CDF dev project (sylvamo-dev)
    #   3. Compares build/ resources with current CDF state
    #   4. Shows diff: what would be created/updated/deleted
    #   5. Does NOT make any changes
    #   6. Exits with error if deployment would fail
```

**Key Points**:
- Uses `--dry-run` flag - **no actual changes** to CDF
- Validates against **dev environment** (safest for testing)
- Must pass for PR to be mergeable (enforced by branch policy)

### Pipeline 2: Deployment (`deploy-pipeline.yml`)

**Purpose**: Actually deploy changes to dev, staging, and production.

**How it works**:

#### Stage 1: DeployDev

```yaml
- stage: DeployDev
  variables:
    - group: dev-toolkit-credentials  # CDF credentials for dev
  
  jobs:
    - job: Deploy
      steps:
        - script: cdf build
          # Same as PR validation - validates and compiles
        
        - script: cdf deploy --dry-run --env dev
          # Shows what will change (safety check)
        
        - script: cdf deploy --env dev
          env:
            IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
          # Actually applies changes to sylvamo-dev CDF project
          # Creates/updates:
          #   - Spaces (e.g., sp_admin_instances)
          #   - Containers (e.g., CogniteSourceSystem)
          #   - Transformations (e.g., tr_populate_SourceSystems)
          #   - Access groups, data sets, etc.
```

**Key Points**:
- **No approval gate** - deploys automatically after merge
- Runs **dry-run first** for safety
- Uses `dev-toolkit-credentials` variable group

#### Stage 2: DeployStaging

```yaml
- stage: DeployStaging
  dependsOn: DeployDev  # Only runs if DeployDev succeeds
  
  jobs:
    - deployment: Deploy
      environment: 'staging'  # ADO Environment with approval gate
      variables:
        - group: staging-toolkit-credentials
      
      strategy:
        runOnce:
          deploy:
            steps:
              - script: cdf build
              - script: cdf deploy --dry-run --env staging
              - script: cdf deploy --env staging
```

**Key Points**:
- Uses `deployment` job type (not `job`) - enables approval gates
- References `environment: 'staging'` - ADO Environment resource
- **Pipeline pauses** until approver clicks "Approve"
- Uses `staging-toolkit-credentials` (different CDF project: sylvamo-test)

#### Stage 3: DeployProd

Same structure as DeployStaging, but:
- Uses `environment: 'production'`
- Uses `prod-toolkit-credentials`
- Targets `sylvamo-prod` CDF project

### Pipeline 3: Test All Environments (`test-all-environments.yml`)

**Purpose**: Manually validate all environments without deploying.

**How it works**:

```yaml
trigger:
  - none  # Manual trigger only

stages:
  - stage: ValidateDev
    # Runs cdf build + cdf deploy --dry-run --env dev
  
  - stage: ValidateStaging
    dependsOn: ValidateDev
    # Runs cdf build + cdf deploy --dry-run --env staging
  
  - stage: ValidateProd
    dependsOn: ValidateStaging
    # Runs cdf build + cdf deploy --dry-run --env prod
```

**Use Cases**:
- Weekly validation to detect configuration drift
- Before major releases
- Troubleshooting deployment issues
- Validating all environments after credential updates

---

## How Authentication Works

### Variable Groups: Secure Credential Storage

Variable groups in ADO are like secure key-value stores:

```
Variable Group: dev-toolkit-credentials
├── CDF_CLUSTER = "az-eastus-1"
├── CDF_PROJECT = "sylvamo-dev"
├── LOGIN_FLOW = "client_credentials"
├── IDP_CLIENT_ID = "abc123..." (visible)
├── IDP_CLIENT_SECRET = "xyz789..." (marked as secret - hidden)
├── IDP_TENANT_ID = "tenant-id..."
└── CDF_URL = "https://az-eastus-1.cognitedata.com"
```

### How Credentials Flow Through the System

```
┌─────────────────────────────────────────────────────────────┐
│ 1. ADO Variable Group (stored securely)                     │
│    └─> Contains CDF credentials                             │
└─────────────────────────────────────────────────────────────┘
                    │
                    ▼ (injected at runtime)
┌─────────────────────────────────────────────────────────────┐
│ 2. Pipeline Environment Variables                           │
│    └─> ADO automatically injects as env vars               │
│    └─> Secrets are masked in logs                           │
└─────────────────────────────────────────────────────────────┘
                    │
                    ▼ (read by CDF CLI)
┌─────────────────────────────────────────────────────────────┐
│ 3. Cognite Toolkit CLI (cdf command)                       │
│    └─> Reads env vars: CDF_PROJECT, IDP_CLIENT_ID, etc.    │
│    └─> Uses OAuth2 client credentials flow                 │
│    └─> Authenticates to CDF API                             │
└─────────────────────────────────────────────────────────────┘
                    │
                    ▼ (HTTPS request)
┌─────────────────────────────────────────────────────────────┐
│ 4. Cognite Data Fusion API                                 │
│    └─> Validates credentials                                │
│    └─> Returns access token                                 │
│    └─> Processes deployment requests                        │
└─────────────────────────────────────────────────────────────┘
```

### Example: How `cdf deploy` Uses Credentials

When the pipeline runs `cdf deploy --env dev`:

1. **CLI reads config file**: `sylvamo/config.dev.yaml`
   ```yaml
   environment:
     project: sylvamo-dev  # Target CDF project
   variables:
     modules:
       clientId: ${IDP_CLIENT_ID}  # Template variable
       clientSecret: ${IDP_CLIENT_SECRET}
   ```

2. **CLI reads environment variables** (injected by ADO):
   ```bash
   IDP_CLIENT_ID=abc123...
   IDP_CLIENT_SECRET=xyz789...
   CDF_PROJECT=sylvamo-dev
   CDF_CLUSTER=az-eastus-1
   ```

3. **CLI substitutes variables**:
   ```yaml
   clientId: "abc123..."  # Resolved from ${IDP_CLIENT_ID}
   clientSecret: "xyz789..."  # Resolved from ${IDP_CLIENT_SECRET}
   ```

4. **CLI authenticates to CDF**:
   - Uses OAuth2 client credentials flow
   - Sends `IDP_CLIENT_ID` and `IDP_CLIENT_SECRET` to token endpoint
   - Receives access token

5. **CLI deploys resources**:
   - Uses access token for API calls
   - Creates/updates resources in `sylvamo-dev` project

---

## How the Toolkit Commands Work

### `cdf build`

**What it does**:
1. Reads `sylvamo/config.dev.yaml` (or `config.staging.yaml`, `config.prod.yaml`)
2. Finds all modules listed in `selected:` section
3. Validates YAML syntax for all resource files
4. Substitutes template variables (`{{ variable }}`) with actual values
5. Compiles resources into `build/` directory
6. Creates deployment-ready artifacts

**Example**:
```yaml
# Input: sylvamo/modules/admin/transformations/populate_SourceSystems.transformation.yaml
space: '{{ adminInstanceSpace }}'

# After build (with adminInstanceSpace = "sp_admin_instances"):
space: 'sp_admin_instances'
```

**Output**: `build/` directory with compiled YAML files ready for deployment

### `cdf deploy --dry-run`

**What it does**:
1. Reads `build/` directory
2. Connects to CDF project (e.g., `sylvamo-dev`)
3. Retrieves current state of all resources
4. Compares `build/` resources with current CDF state
5. Shows diff:
   - **Created**: Resources that don't exist in CDF
   - **Updated**: Resources that exist but differ
   - **Deleted**: Resources in CDF but not in `build/`
6. **Does NOT make any changes**

**Example Output**:
```
DRY RUN - No changes will be applied

Resources to be created:
  - Space: sp_admin_instances
  - Transformation: tr_populate_SourceSystems

Resources to be updated:
  - Container: CogniteSourceSystem (1 property changed)

Resources unchanged:
  - Data Set: cicd_ds
  - Group: cdf-sylvamo-admin
```

### `cdf deploy` (without --dry-run)

**What it does**:
1. Same as `--dry-run` but **actually applies changes**
2. Creates new resources in CDF
3. Updates existing resources
4. Returns success/failure status

**Example**: Creates `tr_populate_SourceSystems` transformation in CDF, which can then be run to populate `CogniteSourceSystem` nodes.

---

## Real-World Example: Deploying Admin Module

### Scenario: Deploy admin module to populate source systems

**Step 1: Developer creates feature branch**
```bash
git checkout -b feature/deploy-admin-module
```

**Step 2: Developer ensures admin module is selected**
```yaml
# sylvamo/config.dev.yaml
selected:
  - modules/admin/  # Already present
```

**Step 3: Developer commits and creates PR**
```bash
git commit -m "Ensure admin module is configured"
git push origin feature/deploy-admin-module
# Create PR in ADO
```

**Step 4: PR Validation Pipeline runs**
```
✅ cdf build - Success
✅ cdf deploy --dry-run --env dev - Success
   Shows: "Would create tr_populate_SourceSystems transformation"
```

**Step 5: PR approved and merged**
```
PR merged to main
```

**Step 6: Deployment Pipeline runs**

**Stage 1: DeployDev**
```
✅ cdf build
✅ cdf deploy --dry-run --env dev
✅ cdf deploy --env dev
   Creates in sylvamo-dev:
     - Space: sp_admin_instances
     - Transformation: tr_populate_SourceSystems
     - Data Set: cicd_ds
     - Groups: cdf-sylvamo-admin, cdf-sylvamo-all-read
```

**Stage 2: DeployStaging** (waits for approval)
```
⏸️  Pipeline paused - waiting for approval
   Approver reviews dry-run output
   Approver clicks "Approve"
   
✅ cdf build
✅ cdf deploy --dry-run --env staging
✅ cdf deploy --env staging
   Creates same resources in sylvamo-test
```

**Stage 3: DeployProd** (waits for approval)
```
⏸️  Pipeline paused - waiting for approval
   Approver reviews dry-run output
   Approver clicks "Approve"
   
✅ cdf build
✅ cdf deploy --dry-run --env prod
✅ cdf deploy --env prod
   Creates same resources in sylvamo-prod
```

**Step 7: Run transformation to populate data**
```bash
# In CDF UI or via script:
# Run transformation: tr_populate_SourceSystems
# This creates CogniteSourceSystem nodes in sp_admin_instances space
```

---

## Key Safety Features

### 1. Dry-Run Before Every Deployment
- **PR validation**: Dry-run prevents invalid configs from being merged
- **Dev deployment**: Dry-run shows what will change before applying
- **Staging deployment**: Dry-run shows what will change before applying
- **Production deployment**: Dry-run shows what will change before applying

### 2. Approval Gates
- **Dev**: No approval (fast iteration)
- **Staging**: 1 approver required (controlled testing)
- **Production**: 1 approver required (production safety)

### 3. Sequential Promotion
- Changes flow: **dev → staging → prod**
- Each stage must succeed before next stage runs
- Failures stop the pipeline

### 4. Environment Isolation
- Each environment uses **separate credentials** (variable groups)
- Each environment targets **separate CDF projects**
- No risk of deploying to wrong environment

---

## Summary

This CI/CD system provides:

1. **Automated validation** before code is merged
2. **Controlled deployment** with approval gates
3. **Consistent process** across all environments
4. **Safety checks** (dry-run) before every deployment
5. **Audit trail** of all deployments in ADO

The pipelines use the Cognite Toolkit CLI (`cdf` command) running in Docker containers, authenticated via OAuth2 client credentials stored securely in ADO Variable Groups. Changes flow from feature branches → PR validation → dev → staging → production, with human approval required for staging and production deployments.
