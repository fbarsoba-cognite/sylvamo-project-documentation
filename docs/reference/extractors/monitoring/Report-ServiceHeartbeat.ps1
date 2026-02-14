<#
.SYNOPSIS
    Reports heartbeat ("seen") status for continuous extractor services to CDF Extraction Pipelines.

.DESCRIPTION
    This script checks the status of continuous extractor services (PI, FabricConnector, DBExtractor)
    and reports a "seen" heartbeat to their corresponding CDF Extraction Pipelines.

    Designed to run as a Windows Scheduled Task every 10 minutes alongside the Extractor-Watchdog.

.NOTES
    Requires: Python 3.11+ with cognite-sdk installed
    VM: PAMIDL02
    Related Jira: SVQS-229

.EXAMPLE
    # Register as a scheduled task
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File C:\Cognite\Scripts\Report-ServiceHeartbeat.ps1"
    $trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 10) -Once -At (Get-Date)
    Register-ScheduledTask -TaskName "Extractor-Heartbeat-Reporter" -Action $action -Trigger $trigger -RunLevel Highest -User "SYSTEM"
#>

# Map service names to CDF Extraction Pipeline external IDs
$serviceMap = @{
    'PiExtractor-S769PI01' = 'ep_pi_s769pi01'
    'PiExtractor-S769PI03' = 'ep_pi_s769pi03'
    'PiExtractor-S519PIP1' = 'ep_pi_s519pip1'
    'FabricConnector'      = 'ep_fabric_ppr_hist_reel'
    'DBExtractor'          = 'ep_db_extractor'
    'FileExtractor'        = 'ep_file_extractor'
}

# Check each service and build report
$reports = @()
foreach ($svc in $serviceMap.GetEnumerator()) {
    $service = Get-Service -Name $svc.Key -ErrorAction SilentlyContinue
    if ($service) {
        $status = if ($service.Status -eq 'Running') { 'seen' } else { 'failure' }
        $message = if ($service.Status -eq 'Running') {
            "Service $($svc.Key) running"
        } else {
            "Service $($svc.Key) is $($service.Status)"
        }
        $reports += @{
            ExternalId = $svc.Value
            Status     = $status
            Message    = $message
        }
    }
}

if ($reports.Count -eq 0) {
    Write-Host "No extractor services found"
    exit 0
}

# Build Python script to report all heartbeats in one batch
$pythonReports = ($reports | ForEach-Object {
    "    ExtractionPipelineRunWrite(extpipe_external_id='$($_.ExternalId)', status='$($_.Status)', message='$($_.Message)')"
}) -join ",`n"

$pythonScript = @"
import os
from cognite.client import CogniteClient, ClientConfig
from cognite.client.credentials import OAuthClientCredentials
from cognite.client.data_classes import ExtractionPipelineRunWrite

credentials = OAuthClientCredentials(
    token_url='https://login.microsoftonline.com/16e3985b-eba3-4a7c-85f6-3bdb7b08e7d2/oauth2/v2.0/token',
    client_id='60512cbe-ec0c-4422-826d-595366df62fe',
    client_secret=os.environ.get('CDF_CLIENT_SECRET', ''),
    scopes=['https://az-eastus-1.cognitedata.com/.default']
)

client = CogniteClient(ClientConfig(
    client_name='extractor-heartbeat',
    project='sylvamo-dev',
    credentials=credentials
))

runs = [
$pythonReports
]

result = client.extraction_pipelines.runs.create(runs)
for r in runs:
    print(f"Reported {r.status} for {r.extpipe_external_id}")
"@

$pythonScript | C:\Python311\python.exe -
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Failed to report heartbeats to CDF"
}
