---
title: "IIS to Azure App Service"
description: "Migrate IIS-hosted apps to Azure App Service with URL rewrites, Easy Auth & deployment slots"
authors: ["marconsilva"]
category: "Infra Modernization"
industry: "Cross-Industry"
services: ["Azure App Service", "Azure SQL Database", "Azure Blob Storage", "Azure App Configuration", "Azure Key Vault"]
languages: [".NET", "C#"]
frameworks: ["ASP.NET Core"]
modernizationTools: []
agenticTools: []
tags: ["iis-migration", "app-service", "entra-id", "deployment-slots", "url-rewrite"]
extensions: ["github.copilot"]
thumbnail: "assets/screenshots/01-home-dashboard.png"
video: ""
version: "1.0.0"
---

## Legacy Application Overview

Cascade HR Portal is an ASP.NET Core 6.0 employee self-service application hosted on IIS 10 (Windows Server 2019). The application relies heavily on IIS-specific features including 20+ URL rewrite rules, Windows Authentication (Negotiate/NTLM), virtual directories pointing to network file shares, and custom error pages — all of which must be migrated to Azure App Service equivalents.

### HR Portal Dashboard

The main landing page provides quick access to Leave, Timesheet, Payslips, and Benefits modules. Note the Windows-authenticated user identity (CASCADE\jsmith) displayed in the navigation bar — a key IIS dependency that requires migration to Entra ID Easy Auth.

![Home Dashboard — HR portal with quick actions and Windows-authenticated user identity](assets/screenshots/01-home-dashboard.png)

### IIS Error Handling

Custom error pages are rendered via `UseStatusCodePagesWithReExecute`, part of the IIS error-handling configuration that needs to be replaced with ASP.NET Core middleware during migration.

![Error 404 — Custom IIS error page requiring middleware migration](assets/screenshots/08-error-404.png)

---

## Screenshots

### Home Dashboard
The main landing page showing the HR portal with quick actions (Leave, Timesheet, Payslips, Benefits) and announcements. Displays the Windows-authenticated user identity (CASCADE\jsmith) in the nav bar — a key IIS dependency to migrate.

![Home Dashboard](assets/screenshots/01-home-dashboard.png)

### Error Page (404)
Custom error page rendered via `UseStatusCodePagesWithReExecute` — part of the IIS error-handling configuration that needs migration.

![Error 404](assets/screenshots/08-error-404.png)

---

## Solution Walkthrough

