# CI/CD Testing Guide: How to Test Code Promotion and Pipelines

This guide provides step-by-step instructions for testing the CI/CD pipeline system, code promotion across environments (dev → staging → prod), and validating that everything works correctly.

---

## Prerequisites

Before testing, ensure:

- ✅ **Pipelines are created** in Azure DevOps (`.devops/dry-run-pipeline.yml`, `.devops/deploy-pipeline.yml`)
- ✅ **Variable groups exist**: `dev-toolkit-credentials`, `staging-toolkit-credentials`, `prod-toolkit-credentials`
- ✅ **ADO Environments created**: `staging` and `production` with approvers configured
- ✅ **Branch policies set**: PR validation pipeline configured on `main` branch
- ✅ **Local environment configured**: `.env` file with CDF credentials for local testing

---

## Testing Strategy Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    TESTING PHASES                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Local Testing (Before Push)                            │
│     └─> Test commands locally, validate configs            │
│                                                             │
│  2. PR Validation Testing                                  │
│     └─> Test dry-run pipeline on feature branch            │
│                                                             │
│  3. Dev Environment Testing                                │
│     └─> Test auto-deployment to dev                        │
│                                                             │
│  4. Staging Promotion Testing                              │
│     └─> Test approval gate and staging deployment          │
│                                                             │
│  5. Production Promotion Testing                           │
│     └─> Test approval gate and prod deployment             │
│                                                             │
│  6. Validation Pipeline Testing                            │
│     └─> Test test-all-environments pipeline                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Local Testing (Before Pushing to ADO)

**Goal:** Validate your changes work locally before triggering pipelines.

### 1.1 Test Build Locally

```bash
# Navigate to ADO repo (or local workspace)
cd /path/to/Industrial-Data-Landscape-IDL

# Test build for dev environment
cdf build --env dev

# Expected: No errors, validates YAML syntax
```

**What to check:**
- ✅ No syntax errors
- ✅ All referenced modules exist
- ✅ Config files are valid

### 1.2 Test Dry-Run Locally

```bash
# Test dry-run for dev (shows what WOULD change)
cdf deploy --dry-run --env dev

# Expected: Shows planned changes without applying them
```

**What to check:**
- ✅ Shows expected changes (creates, updates, deletes)
- ✅ No unexpected changes
- ✅ Target project is correct (`sylvamo-dev`)

### 1.3 Test Actual Deployment Locally (Optional - Dev Only)

```bash
# Only do this in dev environment!
cdf deploy --env dev

# Expected: Actually applies changes to dev CDF project
```

**What to check:**
- ✅ Deployment succeeds
- ✅ Resources appear in CDF UI (`sylvamo-dev` project)
- ✅ No errors in deployment logs

### 1.4 Test Multiple Environments Locally

```bash
# Test all environments with dry-run
cdf deploy --dry-run --env dev
cdf deploy --dry-run --env staging
cdf deploy --dry-run --env prod

# Expected: Each shows changes for its respective CDF project
```

**What to check:**
- ✅ Each environment targets correct CDF project
- ✅ Configurations are consistent across environments
- ✅ No environment-specific errors

---

## Phase 2: PR Validation Pipeline Testing

**Goal:** Test that PR validation pipeline works correctly before merging.

### 2.1 Create Test Feature Branch

```bash
# From ADO repo
cd /path/to/Industrial-Data-Landscape-IDL
git checkout main
git pull origin main

# Create test branch
git checkout -b test/pr-validation-$(date +%Y%m%d)
```

### 2.2 Make a Small Test Change

**Option A: Add a Comment (Safest)**
```bash
# Add a comment to a YAML file
echo "# Test change for PR validation - $(date)" >> sylvamo/config.dev.yaml
```

**Option B: Modify a Non-Critical Config**
```bash
# Add a comment to a transformation file
# Or update a description field
```

**What NOT to change:**
- ❌ Don't modify critical production configs
- ❌ Don't change module selections
- ❌ Don't modify authentication settings

### 2.3 Commit and Push

```bash
git add .
git commit -m "Test: PR validation pipeline"
git push origin test/pr-validation-$(date +%Y%m%d)
```

