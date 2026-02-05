# CI/CD for CDF - Speaker Notes

**Presentation for Technical Platform Teams**

---

## SLIDE: Title / TL;DR

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

## SLIDE: Sylvamo Repository

**SPEAKER NOTES:**

Before we dive in, let me show you where everything lives.

Our Toolkit configuration is managed in Azure DevOps in a repository called **Industrial-Data-Landscape-IDL**. You can find it at dev.azure.com/SylvamoCorp. The branch we're working on is `fernando/test` but the concepts apply to main as well.

All our credentials are stored at the **project level** in the SylvamoCorp ADO project. This means any pipeline in this repository can access them - we don't have to configure credentials per-pipeline.

---

## SLIDE: What is CDF from a CI/CD Perspective?

**SPEAKER NOTES:**

Let me explain what CDF looks like from your perspective as a platform team.

CDF is an **external SaaS endpoint**. It's hosted in Cognite-managed cloud clusters - for Sylvamo, we're using the `westeurope-1` cluster.

When our CI/CD pipeline runs, it connects to CDF over HTTPS. The authentication uses OAuth2 client credentials flow - that's the same pattern you'd use for any service-to-service authentication with Entra ID.

The key mental model here is: **treat CDF like any external cloud API**. It's no different from deploying to AWS, Azure, or calling the Salesforce API. Your pipeline authenticates with credentials, makes API calls to create or update resources, and that's it.

Nothing runs "inside" your network. The pipeline runs in ADO's hosted agents, talks to CDF over the public internet using HTTPS, and CDF does all the work on their end.

---

## SLIDE: The CI/CD Tech Stack

**SPEAKER NOTES:**

Let's talk about the actual tools we use.

The **deployment tool** is the Cognite Toolkit CLI. The command is `cdf`. You can install it as a Python package via pip - `pip install cognite-toolkit` - or use Cognite's official Docker image: `cognite/toolkit` with a specific version tag.

The **key commands** you'll see in pipelines are:
- `cdf build` - this validates your configuration files and compiles them into a deployable format
- `cdf deploy --dry-run` - this shows what would change in CDF without actually making changes. Think of it like `terraform plan`.
- `cdf deploy` - this actually applies the changes. Like `terraform apply`.

For **pipeline definitions**, we use YAML. The Toolkit supports GitHub Actions, Azure DevOps Pipelines, and GitLab CI/CD. For Sylvamo, we're using Azure DevOps, so our pipelines live in `.devops/*.yml` files.

Here's something important: **you don't need to write Python code**. The Toolkit is a pre-built CLI - you just call it from your pipeline. All the configuration is in YAML files. If you know YAML and understand CI/CD concepts, you can work with this.

---

## SLIDE: Repository Structure

**SPEAKER NOTES:**

Let me walk you through how a Toolkit repository is structured.

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

## SLIDE: CI/CD Flow Overview

**SPEAKER NOTES:**

Now let's talk about the actual CI/CD flow. This follows a standard pattern you've probably seen before.

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

## SLIDE: Authentication Model

**SPEAKER NOTES:**

Let's talk about how the pipeline authenticates to CDF. This is probably the most important part for a platform team to understand.

The Toolkit uses **OAuth2 client credentials flow**. This is the standard pattern for service-to-service authentication with Entra ID.

The required environment variables are:

- `LOGIN_FLOW` - set to `client_credentials`
- `CDF_CLUSTER` - the Cognite cluster, like `westeurope-1`
- `CDF_PROJECT` - the target project, like `sylvamo-dev`
- `IDP_CLIENT_ID` - the App Registration's Application ID
- `IDP_CLIENT_SECRET` - the client secret (this is the sensitive one)
- `IDP_TENANT_ID` - your Entra ID tenant ID

**How Sylvamo is configured:**

We use ADO Variable Groups at the project level. We have one group per environment:
- `dev-toolkit-credentials`
- `staging-toolkit-credentials`
- `prod-toolkit-credentials`

Each group contains those six variables. The `IDP_CLIENT_SECRET` is marked as a secret in ADO, so it's encrypted and masked in logs.

**How the flow works:**

1. ADO stores the credentials in a Variable Group - think of it like a secure key-value store
2. The pipeline YAML links to that Variable Group with `variables: - group: dev-toolkit-credentials`
3. When the job runs, ADO automatically injects those values as environment variables
4. The `cdf` CLI reads those environment variables and uses them to authenticate

You never see the secrets in code - they're injected at runtime. The secret values never appear in logs because ADO masks them.

Because we store these at the project level, any pipeline in the Industrial-Data-Landscape-IDL repository can access them. We don't have to configure credentials separately for each pipeline.

---

## SLIDE: Secret Handling Options

**SPEAKER NOTES:**

There are two main options for handling secrets. Let me explain both.

**Option A: ADO Variable Groups**

This is the simpler approach and what Sylvamo uses.

The flow is:
1. Secrets stored in ADO Variable Group
2. Pipeline links to the group
3. ADO injects them as environment variables at runtime
4. Toolkit CLI reads the env vars

This is straightforward and works well for most cases. ADO handles encryption, access control, and audit logging.

**Option B: Azure Key Vault Integration**

This is more complex but might be required if you have organizational policies mandating Key Vault for all secrets.

The flow is:
1. Pipeline authenticates to Azure (using service connection or managed identity)
2. Pipeline step fetches secrets from Key Vault
3. Pipeline exports them as environment variables
4. Toolkit CLI reads the env vars

