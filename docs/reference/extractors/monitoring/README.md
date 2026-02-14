# Extraction Pipeline Monitoring Scripts

Scripts for reporting extractor health to CDF Extraction Pipelines on PAMIDL02 VM.

Related Jira: [SVQS-229](https://cognitedata.atlassian.net/browse/SVQS-229)

## Overview

These scripts enable CDF to monitor all extractors on the VM and send email notifications when extractors fail or stop reporting.

## Scripts

### Report-ServiceHeartbeat.ps1

Reports "seen" (heartbeat) status for all **continuous** extractor services every 10 minutes.

**Services monitored:**
- PiExtractor-S769PI01, S769PI03, S519PIP1
- FabricConnector (ppr_hist_reel)
- DBExtractor
- FileExtractor

**Setup:**
```powershell
# Copy to VM
Copy-Item Report-ServiceHeartbeat.ps1 C:\Cognite\Scripts\

# Register scheduled task
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -File C:\Cognite\Scripts\Report-ServiceHeartbeat.ps1"
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 10) -Once -At (Get-Date)
Register-ScheduledTask -TaskName "Extractor-Heartbeat-Reporter" `
    -Action $action -Trigger $trigger -RunLevel Highest -User "SYSTEM" `
    -Description "Reports service heartbeats to CDF Extraction Pipelines"
```

### Report-ExtractionRun.ps1

Reports success/failure for **scheduled** Fabric extractor tasks after each run.

**Usage:**
```powershell
# After a successful extraction
.\Report-ExtractionRun.ps1 -PipelineExternalId "ep_fabric_ppr_hourly" -Status "success" -Message "4 tables OK"

# Auto-detect from task exit code
.\Report-ExtractionRun.ps1 -PipelineExternalId "ep_fabric_sapecc_daily" -TaskName "FabricExtractor-SAPECC-BSEG"
```

## PI Extractor Native Support

PI extractors support extraction pipelines natively. Add this to each PI extractor's `config.yml` on the VM:

```yaml
extraction-pipeline:
    external-id: ep_pi_s769pi01    # Match the CDF pipeline externalId
    frequency: 600                  # Heartbeat every 10 minutes (seconds)
```

When native PI pipeline reporting is configured, the PI services do NOT need the heartbeat script -- they report directly.

## Prerequisites

- Python 3.11+ with `cognite-sdk` installed (already on PAMIDL02)
- `CDF_CLIENT_SECRET` environment variable set for the service principal
- CDF Extraction Pipelines created via `cdf deploy` (see module `cdf_extractor_pipelines`)

## Architecture

```
                    ┌─────────────────────────────┐
                    │     CDF Extraction Pipelines │
                    │  ┌─────────┐  ┌───────────┐ │
                    │  │ ep_pi_* │  │ ep_fabric_*│ │
                    │  └────▲────┘  └─────▲─────┘ │
                    │       │             │        │
                    │  Email notifications if      │
                    │  heartbeat/run missing        │
                    └───────┼─────────────┼────────┘
                            │             │
            ┌───────────────┼─────────────┼──────────────┐
            │   PAMIDL02 VM │             │              │
            │               │             │              │
            │  PI Extractors│  Heartbeat  │  Run Report  │
            │  (native)─────┘  Script─────┘  Script      │
            │                  (10 min)      (post-task)  │
            │                                             │
            │  ┌──────────────────────────────────────┐   │
            │  │ Extractor-Watchdog (restarts stopped) │   │
            │  └──────────────────────────────────────┘   │
            └─────────────────────────────────────────────┘
```