### 2.4 Create Pull Request

1. Go to Azure DevOps → Repos → Pull Requests
2. Click "New Pull Request"
3. Source: `test/pr-validation-YYYYMMDD`
4. Target: `main`
5. Add description: "Testing PR validation pipeline"
6. Create PR

### 2.5 Verify PR Validation Pipeline

**What to check:**

1. **Pipeline triggers automatically:**
   - ✅ Pipeline appears in "Checks" section of PR
   - ✅ Status shows "Running" or "In progress"

2. **Pipeline steps succeed:**
   - ✅ `cdf build` step completes successfully
   - ✅ `cdf deploy --dry-run` step completes successfully
   - ✅ No errors in pipeline logs

3. **Dry-run output:**
   - ✅ Shows expected changes (your test change)
   - ✅ No unexpected changes
   - ✅ No deployment actually occurs

4. **PR status:**
   - ✅ PR shows "All checks passed" or similar
   - ✅ PR can be merged (if validation passes)

### 2.6 Test Failure Scenario (Optional)

To test that the pipeline correctly blocks bad changes:

```bash
# Make a syntax error
echo "invalid: yaml: [broken" >> sylvamo/config.dev.yaml
git add .
git commit -m "Test: Intentionally break YAML"
git push origin test/pr-validation-$(date +%Y%m%d)
```

**Expected:**
- ❌ Pipeline fails on `cdf build` step
- ❌ PR shows "Checks failed"
- ❌ PR cannot be merged until fixed

---

## Phase 3: Dev Environment Auto-Deployment Testing

**Goal:** Test that merging to `main` automatically deploys to dev.

### 3.1 Merge Test PR

After PR validation passes:

1. Review PR changes
2. Approve PR (if required)
3. Complete/Merge PR to `main`

### 3.2 Verify Dev Deployment Pipeline Triggers

**What to check:**

1. **Pipeline triggers automatically:**
   - ✅ Navigate to Pipelines → Recent runs
   - ✅ New pipeline run appears (triggered by merge to `main`)
   - ✅ Pipeline shows "DeployDev" stage

2. **DeployDev stage runs:**
   - ✅ No approval required (auto-deploys)
   - ✅ `cdf build` succeeds
   - ✅ `cdf deploy --dry-run` runs and shows changes
   - ✅ `cdf deploy --env dev` runs and succeeds

3. **Pipeline logs:**
   - ✅ Check logs for each step
   - ✅ Verify correct CDF project targeted (`sylvamo-dev`)
   - ✅ No errors or warnings

### 3.3 Verify Changes in CDF Dev Environment

1. **Navigate to CDF Fusion UI:**
   - Go to `sylvamo-dev` project
   - Check Data Model → Instances
   - Check Transformations
   - Check other resources you deployed

2. **Verify changes:**
   - ✅ Your test changes appear
   - ✅ Resources are created/updated as expected
   - ✅ No broken references

### 3.4 Test Dev Deployment Failure Handling (Optional)

To test error handling:

```bash
# Make a change that will fail deployment
# (e.g., reference non-existent resource)
git checkout -b test/dev-failure-$(date +%Y%m%d)
# Make breaking change
git commit -m "Test: Breaking change"
git push origin test/dev-failure-$(date +%Y%m%d)
# Create PR, merge after validation
```

**Expected:**
- ✅ Pipeline fails at deployment step
- ✅ Error logged clearly
- ✅ Staging/Prod stages do NOT run (due to `dependsOn`)

---

## Phase 4: Staging Environment Promotion Testing

**Goal:** Test approval gate and staging deployment.

### 4.1 Verify Staging Stage Waits for Approval

After Dev deployment succeeds:

1. **Check pipeline status:**
   - ✅ Pipeline shows "DeployStaging" stage
   - ✅ Status shows "Waiting for approval" or "Pending"
   - ✅ Approval notification appears in ADO

2. **Check approval notification:**
   - ✅ Email/notification sent to approver
   - ✅ ADO shows approval request
   - ✅ Approver can see what will be deployed

### 4.2 Approve Staging Deployment

