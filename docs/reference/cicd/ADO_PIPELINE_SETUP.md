# Azure DevOps Pipeline Setup - Implementation Summary

This document summarizes the CI/CD pipeline implementation for SVQS-171.

## Implementation Status

### ✅ Completed

1. **Pipeline YAML Files Created**
   - `.devops/dry-run-pipeline.yml` - PR validation pipeline
   - `.devops/deploy-pipeline.yml` - Multi-stage deployment pipeline (dev → staging → prod)
   - `.devops/test-all-environments.yml` - Manual validation pipeline for all environments

2. **ADO Resource Creation Scripts**
   - `scripts/05-utilities/ado_create_resources.py` - Script to create variable groups and environments via ADO API

3. **Admin Module Deployment**
   - Admin module deployed to dev environment
   - Transformation `tr_populate_SourceSystems` is available in CDF

4. **Utility Scripts Created**
   - `scripts/run_source_systems_transformation.py` - Run the source systems transformation
   - `scripts/verify_source_systems.py` - Verify CogniteSourceSystem nodes exist

### ⚠️ Requires Manual Setup in ADO

1. **Clone ADO Repository Programmatically**
   ```bash
   # Use the provided script to clone the ADO repo
   uv run python scripts/05-utilities/ado_clone_repo.py
   
   # Or clone to specific location
   uv run python scripts/05-utilities/ado_clone_repo.py --target-dir ~/workspace/ado-repo
   ```
   See `ADO_CLONE_REPO.md` for detailed instructions.

2. **Copy Pipeline Files to ADO Repo**
   - The pipeline files are in `.devops/` folder in this workspace
   - Copy them to the cloned ADO repository:
   ```bash
   cp -r .devops /path/to/cloned/ado-repo/Industrial-Data-Landscape-IDL/
   ```
   - Commit and push:
   ```bash
   cd /path/to/cloned/ado-repo/Industrial-Data-Landscape-IDL
   git add .devops/
   git commit -m "Add CI/CD pipeline files for CDF Toolkit deployment"
   git push origin main
   ```

2. **Create Variable Groups**
   - Run `scripts/05-utilities/ado_create_resources.py` OR create manually in ADO UI
   - Required variable groups:
     - `staging-toolkit-credentials`
     - `prod-toolkit-credentials`
   - Each should contain:
     - `CDF_CLUSTER`
     - `CDF_PROJECT`
     - `LOGIN_FLOW` (set to `client_credentials`)
     - `IDP_CLIENT_ID`
     - `IDP_CLIENT_SECRET` (mark as secret)
     - `IDP_TENANT_ID` (optional for Entra ID)
     - `IDP_TOKEN_URL` (only if NOT using Entra ID)
     - `CDF_URL`

3. **Create ADO Environments**
   - Run `scripts/05-utilities/ado_create_resources.py` OR create manually in ADO UI
   - Create `staging` environment with 1 approver
   - Create `production` environment with 1 approver

4. **Create Pipelines in ADO**
   - Navigate to Pipelines → New Pipeline
   - Select "Existing Azure Pipelines YAML file"
   - Choose branch: `main`
   - Select path: `.devops/dry-run-pipeline.yml` (for PR validation)
   - Repeat for `.devops/deploy-pipeline.yml` (for deployment)
   - Repeat for `.devops/test-all-environments.yml` (for manual testing)

5. **Add Branch Policy**
   - Navigate to Repos → Branches → main → Branch policies
   - Under Build Validation, add the dry-run pipeline
   - Set minimum reviewers to 1

6. **Run Source Systems Transformation**
   - Run `scripts/run_source_systems_transformation.py` (requires env vars set)
   - OR run manually via CDF UI: Transformations → tr_populate_SourceSystems → Run

7. **Verify Source Systems**
   - Run `scripts/verify_source_systems.py` (requires env vars set)
   - OR check manually in CDF UI: Data Model → Instances → sp_admin_instances → CogniteSourceSystem

## Pipeline Files Location

All pipeline files are located in `.devops/` folder:

- **dry-run-pipeline.yml** - Validates PRs with `cdf build` and `cdf deploy --dry-run`
- **deploy-pipeline.yml** - Multi-stage deployment:
  - DeployDev: Auto-deploys to dev (no approval)
  - DeployStaging: Requires approval, deploys to staging
  - DeployProd: Requires approval, deploys to production
- **test-all-environments.yml** - Manual validation pipeline for all environments

## Key Features

- **Dry-run validation** before each actual deployment
- **Approval gates** for staging and production
- **Automatic deployment** to dev on merge to main
- **PR validation** prevents merging invalid configurations

## Next Steps

1. Copy `.devops/` folder to ADO repository
2. Run `ado_create_resources.py` to create variable groups and environments
3. Create pipelines in ADO UI pointing to the YAML files
4. Add branch policy for PR validation
5. Test the pipelines with a sample PR
6. Run source systems transformation and verify nodes exist

## How the CI/CD System Works

For a comprehensive explanation of how the CI/CD system works, its use case, code flow, and pipeline details, see:

**`CICD_SYSTEM_EXPLANATION.md`**

This document covers:
- Use case and business context
- Complete workflow from code change to production
- Technical deep dive into each pipeline
- Authentication flow
- How Toolkit commands work (`cdf build`, `cdf deploy`)
- Real-world examples
- Safety features

### Quick Summary

**Use Case**: Automate deployment of CDF Toolkit modules (data models, transformations, access groups) across dev → staging → production environments with validation and approval gates.

**How It Works**:
1. **PR Validation**: Developer creates PR → `dry-run-pipeline.yml` validates changes → PR can be merged if validation passes
2. **Deployment**: PR merged to main → `deploy-pipeline.yml` triggers → DeployDev (auto) → DeployStaging (approval) → DeployProd (approval)
3. **Test Pipeline**: Manual trigger → `test-all-environments.yml` validates all environments with dry-run

**Key Commands**:
- `cdf build`: Validates YAML, substitutes variables, creates `build/` directory
- `cdf deploy --dry-run`: Shows what WOULD change without making changes
- `cdf deploy`: Actually applies changes to CDF project

**Safety Features**:
- Dry-run before every deployment
- Approval gates for staging and production
- Sequential promotion (dev → staging → prod)
- Environment isolation (separate credentials and CDF projects)

## References

- Plan document: `.cursor/plans/svqs-171_ci_cd_pipeline_setup_7e57fcc5.plan.md`
- System explanation: `CICD_SYSTEM_EXPLANATION.md` (comprehensive guide)
- Clone repo script: `scripts/05-utilities/ado_clone_repo.py`
- Clone repo guide: `ADO_CLONE_REPO.md`
- Official Cognite docs: https://docs.cognite.com/cdf/deploy/cdf_toolkit/guides/cicd/ado_setup
- ADO repo: https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL
