# CI/CD Hands-On Speaker Notes

**Second Presentation: Hands-On Session for Sylvamo Platform Team**

**Audience:** Platform Teams, DevOps Engineers, Technical Leads  
**Duration:** 60–90 minutes (follow-along exercises)  
**Prerequisites:** Phase 1 (CI/CD Overview), Phase 2 (Complete Setup Guide)  
**Last Updated:** February 9, 2026

---

## Session Overview

This session is the **hands-on** follow-up to the CI/CD concepts and setup guide. Attendees will follow along as you demonstrate the actual workflow: creating a feature branch, opening a PR, watching validation, merging, and observing deployment.

**Goal:** Participants see the full flow in action and understand how to use it day-to-day.

---

## Pre-Session Checklist

**Before the session, ensure:**

- [ ] Clone of `Industrial-Data-Landscape-IDL` repo
- [ ] ADO access (SylvamoCorp)
- [ ] CDF access (sylvamo-dev, sylvamo-test)
- [ ] Git configured (identity, credentials)
- [ ] Browser tabs ready: ADO Pipelines, ADO Repos, CDF Fusion

**Attendee checklist (share in chat):**

```
□ ADO: https://dev.azure.com/SylvamoCorp
□ Repo: Industrial-Data-Landscape-IDL
□ CDF: sylvamo-dev, sylvamo-test
□ Git: clone repo, have write access
```

---

## Session Structure

```
┌─────────────────────────────────────────────────────────────┐
│ HANDS-ON SESSION FLOW (60–90 min)                          │
├─────────────────────────────────────────────────────────────┤
│ 1. Intro & Quick Recap (5 min)                             │
│ 2. Exercise 1: Feature Branch & PR (15 min)                │
│ 3. Exercise 2: PR Validation (10 min)                      │
│ 4. Exercise 3: Merge & Deploy (15 min)                     │
│ 5. Exercise 4: Branch Policy (10 min)                      │
│ 6. Exercise 5 (Optional): Promote to Prod (10 min)         │
│ 7. CDF IAM Discussion (10 min)                            │
│ 8. Troubleshooting Demo (5 min)                           │
│ 9. Q&A (10 min)                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## SECTION 1: Intro & Quick Recap

**SPEAKER NOTES:**

> "Welcome to the hands-on session. We'll walk through the real workflow we use at Sylvamo: feature branch, PR, validation, merge, and deployment. You'll see it in action."

**Quick recap:**

> "Remember: we use trunk-based development. One `main` branch. Environment-specific configs. PR validation runs dry-run for Dev and Staging. Merge triggers deploy to Dev and Staging. Production is a separate promote pipeline."

**Transition:** "Let's start with Exercise 1 – creating a feature branch and opening a PR."

---

## SECTION 2: Exercise 1 – Feature Branch & PR

**SPEAKER NOTES:**

> "First, we create a feature branch. Never commit directly to main."

**Live demo – terminal:**

```bash
cd /path/to/Industrial-Data-Landscape-IDL
git checkout main
git pull origin main
git checkout -b feature/hands-on-demo-$(date +%Y%m%d)
```

**Make a small change:**

```bash
echo "# Hands-on demo - $(date)" >> sylvamo/config.dev.yaml
git add sylvamo/config.dev.yaml
git commit -m "Demo: Hands-on session test change"
git push -u origin feature/hands-on-demo-$(date +%Y%m%d)
```

**Create PR in ADO:**

> "Go to Repos → Pull Requests → New. Source: your feature branch. Target: main. Title: 'Demo: Hands-on session test'. Create."

**What to point out:**

- Feature branch name is descriptive
- Change is minimal (comment only)
- PR targets `main`

**Transition:** "Now watch the PR validation run."

---

## SECTION 3: Exercise 2 – PR Validation

**SPEAKER NOTES:**

> "When we create a PR, the dry-run pipeline triggers automatically. It validates against both Dev and Staging."

**Live demo – ADO:**

1. Open the PR
2. Show "Checks" or "Build validation" section
3. Point out: "Validate Dev (Dry Run)" and "Validate Staging (Dry Run)"

**What to explain:**

> "Dry-run does NOT deploy. It shows what WOULD change. If either stage fails, the PR can't be merged. This catches config errors and CDF IAM issues before they hit main."

**Common outcome:**

- Both pass → PR is mergeable
- Staging fails → Often invalid capabilities (annotationsAcl, assetsAcl, relationshipsAcl)

**Transition:** "Let's assume it passes. We'll merge and watch the deploy pipeline."

---

## SECTION 4: Exercise 3 – Merge & Deploy

**SPEAKER NOTES:**

> "We merge the PR. That triggers the deploy pipeline."

**Live demo – ADO:**

1. Click "Complete" or "Merge" on the PR
2. Go to Pipelines → Recent runs
3. Find "Deploy to Dev & Staging" (or similar)
4. Show stages: DeployDev → DeployStaging

**What to explain:**

> "Dev deploys first, then Staging. Both run automatically on merge. No approval gate for these – that's intentional. Production is different; it uses a separate pipeline with approval."

**Verify in CDF:**

> "Open CDF Fusion → sylvamo-dev. Check that the change (e.g., comment in config) is reflected. The actual deployment is the Toolkit applying the built modules."

**Transition:** "Now let's ensure the branch policy is set so PRs always get this validation."

---

## SECTION 5: Exercise 4 – Branch Policy

**SPEAKER NOTES:**

> "Branch policies ensure PRs can't be merged until validation passes."

**Live demo – ADO:**

1. Repos → Branches → main → Branch policies
2. Build validation → Add build policy
3. Build pipeline: Select "PR Validation - CDF Toolkit Dry Run"
4. Policy requirement: **Required**
5. Display name: "CDF Toolkit Dry Run Validation"
6. Save

**What to explain:**

> "With this policy, every PR targeting main must pass the dry-run. Failed pipelines block merge. This is your safety net."

**Transition:** "Optionally, we can look at the Production promotion pipeline."

---

## SECTION 6: Exercise 5 (Optional) – Promote to Prod

**SPEAKER NOTES:**

> "Production is separate. We use a promote-to-prod pipeline that runs weekly or manually."

**Live demo – ADO:**

1. Pipelines → Pipelines
2. Find "Promote to Production (Weekly/Manual)"
3. Click "Run pipeline"
4. Show that it triggers, then pauses at approval gate

**What to explain:**

> "Production has an approval gate. Even if it runs on schedule, it waits for a human to approve. That prevents accidental production deployments."

**Transition:** "Let's talk about CDF IAM – why we had to adjust Group YAML files."

---

## SECTION 7: CDF IAM Discussion

**SPEAKER NOTES:**

> "One thing we learned: staging and production CDF projects restrict WRITE access on some legacy APIs."

**Key points:**

1. **Annotations, Assets, Relationships:** In sylvamo-test and sylvamo-prod, WRITE is not allowed on these legacy APIs.
2. **Group YAML files:** Must use READ only for `annotationsAcl`, `assetsAcl`, `relationshipsAcl`.
3. **Location:** `sylvamo/modules/admin/auth/cognite_toolkit_service_principal.Group.yaml`
4. **Error if wrong:** `ResourceUpdateError: 3 invalid capabilitie(s) are present`

**Show the fix:**

```yaml
# Before (fails in staging/prod)
- annotationsAcl:
    actions: [READ, WRITE, SUGGEST, REVIEW]