1. Navigate to Pipelines → Environments → `staging`
2. Click on pending approval request
3. Review changes (dry-run output)
4. Click "Approve" or "Reject"

### 4.3 Verify Staging Deployment

**What to check:**

1. **After approval:**
   - ✅ Pipeline continues automatically
   - ✅ `cdf deploy --dry-run` runs (shows changes)
   - ✅ `cdf deploy --env staging` runs
   - ✅ Deployment succeeds

2. **Pipeline logs:**
   - ✅ Verify correct CDF project (`sylvamo-test` or `sylvamo-staging`)
   - ✅ No errors
   - ✅ Changes match dev environment

3. **CDF Staging Environment:**
   - ✅ Navigate to staging CDF project
   - ✅ Verify resources match dev
   - ✅ No environment-specific issues

### 4.4 Test Rejection Scenario (Optional)

To test that rejection works:

1. Create another test change
2. Let it deploy to dev
3. When staging approval appears, click "Reject"

**Expected:**
- ✅ Pipeline stops at staging stage
- ✅ Prod stage does NOT run
- ✅ Changes remain only in dev

---

## Phase 5: Production Environment Promotion Testing

**Goal:** Test production approval gate and deployment.

### 5.1 Verify Production Stage Waits for Approval

After Staging deployment succeeds:

1. **Check pipeline status:**
   - ✅ Pipeline shows "DeployProd" stage
   - ✅ Status shows "Waiting for approval"
   - ✅ Approval notification appears

2. **Review staging deployment:**
   - ✅ Verify staging deployment succeeded
   - ✅ Verify staging environment looks correct
   - ✅ Ready to promote to production

### 5.2 Approve Production Deployment

**Important:** Only approve if staging looks good!

1. Navigate to Pipelines → Environments → `production`
2. Review pending approval request
3. Check dry-run output
4. Verify staging environment is stable
5. Click "Approve"

### 5.3 Verify Production Deployment

**What to check:**

1. **After approval:**
   - ✅ Pipeline continues
   - ✅ `cdf deploy --dry-run` runs first
   - ✅ `cdf deploy --env prod` runs
   - ✅ Deployment succeeds

2. **Pipeline logs:**
   - ✅ Verify correct CDF project (`sylvamo-prod`)
   - ✅ No errors
   - ✅ All steps completed successfully

3. **CDF Production Environment:**
   - ✅ Navigate to production CDF project
   - ✅ Verify resources match staging
   - ✅ Production is stable

### 5.4 Verify End-to-End Promotion

**Final verification:**

- ✅ Changes started in dev
- ✅ Promoted to staging (with approval)
- ✅ Promoted to production (with approval)
- ✅ All environments have consistent state
- ✅ No rollbacks needed

---

## Phase 6: Test All-Environments Validation Pipeline

**Goal:** Test the manual validation pipeline that checks all environments.

### 6.1 Run Test-All-Environments Pipeline

1. Navigate to Azure DevOps → Pipelines
2. Find `test-all-environments` pipeline
3. Click "Run pipeline"
4. Select branch: `main`
5. Click "Run"

### 6.2 Verify All Stages Run

**What to check:**

1. **ValidateDev stage:**
   - ✅ Runs `cdf build`
   - ✅ Runs `cdf deploy --dry-run --env dev`
   - ✅ Shows expected changes (or no changes if up-to-date)

2. **ValidateStaging stage:**
   - ✅ Runs after ValidateDev succeeds
   - ✅ Runs `cdf deploy --dry-run --env staging`
   - ✅ Shows expected changes

3. **ValidateProd stage:**
   - ✅ Runs after ValidateStaging succeeds
   - ✅ Runs `cdf deploy --dry-run --env prod`
   - ✅ Shows expected changes

### 6.3 Review Validation Results

**What to look for:**

- ✅ All environments are in sync (or show expected differences)
- ✅ No unexpected changes detected
- ✅ No configuration drift
- ✅ All environments are valid

### 6.4 Schedule Regular Validation (Optional)

Consider scheduling this pipeline to run:
- **Nightly:** Catch drift early
- **Weekly:** Regular validation
- **Before major releases:** Pre-deployment check

