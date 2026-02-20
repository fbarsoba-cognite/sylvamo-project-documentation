# ADR-002: Virtual Instrumentation Tags for Time Series Contextualization

## Status

**Accepted** — February 19, 2026

## Context

### What Is Contextualization in CDF?

In Cognite Data Fusion (CDF), **contextualization** means linking data (such as time series, events, and files) to assets in the asset hierarchy. When data is contextualized, users can:

- Search for an asset and see all related time series, documents, and events
- Click an equipment symbol on a P&ID and see its live sensor data
- Navigate from a time series to the physical location or equipment it represents

Without contextualization, data exists in silos and is hard to discover or relate to the physical plant.

### The Problem: SAP Does Not Track Instrumentation

SAP (and Fabric, which hosts Sylvamo's SAP data) tracks **functional locations** (FLOCs) and **major equipment** (pumps, motors, valves) in the asset hierarchy. However, SAP **does not track instrumentation** — transmitters, sensors, control valves, flow meters, temperature probes, and similar devices that generate process data.

This is **universal across all SAP-based industrial clients**, not specific to Sylvamo. Instrumentation is typically managed in separate systems (PI System, DCS, historians) and is rarely modeled in SAP's asset management module.

### Consequences of the Gap

1. **PI time series have no discrete asset to link to.** PI tag names like `471MR325` or `472-PT-101-A` represent specific instruments on the plant floor. There are no corresponding assets in the SAP-derived hierarchy to contextualize them against.

2. **Time series were mapped to high-level Paper Machine assets.** As a workaround, we initially linked PI time series to PM1 or PM2 (Paper Machine 1/2) based on tag prefix. This meant every search for a specific instrument (e.g., "471MR325") would not return its time series, because the link was only at the PM level.

3. **P&ID annotation could not match instrumentation.** The file annotation pipeline (for P&IDs) detects tag-shaped text in diagrams and matches it against assets in the hierarchy. It can only annotate tags that **exist as assets**. Without discrete instrument assets, all instrumentation circles and bubbles on P&IDs were undetectable — the pipeline had nothing to match against.

4. **Gap analysis was impossible.** We could not measure "how many instruments on this P&ID are contextualized" because instruments were not in the hierarchy at all.

## Decision

We create **virtual (synthetic) assets** for each PI time series tag, placed under the appropriate functional location based on a prefix-to-FLOC mapping.

### Implementation Details

1. **One virtual asset per PI tag** — Each PI time series (e.g., `pi:471MR325`) gets a corresponding Asset node with external ID `vtag:471MR325`.

2. **Parent placement via prefix mapping** — Virtual tags are placed as leaf nodes under the correct functional location:

   | PI Prefix | Parent FLOC (external ID) | Description | Tag Count |
   |-----------|----------------------------|-------------|-----------|
   | 471* | floc:0769-06-01-010 | Paper Machine 1 | 1,725 |
   | 472* | floc:0769-06-01-020 | Paper Machine 2 | 1,708 |
   | 460* | floc:0769-06-01-010 | PM1 Chemical Additives | 11 |
   | 461* | floc:0769-06-01-020 | PM2 Chemical Additives | 5 |
   | 311* | floc:0769 | Eastover Mill root | 1 |
   | 402* | floc:0769 | Eastover Mill root | 1 |

3. **Clear marking as virtual** — Each virtual asset has:
   - `assetType = 'VirtualInstrument'`
   - `sourceId = 'virtual:{original_external_id}'` (e.g., `virtual:pi:471MR325`)

4. **Aliases for matching** — Virtual tags get aliases matching the PI tag name (uppercase, with and without hyphens/underscores) so entity matching and diagram detection can use them.

5. **Time series reference virtual tags** — The `populate_TimeSeries` transformation is updated to set `assets` to the `vtag:` reference instead of the PM-level FLOC.

6. **External ID convention** — `vtag:{PI_TAG_NAME}` (e.g., `vtag:471MR325`).

## Consequences

### Benefits

- **100% discrete time series match** — Every PI time series now links to a specific instrument asset, not a coarse PM-level node.
- **P&ID annotation improvement** — Diagram detection can match all instrumentation circles and bubbles because virtual tags provide aliases for every instrument. (Darren Downtain demonstrated this with the Lion Delasel example: scores jumped from 67% to 93% after adding virtual tags.)
- **Gap analysis capability** — We can measure contextualization completeness: "We detected 1,000 tags and matched 900" becomes meaningful.
- **CDF search returns correct results** — Searching for a specific instrument (e.g., `471MR325`) returns its time series data.

### Tradeoffs

- **~3,468 additional asset nodes** — Negligible storage impact for CDF.
- **Not SAP-managed** — Virtual tags are synthetic; they will not auto-update if SAP changes. They must be maintained by the transformation pipeline.
- **Must be marked clearly** — `assetType` and `sourceId` distinguish virtual tags from real SAP-sourced assets so downstream processes and users understand their origin.

### Future Considerations

When Sylvamo adds instrumentation to SAP (or another source of truth), virtual tags can be phased out. The `populate_TimeSeries` logic can be updated to reference real instrument assets instead of virtual ones. The virtual tag approach is a bridge until authoritative instrumentation data exists.

## References

- **Jira:** [SVQS-261](https://cognitedata.atlassian.net/browse/SVQS-261)
- **Related:** Darren Downtain (SA Lead, Americas) review session, February 19, 2026
- **Implementation:** `populate_VirtualInstrumentationTags.Transformation.sql`, `populate_TimeSeries.Transformation.sql`