# After (works)
- annotationsAcl:
    actions: [READ]
```

**Transition:** "Let's quickly show a couple of common errors and how to fix them."

---

## SECTION 8: Troubleshooting Demo

**SPEAKER NOTES:**

> "If something goes wrong, here are the most common fixes."

**Error 1: Variable group not found**

> "Go to Variable Groups → Click group → Pipeline permissions → Add pipeline → Save."

**Error 2: Invalid capabilities**

> "Update Group YAML: use READ only for annotationsAcl, assetsAcl, relationshipsAcl."

**Error 3: Working directory not found**

> "Add `checkout: self` as first step in the job."

**Reference:** [CI/CD Pipeline Troubleshooting](CICD_PIPELINE_TROUBLESHOOTING.md)

---

## SECTION 9: Q&A

**Common questions:**

**Q: Can we use the same credentials for all environments?**  
> A: Yes, but separate service principals per environment is recommended for audit and security.

**Q: What if we make changes via CDF API?**  
> A: Sync back to git using `cdf dump` and commit the YAML. Otherwise you get drift.

**Q: How do we roll back?**  
> A: `git revert` the bad commit, merge to main, and let the pipeline redeploy the previous state.

**Q: How often does Production deploy?**  
> A: The promote pipeline can run weekly (Monday) or manually. Each run still requires approval.

---

## Handout: Quick Reference Card

**Print or share:**

```
┌─────────────────────────────────────────────────────────────┐
│ CI/CD QUICK REFERENCE                                      │
├─────────────────────────────────────────────────────────────┤
│ Pipeline Names:                                            │
│   PR Validation - CDF Toolkit Dry Run                     │
│   Deploy to Dev & Staging (Auto on Merge)                 │
│   Promote to Production (Weekly/Manual)                    │
│   Test All Environments (Manual)                            │
├─────────────────────────────────────────────────────────────┤
│ Variable Groups:                                            │
│   dev-toolkit-credentials, staging-toolkit-credentials,    │
│   prod-toolkit-credentials                                  │
├─────────────────────────────────────────────────────────────┤
│ Key Commands:                                               │
│   cdf build --env <env>                                     │
│   cdf deploy --dry-run --env <env>                         │
│   cdf deploy --env <env>                                    │
├─────────────────────────────────────────────────────────────┤
│ Workflow:                                                    │
│   feature branch → PR → dry-run → merge → deploy Dev+Staging│
│   Production: separate pipeline, approval required          │
└─────────────────────────────────────────────────────────────┘
```

---

## Resources

- [CI/CD Hands-On Learnings](CICD_HANDS_ON_LEARNINGS.md)
- [CI/CD Complete Setup Guide](CICD_COMPLETE_SETUP_GUIDE.md)
- [CI/CD Pipeline Troubleshooting](CICD_PIPELINE_TROUBLESHOOTING.md)
- [CI/CD Overview](CICD_OVERVIEW.md)
- ADO: https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL

---

*Last Updated: February 9, 2026*
