<#
.SYNOPSIS
    Memory-aware orchestrator for running Fabric extractor tasks sequentially.

.DESCRIPTION
    Runs Fabric extractor tasks one at a time, checking available memory before
    each table and waiting if memory is low. Prevents OOM cascading failures.

    Designed for the SAP ECC daily batch (324 tables) and retry scenarios.

.PARAMETER Tables
    Array of table names to process. If not provided, runs all failed SAPECC tasks.

.PARAMETER MinMemoryMB
    Minimum available memory (MB) required before starting next table. Default: 1500.

.PARAMETER CooldownSeconds
    Seconds to wait between tables for memory cleanup. Default: 30.

.PARAMETER MaxWaitMinutes
    Maximum minutes to wait for memory to free up before skipping a table. Default: 10.

.PARAMETER UsePython
    Force use of 64-bit Python extractor instead of Task Scheduler. Default: true.

.EXAMPLE
    .\Run-MemoryAwareExtraction.ps1
    # Retries all failed SAPECC tables with memory protection

.EXAMPLE
    .\Run-MemoryAwareExtraction.ps1 -Tables @('BSEG','MSEG','EKPO') -MinMemoryMB 2000
    # Retries specific tables with higher memory threshold

.NOTES
    VM: PAMIDL02
    Related Jira: SVQS-229
#>

param(
    [string[]]$Tables,
    [int]$MinMemoryMB = 1500,
    [int]$CooldownSeconds = 30,
    [int]$MaxWaitMinutes = 10,
    [bool]$UsePython = $true
)

function Get-AvailableMemoryMB {
    $os = Get-CimInstance Win32_OperatingSystem
    return [math]::Round($os.FreePhysicalMemory / 1024)
}

function Wait-ForMemory {
    param([int]$MinMB, [int]$MaxWaitMin)
    $waited = 0
    $availMB = Get-AvailableMemoryMB
    while ($availMB -lt $MinMB -and $waited -lt ($MaxWaitMin * 60)) {
        Write-Host "  Memory: ${availMB}MB < ${MinMB}MB threshold. Waiting 30s... ($([math]::Round($waited/60,1))m/$MaxWaitMin m)" -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        [System.GC]::Collect()
        $waited += 30
        $availMB = Get-AvailableMemoryMB
    }
    if ($availMB -lt $MinMB) {
        Write-Host "  Memory still low after ${MaxWaitMin}m: ${availMB}MB" -ForegroundColor Red
        return $false
    }
    return $true
}

# If no tables specified, find all failed SAPECC tasks
if (-not $Tables) {
    Write-Host "Finding failed SAPECC tasks..."
    $Tables = @()
    Get-ScheduledTask | Where-Object { $_.TaskName -like "FabricExtractor-SAPECC-*" } | ForEach-Object {
        $info = Get-ScheduledTaskInfo -TaskName $_.TaskName
        if ($info.LastTaskResult -ne 0) {
            $Tables += $_.TaskName -replace 'FabricExtractor-SAPECC-', ''
        }
    }
    Write-Host "Found $($Tables.Count) failed tables"
}

if ($Tables.Count -eq 0) {
    Write-Host "No tables to process!" -ForegroundColor Green
    exit 0
}

Write-Host "============================================="
Write-Host "  Memory-Aware Extraction"
Write-Host "  $($Tables.Count) tables | Min memory: ${MinMemoryMB}MB"
Write-Host "  Cooldown: ${CooldownSeconds}s | Max wait: ${MaxWaitMinutes}m"
Write-Host "  Mode: $(if ($UsePython) { '64-bit Python' } else { 'Task Scheduler' })"
Write-Host "============================================="

$success = 0; $fail = 0; $skip = 0; $i = 0

foreach ($table in $Tables) {
    $i++
    $availMB = Get-AvailableMemoryMB

    Write-Host "`n$(Get-Date -Format 'HH:mm:ss') [$i/$($Tables.Count)] $table (memory: ${availMB}MB)"

    # Wait for memory if needed
    if (-not (Wait-ForMemory -MinMB $MinMemoryMB -MaxWaitMin $MaxWaitMinutes)) {
        Write-Host "  SKIP $table (insufficient memory after waiting)" -ForegroundColor Red
        $skip++
        continue
    }

    if ($UsePython) {
        # Find config file
        $configs = @(
            "C:\Cognite\FabricExtractor\configs\sapecc-$($table.ToLower()).yaml",
            "C:\Cognite\FabricExtractor\configs\sapecc-$($table).yaml",
            "C:\Cognite\FabricExtractor\configs\gold-$($table.ToLower()).yaml",
            "C:\Cognite\FabricExtractor\configs\gold-$($table).yaml"
        )
        $config = $configs | Where-Object { Test-Path $_ } | Select-Object -First 1

        if (-not $config) {
            Write-Host "  SKIP $table (no config found)" -ForegroundColor Yellow
            $skip++
            continue
        }

        $startTime = Get-Date
        Write-Host "  Running Python extractor..." -NoNewline
        & C:\Python311\python.exe C:\Cognite\FabricExtractor\fabric_delta_extractor.py --config $config 2>&1 | Out-Null
        $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)

        if ($LASTEXITCODE -eq 0) {
            Write-Host " OK (${elapsed}m)" -ForegroundColor Green
            $success++
        } else {
            Write-Host " FAIL (exit=$LASTEXITCODE, ${elapsed}m)" -ForegroundColor Red
            $fail++
        }
    } else {
        # Use Task Scheduler (32-bit connector)
        $taskName = "FabricExtractor-SAPECC-$table"
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if (-not $task) {
            Write-Host "  SKIP $table (no scheduled task)" -ForegroundColor Yellow
            $skip++
            continue
        }
        Start-ScheduledTask -TaskName $taskName
        Write-Host "  Started $taskName, waiting..." -NoNewline
        do { Start-Sleep -Seconds 10 } while ((Get-ScheduledTask -TaskName $taskName).State -eq 'Running')
        $info = Get-ScheduledTaskInfo -TaskName $taskName
        if ($info.LastTaskResult -eq 0) {
            Write-Host " OK" -ForegroundColor Green
            $success++
        } else {
            Write-Host " FAIL (exit=$($info.LastTaskResult))" -ForegroundColor Red
            $fail++
        }
    }

    # Cooldown between tables
    Write-Host "  Cooldown ${CooldownSeconds}s..."
    [System.GC]::Collect()
    Start-Sleep -Seconds $CooldownSeconds
}

Write-Host "`n============================================="
Write-Host "Done: $success OK, $fail failed, $skip skipped out of $($Tables.Count)"
Write-Host "Final memory: $(Get-AvailableMemoryMB) MB"
Write-Host "============================================="
