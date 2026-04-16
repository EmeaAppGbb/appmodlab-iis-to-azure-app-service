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