The Toolkit itself doesn't have a direct Key Vault integration - it just reads environment variables. So you need pipeline steps to bridge the gap.

**Which should you use?**

For Sylvamo, we use Option A - Variable Groups. It's simpler and meets our requirements.

Use Option B if you have centralized secret management policies requiring Key Vault, or if you need the additional capabilities Key Vault provides like automatic rotation.

One more thing: the Toolkit supports `${VAR_NAME}` placeholders in YAML config files. So if you have a secret that needs to go into a configuration file - like a client secret for a workflow trigger - you can write `${IDP_WF_TRIGGER_SECRET}` and the Toolkit will substitute the environment variable value at deploy time.

---

## SLIDE: Key Takeaways for Platform Teams

**SPEAKER NOTES:**

Let me summarize the key points for platform teams:

**Connection Type:** CDF is external SaaS accessed over HTTPS. It's no different from any other cloud API. No VPN, no private endpoints in our current setup - just public HTTPS to Cognite's cluster.

**Auth Method:** OAuth2 client credentials via Entra ID service principal. Standard stuff - you create an App Registration, give it a secret, and use client_id + client_secret to get tokens.

**Secrets Storage:** We use ADO Variable Groups at the project level. You could also integrate with Key Vault if that's required by policy.

**CI Pipeline:** `cdf build` plus `cdf deploy --dry-run` on PRs. This is the validation step.

**CD Pipeline:** `cdf deploy` on main branch merge. This is the actual deployment.

**Environments:** We have separate CDF projects for dev, staging, and prod. Each is completely isolated.

**Approvals:** You can use ADO Environments with approval gates if you want manual approval before deploying to prod.

The bottom line is: **standard CI/CD patterns apply**. If you've set up pipelines for Terraform, ARM templates, or any other infrastructure-as-code tool, this will feel very familiar. CDF is just another external API with a CLI tool.

---

## SLIDE: Sample ADO Pipeline - Dry-Run

**SPEAKER NOTES:**

Let me walk through the dry-run pipeline YAML.

```yaml
trigger:
  - none  # Triggered via PR validation
```

We set trigger to `none` because this pipeline is triggered by PR validation, not by pushes directly.

```yaml
pool:
  vmImage: 'ubuntu-latest'
```

We use Microsoft-hosted agents with Ubuntu.

```yaml
variables:
  - group: dev-toolkit-credentials
```

This links to our Variable Group. ADO will inject all the variables from this group as environment variables.

```yaml
container:
  image: cognite/toolkit:0.5.35
```

We run inside Cognite's official Docker image. This has the `cdf` CLI pre-installed with all dependencies. You specify the version to ensure reproducible builds.

```yaml
steps:
  - script: cdf build
    displayName: 'Build Toolkit Modules'

  - script: cdf deploy --dry-run
    displayName: 'Validate Deployment (Dry Run)'
```

Two simple steps: build and dry-run. If either fails, the pipeline fails and the PR can't be merged.

This pipeline runs on every PR. It validates that the configuration is correct and shows reviewers what would change if this code were merged.

---

## SLIDE: Sample ADO Pipeline - Deploy

**SPEAKER NOTES:**

Now the deploy pipeline.

```yaml
trigger:
  branches:
    include:
      - main
```

This triggers automatically when code is pushed to main - which happens when a PR is merged.

```yaml
variables:
  - group: prod-toolkit-credentials
```

Note we're using the prod credentials here. In a real setup, you might have multiple stages - deploy to dev first, then staging, then prod with approvals.

```yaml
steps:
  - script: cdf build
    displayName: 'Build Toolkit Modules'

  - script: cdf deploy
    displayName: 'Deploy to CDF'
    env:
      IDP_CLIENT_SECRET: $(IDP_CLIENT_SECRET)
```

The deploy step has an extra `env:` block. This is an ADO quirk - secret variables need to be explicitly mapped into the environment for script steps. The `$(IDP_CLIENT_SECRET)` syntax pulls from the Variable Group.

That's it - two steps, and your changes are deployed to CDF.

---

## CLOSING

**SPEAKER NOTES:**

To wrap up:

CDF CI/CD is straightforward if you're familiar with infrastructure-as-code patterns. We have:
- A CLI tool (`cdf`) that handles all the complexity
- YAML configuration files in a Git repository
- Standard CI/CD pipelines that validate on PR and deploy on merge
- OAuth2 authentication using Entra ID service principals
- Secrets stored in ADO Variable Groups

The Sylvamo repository is at dev.azure.com/SylvamoCorp - the Industrial-Data-Landscape-IDL repo. Credentials are already configured at the project level.

Any questions?

---

## APPENDIX: Quick Reference

**Commands:**
- `cdf build` - Validate and compile configuration
- `cdf deploy --dry-run` - Preview changes (no actual changes)
- `cdf deploy` - Apply changes to CDF

**Environment Variables:**
- `LOGIN_FLOW=client_credentials`
- `CDF_CLUSTER=westeurope-1`
- `CDF_PROJECT=sylvamo-dev`
- `IDP_CLIENT_ID=<app-id>`
- `IDP_CLIENT_SECRET=<secret>`
- `IDP_TENANT_ID=<tenant-id>`

**Key URLs:**
- ADO Repo: https://dev.azure.com/SylvamoCorp/_git/Industrial-Data-Landscape-IDL
- Data Model Docs: https://github.com/fbarsoba-cognite/sylvamo-data-model

---

*Speaker notes prepared: February 4, 2026*
