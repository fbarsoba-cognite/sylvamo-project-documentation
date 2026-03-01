# Changelog — Page 4

---

### [SVQS-313] Grafana Observability — Composite Heartbeat for Extractor Monitoring
**Date:** 2026-02-28 23:30 (EST)
**Jira:** [SVQS-313](https://cognitedata.atlassian.net/browse/SVQS-313)
**ADO PRs:** [PR #1050](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/1050), [PR #1051](https://dev.azure.com/SylvamoCorp/Industrial-Data-Landscape-IDL/_git/Industrial-Data-Landscape-IDL/pullrequest/1051)

**Changes:**
- Rewired 3 Grafana dashboards (fleet, detail, data_flow) from TestData to Cognite CDF datasource
- Added 17 Grafana alert rules across 4 categories (offline, error rate, throughput, missed schedule)
- Enhanced `fn_monitoring_metrics` with composite heartbeat: pipeline runs -> RAW delta -> PI state store -> RAW table activity
- Added `_extractor_has_recent_raw_activity` fallback using `min_last_updated_time` filter (25h window)
- Created VM PowerShell scripts (`Add-PipelineReporting.ps1`, `Add-FabricPipelineReporting.ps1`) for adding extraction-pipeline config to all extractors

**Why:**
- Extractors don't support the `extraction-pipeline` reporting feature (version incompatibility), so pipeline runs are always empty
- Composite heartbeat derives extractor liveness from alternative signals: RAW row deltas, PI state store recency, and RAW table `last_updated_time`
- Result: 8/10 extractors correctly show ONLINE; 2 remaining OFFLINE are legitimate (no recent activity / service stopped)