This section documents the complete migration from IIS to Azure App Service, executed using [GitHub Copilot CLI](https://docs.github.com/en/copilot) with `--allow-all-tools --yolo` mode. Each step was run on the `solution-final` branch with tagged commits. All CLI outputs are saved in `assets/outputs/`.

### Branch & Tags

| Branch | Description |
|---|---|
| `main` | Lab documentation and original legacy app |
| `solution-final` | Completed migration with all 9 steps |

| Tag | Step |
|---|---|
| `step-01-iis-assessment` | IIS configuration audit |
| `step-02-url-rewrite-migration` | URL rewrite middleware conversion |
| `step-03-auth-migration` | Windows Auth → Entra ID |
| `step-04-storage-migration` | Virtual directories → Blob Storage |
| `step-05-app-service-deploy` | Bicep IaC for App Service |
| `step-06-deployment-slots` | CI/CD with deployment slots |
| `step-07-ssl-configuration` | SSL and Key Vault integration |
| `step-08-auto-scaling` | Auto-scale rules |
| `step-09-deploy-validate` | App Insights, .NET 9, deployment checklist |

---

### Step 1: Audit IIS Configuration

**Prompt:**
```
Audit the IIS configuration for this ASP.NET Core 6.0 application. Analyze all IIS-specific
dependencies: web.config, IIS-Config/urlrewrite.config, applicationHost.config, setup-iis.ps1,
Program.cs, appsettings.json. Create docs/iis-migration-assessment.md cataloging all URL rewrite
rules, Windows Auth, virtual directories, app pool settings, ARR proxy rules, config transforms,
custom error pages, and SSL settings. Add a /health endpoint via HealthController.cs.
```

**Command:**
```powershell
gh copilot -- -p "STEP 1 PROMPT" --allow-all-tools --yolo 2>&1 | Tee-Object -FilePath "assets/outputs/step-01-iis-assessment.txt"
```

**Files Created:**
- `docs/iis-migration-assessment.md` — Full audit with priority matrix (P0–P3)
- `CascadeHRPortal.Web/Controllers/HealthController.cs` — `/health` endpoint

**Output:** [`assets/outputs/step-01-iis-assessment.txt`](assets/outputs/step-01-iis-assessment.txt)

---

### Step 2: Convert URL Rewrites to ASP.NET Core Middleware

**Prompt:**
```
Convert IIS URL Rewrite rules to ASP.NET Core middleware. Create
CascadeHRPortal.Web/Middleware/UrlRewriteMiddleware.cs replacing all 17+ IIS rewrite rules.
Update Program.cs to register the middleware. Remove rewrite rules from web.config.
```

**Command:**
```powershell
gh copilot -- -p "STEP 2 PROMPT" --allow-all-tools --yolo 2>&1 | Tee-Object -FilePath "assets/outputs/step-02-url-rewrite-migration.txt"
```

**Files Created/Modified:**
- `CascadeHRPortal.Web/Middleware/UrlRewriteMiddleware.cs` — All 17 rules as middleware
- `Program.cs` — Added `app.UseMiddleware<UrlRewriteMiddleware>()`
- `web.config` — Removed `<rewrite>` section

**Output:** [`assets/outputs/step-02-url-rewrite-migration.txt`](assets/outputs/step-02-url-rewrite-migration.txt)

---

### Step 3: Migrate Authentication (Windows Auth → Entra ID)

**Prompt:**
```
Migrate from Windows Authentication to Entra ID Easy Auth. Update Program.cs to use
Microsoft Identity Web. Add AzureAd section to appsettings.json. Update csproj packages.
Remove Windows Auth from web.config. Update all controllers for claims-based identity.
```

**Command:**
```powershell
gh copilot -- -p "STEP 3 PROMPT" --allow-all-tools --yolo 2>&1 | Tee-Object -FilePath "assets/outputs/step-03-auth-migration.txt"
```

**Files Modified:**
- `Program.cs` — `AddMicrosoftIdentityWebAppAuthentication()`
- `appsettings.json` — Added `AzureAd` configuration section
- `CascadeHRPortal.Web.csproj` — Added `Microsoft.Identity.Web`, removed `System.DirectoryServices`
- `web.config` — Removed `<security>/<authentication>` section
- All controllers updated for claims-based identity

**Output:** [`assets/outputs/step-03-auth-migration.txt`](assets/outputs/step-03-auth-migration.txt)

---

### Step 4: Migrate File Access (Virtual Directories → Azure Blob Storage)

**Prompt:**
```
Migrate file access from IIS virtual directories (UNC paths) to Azure Blob Storage.
Refactor DocumentService.cs to use BlobServiceClient. Update appsettings.json with
AzureStorage configuration. Add Azure.Storage.Blobs and Azure.Identity packages.
```

**Command:**
```powershell
gh copilot -- -p "STEP 4 PROMPT" --allow-all-tools --yolo 2>&1 | Tee-Object -FilePath "assets/outputs/step-04-storage-migration.txt"
```

**Files Modified:**
- `CascadeHRPortal.Services/DocumentService.cs` — Uses `BlobServiceClient`/`BlobContainerClient`
- `CascadeHRPortal.Services.csproj` — Added `Azure.Storage.Blobs 12.19.1`
- `CascadeHRPortal.Web.csproj` — Added `Azure.Identity 1.11.0`
- `appsettings.json` — Replaced `FileStorage` UNC paths with `AzureStorage` section
- `Program.cs` — Registered `BlobServiceClient` in DI

**Output:** [`assets/outputs/step-04-storage-migration.txt`](assets/outputs/step-04-storage-migration.txt)

---

### Step 5: Configure App Service with Bicep IaC

**Prompt:**
```
Create Bicep templates for full Azure infrastructure: App Service Plan, App Service with
deployment slots, Azure SQL Database, Blob Storage, App Configuration, Key Vault,
Application Insights. Use managed identity and modular structure.
```

**Command:**
```powershell
gh copilot -- -p "STEP 5 PROMPT" --allow-all-tools --yolo 2>&1 | Tee-Object -FilePath "assets/outputs/step-05-app-service-deploy.txt"
```

**Files Created:**
- `infra/main.bicep` — Orchestrator
- `infra/modules/app-service.bicep` — App Service + staging slot + managed identity
- `infra/modules/sql-database.bicep` — Azure SQL with firewall rules
- `infra/modules/storage.bicep` — Storage account + blob containers
- `infra/modules/monitoring.bicep` — App Insights + Log Analytics
- `infra/parameters.json` — Parameter file

**Output:** [`assets/outputs/step-05-app-service-deploy.txt`](assets/outputs/step-05-app-service-deploy.txt)

---

### Step 6: Set Up Deployment Slots and CI/CD

**Prompt:**
```
Create GitHub Actions workflow (.github/workflows/deploy.yml) with build, deploy-to-staging,
and swap-to-production jobs using OIDC auth. Create scripts/swap-slots.ps1 for slot swap
with health check validation.
```

**Command:**
```powershell
gh copilot -- -p "STEP 6 PROMPT" --allow-all-tools --yolo 2>&1 | Tee-Object -FilePath "assets/outputs/step-06-deployment-slots.txt"
```

**Files Created:**
- `.github/workflows/deploy.yml` — Build → Deploy staging → Swap to production
- `scripts/swap-slots.ps1` — Health check + slot swap + rollback guidance

**Output:** [`assets/outputs/step-06-deployment-slots.txt`](assets/outputs/step-06-deployment-slots.txt)

---

### Step 7: Configure SSL and Key Vault Integration

**Prompt:**
```
Configure SSL for App Service. Create infra/modules/key-vault.bicep with certificate support.
Update app-service.bicep for HTTPS-only and TLS 1.2. Create docs/ssl-migration-guide.md
documenting PFX-to-managed-certificate migration.
```

**Command:**
```powershell
gh copilot -- -p "STEP 7 PROMPT" --allow-all-tools --yolo 2>&1 | Tee-Object -FilePath "assets/outputs/step-07-ssl-configuration.txt"
```

**Files Created/Modified:**
- `infra/modules/key-vault.bicep` — Key Vault with self-signed certificate
- `infra/main.bicep` — Updated to use key-vault module
- `infra/modules/app-service.bicep` — SSL certificate binding
- `docs/ssl-migration-guide.md` — Migration guide

**Output:** [`assets/outputs/step-07-ssl-configuration.txt`](assets/outputs/step-07-ssl-configuration.txt)

---

### Step 8: Configure Auto-Scaling

**Prompt:**
```
Create infra/modules/autoscale.bicep with CPU-based (>70% out, <30% in) and HTTP request-based
(>100/instance) scale rules. Min 1, default 2, max 5 instances. Update main.bicep and parameters.
```

**Command:**
```powershell
gh copilot -- -p "STEP 8 PROMPT" --allow-all-tools --yolo 2>&1 | Tee-Object -FilePath "assets/outputs/step-08-auto-scaling.txt"
```

**Files Created/Modified:**
- `infra/modules/autoscale.bicep` — Auto-scale settings with 3 rules
- `infra/main.bicep` — Autoscale module wiring
- `infra/parameters.json` — Scale parameters

**Output:** [`assets/outputs/step-08-auto-scaling.txt`](assets/outputs/step-08-auto-scaling.txt)

---

### Step 9: Deploy and Validate

**Prompt:**
```
Add Application Insights telemetry to Program.cs. Upgrade from .NET 6 to .NET 9. Change
hosting model to OutOfProcess. Create docs/deployment-checklist.md with pre-deployment
verification steps.
```

**Command:**
```powershell
gh copilot -- -p "STEP 9 PROMPT" --allow-all-tools --yolo 2>&1 | Tee-Object -FilePath "assets/outputs/step-09-deploy-validate.txt"
```

**Files Modified/Created:**
- `Program.cs` — `AddApplicationInsightsTelemetry()`
- Both `.csproj` files — Upgraded `net6.0` → `net9.0`
- `web.config` — `hostingModel="OutOfProcess"`
- `appsettings.json` — `ApplicationInsights` section
- `docs/deployment-checklist.md` — Pre-deployment checklist

**Output:** [`assets/outputs/step-09-deploy-validate.txt`](assets/outputs/step-09-deploy-validate.txt)

---

### Migration Summary

| IIS Feature | Azure App Service Equivalent |
|---|---|
| URL Rewrite Module | ASP.NET Core `UrlRewriteMiddleware` |
| Windows Authentication | Entra ID + Microsoft Identity Web |
| Virtual Directories (UNC) | Azure Blob Storage + `BlobServiceClient` |
| Application Pool Identity | App Service Managed Identity |
| IIS SSL/PFX Certificates | App Service Managed Certs / Key Vault |
| Web.config Transforms | App Service Configuration + Key Vault refs |
| ARR Reverse Proxy | YARP / Azure Application Gateway |
| Manual Web Deploy | GitHub Actions + Deployment Slots |
| No auto-scaling | App Service Auto-Scale (CPU + HTTP rules) |
| No monitoring | Application Insights |

### How to Reproduce

```powershell
# Clone and checkout the solution
git clone https://github.com/EmeaAppGbb/appmodlab-iis-to-azure-app-service.git
cd appmodlab-iis-to-azure-app-service
git checkout solution-final

# View a specific step
git checkout step-03-auth-migration   # e.g., see auth migration changes

# Deploy infrastructure
az deployment group create --resource-group cascade-hr-rg --template-file infra/main.bicep --parameters infra/parameters.json

# Build and run locally
cd CascadeHRPortal
dotnet restore && dotnet build
dotnet run --project CascadeHRPortal.Web
```