---

## Testing Checklist Summary

Use this checklist to verify everything works:

### Local Testing
- [ ] `cdf build --env dev` succeeds
- [ ] `cdf deploy --dry-run --env dev` shows expected changes
- [ ] Local deployment to dev works (optional)

### PR Validation
- [ ] PR validation pipeline triggers on PR creation
- [ ] `cdf build` step succeeds
- [ ] `cdf deploy --dry-run` step succeeds
- [ ] PR can be merged after validation passes
- [ ] Bad changes are blocked (syntax errors fail pipeline)

### Dev Auto-Deployment
- [ ] Merging to `main` triggers deploy pipeline
- [ ] DeployDev stage runs automatically (no approval)
- [ ] Dry-run runs before actual deployment
- [ ] Deployment succeeds
- [ ] Changes appear in dev CDF project

### Staging Promotion
- [ ] DeployStaging stage waits for approval
- [ ] Approval notification appears
- [ ] Dry-run runs before deployment
- [ ] Deployment succeeds after approval
- [ ] Changes appear in staging CDF project
- [ ] Rejection stops pipeline (optional test)

### Production Promotion
- [ ] DeployProd stage waits for approval
- [ ] Approval notification appears
- [ ] Dry-run runs before deployment
- [ ] Deployment succeeds after approval
- [ ] Changes appear in production CDF project

### Validation Pipeline
- [ ] Can run test-all-environments pipeline manually
- [ ] All three validation stages run successfully
- [ ] Shows expected changes (or no changes if in sync)

---

## Troubleshooting Common Issues

### Pipeline Doesn't Trigger

**Check:**
- Branch name matches trigger pattern (`main` for deploy, PR for validation)
- Pipeline YAML file is in `.devops/` folder
- Pipeline is created in ADO UI and linked to YAML file

### Dry-Run Shows Unexpected Changes

**Check:**
- Config files are correct for each environment
- Variable groups have correct CDF project names
- No manual changes were made directly in CDF

### Deployment Fails

**Check:**
- Variable groups have correct credentials
- CDF project exists and is accessible
- Service principal has correct permissions
- Check pipeline logs for specific error messages

### Approval Not Appearing

**Check:**
- ADO Environment is created (`staging`, `production`)
- Approvers are configured in Environment settings
- Pipeline uses `deployment:` job type (not regular `job:`)
- Environment name matches exactly (`environment: 'staging'`)

### Changes Don't Appear in CDF

**Check:**
- Correct CDF project targeted (check `CDF_PROJECT` variable)
- Deployment actually succeeded (check logs)
- CDF UI cache (refresh browser)
- Check CDF project directly via API/SDK

---

## Best Practices for Testing

1. **Start Small:**
   - Test with non-critical changes first
   - Use comments or descriptions for initial tests
   - Don't modify production-critical configs initially

2. **Test Incrementally:**
   - Test each phase before moving to next
   - Fix issues before proceeding
   - Document any problems encountered

3. **Verify in CDF UI:**
   - Always check CDF UI after deployments
   - Compare environments to ensure consistency
   - Verify resources are created/updated correctly

4. **Monitor Pipeline Logs:**
   - Review logs for each step
   - Look for warnings or errors
   - Save logs for troubleshooting

5. **Test Failure Scenarios:**
   - Test that bad changes are blocked
   - Test that approvals work correctly
   - Test that failures stop promotion

6. **Document Results:**
   - Keep notes on what was tested
   - Document any issues found
   - Update this guide with learnings

---

## Next Steps After Testing

Once testing is complete:

1. **Document Results:**
   - Update this guide with any findings
   - Document any customizations made
   - Note any environment-specific considerations

2. **Train Team:**
   - Share testing results with team
   - Train approvers on approval process
   - Document common workflows

3. **Set Up Monitoring:**
   - Configure pipeline notifications
   - Set up alerts for failures
   - Monitor deployment frequency

4. **Regular Validation:**
   - Schedule test-all-environments pipeline
   - Regular reviews of pipeline health
   - Periodic testing of failure scenarios

---

*Last Updated: February 7, 2026*
