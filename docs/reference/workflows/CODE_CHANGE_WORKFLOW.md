# Code Change Workflow

> **Source:** This is a copy of `.cursor/rules/code_change_workflow.mdc` for accessibility outside Cursor.


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

## 1. Jira Ticket
- Check if an existing Jira ticket covers the change
- If not, create a new Jira ticket in SVQS project
- Assign to the requesting user
- Move to "In Progress"
- Add to current sprint (Sprint 3)

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

### 4.4 Transformation Preview (Dry Run)

Before running transformations that modify data:

```python
# Preview transformation output WITHOUT modifying data
t = client.transformations.retrieve(external_id="tr_xxx")
preview = client.transformations.preview(
    query=t.query,
    source_limit=10,
    convert_to_string=True
)
print(f"Preview: {len(preview.results)} rows")
```

- Verify output looks correct before running
- Check relations are populated (asset, roll, etc.)
- Only run transformation after preview confirms expected results

## 5. Pull Request
- Push branch to ADO: `git push -u ado <branch-name>`
- Create PR targeting `main` via the **ADO REST API** (do NOT generate manual links)
- Authentication: use `git credential fill` to retrieve stored ADO credentials
- API endpoint: `https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_apis/git/repositories/Industrial-Data-Landscape-IDL/pullrequests?api-version=7.1`
- Include summary of changes and test plan in PR description

### How to create the PR programmatically

```python
import subprocess, json, urllib.request, base64

# Get credentials from git credential helper
proc = subprocess.run(
    ['git', 'credential', 'fill'],
    input='protocol=https\nhost=dev.azure.com\n\n',
    capture_output=True, text=True, timeout=5
)
creds = {}
for line in proc.stdout.strip().split('\n'):
    if '=' in line:
        k, v = line.split('=', 1)
        creds[k] = v

auth = base64.b64encode(f"{creds['username']}:{creds['password']}".encode()).decode()

pr_body = {
    "sourceRefName": "refs/heads/<branch-name>",
    "targetRefName": "refs/heads/main",
    "title": "SVQS-XXX: Short description",
    "description": "## Summary\n- ..."
}

url = "https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_apis/git/repositories/Industrial-Data-Landscape-IDL/pullrequests?api-version=7.1"
req = urllib.request.Request(url, data=json.dumps(pr_body).encode(), method="POST")
req.add_header("Authorization", f"Basic {auth}")
req.add_header("Content-Type", "application/json")

with urllib.request.urlopen(req) as resp:
    result = json.loads(resp.read().decode())
    pr_id = result["pullRequestId"]
    # PR URL: https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/{pr_id}
```

## 6. Cross-Linking
- Add ADO branch/PR link to Jira ticket
- Reference Jira ticket in PR description and commit messages

## 7. Documentation (REQUIRED for all code changes)

### 7.1 Change Log (REQUIRED for ALL changes)

Every code change MUST be logged in the change log:

1. **Location:** sylvamo-project-documentation (GitHub) — **NOT ADO**
   - Path: `docs/reference/data-model/changelog/CHANGELOG-XXXX.md`
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
- **Comment Style:** Always write Jira comments in first person singular ("I updated...", "I found..."), NOT plural ("We updated...", "We found...").
- **Links in ADF:** Do NOT use wiki markup `[text|url]`. Use proper ADF link format:
  ```python
  {"type": "text", "text": "Link Text", "marks": [{"type": "link", "attrs": {"href": "https://..."}}]}
  ```
  Always verify links render correctly after posting.
- **Changelog Link (REQUIRED):** When closing a Jira ticket that involved code changes or SDK operations, add a comment linking to the changelog entry:
  ```python
  {
      "type": "paragraph",
      "content": [
          {"type": "text", "text": "Changelog: "},
          {"type": "text", "text": "CHANGELOG-0001.md#svqs-xxx", "marks": [
              {"type": "link", "attrs": {"href": "https://github.com/fbarsoba-cognite/sylvamo-project-documentation/blob/main/docs/reference/data-model/changelog/CHANGELOG-0001.md"}}
          ]}
      ]
  }
  ```
  This ensures traceability between Jira tickets and documented changes.

## ADO Details
- Repo: Industrial-Data-Landscape-IDL
- Organization: SylvamoCorp
- Project: Industrial-Data-Landscape-IDL
- Remote name: `ado`
- Authentication: `git credential fill` (uses stored credentials from git pushes — no PAT needed)

## Documentation Repo Details
- GitHub: https://github.com/fbarsoba-cognite/sylvamo-project-documentation
- Clone to: `../sylvamo-project-documentation` (sibling folder)
- ADRs go in: `docs/reference/data-model/decisions/`

## Team Jira Accounts

For tagging team members in Jira comments, use these account IDs:

| Name | Account ID | Email |
|------|------------|-------|
| Fernando Barsoba | `712020:d931a401-d119-4163-8741-19e05ac78283` | fernando.barsoba@cognite.com |
| Anvar Akhiiartdinov | `5e158015b783d60db0a06e9b` | anvar.akhiiartdinov@cognite.com |
| Max Tollefsen | `712020:23ec21ff-46ea-46dd-bdc3-af285ed7f5c3` | max.tollefsen@cognite.com |
| Santiago Espinosa | `712020:2060fa8d-7601-42f3-bf3d-0ca96ee8dec3` | santiago.espinosa@cognite.com |

**Usage in Jira API (ADF format):**
```python
{"type": "mention", "attrs": {"id": "ACCOUNT_ID", "text": "@Name"}}
```
