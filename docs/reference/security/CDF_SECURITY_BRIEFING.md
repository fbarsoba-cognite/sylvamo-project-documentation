# CDF Security Briefing

**Meeting-ready primer for explaining Cognite Data Fusion security in the context of stakeholder concerns**

> **Purpose:** Support meetings where security, identity, or access concerns are raised. Use this document to explain the CDF security model, responsibility split, and validation approach. Convert sections into slides as needed.

---

## Table of Contents

1. [What Triggered the Concern](#1-what-triggered-the-concern)
2. [Plain-Language Issue Statement](#2-plain-language-issue-statement)
3. [CDF Security Model Overview](#3-cdf-security-model-overview)
4. [Responsibility Split](#4-responsibility-split)
5. [Root-Cause Hypotheses](#5-root-cause-hypotheses)
6. [Validation Checklist](#6-validation-checklist)
7. [Immediate Controls to Propose](#7-immediate-controls-to-propose)
8. [Meeting Narrative](#8-meeting-narrative)
9. [Q&A Prep](#9-qa-prep)
10. [Technical Deep Dive](#10-technical-deep-dive)

---

## 1. What Triggered the Concern

A forwarded email thread raised two core concerns:

| Concern | Description |
|---------|-------------|
| **Device access** | A team member reportedly accessed Cognite from a non-work (personal) computer |
| **Data access** | A team member reportedly accessed data they believed they should not be able to access |

> **Source:** Internal email thread (Suliman raised concerns; Torgrim provided Cognite’s response on identity and RBAC.)

---

## 2. Plain-Language Issue Statement

The concern is likely **not** “CDF is wide open,” but rather a potential mismatch in **identity governance and access mapping**:

- **Device access path** is controlled primarily by corporate IdP and Conditional Access policy.
- **Data authorization in CDF** is controlled by CDF groups and capabilities, often synced from IdP group memberships.
- If access seems too broad, typical causes are:
  - Permissive IdP group membership
  - Incorrect CDF group mapping (`sourceId` / group linkage)
  - Overly broad CDF capabilities or scopes

```mermaid
flowchart LR
    subgraph Concern["Reported Concern"]
        A[Non-work device access]
        B[Data I shouldn't see]
    end

    subgraph LikelyCause["Likely Root Cause"]
        C[IdP / Conditional Access]
        D[Group membership or mapping]
    end

    A --> C
    B --> D
```

---

## 3. CDF Security Model Overview

### High-Level Architecture

```mermaid
flowchart TB
    subgraph User["User or Service Principal"]
        U[Identity]
    end

    subgraph IdP["Sylvamo Identity Provider (Entra ID)"]
        Auth[Authentication]
        Groups[Group Membership]
    end

    subgraph CDF["Cognite Data Fusion"]
        CDFGroups[CDF Groups]
        Capabilities[Capabilities / ACLs]
        Data[CDF Data]
    end

    U -->|"1. Login (OAuth2)"| Auth
    Auth -->|"2. Token"| CDF
    Groups -->|"3. Sync via sourceId"| CDFGroups
    CDFGroups --> Capabilities
    Capabilities -->|"4. Authorize"| Data
```

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Authentication** | Who are you? Handled by Sylvamo’s IdP (Entra ID / OAuth2). |
| **Authorization** | What can you do? Handled by CDF IAM groups and capabilities (ACLs). |
| **Group-based access** | Access is granted via groups, not individual user hardcoding. |
| **Service principals** | Apps, pipelines, and functions are identities too; they must be governed like users. |
| **Scope** | Capabilities can be limited to datasets, spaces, tables, or projects. |

### CDF as Service Provider (SP)

```mermaid
flowchart LR
    subgraph Sylvamo["Sylvamo IT"]
        IdP[Entra ID / IdP]
        Groups[Azure AD Groups]
    end

    subgraph Cognite["Cognite Platform"]
        CDF[CDF]
    end

    IdP -->|"OAuth2 / OIDC"| CDF
    Groups -->|"sourceId = Object ID"| CDF
    CDF -->|"No separate user store"| CDF
```

> **Cognite acts as a Service Provider (SP)** that integrates directly with Sylvamo’s Identity Provider (IdP). CDF does not maintain a separate user store; it relies on your enterprise identity and group membership.

---

## 4. Responsibility Split

Understanding who owns what is critical for addressing concerns and assigning remediation.

```mermaid
flowchart TB
    subgraph SylvamoIT["Sylvamo IT / IdP Owner"]
        CA[Conditional Access]
        MFA[MFA Enforcement]
        GM[Group Membership Hygiene]
        AR[Access Recertification]
    end

    subgraph Cognite["Cognite Platform"]
        TI[Tenant Isolation]
        AL[Audit Logging]
        IAM[IAM Capability Framework]
    end

    subgraph Shared["Shared Responsibility"]
        Mapping[IdP Group → CDF Group Mapping]
        LP[Least-Privilege Design]
    end

    CA --> Mapping
    GM --> Mapping
    IAM --> LP
```

### Responsibility Matrix

| Area | Sylvamo IT | Cognite | Shared |
|------|------------|---------|--------|
| **Device-based access** (work vs non-work laptop) | ✅ Owner | — | — |
| **Conditional Access, MFA, compliant device** | ✅ Owner | — | — |
| **Group membership and hygiene** | ✅ Owner | — | — |
| **Platform security, tenant isolation** | — | ✅ Owner | — |
| **Audit logging, SOC 2** | — | ✅ Owner | — |
| **Mapping IdP groups to CDF capabilities** | — | — | ✅ Shared |
| **Least-privilege role design** | — | — | ✅ Shared |

---

## 5. Root-Cause Hypotheses

Use these as discussion points when investigating reported issues:

```mermaid
mindmap
  root(Reported Access Concern)
    Device
      Conditional Access gap
      Unmanaged devices allowed
    Data
      Group over-entitlement
      User in overly broad IdP group
    Mapping
      Wrong sourceId
      CDF group not linked to intended IdP group
    Scope
      Capabilities too broad
      Dataset/space limits not applied
```

| Hypothesis | Owner | Validation |
|------------|-------|------------|
| **Conditional Access gap** | Sylvamo IT | Check IdP policy for Cognite app: managed device, MFA, location |
| **Group over-entitlement** | Sylvamo IT | Identify user’s effective group memberships in IdP |
| **CDF mapping issue** | Shared | Verify `sourceId` on CDF groups matches intended Azure AD group Object ID |
| **Scope too broad** | Shared | Review capability scopes (dataset, space, table) vs. `all: {}` |

---

## 6. Validation Checklist

Evidence-oriented steps to verify security posture:

```mermaid
flowchart TD
    A[Start Validation] --> B{Conditional Access<br/>for Cognite app?}
    B -->|No| C[Configure CA policy]
    B -->|Yes| D[Identify user/SP<br/>effective memberships]
    D --> E[Verify CDF groups<br/>and capabilities]
    E --> F[Check scope on<br/>sensitive permissions]
    F --> G[Review audit logs]
    G --> H[Reproduce with<br/>test identity]
    H --> I[Document findings]
    C --> D
```

| Step | Action | Owner |
|------|--------|-------|
| 1 | Confirm Conditional Access policy for Cognite app (managed device, MFA, location/risk) | Sylvamo IT |
| 2 | Identify user/SP effective memberships in IdP | Sylvamo IT |
| 3 | Verify mapped CDF groups and their capabilities | Shared |
| 4 | Check scope on sensitive permissions (dataset vs. `all`) | Shared |
| 5 | Review audit logs for who accessed what, from where | Shared |
| 6 | Reproduce suspected access with a test identity (controlled) | Shared |
| 7 | Document findings and assign remediation | Shared |

---

## 7. Immediate Controls to Propose

| Control | Description | Owner |
|---------|-------------|-------|
| **Conditional Access** | Enforce managed-device-only access for CDF via IdP policy | Sylvamo IT |
| **Separate identities** | Ensure human and machine identities are distinct; no shared credentials | Shared |
| **Least privilege** | Remove broad `all` scopes where possible; apply dataset/space limits | Shared |
| **Access recertification** | Quarterly review of high-impact group memberships | Sylvamo IT |
| **Alerting** | Unusual sign-ins and privilege changes | Sylvamo IT |

---

## 8. Meeting Narrative

Suggested 3-part structure for the meeting:

### Part 1: Clarify the Concern

> "We take this seriously. We’re treating it as an identity and authorization validation exercise, not assuming a platform flaw."

### Part 2: Explain Architecture

> "CDF enforces group-based access. The device gate and sign-in policy are controlled by our IdP and Conditional Access. CDF does not bypass those policies."

### Part 3: Commit to Actions

> "We will run a focused audit and return with findings, remediation, and owners."

---

## 9. Q&A Prep

| Question | Suggested Answer |
|----------|------------------|
| **Can Cognite bypass our corporate access rules?** | Generally no. The login flow depends on your IdP policies. If unmanaged devices can log in, that is an IdP/ Conditional Access configuration choice. |
| **Why could someone see too much?** | Usually entitlement or mapping misconfiguration—e.g., user in an overly broad IdP group, or CDF group linked to the wrong IdP group. |
| **Can AI see data users cannot?** | No. Cognite’s AI uses identity delegation: it only sees data the logged-in user can access. |
| **Can we lock this down quickly?** | Yes. Conditional Access + least-privilege + mapping validation can be applied in a short cycle. |

---

## 10. Technical Deep Dive

### Groups and Capabilities

Each CDF group has a list of **capabilities** (ACLs). Each capability has:

- **Actions:** e.g. `READ`, `WRITE`, `LIST`, `CREATE`, `DELETE`
- **Scope:** limits where it applies (dataset, space, table, or `all`)

```mermaid
flowchart LR
    subgraph Group["CDF Group"]
        C1[extractionConfigsAcl: READ]
        C2[assetsAcl: READ, WRITE]
        C3[filesAcl: READ]
    end

    subgraph Scope["Scope Types"]
        S1[datasetScope]
        S2[spaceIdScope]
        S3[tableScope]
        S4[all]
    end

    C1 --> S1
    C2 --> S2
    C3 --> S4
```

### sourceId → IdP Group Link

```mermaid
flowchart TB
    subgraph AzureAD["Azure AD"]
        AADGroup[Azure AD Group<br/>Object ID: 94188b6a-...]
        User[User]
        SP[Service Principal]
    end

    subgraph CDF["CDF"]
        CDFGroup[gp_file_annotation<br/>sourceId = Object ID]
        Cap[Capabilities]
    end

    User --> AADGroup
    SP --> AADGroup
    AADGroup -->|"sourceId"| CDFGroup
    CDFGroup --> Cap
```

- `sourceId` on a CDF group = **Object ID** of the Azure AD group
- CDF syncs membership from that IdP group
- Users/SPs in the IdP group receive the CDF group’s capabilities

### Common Failure Modes (4xx)

| Failure | Cause | Fix |
|---------|-------|-----|
| **4xx on extraction pipeline config** | Workflow SP lacks `extractionConfigsAcl: READ` | Add SP to Azure AD group whose Object ID is the group’s `sourceId` |
| **403 Forbidden** | Identity not in group or group missing capability | Verify SP/user in Azure AD group; verify CDF group has required capability |
| **Group has no members** | `sourceId` placeholder or wrong Object ID | Set `groupSourceId` to correct Azure AD group Object ID |
| **401 Unauthorized** | Wrong credentials or token | Check `IDP_CLIENT_ID`, `IDP_CLIENT_SECRET`, `IDP_TENANT_ID` |

### Scoping Types (Least Privilege)

| Scope Type | Example | Use Case |
|------------|---------|----------|
| `all: {}` | Full access | Use sparingly; admin bootstrap only |
| `datasetScope: { ids: [ds_xxx] }` | Specific datasets | Extraction pipelines, workflows |
| `spaceIdScope: { spaceIds: [...] }` | Specific data model spaces | Transformations, data model access |
| `tableScope: { dbsToTables: {...} }` | Specific RAW tables | Extractor-specific access |

---

## References

- [CI/CD Overview](../cicd/CICD_OVERVIEW.md) — Pipeline auth, service principals
- [CI/CD Hands-On Learnings](../cicd/CICD_HANDS_ON_LEARNINGS.md) — CDF IAM groups, restricted capabilities
- [Pipeline Troubleshooting](../cicd/CICD_PIPELINE_TROUBLESHOOTING.md) — Invalid capabilities, 4xx handling
- Sylvamo IDL repo: `scripts/validate_file_annotation_permissions.py` — Example permission validation

---

*Last updated: February 2026*
