# CI/CD Pipeline Troubleshooting Guide

This guide documents common issues encountered during CI/CD pipeline setup and execution, along with their solutions. This is based on real-world troubleshooting during the initial Sylvamo CI/CD implementation.

---

## Table of Contents

1. [Variable Group Permission Issues](#variable-group-permission-issues)
2. [Pipeline Version Mismatch Errors](#pipeline-version-mismatch-errors)
3. [Missing Environment Variables](#missing-environment-variables)
4. [Working Directory Not Found](#working-directory-not-found)
5. [Project Name Mismatch Errors](#project-name-mismatch-errors)
6. [Authentication Failures](#authentication-failures)
7. [Invalid Capabilities (CDF IAM)](#invalid-capabilities-cdf-iam)
8. [Complete Pipeline YAML Reference](#complete-pipeline-yaml-reference)

---

## Variable Group Permission Issues

### Issue: "Variable group could not be found or has not been authorized for use"

**Error Message:**
```
Encountered error(s) while parsing pipeline YAML: 
Stage DeployDev: Variable group dev-toolkit-credentials could not be found. 
The variable group does not exist or has not been authorized for use.
```

**Root Cause:**
The pipeline YAML references a variable group, but the pipeline doesn't have permission to access it.

**Solution:**

1. **Navigate to Variable Groups:**
   - Go to: Pipelines → Library → Variable groups
   - Click on the variable group name (e.g., `dev-toolkit-credentials`)

2. **Grant Pipeline Permission:**
   - Click "Pipeline permissions" button
   - Click the "+" button to add a pipeline
   - Select `Industrial-Data-Landscape-IDL` (or your repository name)
   - Click "Save"

3. **Verify:**
   - The repository should now appear in the "Permitted pipelines" list
   - Close the modal and save the variable group

**Prevention:**
- Always grant pipeline permissions when creating new variable groups
- Use consistent naming: `dev-toolkit-credentials`, `staging-toolkit-credentials`, `prod-toolkit-credentials`

---

## Pipeline Version Mismatch Errors

### Issue: Toolkit Version Mismatch

**Error Message:**
```
cognite_toolkit._cdf_tk.exceptions.ToolkitVersionError: 
The version of the modules (0.7.78) does not match the version of the installed CLI (0.5.35).
Please either run `cdf-tk modules upgrade` to upgrade your modules, 
or downgrade your CLI version to match the modules.
```

**Root Cause:**
The Docker container image version doesn't match the modules version in your repository.

**Solution:**

Update the Docker image version in your pipeline YAML to match your modules version:

```yaml
container:
  image: cognite/toolkit:0.7.78  # Match your modules version
```

**Steps:**

1. **Check your modules version:**
   - Look in `cdf.toml` file: `version = "0.7.78"`
   - Or check `sylvamo/build_info.dev.yaml` for module version

2. **Update pipeline YAML:**
   - Open `.devops/deploy-pipeline.yml` in ADO
   - Find all instances of `image: cognite/toolkit:X.X.X`
   - Update to match your modules version (e.g., `0.7.78`)

3. **Update all stages:**
   - Dev stage
   - Staging stage
   - Production stage

**Prevention:**
- Keep Docker image version in sync with modules version
- Document version requirements in pipeline README
- Use version variables if possible for consistency

---

## Missing Environment Variables

### Issue: Missing IDP_CLIENT_SECRET in Dry-Run Steps

**Error Message:**
```
ERROR (ToolkitMissingValueError): The login flow 'client_credentials' requires 
the following environment variables: IDP_CLIENT_SECRET.
```

**Root Cause:**
Environment variables are only passed to the final `cdf deploy` step, but `cdf deploy --dry-run` also needs them for authentication.

**Solution:**

Add `env:` section to **all** `cdf deploy` commands (both dry-run and actual deploy):

```yaml
- script: cdf deploy --dry-run --env dev
  displayName: 'Validate Deployment (Dry Run)'
  workingDirectory: 'sylvamo'
  env:  # ← Add this section
    IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
    INGESTION_CLIENT_ID: $(INGESTION_CLIENT_ID)
    INGESTION_CLIENT_SECRET: $(INGESTION_CLIENT_SECRET)

- script: cdf deploy --env dev
  displayName: 'Deploy to Dev CDF'
  workingDirectory: 'sylvamo'
  env:  # ← Also ensure this exists
    IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
    INGESTION_CLIENT_ID: $(INGESTION_CLIENT_ID)
    INGESTION_CLIENT_SECRET: $(INGESTION_CLIENT_SECRET)
```

**Required Environment Variables:**

For each environment, ensure these are in the variable group and passed to pipeline steps:

| Variable | Description | Secret? |
|----------|-------------|---------|
| `IDP_CLIENT_SECRET` | Azure AD Service Principal Secret | Yes |
| `INGESTION_CLIENT_ID` | Ingestion Service Principal Client ID | No |
| `INGESTION_CLIENT_SECRET` | Ingestion Service Principal Secret | Yes |

**Prevention:**
- Always add `env:` sections to both dry-run and deploy steps
- Document required environment variables in pipeline comments
- Use consistent variable names across all stages

---

## Working Directory Not Found

### Issue: "Not found workingDirectory: /_w/1/s/sylvamo"

**Error Message:**
```
##[error] Not found workingDirectory: /_w/1/s/sylvamo
```

**Root Cause:**
The pipeline is trying to run commands from the `sylvamo/` directory, but either:
1. The repository checkout didn't happen
2. The `sylvamo/` directory doesn't exist in the repository
3. The `workingDirectory` path is incorrect

**Solution:**

**Step 1: Add Explicit Checkout**

Add `checkout: self` as the first step in each job:

```yaml
steps:
  - checkout: self  # ← Add this first
  - script: cdf build
    displayName: 'Build'
    workingDirectory: 'sylvamo'
```

**Step 2: Verify Repository Structure**

Ensure your ADO repository has this structure:
```
Industrial-Data-Landscape-IDL/
  sylvamo/
    modules/
    config.dev.yaml
    config.staging.yaml
    config.prod.yaml
  .devops/
    deploy-pipeline.yml
  cdf.toml
```

**Step 3: Use Correct Working Directory**

The `workingDirectory` should be relative to the repository root:

```yaml
workingDirectory: 'sylvamo'  # Relative to repo root after checkout
```

**Prevention:**
- Always include `checkout: self` when using containers
- Verify repository structure matches expected layout
- Test pipeline with a simple command first to verify paths

---

## Project Name Mismatch Errors

### Issue: Project Name Mismatch Between Config and Environment Variable

**Error Message:**
```
ERROR (ToolkitEnvError): Project name mismatch between project set in the 
environment section of 'config.staging.yaml' and the environment variable 'CDF_PROJECT', 
<my-project-staging> ≠ sylvamo-test.
```

**Root Cause:**
The `project:` value in `config.staging.yaml` (or `config.prod.yaml`) doesn't match the `CDF_PROJECT` value in the variable group. The Toolkit enforces this match for staging/prod environments as a safety check.

**Solution:**

**Step 1: Check Config File**

Open `sylvamo/config.staging.yaml` in ADO repository:
```yaml
environment:
  name: staging
  project: <my-project-staging>  # ← This is a placeholder!
```

**Step 2: Check Variable Group**

Go to Pipelines → Library → Variable groups → `staging-toolkit-credentials`:
- Variable: `CDF_PROJECT`
- Value: `sylvamo-test` (or your actual staging project name)

**Step 3: Make Them Match**

Update `config.staging.yaml` to match the variable group:

```yaml
environment:
  name: staging
  project: sylvamo-test  # ← Must match CDF_PROJECT variable exactly
```

**For Production:**

Similarly, ensure `config.prod.yaml` matches `prod-toolkit-credentials`:

```yaml
environment:
  name: prod
  project: sylvamo-prod  # ← Must match CDF_PROJECT in prod variable group
```

**Verification Checklist:**

- [ ] `config.dev.yaml` → `project: sylvamo-dev`
- [ ] `config.staging.yaml` → `project: sylvamo-test` (matches variable group)
- [ ] `config.prod.yaml` → `project: sylvamo-prod` (matches variable group)
- [ ] Variable group `dev-toolkit-credentials` → `CDF_PROJECT = sylvamo-dev`
- [ ] Variable group `staging-toolkit-credentials` → `CDF_PROJECT = sylvamo-test`
- [ ] Variable group `prod-toolkit-credentials` → `CDF_PROJECT = sylvamo-prod`

**Prevention:**
- Use consistent project naming: `sylvamo-{env}`
- Document project names in variable group descriptions
- Validate config files match variable groups before committing

---

## Authentication Failures

### Issue: Invalid Client Secret

**Error Message:**
```
cognite.client.exceptions.CogniteAuthError: Error generating access token: 
invalid_client, 401, AADSTS7000215: Invalid client secret provided. 
Ensure the secret being sent in the request is the client secret.
```

**Root Cause:**
The client secret in the variable group is incorrect, expired, or doesn't match the service principal.

**Solution:**

**Step 1: Verify Variable Group Values**

1. Go to Pipelines → Library → Variable groups
2. Click on the failing environment's variable group (e.g., `staging-toolkit-credentials`)
3. Check these variables:
   - `IDP_CLIENT_ID` - Should match Azure AD App Registration Client ID
   - `IDP_CLIENT_SECRET` - Should be the current secret (not expired)
   - `IDP_TENANT_ID` - Should match Azure AD Tenant ID

**Step 2: Check Secret Expiration**

Azure AD secrets expire. If the secret is expired:

1. Go to Azure Portal → Azure Active Directory → App registrations
2. Find your service principal (by `IDP_CLIENT_ID`)
3. Go to "Certificates & secrets"
4. Create a new client secret
5. Update the variable group with the new secret value
6. **Important:** Mark it as "Secret" (padlock icon) in ADO

**Step 3: Verify Service Principal Permissions**

Ensure the service principal has access to the CDF project:

1. Check CDF project access in Cognite Data Fusion UI
2. Verify service principal is in the correct groups
3. Verify API permissions in Azure AD

**Step 4: Compare with Working Environment**

If dev works but staging fails:

1. Compare `dev-toolkit-credentials` with `staging-toolkit-credentials`
2. Ensure staging has its own service principal (if required)
3. Or ensure staging uses the same credentials as dev (if that's your setup)

**Common Issues:**

- **Expired Secret:** Generate new secret in Azure AD
- **Wrong Secret:** Copy-paste error, verify character-by-character
- **Not Marked as Secret:** Click padlock icon in ADO variable group
- **Wrong Service Principal:** Using dev credentials for staging when separate SP is required

**Prevention:**
- Document secret expiration dates
- Set reminders before secrets expire
- Use separate service principals per environment (recommended)
- Document which credentials are shared vs. environment-specific

---

## Missing Build Environment Parameter

### Issue: Build Created for Wrong Environment

**Error Message:**
```
ERROR (ToolkitEnvError): Expected to deploy for 'staging' environment, 
but the last build was created for the 'dev' environment.
```

**Root Cause:**
The `cdf build` command is running without `--env` parameter, so it defaults to 'dev'. Then `cdf deploy --env staging` fails because the build artifacts are for dev.

**Solution:**

Add `--env` parameter to **all** `cdf build` commands:

```yaml
# Dev stage
- script: cdf build --env dev  # ← Add --env dev
  displayName: 'Build'
  workingDirectory: 'sylvamo'

# Staging stage
- script: cdf build --env staging  # ← Add --env staging
  displayName: 'Build'
  workingDirectory: 'sylvamo'

# Production stage
- script: cdf build --env prod  # ← Add --env prod
  displayName: 'Build'
  workingDirectory: 'sylvamo'
```

**Why This Matters:**

- `cdf build` reads the appropriate `config.<env>.yaml` file
- It creates environment-specific build artifacts
- `cdf deploy` expects build artifacts to match the target environment
- This prevents accidentally deploying dev artifacts to production

**Prevention:**
- Always use `--env` parameter with `cdf build`
- Match build environment with deploy environment
- Document environment-specific build requirements

---

## Invalid Capabilities (CDF IAM)

### Issue: ResourceUpdateError - Invalid Capabilities

**Error Message:**
```
 cognitertools.exceptions.ResourceUpdateError: 3 invalid capabilitie(s) are present
```

**Root Cause:**
Staging and production CDF projects (`sylvamo-test`, `sylvamo-prod`) restrict WRITE access to certain legacy APIs (Annotations, Assets, Relationships). The deployment service principal's Group YAML may request WRITE privileges that are not allowed in those projects.

**Solution:**

1. **Locate the Group YAML file** in your admin module:
   - `sylvamo/modules/admin/auth/cognite_toolkit_service_principal.Group.yaml`

2. **Update the following capabilities** to use READ only for staging/prod:

   ```yaml
   # Change from WRITE to READ only
   - annotationsAcl:
       actions: [READ]
   - assetsAcl:
       actions: [READ]
   - relationshipsAcl:
       actions: [READ]
   ```

3. **Maintain environment-specific configs** if needed:
   - Dev can keep full WRITE
   - Staging and prod use READ only for these ACLs

**Reference:** See [CDF IAM Groups Setup](CICD_COMPLETE_SETUP_GUIDE.md#cdf-iam-groups-setup) and [CI/CD Hands-On Learnings - CDF IAM Groups](CICD_HANDS_ON_LEARNINGS.md#cdf-iam-groups) for full context.

---

## Complete Pipeline YAML Reference

Here's the complete, corrected `deploy-pipeline.yml` with all fixes applied:

```yaml
# .devops/deploy-pipeline.yml
trigger:
  branches:
    include:
      - main  # Triggers on push to main (after merge)

pool:
  vmImage: 'ubuntu-latest'

# Deploy to DEV first
stages:
  - stage: DeployDev
    displayName: 'Deploy to Dev'
    variables:
      - group: dev-toolkit-credentials
    jobs:
      - job: Deploy
        container:
          image: cognite/toolkit:0.7.78  # Match your modules version
        steps:
          - checkout: self  # Required for container jobs
          - script: cdf build --env dev  # Must specify environment
            displayName: 'Build'
            workingDirectory: 'sylvamo'
          - script: cdf deploy --dry-run --env dev
            displayName: 'Validate Deployment (Dry Run)'
            workingDirectory: 'sylvamo'
            env:  # Required for authentication
              IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
              INGESTION_CLIENT_ID: $(INGESTION_CLIENT_ID)
              INGESTION_CLIENT_SECRET: $(INGESTION_CLIENT_SECRET)
          - script: cdf deploy --env dev
            displayName: 'Deploy to Dev CDF'
            workingDirectory: 'sylvamo'
            env:  # Required for authentication
              IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
              INGESTION_CLIENT_ID: $(INGESTION_CLIENT_ID)
              INGESTION_CLIENT_SECRET: $(INGESTION_CLIENT_SECRET)

  - stage: DeployStaging
    displayName: 'Deploy to Staging'
    dependsOn: DeployDev
    variables:
      - group: staging-toolkit-credentials
    jobs:
      - deployment: Deploy
        environment: 'staging'  # ADO Environment with approval
        container:
          image: cognite/toolkit:0.7.78
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                - script: cdf build --env staging
                  displayName: 'Build'
                  workingDirectory: 'sylvamo'
                - script: cdf deploy --dry-run --env staging
                  displayName: 'Validate Deployment (Dry Run)'
                  workingDirectory: 'sylvamo'
                  env:
                    IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
                    INGESTION_CLIENT_ID: $(INGESTION_CLIENT_ID)
                    INGESTION_CLIENT_SECRET: $(INGESTION_CLIENT_SECRET)
                - script: cdf deploy --env staging
                  displayName: 'Deploy to Staging CDF'
                  workingDirectory: 'sylvamo'
                  env:
                    IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
                    INGESTION_CLIENT_ID: $(INGESTION_CLIENT_ID)
                    INGESTION_CLIENT_SECRET: $(INGESTION_CLIENT_SECRET)

  - stage: DeployProd
    displayName: 'Deploy to Production'
    dependsOn: DeployStaging
    variables:
      - group: prod-toolkit-credentials
    jobs:
      - deployment: Deploy
        environment: 'production'  # ADO Environment with approval gate
        container:
          image: cognite/toolkit:0.7.78
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                - script: cdf build --env prod
                  displayName: 'Build'
                  workingDirectory: 'sylvamo'
                - script: cdf deploy --dry-run --env prod
                  displayName: 'Validate Deployment (Dry Run)'
                  workingDirectory: 'sylvamo'
                  env:
                    IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
                    INGESTION_CLIENT_ID: $(INGESTION_CLIENT_ID)
                    INGESTION_CLIENT_SECRET: $(INGESTION_CLIENT_SECRET)
                - script: cdf deploy --env prod
                  displayName: 'Deploy to Production CDF'
                  workingDirectory: 'sylvamo'
                  env:
                    IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
                    INGESTION_CLIENT_ID: $(INGESTION_CLIENT_ID)
                    INGESTION_CLIENT_SECRET: $(INGESTION_CLIENT_SECRET)
```

**Key Points:**

1. ✅ **Checkout:** `checkout: self` as first step in all jobs
2. ✅ **Working Directory:** `workingDirectory: 'sylvamo'` on all script steps
3. ✅ **Build Environment:** `cdf build --env <env>` with environment specified
4. ✅ **Deploy Environment:** `cdf deploy --env <env>` with environment specified
5. ✅ **Environment Variables:** `env:` section on both dry-run and deploy steps
6. ✅ **Docker Version:** Match `cognite/toolkit` version with modules version
7. ✅ **Variable Groups:** Properly named and permissioned

---

## Quick Reference: Common Error → Solution

| Error | Solution |
|-------|----------|
| "Variable group could not be found" | Grant pipeline permission in variable group |
| "ToolkitVersionError: version mismatch" | Update Docker image version to match modules |
| "Missing environment variables: IDP_CLIENT_SECRET" | Add `env:` section to dry-run steps |
| "Not found workingDirectory" | Add `checkout: self` and verify `sylvamo/` exists |
| "Project name mismatch" | Update `config.<env>.yaml` project to match `CDF_PROJECT` |
| "Invalid client secret" | Check secret expiration, verify values in variable group |
| "Build created for wrong environment" | Add `--env` parameter to `cdf build` commands |

---

## Summary: Pipeline Setup Checklist

Before running pipelines, verify:

- [ ] **Variable Groups Created:**
  - [ ] `dev-toolkit-credentials` (or `dev-toolkit-credentials`)
  - [ ] `staging-toolkit-credentials`
  - [ ] `prod-toolkit-credentials`

- [ ] **Variable Groups Configured:**
  - [ ] All required variables present (CDF_CLUSTER, CDF_PROJECT, IDP_CLIENT_ID, IDP_CLIENT_SECRET, etc.)
  - [ ] Secrets marked as secret (padlock icon)
  - [ ] Pipeline permissions granted

- [ ] **Config Files Match Variables:**
  - [ ] `config.dev.yaml` → `project: sylvamo-dev` matches `CDF_PROJECT` in dev variable group
  - [ ] `config.staging.yaml` → `project: sylvamo-test` matches `CDF_PROJECT` in staging variable group
  - [ ] `config.prod.yaml` → `project: sylvamo-prod` matches `CDF_PROJECT` in prod variable group

- [ ] **Pipeline YAML Correct:**
  - [ ] `checkout: self` in all jobs
  - [ ] `workingDirectory: 'sylvamo'` on all script steps
  - [ ] `cdf build --env <env>` with environment specified
  - [ ] `env:` sections on all deploy steps (dry-run and actual)
  - [ ] Docker image version matches modules version

- [ ] **ADO Environments Created:**
  - [ ] `staging` environment with approvers
  - [ ] `production` environment with approvers

---

*Last Updated: February 8, 2026*
*Based on real-world troubleshooting during Sylvamo CI/CD implementation*
