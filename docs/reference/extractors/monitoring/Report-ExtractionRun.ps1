<#
.SYNOPSIS
    Reports extraction run status to CDF Extraction Pipeline after a Fabric extractor task completes.

.DESCRIPTION
    This script is designed to be called after each Fabric extractor task (Task Scheduler or Python)
    completes. It reports success or failure to the corresponding CDF Extraction Pipeline, enabling
    heartbeat monitoring and email notifications.

    Can be used as a wrapper around the extractor or called as a post-run action.

.PARAMETER PipelineExternalId
    The CDF Extraction Pipeline external ID (e.g., ep_fabric_ppr_hourly, ep_fabric_sapecc_daily).

.PARAMETER Status
    The run status: "success", "failure", or "seen" (heartbeat).

.PARAMETER Message
    Optional message describing the run result (e.g., "Extracted 1000 rows" or error details).

.PARAMETER TaskName
    Optional Task Scheduler task name for automatic exit code detection.

.EXAMPLE
    # Report success after a task completes
    .\Report-ExtractionRun.ps1 -PipelineExternalId "ep_fabric_ppr_hourly" -Status "success" -Message "4 tables extracted"

.EXAMPLE
    # Auto-detect status from a scheduled task's last result
    .\Report-ExtractionRun.ps1 -PipelineExternalId "ep_fabric_sapecc_daily" -TaskName "FabricExtractor-SAPECC-BSEG"

.NOTES
    Requires: Python 3.11+ with cognite-sdk installed
    VM: PAMIDL02
    Related Jira: SVQS-229
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$PipelineExternalId,

    [Parameter(Mandatory=$false)]
    [ValidateSet("success", "failure", "seen")]
    [string]$Status,

    [Parameter(Mandatory=$false)]
    [string]$Message = "",

    [Parameter(Mandatory=$false)]
    [string]$TaskName
)

# If TaskName is provided, auto-detect status from last task result
if ($TaskName -and -not $Status) {
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($taskInfo) {
        if ($taskInfo.LastTaskResult -eq 0) {
            $Status = "success"
            $Message = "Task $TaskName completed successfully"
        } else {
            $Status = "failure"
            $Message = "Task $TaskName failed with exit code $($taskInfo.LastTaskResult)"
        }
    } else {
        $Status = "failure"
        $Message = "Task $TaskName not found"
    }
}

if (-not $Status) {
    Write-Error "Either -Status or -TaskName must be provided"
    exit 1
}

# Use Python to report to CDF (leverages existing cognite-sdk installation)
$pythonScript = @"
import os
from cognite.client import CogniteClient, ClientConfig
from cognite.client.credentials import OAuthClientCredentials
from cognite.client.data_classes import ExtractionPipelineRunWrite

# Authentication (same SP as Fabric extractors)
credentials = OAuthClientCredentials(
    token_url='https://login.microsoftonline.com/16e3985b-eba3-4a7c-85f6-3bdb7b08e7d2/oauth2/v2.0/token',
    client_id='60512cbe-ec0c-4422-826d-595366df62fe',
    client_secret=os.environ.get('CDF_CLIENT_SECRET', ''),
    scopes=['https://az-eastus-1.cognitedata.com/.default']
)

client = CogniteClient(ClientConfig(
    client_name='extractor-monitor',
    project='sylvamo-dev',
    credentials=credentials
))

# Report run
run = ExtractionPipelineRunWrite(
    extpipe_external_id='$PipelineExternalId',
    status='$Status',
    message='$Message'
)
client.extraction_pipelines.runs.create(run)
print(f"Reported {run.status} for {run.extpipe_external_id}")
"@

# Execute via Python
$pythonScript | C:\Python311\python.exe -
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Failed to report extraction run to CDF"
}
