---
title: Code Change Workflow
description: Standard workflow for making code changes - Jira, ADO branch, PR, documentation, and linking
type: Always
globs: 
alwaysApply: true
---

# Code Change Workflow

> **To invoke this rule:** Type `@code_change_workflow` in the prompt, or it applies automatically (alwaysApply: true).

**For ALL code changes, follow this workflow:**

## Performance: Use Parallel Agents

When tasks can be parallelized, use multiple agents to speed up work:
- Use `Task` tool with multiple parallel invocations for independent tasks
- Example: Create Jira ticket + Create ADO branch can run in parallel
- Example: Update multiple files that don't depend on each other
- Maximum 4 concurrent agents recommended

## Environment & Credentials

All project credentials (CDF, Jira, SharePoint) are in the main worktree `.env` file:

```
/Users/fernando.barsoba/Library/CloudStorage/OneDrive-CogniteAS/Sylvamo-Code/sylvamo/.env
```

**ALWAYS check this file FIRST** before writing any script or running any command that needs authentication. Key variables:
- `CDF_PROJECT`, `CDF_CLUSTER`, `CDF_URL` -- CDF connection
- `IDP_CLIENT_ID`, `IDP_CLIENT_SECRET`, `IDP_TENANT_ID`, `IDP_TOKEN_URL` -- OAuth
- `JIRA_EMAIL`, `JIRA_API_TOKEN` -- Jira API
- `SHAREPOINT_*` -- SharePoint

Do NOT hardcode credentials. Read them from this `.env` file.

## SDK Usage: CLI First

**NEVER use the Cognite Python SDK** for standard operations unless explicitly requested.

- **Use CDF CLI tools** (`cdf build`, `cdf deploy`, `cdf clean`) for all deployments
- **Use transformations** (SQL) for data population - not SDK scripts
- **SDK is allowed only for:**
  - One-off validation/debugging queries (when user requests)
  - Operations not supported by CLI (e.g., deleting specific instances)
  - When user explicitly asks to use SDK

### Orphaned CDF Resources (Views, Containers, Instances)

When removing views/containers/instances from the codebase:
1. **`cdf deploy` does NOT automatically delete** orphaned resources from CDF
2. **Preferred approach:** Use `cdf clean` if available, or create a cleanup script in a PR
3. **If SDK cleanup is required:**
   - Document in the changelog what was deleted and why
   - Reference the original PR that removed the code
   - Only use SDK for resources that cannot be deleted via CLI

**Example:** If you remove `Equipment.View.yaml` from codebase and deploy, the view may still exist in CDF. Either:
- Run `cdf clean --env dev` to remove orphaned resources
- Or use SDK to delete, documenting in changelog under the original ticket

## 1. Jira Ticket
- Check if an existing Jira ticket covers the change
- If not, create a new Jira ticket in SVQS project
- Assign to the requesting user
- Move to "In Progress"
- Add to current sprint (Sprint 2)

## 2. ADO Branch
- Create a feature branch in ADO: `feature/SVQS-XXX-short-description`
- Base off `main` branch (or appropriate base branch)
- ADO Repo: https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL

## 3. Code Changes
- Make changes in the branch
- Commit with format: `SVQS-XXX: Short description`
  - Example: `SVQS-243: Add ISA-95 assetType classification`
  - Do NOT include `Co-authored-by` lines

## 4. Validation & Dry Run (REQUIRED)

**Before pushing, ALWAYS validate:**

### 4.1 Build Validation
```bash
cdf build --env dev
```
- Must complete without errors
- Warnings are acceptable but review them

### 4.2 Dry Run Deployment
```bash
cdf deploy --dry-run --env dev
```
- Review what WOULD be created/changed/deleted
- Verify no unexpected changes
- Check for breaking changes (deleted views, changed properties)

### 4.3 Post-Deployment Validation (after merge & deploy)
After deployment, verify:
1. **Transformations run successfully** - Check CDF Fusion > Transformations
2. **Data is populated correctly** - Query the data model to verify counts/values
3. **Nothing is broken** - Check related entities still work
4. **No regressions** - Existing functionality still works

Example validation script:
```python
# Query to verify changes
client.data_modeling.instances.list(sources=[view_id], limit=10)
```

## 5. Pull Request
- Push branch to ADO
- Create PR targeting `main`
- Include summary of changes and test plan in PR description

## 6. Cross-Linking
- Add ADO branch/PR link to Jira ticket
- Reference Jira ticket in PR description and commit messages

## 7. Documentation (REQUIRED for all code changes)

### 7.1 Change Log (REQUIRED for ALL changes)

Every code change MUST be logged in the change log:

1. **Location:** `docs/reference/data-model/changelog/CHANGELOG-XXXX.md`
2. **Format:** ~10 entries per page, then start new page (CHANGELOG-0001.md, CHANGELOG-0002.md, etc.)
3. **Entry format:**
   ```markdown
   ### [SVQS-XXX] Short Title
   **Date:** YYYY-MM-DD HH:MM (timezone)
   **Jira:** [SVQS-XXX](link)
   **ADO PR:** [PR #XXX](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/XXX)
   
   **Changes:**
   - Bullet points of what changed
   
   **Why:**
   - Brief explanation of why the change was made
   ```
   
   > **IMPORTANT:** Always link to the **Pull Request URL** (e.g., `/pullrequest/893`), NOT the branch URL. Branches are deleted after merge, but PR URLs persist.

### 7.2 ADRs (for architectural/design decisions)

For changes involving **data model decisions, architectural choices, or design patterns**:

1. **Document in sylvamo-project-documentation repo:**
   - Repo: https://github.com/fbarsoba-cognite/sylvamo-project-documentation
   - Location: `docs/reference/data-model/decisions/` (for ADRs)
   - Use ADR format (Architecture Decision Record)

2. **ADR Template:**
   ```markdown
   # ADR-XXX: [Decision Title]
   
   ## Status
   Accepted | Proposed | Deprecated
   
   ## Context
   What is the issue? Why are we making this decision?
   
   ## Decision
   What is the change being proposed/implemented?
   
   ## Consequences
   What are the results? Benefits and tradeoffs.
   
   ## References
   - Jira: [SVQS-XXX](https://cognitedata.atlassian.net/browse/SVQS-XXX)
   - ADO PR: [PR #XXX](https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL/pullrequest/XXX)
   - Related docs: links to standards, research, etc.
   ```

3. **Link the ADR:**
   - Add ADR link to Jira ticket description
   - Reference ADR in PR description

## Jira API Details
- Base URL: https://cognitedata.atlassian.net
- Project Key: SVQS
- Credentials: `JIRA_EMAIL` and `JIRA_API_TOKEN` from the `.env` file (see "Environment & Credentials" above)

## ADO Details
- Repo: Industrial-Data-Landscape-IDL
- Organization: SylvamoCorp
- Remote name: `ado`

## Documentation Repo Details
- GitHub: https://github.com/fbarsoba-cognite/sylvamo-project-documentation
- Clone to: `../sylvamo-project-documentation` (sibling folder)
- ADRs go in: `docs/reference/data-model/decisions/`
