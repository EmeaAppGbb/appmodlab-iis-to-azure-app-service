# IIS to Azure App Service Migration Lab

This repository contains the legacy IIS-hosted application and migration materials for the "IIS to Azure App Service" migration lab.

## Overview

**Business Domain:** Cascade Human Resources - Employee self-service HR portal

This lab demonstrates migrating a legacy ASP.NET Core 6.0 application from IIS 10 on Windows Server to Azure App Service, handling IIS-specific features like URL rewrite rules, Windows Authentication, virtual directories, and custom handlers.

## Project Structure

```
CascadeHRPortal/
├── CascadeHRPortal.sln              # Visual Studio solution
├── CascadeHRPortal.Web/             # ASP.NET Core 6.0 web application
│   ├── Controllers/                 # MVC controllers (Leave, Timesheet, Payslip, etc.)
│   ├── Views/                       # Razor views
│   ├── wwwroot/                     # Static assets (CSS, JS)
│   ├── web.config                   # IIS-specific configuration
│   ├── appsettings.json             # Application configuration
│   └── Program.cs                   # Application startup
├── CascadeHRPortal.Services/        # Business logic services
│   ├── Models/                      # Data models
│   ├── LeaveService.cs              # Leave request management
│   ├── TimesheetService.cs          # Timesheet submission
│   ├── PayrollIntegrationService.cs # External payroll API integration
│   ├── DocumentService.cs           # File access via virtual directories
│   └── EmailService.cs              # SMTP email notifications
├── IIS-Config/                      # IIS configuration files
│   ├── applicationHost.config       # IIS site and app pool configuration
│   ├── urlrewrite.config            # 20+ URL rewrite rules
│   ├── web.config.transform.*       # Environment-specific transforms
│   └── setup-iis.ps1                # PowerShell IIS setup script
└── Database/
    └── schema.sql                   # SQL Server database schema
```

## Legacy Technology Stack

- **Hosting:** IIS 10 on Windows Server 2019
- **Framework:** ASP.NET Core 6.0 (in-process hosting model)
- **IIS Features:**
  - URL Rewrite Module 2.1 (20+ rewrite rules)
  - Application Request Routing (ARR) for reverse proxy
  - Windows Authentication (Negotiate/NTLM)
  - Virtual directories pointing to network file shares
  - Custom error pages
  - Application pool with specific identity and recycling settings
- **Database:** SQL Server 2019 (separate server)
- **Email:** SMTP relay server
- **SSL:** PFX certificate bound to IIS site

## Key IIS Dependencies (Anti-Patterns)

1. **URL Rewrite Rules:** 20+ rules in web.config for legacy URLs, API versioning, trailing slash normalization
2. **Virtual Directories:** `/documents` → `\\fileserver\hr-documents`, `/payslips` → `\\fileserver\payslips`
3. **Windows Authentication:** Tightly coupled to IIS/Active Directory
4. **Config Transforms:** web.config.transform files for environment-specific settings
5. **ARR Proxy Rules:** Forwarding `/api/payroll/*` to internal payroll service
6. **Application Pool Identity:** Used for SQL Server trusted connection
7. **No Health Checks:** Missing health check endpoints
8. **Manual Deployment:** Web Deploy with manual IIS configuration

## Features

The HR portal provides:
- **Leave Management:** Submit, view, and cancel leave requests
- **Timesheets:** Weekly timesheet submission and approval tracking
- **Payslips:** View and download payslip PDFs from network file share
- **Employee Profile:** View and edit employee information
- **Benefits:** Enroll in benefit plans (health, dental)
- **Employee Directory:** Search for colleagues

## Setup Instructions

### Prerequisites
- Windows Server 2019 or Windows 10/11 with IIS
- .NET 6.0 SDK
- SQL Server 2019 (or SQL Server Express)
- IIS URL Rewrite Module 2.1
- IIS Application Request Routing (ARR)

### Quick Start

1. **Install IIS Features:**
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45
   ```

2. **Setup Database:**
   ```powershell
   sqlcmd -S localhost -i Database\schema.sql
   ```

3. **Configure IIS:**
   ```powershell
   cd IIS-Config
   .\setup-iis.ps1
   ```

4. **Build and Publish:**
   ```powershell
   dotnet publish CascadeHRPortal.Web -c Release -o C:\inetpub\wwwroot\CascadeHRPortal
   ```

5. **Access the Application:**
   - Navigate to `http://localhost` or `https://localhost`
   - Windows Authentication will prompt for credentials

## Migration to Azure App Service

The lab guides you through:
1. **IIS Assessment:** Cataloging URL rewrite rules, virtual directories, auth settings
2. **URL Rewrite Migration:** Converting IIS rules to ASP.NET Core middleware
3. **Authentication Migration:** Moving from Windows Auth to Entra ID Easy Auth
4. **Storage Migration:** Replacing virtual directories with Azure Blob Storage
5. **App Service Deployment:** Using deployment slots, auto-scaling, managed certificates

## Lab Branches

- `main` — Full lab documentation
- `legacy` — This IIS-hosted application
- `solution` — Modernized Azure App Service version
- `step-1-iis-assessment` — IIS configuration audit
- `step-2-url-rewrite-migration` — ASP.NET Core middleware
- `step-3-auth-migration` — Entra ID Easy Auth
- `step-4-storage-migration` — Azure Blob Storage
- `step-5-app-service-deploy` — App Service with slots

## License

This is a demonstration application for training purposes.

---

**Cascade Human Resources** | Legacy IIS Application (2016 Edition)
