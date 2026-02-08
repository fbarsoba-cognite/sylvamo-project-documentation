# CI/CD Complete Setup Guide - Speaker Notes

**Phase 2: Hands-On Setup Session**  
**Audience**: Platform Teams, DevOps Engineers, Technical Leads  
**Duration**: 60-90 minutes (hands-on setup session)  
**Last Updated**: February 8, 2026  
**Prerequisites**: Phase 1 - [CI/CD Overview](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/blob/main/docs/reference/cicd/CICD_OVERVIEW.md)  
**Source**: [CI/CD Complete Setup Guide](CICD_COMPLETE_SETUP_GUIDE.md)

---

## Phase Context

**This is Phase 2 of a two-part presentation:**

- **Phase 1** (Completed): [CI/CD Overview](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/blob/main/docs/reference/cicd/CICD_OVERVIEW.md)
  - Concepts: What is CDF from a CI/CD perspective?
  - Tech stack: Cognite Toolkit CLI, authentication model
  - Flow: PR validation → merge → deployment
  - Repository structure and configuration files

- **Phase 2** (This Session): Hands-On Setup
  - Step-by-step pipeline creation
  - Variable groups and environments configuration
  - Testing and validation
  - Troubleshooting real-world issues

**Assumed Knowledge from Phase 1:**
- Understanding of CDF as external SaaS endpoint
- Familiarity with `cdf build`, `cdf deploy --dry-run`, `cdf deploy` commands
- Knowledge of OAuth2 client credentials authentication
- Understanding of ADO Variable Groups concept
- Awareness of repository structure (`sylvamo/`, `config.<env>.yaml`, `.devops/`)

---

## Pre-Presentation Checklist

Before presenting, ensure you have:

- [ ] Access to Azure DevOps (SylvamoCorp organization)
- [ ] Access to `Industrial-Data-Landscape-IDL` repository
- [ ] Permissions to create pipelines, variable groups, and environments
- [ ] CDF credentials for dev, staging, and production environments
- [ ] Azure AD service principal credentials
- [ ] Access to CDF Fusion UI for verification
- [ ] Terminal/IDE ready for Git operations
- [ ] Browser tabs ready: ADO, CDF UI, Azure Portal

---

## Presentation Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION FLOW                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Introduction & Overview (10 min)                       │
│     └─> What is CI/CD for CDF? Why does it matter?        │
│                                                             │
│  2. Prerequisites & Repository Structure (5 min)            │
│     └─> What do we need? How is code organized?            │
│                                                             │
│  3. Hands-On Setup (45-60 min)                             │
│     ├─> Step 1: Prepare Pipeline YAML Files                │
│     ├─> Step 2: Create Variable Groups                    │
│     ├─> Step 3: Create ADO Environments                  │
│     ├─> Step 4: Create Pipelines                          │
│     ├─> Step 5: Configure Branch Policies                 │
│     ├─> Step 6: Verify Config Files                        │
│     └─> Step 7: Test the Setup                            │
│                                                             │
│  4. Troubleshooting & Best Practices (10 min)             │
│     └─> Common issues and how to avoid them                │
│                                                             │
│  5. Q&A and Next Steps (10 min)                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## SECTION 1: Introduction & Overview

**⏱️ ~10 minutes**

### Slide 1: Welcome & Phase 2 Objectives

