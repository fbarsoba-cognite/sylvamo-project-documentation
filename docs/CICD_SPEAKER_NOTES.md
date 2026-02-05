# CI/CD for CDF - Speaker Notes

**Technical Overview Presentation**

---

## PRESENTATION FLOW TRACKER

| # | Section | Time | Status |
|---|---------|------|--------|
| 1 | [Opening / TL;DR](#slide-1-opening--tldr) | 3 min | ⬜ |
| 2 | [What is CDF from CI/CD Perspective](#slide-2-what-is-cdf-from-a-cicd-perspective) | 3 min | ⬜ |
| 3 | [The Tech Stack](#slide-3-the-cicd-tech-stack) | 3 min | ⬜ |
| 4 | [Repository Structure](#slide-4-repository-structure) | 3 min | ⬜ |
| 5 | [CI/CD Flow Overview](#slide-5-cicd-flow-overview) | 5 min | ⬜ |
| 6 | [Authentication Model](#slide-6-authentication-model) | 5 min | ⬜ |
| 7 | [Secret Handling](#slide-7-secret-handling-options) | 3 min | ⬜ |
| 8 | [Key Takeaways](#slide-8-key-takeaways) | 3 min | ⬜ |
| 9 | [Sample Pipelines](#slide-9-sample-ado-pipelines) | 5 min | ⬜ |
| 10 | [Questions](#slide-10-questions) | 5 min | ⬜ |
| | **TOTAL** | **~38 min** | |

---

## LINKS TO HAVE OPEN (Prep Before Meeting)

| Tab | URL | When to Show |
|-----|-----|--------------|
| **GitHub Docs** | [CICD_OVERVIEW.md](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md) | Throughout |
| **GitHub README** | [sylvamo-data-model](https://github.com/fbarsoba-cognite/sylvamo-data-model#cicd-for-cdf) | Reference |
| **ADO Repo** | [Industrial-Data-Landscape-IDL](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL) | Demo sections |

---

## SLIDE 1: Opening / TL;DR

**⏱️ ~3 minutes**

**📺 SHOW:** Title slide

**📄 GITHUB REF:** [CICD_OVERVIEW.md - TL;DR](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#cicd-for-cognite-data-fusion-cdf)

**SPEAKER NOTES:**

Welcome everyone. Today I'm going to walk you through how we do CI/CD for Cognite Data Fusion, or CDF. This is aimed at technical folks who may not be familiar with CDF specifically, so I'll explain things from a platform engineering perspective.

Let me start with the big picture - five key points to keep in mind:

1. **CDF is a cloud service** - think of it like Salesforce, Snowflake, or any other SaaS platform. We deploy TO it, not inside it.

2. **We use a CLI tool called Cognite Toolkit** - the command is just `cdf`. This is a pre-built tool from Cognite, we don't write custom deployment code.

3. **Three commands to remember**: `cdf build` validates our configuration, `cdf deploy --dry-run` shows what WOULD change without actually changing anything, and `cdf deploy` applies the changes for real.

4. **Authentication uses a service principal** - this is an Entra ID app registration with a client ID and client secret. It's basically a robot account that the pipeline uses to talk to CDF.

5. **Secrets are stored in ADO Variable Groups** - these are project-level variable groups in our SylvamoCorp Azure DevOps project. The pipeline automatically injects them as environment variables at runtime.

If you remember nothing else from this presentation, remember those five points.

---

## SLIDE 2: What is CDF from a CI/CD Perspective?

**⏱️ ~3 minutes**

**📺 SHOW:** The diagram below or [CICD_OVERVIEW.md](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#what-is-cdf-from-a-cicd-perspective)

**📄 GITHUB REF:** [CICD_OVERVIEW.md - What is CDF](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#what-is-cdf-from-a-cicd-perspective)

**SPEAKER NOTES:**

Let me explain what CDF looks like from your perspective as a platform team.

CDF is an **external SaaS endpoint**. It's hosted in Cognite-managed cloud clusters - for Sylvamo, we're using the `westeurope-1` cluster.

```
┌─────────────────┐     HTTPS/OAuth2     ┌─────────────────┐
│  Your CI/CD     │ ──────────────────▶  │  Cognite Data   │
│  Pipeline       │                       │  Fusion (CDF)   │
│  (ADO/GitHub)   │                       │  Cloud SaaS     │
└─────────────────┘                       └─────────────────┘
```

When our CI/CD pipeline runs, it connects to CDF over HTTPS. The authentication uses OAuth2 client credentials flow - that's the same pattern you'd use for any service-to-service authentication with Entra ID.

The key mental model here is: **treat CDF like any external cloud API**. It's no different from deploying to AWS, Azure, or calling the Salesforce API. Your pipeline authenticates with credentials, makes API calls to create or update resources, and that's it.

Nothing runs "inside" your network. The pipeline runs in ADO's hosted agents, talks to CDF over the public internet using HTTPS, and CDF does all the work on their end.

---

## SLIDE 3: The CI/CD Tech Stack

**⏱️ ~3 minutes**

**📺 SHOW:** The table below or [CICD_OVERVIEW.md](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#the-cicd-tech-stack)

**📄 GITHUB REF:** [CICD_OVERVIEW.md - Tech Stack](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#the-cicd-tech-stack)

**SPEAKER NOTES:**

Let's talk about the actual tools we use.

| Component | Technology |
|-----------|------------|
| **Deploy Tool** | Cognite Toolkit CLI (`cdf`) |
| **Package** | `cognite-toolkit` (pip) or Docker `cognite/toolkit:<version>` |
| **Key Commands** | `cdf build`, `cdf deploy --dry-run`, `cdf deploy` |
| **Pipeline Definitions** | YAML (platform-specific) |

The **deployment tool** is the Cognite Toolkit CLI. The command is `cdf`. You can install it as a Python package via pip - `pip install cognite-toolkit` - or use Cognite's official Docker image: `cognite/toolkit` with a specific version tag.

**Supported Platforms:**
- GitHub Actions → `.github/workflows/*.yml`
- Azure DevOps → `.devops/*.yml`
- GitLab CI/CD → `.gitlab-ci.yml`

The **key commands** you'll see in pipelines are:
- `cdf build` - this validates your configuration files and compiles them into a deployable format
- `cdf deploy --dry-run` - this shows what would change in CDF without actually making changes. Think of it like `terraform plan`.
- `cdf deploy` - this actually applies the changes. Like `terraform apply`.

Here's something important: **you don't need to write Python code**. The Toolkit is a pre-built CLI - you just call it from your pipeline. All the configuration is in YAML files. If you know YAML and understand CI/CD concepts, you can work with this.

---

## SLIDE 4: Repository Structure

**⏱️ ~3 minutes**

**📺 SHOW:** The structure below or navigate to [ADO Repo](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL)

**📄 GITHUB REF:** [CICD_OVERVIEW.md - Repository Structure](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#repository-structure)

**SPEAKER NOTES:**

Let me walk you through how a Toolkit repository is structured.

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

At the root of the repo, you have an organization directory - in our case, it's called `sylvamo/`. Inside that directory, you have:

**Config files per environment:**
- `config.dev.yaml` - points to our DEV CDF project
- `config.staging.yaml` - points to STAGING
- `config.prod.yaml` - points to PROD

Each config file defines two things:
1. The **target CDF project** - like `project: sylvamo-dev`
2. Which **modules to deploy** - a `selected:` list that says which pieces of infrastructure to include

**Modules directory:**
The `modules/` folder contains the actual resources you're deploying - data models, transformations, RAW databases, access groups, whatever CDF resources you need.

The key concept here is: **one repo, multiple environments**. The same module code deploys to dev, staging, and prod. The only difference is which config file you point to - and each config file points to a different CDF project.

This is created initially by running `cdf modules init <organization_dir>`, which scaffolds out this structure for you.

---

## SLIDE 5: CI/CD Flow Overview

**⏱️ ~5 minutes**

**📺 SHOW:** The flow diagram below or [CICD_OVERVIEW.md](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#cicd-flow-overview)

**📄 GITHUB REF:** [CICD_OVERVIEW.md - CI/CD Flow](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#cicd-flow-overview)

**SPEAKER NOTES:**

Now let's talk about the actual CI/CD flow. This follows a standard pattern you've probably seen before.

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

**On feature branches - the CI part:**

When a developer creates a PR, the CI pipeline triggers automatically. It runs two steps:

1. `cdf build` - validates the configuration
2. `cdf deploy --dry-run` - shows what WOULD change in CDF

The dry-run output shows exactly which resources would be created, updated, or deleted. This is like `terraform plan` - it's a preview, nothing actually changes.

We configure this as a **branch policy** - the PR cannot be merged unless this pipeline passes. This gives reviewers confidence that the changes are valid and they can see the impact before approving.

**On main branch - the CD part:**

When code is merged to main, the CD pipeline triggers. It runs:

1. `cdf build` - again, validates everything
2. `cdf deploy` - actually applies the changes to CDF

For environment promotion, we use a model of DEV → STAGING → PROD. Each is a separate CDF project, and you can add approval gates between stages using ADO Environments.

The key safety net here is the **two-step process**:
- PR stage: dry-run shows what WOULD change
- Merge stage: deploy actually applies changes

Nothing changes in CDF until code is merged to main. This gives you full auditability through Git history.

---

## SLIDE 6: Authentication Model

**⏱️ ~5 minutes**

**📺 SHOW:** The table below or [CICD_OVERVIEW.md](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#authentication-model)

**📄 GITHUB REF:** [CICD_OVERVIEW.md - Authentication](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#authentication-model)

**SPEAKER NOTES:**

Let's talk about how the pipeline authenticates to CDF. This is probably the most important part for a platform team to understand.

The Toolkit uses **OAuth2 client credentials flow**. This is the standard pattern for service-to-service authentication with Entra ID.

The required environment variables are:

| Environment Variable | Description |
|---------------------|-------------|
| `LOGIN_FLOW` | `client_credentials` |
| `CDF_CLUSTER` | e.g., `westeurope-1` |
| `CDF_PROJECT` | e.g., `sylvamo-dev` |
| `IDP_CLIENT_ID` | Service Principal App ID |
| `IDP_CLIENT_SECRET` | Service Principal Secret |
| `IDP_TENANT_ID` | Entra ID Tenant |

**How the flow works:**

1. ADO stores the credentials in a Variable Group - think of it like a secure key-value store
2. The pipeline YAML links to that Variable Group with `variables: - group: dev-toolkit-credentials`
3. When the job runs, ADO automatically injects those values as environment variables
4. The `cdf` CLI reads those environment variables and uses them to authenticate

You never see the secrets in code - they're injected at runtime. The secret values never appear in logs because ADO masks them.

**ADO Configuration:**
```
Variable Groups (per environment):
  ├── dev-toolkit-credentials
  ├── staging-toolkit-credentials
  └── prod-toolkit-credentials
```

Because we store these at the project level, any pipeline in the repository can access them. We don't have to configure credentials separately for each pipeline.

---

## SLIDE 7: Secret Handling Options

**⏱️ ~3 minutes**

**📺 SHOW:** The options below or [CICD_OVERVIEW.md](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#secret-handling-options)

**📄 GITHUB REF:** [CICD_OVERVIEW.md - Secret Handling](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#secret-handling-options)

**SPEAKER NOTES:**

There are two main options for handling secrets. Let me explain both.

**Option A: ADO Variable Groups (Simplest)**

This is the simpler approach and what Sylvamo uses.

```
ADO Variable Group ──▶ Pipeline Env Vars ──▶ Toolkit CLI
     (secrets)              (injected)         (reads ${VAR})
```

The flow is:
1. Secrets stored in ADO Variable Group
2. Pipeline links to the group
3. ADO injects them as environment variables at runtime
4. Toolkit CLI reads the env vars

This is straightforward and works well for most cases. ADO handles encryption, access control, and audit logging.

**Option B: Azure Key Vault Integration**

This is more complex but might be required if you have organizational policies mandating Key Vault for all secrets.

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

The Toolkit itself doesn't have a direct Key Vault integration - it just reads environment variables. So you need pipeline steps to bridge the gap.

**Which should you use?**

Use Option A - Variable Groups - for simplicity. It meets most requirements.

Use Option B if you have centralized secret management policies requiring Key Vault, or if you need automatic rotation.

One more thing: the Toolkit supports `${VAR_NAME}` placeholders in YAML config files. So if you have a secret that needs to go into a configuration file - like a client secret for a workflow trigger - you can write `${IDP_WF_TRIGGER_SECRET}` and the Toolkit will substitute the environment variable value at deploy time.

---

## SLIDE 8: Key Takeaways

**⏱️ ~3 minutes**

**📺 SHOW:** The table below or [CICD_OVERVIEW.md](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#key-takeaways-for-platform-teams)

**📄 GITHUB REF:** [CICD_OVERVIEW.md - Key Takeaways](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#key-takeaways-for-platform-teams)

**SPEAKER NOTES:**

Let me summarize the key points:

| Topic | What to Know |
|-------|--------------|
| **Connection Type** | External SaaS over HTTPS (like any cloud API) |
| **Auth Method** | OAuth2 client credentials via Entra ID service principal |
| **Secrets Storage** | ADO Variable Groups or Azure Key Vault → env vars |
| **CI Pipeline** | `cdf build` + `cdf deploy --dry-run` (PR validation) |
| **CD Pipeline** | `cdf deploy` on main branch merge |
| **Environments** | Separate CDF projects for dev/staging/prod |
| **Approvals** | Use ADO Environments + approval gates for prod |

**Connection Type:** CDF is external SaaS accessed over HTTPS. It's no different from any other cloud API. No VPN, no private endpoints in our current setup - just public HTTPS to Cognite's cluster.

**Auth Method:** OAuth2 client credentials via Entra ID service principal. Standard stuff - you create an App Registration, give it a secret, and use client_id + client_secret to get tokens.

**The bottom line is: standard CI/CD patterns apply.** If you've set up pipelines for Terraform, ARM templates, or any other infrastructure-as-code tool, this will feel very familiar. CDF is just another external API with a CLI tool.

---

## SLIDE 9: Sample ADO Pipelines

**⏱️ ~5 minutes**

**📺 SHOW:** The YAML examples below or [CICD_OVERVIEW.md](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#sample-ado-pipeline-dry-run)

**📄 GITHUB REF:** [CICD_OVERVIEW.md - Sample Pipelines](https://github.com/fbarsoba-cognite/sylvamo-data-model/blob/main/docs/CICD_OVERVIEW.md#sample-ado-pipeline-dry-run)

**SPEAKER NOTES:**

Let me walk through the actual pipeline YAML.

### Dry-Run Pipeline (PR Validation)

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

We set trigger to `none` because this pipeline is triggered by PR validation, not by pushes directly.

We use Microsoft-hosted agents with Ubuntu, and run inside Cognite's official Docker image which has the `cdf` CLI pre-installed.

The `variables` section links to our Variable Group - ADO will inject all the variables from this group as environment variables.

### Deploy Pipeline (On Merge)

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

This triggers automatically when code is pushed to main. The deploy step has an extra `env:` block - this is an ADO quirk where secret variables need to be explicitly mapped for script steps.

That's it - two steps, and your changes are deployed to CDF.

---

## SLIDE 10: Questions

**⏱️ ~5 minutes**

**📺 SHOW:** Q&A slide or just open for discussion

**SPEAKER NOTES:**

To wrap up:

CDF CI/CD is straightforward if you're familiar with infrastructure-as-code patterns. We have:
- A CLI tool (`cdf`) that handles all the complexity
- YAML configuration files in a Git repository
- Standard CI/CD pipelines that validate on PR and deploy on merge
- OAuth2 authentication using Entra ID service principals
- Secrets stored in ADO Variable Groups

**Key URLs:**
- ADO Repo: https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL
- Data Model Docs: https://github.com/fbarsoba-cognite/sylvamo-data-model

Any questions?

---

## QUICK REFERENCE

### Commands
- `cdf build` - Validate and compile configuration
- `cdf deploy --dry-run` - Preview changes (no actual changes)
- `cdf deploy` - Apply changes to CDF

### Environment Variables
- `LOGIN_FLOW=client_credentials`
- `CDF_CLUSTER=westeurope-1`
- `CDF_PROJECT=sylvamo-dev`
- `IDP_CLIENT_ID=<app-id>`
- `IDP_CLIENT_SECRET=<secret>`
- `IDP_TENANT_ID=<tenant-id>`

---

# APPENDIX: Customer Handoff Version

**Use this version when you want to frame the meeting as a handoff with specific action items for the customer's platform team.**

---

## FRAMING: How to Position This Meeting

**INTERNAL NOTE (don't say this out loud):**

The goal is to:
1. **Show what we built** - demo the working CI/CD setup
2. **Transfer understanding** - explain how it works so they can own it
3. **Give them clear ownership** - specific things THEY need to do going forward

Avoid making it sound like "we did everything, you're done." Instead: "we set up the foundation, here's what you own now."

---

## Opening (Handoff Version)

Thanks for joining. Today I want to walk you through the CI/CD setup we've put in place for CDF deployments.

I'll show you:
1. **What we've built** - the pipelines, the configuration, how it all works
2. **How you'll use it** - the day-to-day workflow
3. **What you own going forward** - the pieces that your team will manage

By the end, you'll have a clear picture of the system and know exactly what actions you need to take.

---

## What's Already Done (Cognite Setup)

| Component | Status | Details |
|-----------|--------|---------|
| Toolkit repository | Done | Industrial-Data-Landscape-IDL in your ADO |
| Pipeline YAML files | Done | `.devops/` folder with dry-run and deploy pipelines |
| Docker image reference | Done | Using `cognite/toolkit:0.5.35` |
| Config file structure | Done | `config.dev.yaml`, `config.staging.yaml`, `config.prod.yaml` |
| Variable Groups | Done | `dev-toolkit-credentials` created with all required vars |
| Service Principal | Done | App registration in Entra ID with CDF access |

This is the foundation. You don't need to set any of this up - it's working today.

---

## What YOUR Team Owns - Action Items

### 1. Enable Branch Policies (Required)

**What:** Configure the dry-run pipeline as a required check on PRs to main.

**Why:** Prevents broken configurations from being merged.

**How:** 
- Go to Repos → Branches → main → Branch policies
- Add a Build Validation policy
- Select the dry-run pipeline
- Set to "Required"

**Who:** Your ADO admin | **When:** This week

---

### 2. Set Up Approval Gates for Production (Required)

**What:** Add manual approval before deploying to staging and prod.

**How:**
- Create ADO Environments: `cdf-staging`, `cdf-prod`
- Add approvers to each environment
- Update deploy pipeline to use environments

**Who:** Your platform team | **When:** Before deploying to staging/prod

---

### 3. Own the Variable Groups (Ongoing)

**What:** You now own the credentials in the Variable Groups.

**Responsibilities:**
- **Access control** - manage who can view/edit the Variable Groups
- **Secret rotation** - when you rotate the service principal secret, update it here
- **Audit** - periodically review access and usage

**Where:** Project Settings → Pipelines → Library → Variable Groups

---

### 4. Monitor Pipeline Runs (Ongoing)

**What:** Keep an eye on pipeline success/failure rates.

**How:**
- Check the Pipelines section regularly
- Consider setting up notifications for failed runs
- Review dry-run output before approving PRs

---

### 5. Onboard Your Developers (This Month)

**Key things they need to know:**
- All CDF changes go through Git - no manual changes in the UI
- Create a branch, make changes, open a PR
- Review the dry-run output before approving
- Merge to main to deploy

---

### 6. Extend to Staging and Production (Future)

**What's needed:**
- Create Variable Groups for staging and prod credentials
- Update pipelines with multi-stage deployment
- Add the approval gates mentioned above

**Who:** Your platform team (we can assist)

---

## CHEAT SHEET: Action Items Summary

| # | Action | Owner | Timeline | Priority |
|---|--------|-------|----------|----------|
| 1 | Enable branch policies on main | ADO Admin | This week | Required |
| 2 | Set up approval gates for staging/prod | Platform Team | Before prod deploy | Required |
| 3 | Review Variable Group access controls | Security Team | This week | Required |
| 4 | Set up pipeline failure notifications | Platform Team | This month | Recommended |
| 5 | Onboard 1-2 developers to workflow | Platform Team | This month | Required |
| 6 | Plan staging/prod extension | Platform + Cognite | This quarter | Future |

---

*Speaker notes prepared: February 4, 2026*
