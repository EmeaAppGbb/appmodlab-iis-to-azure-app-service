<#
.SYNOPSIS
    Swaps a staging deployment slot to production with health-check validation.

.DESCRIPTION
    Performs a zero-downtime slot swap for an Azure App Service.
    Validates health of both staging (pre-swap) and production (post-swap)
    endpoints before and after the swap operation.

.PARAMETER AppName
    The name of the Azure App Service.

.PARAMETER ResourceGroup
    The Azure resource group containing the App Service.

.PARAMETER SlotName
    The source slot to swap into production. Defaults to 'staging'.

.PARAMETER HealthPath
    The path to use for health checks. Defaults to '/'.

.PARAMETER MaxRetries
    Maximum number of health-check retry attempts. Defaults to 10.

.PARAMETER RetryDelaySec
    Seconds to wait between health-check retries. Defaults to 15.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [string]$SlotName = 'staging',

    [string]$HealthPath = '/',

    [int]$MaxRetries = 10,

    [int]$RetryDelaySec = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-EndpointHealth {
    param(
        [string]$Url,
        [int]$MaxRetries,
        [int]$RetryDelaySec
    )

    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
                Write-Host "  Health check passed (HTTP $($response.StatusCode))"
                return $true
            }
            Write-Host "  Attempt ${i}/${MaxRetries}: HTTP $($response.StatusCode)"
        }
        catch {
            Write-Host "  Attempt ${i}/${MaxRetries}: $($_.Exception.Message)"
        }

        if ($i -lt $MaxRetries) {
            Start-Sleep -Seconds $RetryDelaySec
        }
    }

    return $false
}

# ── Pre-swap: Validate staging slot is healthy ──
$stagingUrl = "https://${AppName}-${SlotName}.azurewebsites.net${HealthPath}"
Write-Host "Pre-swap health check: $stagingUrl"

$stagingHealthy = Test-EndpointHealth -Url $stagingUrl -MaxRetries $MaxRetries -RetryDelaySec $RetryDelaySec
if (-not $stagingHealthy) {
    Write-Error "Staging slot health check failed. Aborting swap."
    exit 1
}

# ── Execute slot swap ──
Write-Host "`nSwapping slot '$SlotName' to production for '$AppName'..."
az webapp deployment slot swap `
    --name $AppName `
    --resource-group $ResourceGroup `
    --slot $SlotName `
    --target-slot production

if ($LASTEXITCODE -ne 0) {
    Write-Error "Slot swap failed with exit code $LASTEXITCODE."
    exit 1
}

Write-Host "Slot swap completed successfully.`n"

# ── Post-swap: Validate production is healthy ──
$productionUrl = "https://${AppName}.azurewebsites.net${HealthPath}"
Write-Host "Post-swap health check: $productionUrl"

$productionHealthy = Test-EndpointHealth -Url $productionUrl -MaxRetries $MaxRetries -RetryDelaySec $RetryDelaySec
if (-not $productionHealthy) {
    Write-Host "`n::warning::Production health check failed after swap. Consider swapping back."
    Write-Host "To revert, run:"
    Write-Host "  az webapp deployment slot swap --name $AppName --resource-group $ResourceGroup --slot $SlotName --target-slot production"
    exit 1
}

Write-Host "`nDeployment to production completed successfully."
