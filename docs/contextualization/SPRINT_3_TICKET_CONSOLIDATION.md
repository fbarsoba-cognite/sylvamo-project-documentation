# Sprint 3 Contextualization Ticket Consolidation

**Generated:** 2026-02-24 21:21

This report supersedes the previous SPRINT_3_CONTEXTUALIZATION_AUDIT.md (removed), which used unreliable keyword matching. This analysis uses curated mapping based on ticket semantics and Darren's guidance from Feb 19, 23, 24 transcripts.

---

## 1. Contextualization Tickets (16 labeled)

| Key | Summary | Status | Assignee | Mapped Items |
|-----|---------|--------|----------|--------------|
| SVQS-282 | Implement Virtual Instrumentation Tags for PI Tag ... | In Progress | Fernando Barsoba | phase2:2.1, phase2:2.2, phase2:2.3, phase2:2.4, phase2:2.5, phase2:2.6, phase2:2.8, phase2:2.9 (+4 more) |
| SVQS-263 | Run file annotation pipeline on all documents | In Progress | Fernando Barsoba | phase1:1.1, phase1:1.2, phase1:1.9, phase3:3.1, phase3:3.2, phase3:3.3, phase3:3.4, phase3:3.5 (+3 more) |
| SVQS-235 | Critical for UC1 & 2: Contextualize Time Series (P... | In Progress | Max Tollefsen | phase2:2.1, phase2:2.2, phase2:2.3, phase2:2.7 |
| SVQS-258 | Evaluate equipment table for additional contextual... | In Progress | Fernando Barsoba | phase4:4.1, phase4:4.2, phase4:4.3, phase4:4.4 |
| SVQS-264 | Show before/after contextualization improvement me... | To Do | Fernando Barsoba | crosscutting:5.1, crosscutting:5.5, crosscutting:5.6, crosscutting:5.7, phase3:3.2 |
| SVQS-234 | Refine contextualization P&IDs (Asset Tag Matching... | In Progress | Max Tollefsen | phase3:3.5, phase3:3.9, phase1:1.4, crosscutting:5.7 |
| SVQS-233 | Contextualize Files to Assets (Non-P&IDs, Document... | To Do | Max Tollefsen | phase1:1.5, phase3:3.9 |
| SVQS-280 | Files to Assets - SOPs, P&IDs, etc. - Contextualiz... | To Do | Santiago Espinosa | phase1:1.5, phase3:3.9, phase3:3.10, phase3:3.11 |
| SVQS-231 | Contextualize File to File Linking within P&IDs | In Progress | Max Tollefsen | — |
| SVQS-219 | Critical for UC 1&2, Refine: Categorize PI tags | In Progress | Max Tollefsen | phase2:2.1, phase2:2.4, phase2:2.8, phase2:2.9 |
| SVQS-174 | Contextualize Production Orders | In Progress | Fernando Barsoba | — |
| SVQS-173 | Critical for UC1: Contextualize Purchasing and Pro... | In Progress | Fernando Barsoba | — |
| SVQS-164 | UC2: Create Separate Extension for Scanner Time Se... | To Do | Fernando Barsoba | phase2:2.8 |
| SVQS-159 | Validate Search Experience: End-to-End Demo | To Do | Elise Buck | crosscutting:5.1 |
| SVQS-138 | Verify Contextualization of work orders | To Do | Max Tollefsen | — |
| SVQS-136 | Determine Contextualization Approach | To Do | Max Tollefsen | — |

---

## 2. Workstream Groupings

### A: Foundation / Aliases (Phase 1)

- **Primary:** SVQS-263
- **Related:** SVQS-282

### B: Time Series / Virtual Tags (Phase 2)

- **Primary:** SVQS-282, SVQS-235, SVQS-219
- **Related:** SVQS-164

### C: File Annotation / P&ID Refinement (Phase 3)

- **Primary:** SVQS-263, SVQS-234
- **Related:** SVQS-280, SVQS-233, SVQS-231

### D: Equipment (Phase 4)

- **Primary:** SVQS-258
- **Related:** —

### E: Metrics / Reporting (Cross-cutting)

- **Primary:** SVQS-264
- **Related:** —

### Other / Entity Matching

- **Primary:** SVQS-174, SVQS-173
- **Related:** SVQS-138

### Candidates for closure/merge

- **Primary:** —
- **Related:** SVQS-136, SVQS-159

---

## 3. Phase-by-Phase Coverage Matrix (Curated)

| Ground Truth Item | Tickets |
|-------------------|---------|
| phase1 1.1: Deploy File Annotation pipeline and Streamlit app | SVQS-263 |
| phase1 1.2: Ensure assets have DetectInDiagrams tag | SVQS-263 |
| phase1 1.3: Populate aliases via Key Extraction and Aliasing pipeli... | SVQS-282 |
| phase1 1.4: Generate aliases from asset tag name field | SVQS-282, SVQS-234 |
| phase1 1.5: Asset hierarchy: functional locations and equipment as ... | SVQS-233, SVQS-280 |
| phase1 1.6: Use equipment record for equipment table (serial, model... | — |
| phase1 1.7: Specify which field pipeline looks at for aliases (defa... | SVQS-282 |
| phase1 1.8: Handle duplicate sort fields; isolation for cross-site ... | — |
| phase1 1.9: Fix file annotation workflow (extraction runs, file tag... | SVQS-263 |
| phase1 1.10: Clean up asset hierarchy presentation | — |
| phase2 2.1: Create virtual/synthetic tags for time series instrumen... | SVQS-282, SVQS-235, SVQS-219 |
| phase2 2.2: Create discrete instrumentation tags under FLs (not hig... | SVQS-282, SVQS-235 |
| phase2 2.3: Recontextualize time series to virtual tags (~100% targ... | SVQS-282, SVQS-235 |
| phase2 2.4: Option A: Create tags from TS names in dedicated space ... | SVQS-282, SVQS-219 |
| phase2 2.5: Option B: P&ID hierarchy - Create asset hierarchy from ... | SVQS-282 |
| phase2 2.6: Location config: define sites/areas/systems, file names... | SVQS-282 |
| phase2 2.7: P&ID-to-hierarchy mapping (manual or automated) | SVQS-235 |
| phase2 2.8: Exclude calculated/system-generated TS from contextuali... | SVQS-282, SVQS-219, SVQS-164 |
| phase2 2.9: Use time series as source of truth for virtual tags | SVQS-282, SVQS-219 |
| phase2 2.10: Validate P&ID-extracted tags against known time series | SVQS-282 |
| phase3 3.1: Run file annotation pipeline after aliases and virtual ... | SVQS-263 |
| phase3 3.2: Run baseline metrics before applying changes | SVQS-263, SVQS-264 |
| phase3 3.3: Use Streamlit dashboard for refinement (patterns, canva... | SVQS-263 |
| phase3 3.4: Iterate on aliases and patterns to improve scores | SVQS-263 |
| phase3 3.5: Configure pattern extraction (1-3 alpha, 1-4 numeric pe... | SVQS-263, SVQS-234 |
| phase3 3.6: Use pattern-generation function against asset hierarchy | SVQS-263 |
| phase3 3.7: Implement whitelist - derank tags not matching naming c... | SVQS-263 |
| phase3 3.8: Three-step flow: extract, create hierarchy, persist | SVQS-263 |
| phase3 3.9: Scope file contextualization to correct asset sub-tree ... | SVQS-234, SVQS-233, SVQS-280 |
| phase3 3.10: Shared utilities: include all relevant sub-trees | SVQS-280 |
| phase3 3.11: Design for expansion - isolation from start | SVQS-280 |
| phase4 4.1: Get equipment table from SAP/Fabric (EQUI) | SVQS-258 |
| phase4 4.2: Evaluate equipment tech_id for additional tag values | SVQS-258 |
| phase4 4.3: Create assets from equipment if more tag values | SVQS-258 |
| crosscutting 5.1: Exhaust all avenues before showing client - first impre... | SVQS-264, SVQS-159 |
| crosscutting 5.2: Present missing-tags info before end of quick start | — |
| crosscutting 5.3: Frame: I detected X tags, you had Y in source | — |
| crosscutting 5.4: Offer options: load missing tags or create virtual tags | — |
| crosscutting 5.5: Clarify quantity vs quality when reporting | SVQS-264 |
| crosscutting 5.6: File annotation: measure detection vs existence | SVQS-264 |
| crosscutting 5.7: Metadata/entity matching: measure relationships and mat... | SVQS-264, SVQS-234 |
| crosscutting 5.8: Communicate virtual-tag approach to Sylvamo | — |
| crosscutting 5.9: Pull in Jack Zho when pipeline deployed for config help | — |

---

## 4. Gaps (Darren Items with NO Ticket Coverage)

| Phase | Item | Description | Priority |
|-------|------|-------------|----------|
| phase1 | 1.6 | Use equipment record for equipment table (serial, model, man... | important |
| phase1 | 1.8 | Handle duplicate sort fields; isolation for cross-site dedup... | important |
| phase1 | 1.10 | Clean up asset hierarchy presentation | nice-to-have |
| crosscutting | 5.2 | Present missing-tags info before end of quick start | important |
| crosscutting | 5.3 | Frame: I detected X tags, you had Y in source | important |
| crosscutting | 5.4 | Offer options: load missing tags or create virtual tags | important |
| crosscutting | 5.8 | Communicate virtual-tag approach to Sylvamo | important |
| crosscutting | 5.9 | Pull in Jack Zho when pipeline deployed for config help | nice-to-have |

---

## 5. Recommendations

### Consolidation

- **SVQS-136** (Determine Contextualization Approach): Superseded by SVQS-282, 263, 235, etc. Consider closing as duplicate.
- **SVQS-138** (Verify work orders): Clarify scope or merge into SVQS-174 (Production Orders) if same entity-matching domain.
- **SVQS-280** and **SVQS-233**: Both cover Files-to-Assets for non-P&IDs. Consider merging or clarifying: 280 = approach, 233 = execution.

### Gaps to Address

- **1.3, 1.4, 1.7** (Aliases): Add as sub-tasks to SVQS-282 or SVQS-263.
- **1.8** (Duplicate sort fields): Create sub-task or new ticket if blocking.
- **1.10** (Clean up asset hierarchy): Defer or add to SVQS-282.
- **2.6** (Location config): Add to SVQS-282 or create dedicated ticket for P&ID-to-hierarchy mapping.
- **3.10, 3.11** (Shared utilities, design for expansion): Add to SVQS-280 scope.
- **5.2–5.4, 5.8** (Client communication): No ticket. Consider adding to SVQS-264 (metrics) or creating a stakeholder-communication ticket.
- **5.9** (Jack Zho): Operational note, not a ticket.

### Reference

- Ground truth from `docs/contextualization/` transcripts (Feb 19, 23, 24)
- [CONTEXTUALIZATION_NEXT_STEPS.md](https://github.com/fbarsoba-cognite/sylvamo-project-documentation/blob/main/docs/contextualization/contextualization-improvement-plan.md)
