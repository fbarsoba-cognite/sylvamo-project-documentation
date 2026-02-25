# PR #992 / SVQS-282: Virtual Instrumentation Tags — Explanation for Max

**Date:** 2026-02-23  
**Jira:** [SVQS-282](https://cognitedata.atlassian.net/browse/SVQS-282)  
**ADO PR:** [#992](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/992)

This document summarizes the SVQS-282 changes and the **array_union fix** (from Max's PR review). Full technical detail is in [VIRTUAL_INSTRUMENTATION_TAGS.md](../reference/data-model/VIRTUAL_INSTRUMENTATION_TAGS.md).

---

## What does populate_TimeSeries actually do?

**populate_TimeSeries** creates `MfgTimeSeries` nodes in the data model from CDF's classic time series (`_cdf.timeseries`). It runs on a schedule and re-processes **all** time series each run.

- **Source:** `_cdf.timeseries` (PI, Proficy, lab, etc.)
- **Target:** `MfgTimeSeries` view
- **Sets:** name, description, type, isStep, timeSeries (sparkline), piTagName, measurementType, and **assets**
- **assets logic:** For PI tags, adds vtag reference + PM-level FLOC; uses `array_union` to **merge** with existing assets instead of overwriting

---

## The array_union fix (Max's review)

**Problem:** The original PR replaced `assets` with `array(vtag)`, wiping out existing FLOC links from entity matching and manual mappings (e.g. SVQS-283).

**Fix:** Both `populate_TimeSeries` and `recontextualize_TimeSeries` now:
1. Self-join to existing `MfgTimeSeries` via `cdf_nodes()`
2. Use `array_union(coalesce(existing_assets, array()), array(new_refs))` to merge
3. Preserve all existing links (FLOC, vtag, manual mappings)

**Example (471BW229):**
- Before PR: `assets = [floc:0769-06-01-010-015-045]` (from manual mapping)
- Original PR (broken): `assets = [vtag:471BW229]` (FLOC lost)
- After fix: `assets = [vtag:471BW229, floc:0769-06-01-010-015-045, floc:0769-06-01-010]` (all preserved)

---

## Transformation pipeline (6 steps)

1. **populate_Asset** — SAP FLOCs
2. **populate_VirtualInstrumentationTags** — vtag assets from PI tags
3. **generate_VirtualTag_Aliases** — aliases for P&ID matching
4. **populate_TimeSeries** — MfgTimeSeries with assets = array_union(existing, [vtag + PM FLOC])
5. **recontextualize_TimeSeries** — adds vtag to Anvar's 210 curated tags (array_union)
6. **Entity Matching / Manual Mappings** — deeper FLOC links (preserved)

---

## References

- **Full doc:** [VIRTUAL_INSTRUMENTATION_TAGS.md](../reference/data-model/VIRTUAL_INSTRUMENTATION_TAGS.md)
- **SQL details:** [TRANSFORMATIONS.md §4.3](../reference/data-model/TRANSFORMATIONS.md#43-timeseries-transformation)
- **Contextualization plan:** [contextualization-improvement-plan.md](contextualization-improvement-plan.md)
