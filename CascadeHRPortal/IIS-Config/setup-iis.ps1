# IIS Setup Script for Cascade HR Portal
# Run with administrator privileges

$ErrorActionPreference = "Stop"
Write-Host "=== Cascade HR Portal IIS Setup ===" -ForegroundColor Cyan

$siteName = "CascadeHRPortal"
$appPoolName = "CascadeHRPortalAppPool"
$physicalPath = "C:\inetpub\wwwroot\CascadeHRPortal"

Import-Module WebAdministration

# Create application pool
Write-Host "Creating application pool: $appPoolName" -ForegroundColor Yellow
if (Test-Path "IIS:\AppPools\$appPoolName") {
    Remove-WebAppPool -Name $appPoolName
}
New-WebAppPool -Name $appPoolName
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value ""
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "managedPipelineMode" -Value "Integrated"
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "enable32BitAppOnWin64" -Value $false
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "processModel.identityType" -Value "NetworkService"
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "recycling.periodicRestart.time" -Value "00:00:00"
Clear-ItemProperty "IIS:\AppPools\$appPoolName" -Name "recycling.periodicRestart.schedule"
New-ItemProperty "IIS:\AppPools\$appPoolName" -Name "recycling.periodicRestart.schedule" -Value @{value='02:00:00'}
Write-Host "Application pool created" -ForegroundColor Green

# Create website
Write-Host "Creating website: $siteName" -ForegroundColor Yellow
if (Test-Path "IIS:\Sites\$siteName") {
    Remove-Website -Name $siteName
}
if (-not (Test-Path $physicalPath)) {
    New-Item -ItemType Directory -Path $physicalPath -Force | Out-Null
}
New-Website -Name $siteName -PhysicalPath $physicalPath -ApplicationPool $appPoolName -Port 80
New-WebBinding -Name $siteName -Protocol https -Port 443
Write-Host "Website created" -ForegroundColor Green

# Configure Windows Authentication
Write-Host "Configuring Windows Authentication" -ForegroundColor Yellow
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name "enabled" -Value $false -PSPath "IIS:\" -Location $siteName
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name "enabled" -Value $true -PSPath "IIS:\" -Location $siteName
Write-Host "Windows Authentication configured" -ForegroundColor Green

# Create virtual directories
Write-Host "Creating virtual directories" -ForegroundColor Yellow
$localDocsPath = "C:\inetpub\hr-documents"
$localPayslipsPath = "C:\inetpub\payslips"
if (-not (Test-Path $localDocsPath)) { New-Item -ItemType Directory -Path $localDocsPath -Force | Out-Null }
if (-not (Test-Path $localPayslipsPath)) { New-Item -ItemType Directory -Path $localPayslipsPath -Force | Out-Null }
New-WebVirtualDirectory -Site $siteName -Name "documents" -PhysicalPath $localDocsPath
New-WebVirtualDirectory -Site $siteName -Name "payslips" -PhysicalPath $localPayslipsPath
Write-Host "Virtual directories created" -ForegroundColor Green

Write-Host ""
Write-Host "=== IIS Setup Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Publish the application to: $physicalPath" -ForegroundColor White
Write-Host "2. Configure SSL certificate binding for HTTPS" -ForegroundColor White
Write-Host "3. Test at: http://localhost or https://localhost" -ForegroundColor White
