# CI/CD for Cognite Data Fusion (CDF)

**A Technical Overview for Platform Teams**

---

## What is CDF from a CI/CD Perspective?

CDF is an **external SaaS endpoint**:

```
┌─────────────────┐     HTTPS/OAuth2     ┌─────────────────┐
│  Your CI/CD     │ ──────────────────▶  │  Cognite Data   │
│  Pipeline       │                       │  Fusion (CDF)   │
│  (ADO/GitHub)   │                       │  Cloud SaaS     │
└─────────────────┘                       └─────────────────┘
```

- CDF is hosted in Cognite-managed cloud clusters (e.g., `westeurope-1`)
- Pipelines connect via **HTTPS** using **OAuth2 client credentials**
- Treat it like any external API with a CLI deploy tool

---

## The CI/CD Tech Stack

| Component | Technology |
|-----------|------------|
| **Deploy Tool** | Cognite Toolkit CLI (`cdf`) |
| **Package** | `cognite-toolkit` (pip) or Docker `cognite/toolkit:<version>` |
| **Key Commands** | `cdf build`, `cdf deploy --dry-run`, `cdf deploy` |
| **Pipeline Definitions** | YAML (platform-specific) |

**Supported Platforms:**
- GitHub Actions → `.github/workflows/*.yml`
- Azure DevOps → `.devops/*.yml`
- GitLab CI/CD → `.gitlab-ci.yml`

**Languages:** Python (CLI runtime), YAML (configs + pipelines)

---

## Repository Structure

```
<repo>/
  sylvamo/                    # organization directory
    config.dev.yaml           # → points to DEV CDF project
    config.staging.yaml       # → points to STAGING CDF project  
    config.prod.yaml          # → points to PROD CDF project
    modules/
      module_a/               # Toolkit modules (resources to deploy)
      module_b/
```

**`config.<env>.yaml` defines:**
- Target CDF project (`project: sylvamo-dev`)
- Which modules to deploy (`selected:` list)

**Created via:** `cdf modules init <organization_dir>`

---

## CI/CD Flow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        FEATURE BRANCH                           │
├─────────────────────────────────────────────────────────────────┤
│  PR Created → CI Pipeline Triggers                              │
│                                                                 │
│    ┌──────────┐      ┌─────────────────┐                        │
│    │ cdf build│ ───▶ │ cdf deploy      │  ✓ Validates config   │
│    └──────────┘      │ --dry-run       │  ✓ Shows what WOULD   │
│                      └─────────────────┘    change in CDF       │
│                                                                 │
│  ✓ Must pass before merge (branch policy)                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ merge
┌─────────────────────────────────────────────────────────────────┐
│                         MAIN BRANCH                             │
├─────────────────────────────────────────────────────────────────┤
│  Merge → CD Pipeline Triggers                                   │
│                                                                 │
│    ┌──────────┐      ┌─────────────┐                            │
│    │ cdf build│ ───▶ │ cdf deploy  │  ✓ Applies changes to CDF │
│    └──────────┘      └─────────────┘                            │
│                                                                 │
│  Environment promotion: DEV → STAGING → PROD (with approvals)  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Authentication Model

**Pipeline → CDF authentication uses OAuth2 client credentials**

| Environment Variable | Description |
|---------------------|-------------|
| `LOGIN_FLOW` | `client_credentials` |
| `CDF_CLUSTER` | e.g., `westeurope-1` |
| `CDF_PROJECT` | e.g., `sylvamo-dev` |
| `IDP_CLIENT_ID` | Service Principal App ID |
| `IDP_CLIENT_SECRET` | Service Principal Secret |
| `IDP_TENANT_ID` | Entra ID Tenant |

**Azure DevOps pattern:**
```
Variable Groups (per environment):
  ├── dev-toolkit-credentials
  ├── staging-toolkit-credentials
  └── prod-toolkit-credentials
```

Secret values marked as **secret** in ADO → injected as env vars at runtime.

---

## Secret Handling Options

### Option A: ADO Variable Groups (Simplest)
```
ADO Variable Group ──▶ Pipeline Env Vars ──▶ Toolkit CLI
     (secrets)              (injected)         (reads ${VAR})
```

### Option B: Azure Key Vault Integration
```
Pipeline Step          Pipeline Step          Pipeline Step
     │                      │                      │
     ▼                      ▼                      ▼
┌─────────┐           ┌──────────┐           ┌───────────┐
│ Auth to │ ────────▶ │ Fetch    │ ────────▶ │ Export as │
│ Key     │           │ Secrets  │           │ Env Vars  │
│ Vault   │           │ from KV  │           │           │
└─────────┘           └──────────┘           └───────────┘
                                                   │
                                                   ▼
                                             cdf deploy
```

Toolkit uses `${VAR_NAME}` placeholders in YAML configs.

---

## Key Takeaways for Platform Teams

| Topic | What to Know |
|-------|--------------|
| **Connection Type** | External SaaS over HTTPS (like any cloud API) |
| **Auth Method** | OAuth2 client credentials via Entra ID service principal |
| **Secrets Storage** | ADO Variable Groups or Azure Key Vault → env vars |
| **CI Pipeline** | `cdf build` + `cdf deploy --dry-run` (PR validation) |
| **CD Pipeline** | `cdf deploy` on main branch merge |
| **Environments** | Separate CDF projects for dev/staging/prod |
| **Approvals** | Use ADO Environments + approval gates for prod |

**Bottom line:** Standard CI/CD patterns apply. CDF is just another external API with a CLI tool.

---

## Sample ADO Pipeline (Dry-Run)

```yaml
trigger:
  - none  # Triggered via PR validation

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: dev-toolkit-credentials  # Contains CDF auth vars

container:
  image: cognite/toolkit:0.5.35

steps:
  - script: cdf build
    displayName: 'Build Toolkit Modules'

  - script: cdf deploy --dry-run
    displayName: 'Validate Deployment (Dry Run)'
```

---

## Sample ADO Pipeline (Deploy)

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: prod-toolkit-credentials

container:
  image: cognite/toolkit:0.5.35

steps:
  - script: cdf build
    displayName: 'Build Toolkit Modules'

  - script: cdf deploy
    displayName: 'Deploy to CDF'
    env:
      IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
```

---

*Updated: February 4, 2026*