**📄 REFERENCE:** 
- Phase 1: [CI/CD Overview](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/blob/main/docs/reference/cicd/CICD_OVERVIEW.md)
- Phase 2: [Setup Guide - Overview and Concepts](CICD_COMPLETE_SETUP_GUIDE.md#overview-and-concepts)

**SPEAKER NOTES:**

> "Welcome back! In Phase 1, we covered the concepts and architecture of CI/CD for Cognite Data Fusion. Today, in Phase 2, we're going to roll up our sleeves and actually build it. By the end of this session, you'll have working pipelines that automatically deploy to dev, staging, and production environments."

**Quick Recap of Phase 1:**

> "Just to refresh - we learned that:"
> - CDF is an external SaaS endpoint (like AWS or Azure)
> - We use the Cognite Toolkit CLI (`cdf` command)
> - Three key commands: `build`, `deploy --dry-run`, `deploy`
> - Authentication via OAuth2 service principals
> - Secrets stored in ADO Variable Groups

**Phase 2 Objectives:**

1. **Set up** three Azure DevOps pipelines (PR validation, deployment, testing)
2. **Configure** variable groups with CDF credentials
3. **Create** ADO environments with approval gates
4. **Configure** branch policies for PR validation
5. **Test** the complete workflow end-to-end
6. **Troubleshoot** common issues we'll encounter

**What We'll Build:**

- **PR Validation Pipeline** - Runs on every PR, prevents bad code from merging
- **Deployment Pipeline** - Multi-stage (dev → staging → prod) with approvals
- **Test Pipeline** - Manual validation of all environments

**Transition**: "Let's start by reviewing what we need before we begin."

---

### Slide 2: Quick Review - CI/CD Flow

**📄 REFERENCE:** 
- Phase 1: [CI/CD Overview - CI/CD Flow](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/blob/main/docs/reference/cicd/CICD_OVERVIEW.md#cicd-flow-overview)
- Phase 2: [Setup Guide - Overview and Concepts](CICD_COMPLETE_SETUP_GUIDE.md#overview-and-concepts)

**📺 SHOW:** The CI/CD flow diagram from Phase 1

**SPEAKER NOTES:**

> "Let's quickly review the flow we discussed in Phase 1, because we'll be implementing this today."

**Review the Flow:**

```
Feature Branch → PR → Dry-Run → Merge → Deploy Dev → Approve → Deploy Staging → Approve → Deploy Prod
```

**Key Points to Reinforce:**

1. **PR Stage (CI):**
   - `cdf build` → validates configuration
   - `cdf deploy --dry-run` → previews changes (like `terraform plan`)
   - Must pass before merge (branch policy)

2. **Merge Stage (CD):**
   - `cdf deploy` → actually applies changes (like `terraform apply`)
   - Environment promotion: dev → staging → prod
   - Approval gates protect staging and production

**What We're Building Today:**

> "Today we'll create the actual pipelines that implement this flow. We'll configure:"
> - The PR validation pipeline (dry-run on PRs)
> - The deployment pipeline (actual deployments)
> - The approval gates (staging/prod protection)
> - The branch policies (enforce PR validation)

**Transition**: "Now let's make sure everyone has what they need before we start."

---

### Slide 3: Prerequisites

**📄 REFERENCE:** [Setup Guide - Prerequisites](CICD_COMPLETE_SETUP_GUIDE.md#prerequisites)

**SPEAKER NOTES:**

> "Before we dive in, let's make sure everyone has what they need."

**Checklist to Review:**

**Azure DevOps Access:**
- ✅ Access to SylvamoCorp organization
- ✅ Access to `Industrial-Data-Landscape-IDL` repository
- ✅ Permissions to create pipelines, variable groups, environments

**CDF Access:**
- ✅ Access to dev, staging, and production CDF projects
- ✅ Service principal credentials for each environment
- ✅ Know your CDF project names (`sylvamo-dev`, `sylvamo-test`, `sylvamo-prod`)

**Azure AD Access:**
- ✅ Access to Azure Active Directory / Entra ID
- ✅ Service principal client IDs and secrets
- ✅ Tenant ID

**Repository Access:**
- ✅ Local clone of repository
- ✅ Write access to `main` branch (or ability to create PRs)

**Interactive Check:**

> "Can everyone access Azure DevOps? Raise your hand if you need help getting access."

**Transition**: "Good. Now let's look at how the repository is structured."

---

## SECTION 2: Repository Structure

**⏱️ ~5 minutes**

### Slide 4: Repository Structure

**📄 REFERENCE:** [Setup Guide - Repository Structure](CICD_COMPLETE_SETUP_GUIDE.md#repository-structure)

**📺 SHOW:** Navigate to ADO repository and show the structure

**SPEAKER NOTES:**

> "Let's understand how the code is organized. This structure is critical - the pipelines expect this layout."

**Show This Structure:**

```
Industrial-Data-Landscape-IDL/
  sylvamo/                    # Organization directory
    config.dev.yaml           # → points to DEV CDF project
    config.staging.yaml       # → points to STAGING CDF project  
    config.prod.yaml          # → points to PROD CDF project
    modules/                  # Toolkit modules (resources to deploy)
      admin/
      mfg_core/
      mfg_extended/
  .devops/                    # Pipeline definitions
    dry-run-pipeline.yml
    deploy-pipeline.yml
    test-all-environments.yml
  cdf.toml                    # Toolkit configuration
```

**Walk Through Each Level:**

1. **`sylvamo/`** - Organization directory
   > "This is created by `cdf modules init sylvamo`. It's the root of all Toolkit configuration."

2. **`config.<env>.yaml`** - Environment configs
   > "These are the magic files. Each one points to a different CDF project. Same code, different targets."

3. **`modules/`** - Logical groupings
   > "Think of modules like Terraform modules or Helm charts. Each one is a cohesive set of resources."

**Critical Point:**

> "The `project:` value in each `config.<env>.yaml` MUST match the `CDF_PROJECT` variable in the corresponding variable group. The Toolkit enforces this for staging/prod as a safety check."

**Transition**: "Now let's start the hands-on setup. We'll go step by step."

---

## SECTION 3: Hands-On Setup

**⏱️ ~45-60 minutes**

### Step 1: Prepare Pipeline YAML Files

**⏱️ ~5 minutes**

**📄 REFERENCE:** [Setup Guide - Step 1](CICD_COMPLETE_SETUP_GUIDE.md#step-1-prepare-pipeline-yaml-files)

**SPEAKER NOTES:**

> "First, we need to verify our pipeline YAML files are correct. These files define what the pipelines do."

**What to Check:**

1. **Files Exist:**
   - `.devops/dry-run-pipeline.yml`
   - `.devops/deploy-pipeline.yml`
   - `.devops/test-all-environments.yml`

2. **Critical Requirements:**

**Show This Checklist:**

✅ **Checkout Step:** `checkout: self` as first step  
✅ **Working Directory:** `workingDirectory: 'sylvamo'` on all scripts  
✅ **Build Environment:** `cdf build --env <env>` with environment  
✅ **Environment Variables:** `env:` section on all deploy steps  
✅ **Docker Version:** Match `cognite/toolkit` version with modules version

**Common Mistakes to Highlight:**

> "I've seen these mistakes cause failures:"
> - Missing `checkout: self` → "workingDirectory not found"
> - Missing `--env` on `cdf build` → Builds for wrong environment
> - Missing `env:` on dry-run → Authentication failures
> - Wrong Docker version → Version mismatch

**Show Example:**

```yaml
steps:
  - checkout: self  # ← Required first step
  - script: cdf build --env dev  # ← Must specify environment
    displayName: 'Build'
    workingDirectory: 'sylvamo'  # ← Required
  - script: cdf deploy --dry-run --env dev
    env:  # ← Required for authentication
      IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
```

**Action:** "Let's verify these files exist and are committed to `main` branch."

**Transition**: "Good. Now let's create the variable groups where we'll store credentials."

---

### Step 2: Create Variable Groups

**⏱️ ~15 minutes**

**📄 REFERENCE:** [Setup Guide - Step 2](CICD_COMPLETE_SETUP_GUIDE.md#step-2-create-variable-groups)

**📺 SHOW:** Navigate to Pipelines → Library → Variable groups

**SPEAKER NOTES:**

> "Variable groups are where we store CDF credentials securely. We need three groups - one per environment."

**Why Variable Groups?**

> "Instead of hardcoding secrets in YAML (bad!), we store them in ADO Variable Groups. ADO injects them as environment variables at runtime. Secrets never appear in logs."

**Live Demo - Create Dev Variable Group:**

1. **Navigate:**
   > "Go to Pipelines → Library → Variable groups"

2. **Create Group:**
   > "Click '+ Variable group'"
   > "Name: `dev-toolkit-credentials`"
   > "Description: 'Credentials for CDF dev environment'"

3. **Add Variables:**
   > "Click '+ Add' and add these one by one:"

**Show Variable Table:**

| Variable | Value | Secret? |
|----------|-------|---------|
| `CDF_CLUSTER` | `az-eastus-1` | No |
| `CDF_PROJECT` | `sylvamo-dev` | No |
| `LOGIN_FLOW` | `client_credentials` | No |
| `IDP_CLIENT_ID` | (Your App ID) | No |
| `IDP_CLIENT_SECRET` | (Your Secret) | **Yes** ← Click padlock |
| `IDP_TENANT_ID` | (Your Tenant ID) | No |
| `CDF_URL` | `https://az-eastus-1.cognitedata.com` | No |
| `INGESTION_CLIENT_ID` | (Same or separate) | No |
| `INGESTION_CLIENT_SECRET` | (Same or separate) | **Yes** ← Click padlock |

**Critical Step - Pipeline Permissions:**

> "Before saving, click 'Pipeline permissions' → '+' → Select `Industrial-Data-Landscape-IDL` → Save"
> 
> "This is critical! If you forget this, you'll get 'Variable group could not be found' errors."

**Repeat for Staging and Production:**

> "Now create `staging-toolkit-credentials` and `prod-toolkit-credentials` with the same variables, but:"
> - Staging: `CDF_PROJECT = sylvamo-test`
> - Production: `CDF_PROJECT = sylvamo-prod`

**Verification:**

> "Checklist:"
> - [ ] All three groups exist
> - [ ] All variables present
> - [ ] Secrets marked as secret (padlock icon)
> - [ ] Pipeline permissions granted

**Common Issue:**

> "If you see permission errors, go back and grant pipeline permissions. This is the #1 issue I see."

**Transition**: "Great! Now let's set up approval gates for staging and production."

---

### Step 3: Create ADO Environments

**⏱️ ~10 minutes**

**📄 REFERENCE:** [Setup Guide - Step 3](CICD_COMPLETE_SETUP_GUIDE.md#step-3-create-ado-environments)

**📺 SHOW:** Navigate to Pipelines → Environments

**SPEAKER NOTES:**

> "Environments enable approval gates. When code reaches staging or production, someone must approve before deployment."

**Why Environments?**

> "This gives you control. Dev deploys automatically, but staging and production require human approval. This prevents accidental production deployments."

**Live Demo - Create Staging Environment:**

1. **Navigate:**
   > "Go to Pipelines → Environments"

2. **Create Environment:**
   > "Click '+ Create environment'"
   > "Name: `staging` ← Must match exactly (case-sensitive!)"
   > "Description: 'Staging environment for CDF deployments'"
   > "Resource type: 'None'"
   > "Click 'Create'"

3. **Add Approval Gate:**
   > "Click on the `staging` environment"
   > "Click 'Approvals and checks' → '+ Add check'"
   > "Select 'Approvals'"
   > "Add approver: [Select yourself or team lead]"
   > "Minimum approvers: 1"
   > "Click 'Create'"

**Repeat for Production:**

> "Now create `production` environment with the same approval setup."

**Critical Point:**

> "The environment names MUST match exactly what's in the pipeline YAML:"
> - Pipeline says: `environment: 'staging'`
> - ADO environment must be: `staging` (not `Staging` or `STAGING`)

**Verification:**

> "Checklist:"
> - [ ] `staging` environment exists
> - [ ] `production` environment exists
> - [ ] Each has at least 1 approver
> - [ ] Names match pipeline YAML exactly

**Transition**: "Perfect! Now let's create the actual pipelines."

---

### Step 4: Create Pipelines in Azure DevOps

**⏱️ ~15 minutes**

**📄 REFERENCE:** [Setup Guide - Step 4](CICD_COMPLETE_SETUP_GUIDE.md#step-4-create-pipelines-in-azure-devops)

**📺 SHOW:** Navigate to Pipelines → Pipelines

**SPEAKER NOTES:**

> "Now we'll create three pipelines. These are the actual automation that runs your deployments."

**Pipeline 1: PR Validation**

**Live Demo:**

1. **Navigate:**
   > "Go to Pipelines → Pipelines"
   > "Click 'Create Pipeline' (or 'New Pipeline')"

2. **Select Repository:**
   > "Where is your code? → 'Azure Repos Git'"
   > "Select repository: 'Industrial-Data-Landscape-IDL'"

3. **Configure:**
   > "Select 'Existing Azure Pipelines YAML file'"
   > "Branch: `main`"
   > "Path: `.devops/dry-run-pipeline.yml`"
   > "Click 'Continue'"

4. **Review & Save:**
   > "Review the YAML (should show dry-run pipeline)"
   > "Click 'Save'"
   > "Rename: Click three dots → 'Rename/move' → Name: 'PR Validation'"

**What This Pipeline Does:**

> "This pipeline runs on every PR. It validates your changes with `cdf build` and `cdf deploy --dry-run`. If it fails, the PR can't be merged."

**Pipeline 2: Deployment Pipeline**

**Live Demo:**

1. **Create:**
   > "Click 'New Pipeline'"
   > "Azure Repos Git → Industrial-Data-Landscape-IDL"
   > "Existing YAML file"
   > "Path: `.devops/deploy-pipeline.yml`"
   > "Click 'Continue'"

2. **Review:**
   > "This should show three stages: DeployDev, DeployStaging, DeployProd"
   > "Click 'Save'"
   > "Rename: 'Deploy to CDF'"

**What This Pipeline Does:**

> "This is the main deployment pipeline. It:"
> - Auto-deploys to dev (no approval)
> - Waits for approval to deploy to staging
> - Waits for approval to deploy to production

**Pipeline 3: Test All Environments**

**Live Demo:**

1. **Create:**
   > "Click 'New Pipeline'"
   > "Path: `.devops/test-all-environments.yml`"
   > "Save and rename: 'Validate All Environments'"

**What This Pipeline Does:**

> "This is a manual pipeline you can run anytime to validate all environments. Useful for checking if environments are in sync."

**Verification:**

> "Checklist:"
> - [ ] Three pipelines appear in list
> - [ ] PR Validation can be run manually
> - [ ] Deploy to CDF shows three stages
> - [ ] No errors when viewing YAML

**Common Issues:**

> "If you see errors about variable groups, check that:"
> - Variable groups exist
> - Pipeline permissions are granted
> - Variable group names match YAML exactly

**Transition**: "Good! Now let's configure branch policies so PRs require validation."

---

### Step 5: Configure Branch Policies

**⏱️ ~5 minutes**

**📄 REFERENCE:** [Setup Guide - Step 5](CICD_COMPLETE_SETUP_GUIDE.md#step-5-configure-branch-policies)

**📺 SHOW:** Navigate to Repos → Branches

**SPEAKER NOTES:**

> "Branch policies ensure that PRs can't be merged until the validation pipeline passes. This prevents bad code from reaching main."

**Live Demo:**

1. **Navigate:**
   > "Go to Repos → Branches"
   > "Find `main` branch"
   > "Click '...' next to `main` → 'Branch policies'"

2. **Add Build Policy:**
   > "Under 'Build validation', click '+ Add build policy'"
   > "Build pipeline: Select 'PR Validation'"
   > "Display name: 'PR Validation Pipeline'"
   > "Trigger: Automatic"
   > "Policy requirement: **Required** ← This is critical!"
   > "Click 'Save'"

**What This Does:**

> "Now when someone creates a PR targeting `main`:"
> - PR Validation pipeline triggers automatically
> - PR cannot be merged until pipeline passes
> - Failed pipelines block merge

**Verification:**

> "Checklist:"
> - [ ] Branch policy configured on `main`
> - [ ] PR Validation pipeline listed as required
> - [ ] Policy shows as "Required"

**Transition**: "Excellent! Now let's verify our config files match the variable groups."

---

### Step 6: Verify Config Files Match Variables

**⏱️ ~5 minutes**

**📄 REFERENCE:** [Setup Guide - Step 6](CICD_COMPLETE_SETUP_GUIDE.md#step-6-verify-config-files-match-variables)

**📺 SHOW:** Navigate to Repos → Files → sylvamo/config.staging.yaml

**SPEAKER NOTES:**

> "This is a critical step. The Toolkit enforces that `project:` in config files matches `CDF_PROJECT` in variable groups. This prevents deploying to the wrong project."

**Why This Matters:**

> "Imagine you accidentally deploy dev code to production. This check prevents that. The Toolkit compares:"
> - `config.staging.yaml` → `project: sylvamo-test`
> - Variable group → `CDF_PROJECT = sylvamo-test`
> - If they don't match → Error!

**Live Demo - Check Config Files:**

1. **Navigate:**
   > "Go to Repos → Files"
   > "Open `sylvamo/config.dev.yaml`"
   > "Check: `project: sylvamo-dev`"

2. **Check Staging:**
   > "Open `sylvamo/config.staging.yaml`"
   > "Check: `project: sylvamo-test`"

3. **Check Production:**
   > "Open `sylvamo/config.prod.yaml`"
   > "Check: `project: sylvamo-prod`"

**Fix Placeholders:**

> "If you see placeholders like `<my-project-staging>`:"
> - Click "Edit"
> - Replace with actual project name: `project: sylvamo-test`
> - Commit the change

**Verification Checklist:**

> "For each environment:"
> - [ ] `config.dev.yaml` → `project: sylvamo-dev` matches `CDF_PROJECT` in `dev-toolkit-credentials`
> - [ ] `config.staging.yaml` → `project: sylvamo-test` matches `CDF_PROJECT` in `staging-toolkit-credentials`
> - [ ] `config.prod.yaml` → `project: sylvamo-prod` matches `CDF_PROJECT` in `prod-toolkit-credentials`

**Common Issue:**

> "I've seen this error: 'Project name mismatch: <my-project-staging> ≠ sylvamo-test'"
> "Solution: Update the config file to remove the placeholder."

**Transition**: "Perfect! Now let's test everything to make sure it works."

---

### Step 7: Test the Setup

**⏱️ ~15 minutes**

**📄 REFERENCE:** [Setup Guide - Step 7](CICD_COMPLETE_SETUP_GUIDE.md#step-7-test-the-setup)

**SPEAKER NOTES:**

> "Now let's test each component to make sure everything works end-to-end."

**Test 1: PR Validation Pipeline**

**Live Demo:**

1. **Create Test Branch:**
   ```bash
   git checkout -b test/pr-validation-$(date +%Y%m%d)
   ```

2. **Make Small Change:**
   ```bash
   echo "# Test change - $(date)" >> sylvamo/config.dev.yaml
   git add .
   git commit -m "Test: PR validation pipeline"
   git push origin test/pr-validation-$(date +%Y%m%d)
   ```

3. **Create PR:**
   > "Go to Repos → Pull Requests"
   > "Create PR: test branch → main"
   > "Add description: 'Testing PR validation pipeline'"

4. **Verify:**
   > "Check 'Checks' section:"
   > - ✅ PR Validation pipeline triggers automatically
   > - ✅ Pipeline appears in checks
   > - ✅ `cdf build` step succeeds
   > - ✅ `cdf deploy --dry-run` step succeeds
   > - ✅ PR shows "All checks passed"

**What to Watch For:**

> "If the pipeline fails, check:"
> - Variable group permissions
> - Pipeline YAML syntax
> - Config file errors

**Test 2: Dev Deployment**

**Live Demo:**

1. **Merge PR:**
   > "After PR validation passes, merge the PR to `main`"

2. **Watch Pipeline:**
   > "Go to Pipelines → Recent runs"
   > "Find the 'Deploy to CDF' pipeline run"
   > "Watch DeployDev stage:"
   > - ✅ Runs automatically (no approval)
   > - ✅ `cdf build --env dev` succeeds
   > - ✅ `cdf deploy --dry-run --env dev` succeeds
   > - ✅ `cdf deploy --env dev` succeeds

3. **Verify in CDF:**
   > "Go to CDF Fusion UI → sylvamo-dev project"
   > "Verify your test change appears"

**Test 3: Staging Approval Gate**

**Live Demo:**

1. **After Dev Succeeds:**
   > "Check pipeline status"
   > "DeployStaging stage should show 'Waiting for approval'"

2. **Approve:**
   > "Go to Pipelines → Environments → staging"
   > "Click on pending approval"
   > "Review dry-run output"
   > "Click 'Approve'"

3. **Watch Deployment:**
   > "Pipeline continues automatically"
   > "Staging deployment succeeds"

**Test 4: Production Approval Gate**

**Live Demo:**

1. **After Staging Succeeds:**
   > "DeployProd stage shows 'Waiting for approval'"

2. **Approve:**
   > "Go to Environments → production"
   > "Approve production deployment"

3. **Verify:**
   > "Production deployment succeeds"
   > "All environments have consistent state"

**Complete Testing Checklist:**

> "Verify:"
> - [ ] PR Validation pipeline works
> - [ ] Dev auto-deployment works
> - [ ] Staging approval gate works
> - [ ] Production approval gate works
> - [ ] All environments receive deployments correctly
> - [ ] No errors in pipeline logs

**Transition**: "Excellent! Everything is working. Now let's talk about common issues you might encounter."

---

## SECTION 4: Troubleshooting & Best Practices

**⏱️ ~10 minutes**

**📄 REFERENCE:** [Setup Guide - Troubleshooting Common Issues](CICD_COMPLETE_SETUP_GUIDE.md#troubleshooting-common-issues)

**SPEAKER NOTES:**

> "Based on real-world troubleshooting, here are the most common issues and how to fix them."

### Issue 1: Variable Group Permission Errors

**Error:**
```
Variable group dev-toolkit-credentials could not be found.
```

**Solution:**
> "Go to Variable Groups → Click on group → Pipeline permissions → Add pipeline → Save"

**Prevention:**
> "Always grant pipeline permissions when creating variable groups. Do it before saving."

---

### Issue 2: Version Mismatch

**Error:**
```
ToolkitVersionError: modules (0.7.78) does not match CLI (0.5.35)
```

**Solution:**
> "Update Docker image version in pipeline YAML:"
> ```yaml
> container:
>   image: cognite/toolkit:0.7.78  # Match your modules version
> ```

**How to Find Version:**
> "Check `cdf.toml`: `version = "0.7.78"`"

---

### Issue 3: Missing Environment Variables

**Error:**
```
ERROR: Missing environment variables: IDP_CLIENT_SECRET
```

**Solution:**
> "Add `env:` section to ALL `cdf deploy` commands (dry-run AND actual):"
> ```yaml
> - script: cdf deploy --dry-run --env dev
>   env:
>     IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
> ```

**Prevention:**
> "Always add `env:` sections to both dry-run and deploy steps."

---

### Issue 4: Working Directory Not Found

**Error:**
```
Not found workingDirectory: /_w/1/s/sylvamo
```

**Solution:**
> "Add `checkout: self` as first step:"
> ```yaml
> steps:
>   - checkout: self  # ← Add this first
>   - script: cdf build
>     workingDirectory: 'sylvamo'
> ```

**Prevention:**
> "Always include `checkout: self` when using containers."

---

### Issue 5: Project Name Mismatch

**Error:**
```
Project name mismatch: <my-project-staging> ≠ sylvamo-test
```

**Solution:**
> "Update `config.staging.yaml`:"
> ```yaml
> environment:
>   project: sylvamo-test  # ← Must match CDF_PROJECT exactly
> ```

**Prevention:**
> "Use consistent project naming. Validate before committing."

---

### Issue 6: Authentication Failures

**Error:**
```
CogniteAuthError: Invalid client secret provided
```

**Solution:**
> "Check:"
> - Secret expiration (Azure AD secrets expire)
> - Generate new secret if expired
> - Update variable group
> - Mark as secret (padlock icon)

**Prevention:**
> "Document secret expiration dates. Set reminders."

---

### Issue 7: Build for Wrong Environment

**Error:**
```
Expected to deploy for 'staging', but build was for 'dev'
```

**Solution:**
> "Add `--env` to ALL `cdf build` commands:"
> ```yaml
> - script: cdf build --env staging  # ← Must specify
> ```

**Prevention:**
> "Always use `--env` parameter with `cdf build`."

---

### Quick Reference Table

**Show This:**

| Error | Quick Fix |
|-------|-----------|
| Variable group not found | Grant pipeline permission |
| Version mismatch | Update Docker image version |
| Missing env vars | Add `env:` to dry-run steps |
| Working directory not found | Add `checkout: self` |
| Project name mismatch | Update config file |
| Invalid client secret | Check expiration, regenerate |
| Build for wrong env | Add `--env` to `cdf build` |

**Transition**: "Now let's wrap up with next steps."

---

## SECTION 5: Q&A and Next Steps

**⏱️ ~10 minutes**

### Q&A Session

**Common Questions:**

**Q: "Can we use the same credentials for all environments?"**  
> A: "Yes, but it's not recommended. Best practice is separate service principals per environment for better security and audit trails."

**Q: "What if a deployment fails?"**  
> A: "The pipeline stops at the failed stage. Fix the issue, commit the fix, and the pipeline will retry. Staging/Prod won't deploy if Dev fails."

**Q: "How do we roll back a bad deployment?"**  
> A: "Use `git revert` to revert the bad commit, merge to main, and let the pipeline redeploy. The Toolkit applies the previous good state."

**Q: "Can we skip stages?"**  
> A: "Not recommended, but you can manually cancel stages in ADO. The pipeline uses `dependsOn` to enforce order."

**Q: "How often should we run the validation pipeline?"**  
> A: "Consider scheduling it nightly or weekly to catch configuration drift early."

---

### Next Steps

**📄 REFERENCE:** [Setup Guide - Summary](CICD_COMPLETE_SETUP_GUIDE.md#summary)

**Action Items:**

1. **Test Your Setup:**
   - Create a test PR
   - Verify PR validation works
   - Test dev deployment
   - Test approval gates

2. **Train Your Team:**
   - Share this guide with team
   - Train approvers on approval process
   - Document your workflows

3. **Set Up Monitoring:**
   - Configure pipeline notifications
   - Set up alerts for failures
   - Monitor deployment frequency

4. **Regular Validation:**
   - Schedule test-all-environments pipeline
   - Regular reviews of pipeline health
   - Periodic testing of failure scenarios

5. **Document Customizations:**
   - Note any deviations from this guide
   - Document environment-specific considerations
   - Update this guide with learnings

---

### Resources

**📄 REFERENCE POINTS:**

**Phase 1 Materials:**
- **[CI/CD Overview](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/blob/main/docs/reference/cicd/CICD_OVERVIEW.md)** - Concepts, architecture, and flow (Phase 1)

**Phase 2 Materials:**
- **[CI/CD Complete Setup Guide](CICD_COMPLETE_SETUP_GUIDE.md)** - This comprehensive setup guide
- **[CI/CD Testing Guide](CICD_TESTING_GUIDE.md)** - Detailed testing procedures
- **[CI/CD Pipeline Troubleshooting Guide](CICD_PIPELINE_TROUBLESHOOTING.md)** - Comprehensive troubleshooting

**ADO Links:**

- Pipelines: `https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_build`
- Variable Groups: `https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_library?itemType=VariableGroups`
- Environments: `https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_library?itemType=Environments`
- Repository: `https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL`

---

### Closing

**Final Points:**

> "You now have a complete CI/CD setup for CDF. Remember:"
> 
> 1. **PR validation** prevents bad code from merging
> 2. **Dry-run** shows changes before applying
> 3. **Approval gates** protect staging and production
> 4. **Environment promotion** ensures safe deployments
> 
> "If you run into issues, refer to the troubleshooting guide. Most problems are configuration-related and easy to fix."

**Phase 1 + Phase 2 Complete:**

> "Together, Phase 1 and Phase 2 give you:"
> - **Phase 1:** Understanding of concepts, architecture, and flow
> - **Phase 2:** Hands-on implementation and troubleshooting
> 
> "You now have both the knowledge and the working pipelines."

**Thank You:**

> "Thank you for your attention. Feel free to ask questions or reach out if you need help."

---

## Presentation Tips

### Timing Management

- **Introduction:** Keep to 10 minutes - don't get stuck in concepts
- **Hands-On Setup:** Allow 45-60 minutes - this is the core
- **Troubleshooting:** 10 minutes - reference, don't deep-dive
- **Q&A:** 10 minutes - be flexible

### Interactive Elements

- **Check Access:** "Can everyone access Azure DevOps? Raise your hand..."
- **Live Demo:** Do the setup live, don't just show slides
- **Pause for Questions:** After each major step
- **Verify Together:** Check each step as a group

### Common Challenges

**Challenge:** "Someone doesn't have access"  
**Solution:** Have a backup demo account ready, or pair them with someone who has access

**Challenge:** "Pipeline fails during demo"  
**Solution:** This is actually good! Use it as a teaching moment - show troubleshooting

**Challenge:** "Takes longer than expected"  
**Solution:** Prioritize Steps 1-4 (core setup). Steps 5-7 can be done after the session

**Challenge:** "Questions derail the flow"  
**Solution:** Use parking lot - write down questions, address at end

---

## Appendix: Quick Reference Cards

### Setup Checklist (Print This)

```
□ Prerequisites verified
□ Pipeline files committed to main
□ Variable groups created (dev, staging, prod)
□ Pipeline permissions granted
□ Environments created (staging, production)
□ Approvers configured
□ Pipelines created (PR Validation, Deploy, Test All)
□ Branch policy configured
□ Config files match variable groups
□ Test PR created and validated
□ Dev deployment tested
□ Approval gates tested
```

### Common Errors Quick Fix

```
Variable group not found → Grant pipeline permission
Version mismatch → Update Docker image version
Missing env vars → Add env: to dry-run steps
Working directory not found → Add checkout: self
Project name mismatch → Update config file
Invalid client secret → Check expiration
Build for wrong env → Add --env to cdf build
```

---

*Last Updated: February 8, 2026*
*Based on real-world Sylvamo CI/CD implementation and troubleshooting*
