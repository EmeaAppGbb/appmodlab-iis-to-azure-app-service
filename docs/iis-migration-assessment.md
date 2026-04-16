# IIS Migration Assessment — Cascade HR Portal

**Date:** 2026-04-16
**Application:** CascadeHRPortal.Web (ASP.NET Core 6.0, InProcess hosting on IIS)
**Target Platform:** Azure App Service (Windows)

---

## Table of Contents

1. [URL Rewrite Rules](#1-url-rewrite-rules)
2. [Windows Authentication Configuration](#2-windows-authentication-configuration)
3. [Virtual Directories](#3-virtual-directories)
4. [Application Pool Settings](#4-application-pool-settings)
5. [ARR / Reverse-Proxy Rules](#5-arr--reverse-proxy-rules)
6. [Configuration Transforms](#6-configuration-transforms)
7. [Custom Error Pages](#7-custom-error-pages)
8. [SSL / TLS Settings](#8-ssl--tls-settings)
9. [Additional IIS Dependencies](#9-additional-iis-dependencies)
10. [Migration Priority Matrix](#10-migration-priority-matrix)

---

## 1. URL Rewrite Rules

The application uses the IIS URL Rewrite module extensively. Rules are defined in two places:

- `CascadeHRPortal.Web/web.config` (2 rules — inline)
- `IIS-Config/urlrewrite.config` (17 inbound rules + 1 outbound rule)

### 1.1 Inbound Rules

| # | Rule Name | Source File | Type | Pattern | Target | Stop Processing |
|---|-----------|-------------|------|---------|--------|-----------------|
| 1 | HTTPS Redirect | web.config, urlrewrite.config | Redirect 301 | `(.*)` when `{HTTPS}` is `OFF` | `https://{HTTP_HOST}/{R:1}` | Yes |
| 2 | Legacy HR Portal Redirect | web.config, urlrewrite.config | Redirect 301 | `^hr-portal/(.*)$` | `/{R:1}` | Yes |
| 3 | API v1 to v2 Rewrite | urlrewrite.config | Rewrite | `^api/v1/(.*)$` | `api/v2/{R:1}` | No |
| 4 | Remove Trailing Slash | urlrewrite.config | Redirect 301 | `(.*)/$` (not file/dir) | `{R:1}` | Yes |
| 5 | Lowercase URLs | urlrewrite.config | Redirect 301 | `[A-Z]` (excludes static assets) | `{ToLower:{URL}}` | Yes |
| 6 | Remove WWW Prefix | urlrewrite.config | Redirect 301 | `(.*)` when host starts with `www.` | `https://{C:1}/{R:1}` | Yes |
| 7 | Employee Lookup Legacy | urlrewrite.config | Redirect 301 | `^employees/search\?q=(.*)$` | `/Directory/Search?query={R:1}` | Yes |
| 8 | Payslip Download Legacy | urlrewrite.config | Redirect 301 | `^payslips/download/([0-9]+)$` | `/Payslip/Download/{R:1}` | Yes |
| 9 | Benefits Legacy URL | urlrewrite.config | Redirect 301 | `^benefits-enrollment$` | `/Benefits/Enroll` | Yes |
| 10 | Leave Status Legacy | urlrewrite.config | Redirect 301 | `^leave/status/([0-9]+)$` | `/Leave/Details/{R:1}` | Yes |
| 11 | Timesheet Legacy Format | urlrewrite.config | Redirect 301 | `^timesheet/submit/([0-9]{4})-W([0-9]{2})$` | `/Timesheet/Submit?year={R:1}&week={R:2}` | Yes |
| 12 | Calendar Legacy URL | urlrewrite.config | Redirect 301 | `^calendar/([0-9]{4})/([0-9]{2})$` | `/Leave/Calendar?year={R:1}&month={R:2}` | Yes |
| 13 | PDF Reports Legacy | urlrewrite.config | Redirect 301 | `^reports/pdf/([a-z-]+)/([0-9]+)$` | `/Reports/{R:1}?id={R:2}&format=pdf` | Yes |
| 14 | Mobile Site Redirect | urlrewrite.config | Redirect 302 | `^mobile/(.*)$` | `/{R:1}?mobile=true` | Yes |
| 15 | Intranet Legacy Path | urlrewrite.config | Redirect 301 | `^intranet/hr/(.*)$` | `/{R:1}` | Yes |
| 16 | Payroll API Proxy | urlrewrite.config | **Rewrite (ARR proxy)** | `^api/payroll/(.*)$` | `http://payroll-internal.cascade.local/api/{R:1}` | Yes |
| 17 | Document Service Proxy | urlrewrite.config | **Rewrite (ARR proxy)** | `^documents/(.*)$` (pdf/docx/xlsx) | `http://docs-internal.cascade.local/{R:1}` | Yes |

### 1.2 Outbound Rules

| Rule Name | Condition | Action |
|-----------|-----------|--------|
| Add HSTS Header | `{HTTPS}` is `on` | Sets `Strict-Transport-Security: max-age=31536000; includeSubDomains` |

### 1.3 Migration Strategy — URL Rewrite Rules

| Category | Rules | Strategy |
|----------|-------|----------|
| **HTTPS Redirect** (#1) | HTTPS Redirect | **Drop.** Azure App Service supports "HTTPS Only" toggle — set via portal or ARM (`httpsOnly: true`). No rewrite rule needed. |
| **Canonical URL rules** (#4, #5, #6) | Trailing slash, lowercase, remove WWW | Reimplement as ASP.NET Core middleware using `Microsoft.AspNetCore.Rewrite` (already referenced in csproj). Add rules in `Program.cs`. |
| **Legacy redirects** (#2, #7–15) | HR Portal, Employee, Payslip, Benefits, Leave, Timesheet, Calendar, PDF Reports, Mobile, Intranet | Reimplement as ASP.NET Core redirect rules or a dedicated `RedirectMiddleware`. Group all legacy path mappings in a configuration file for maintainability. |
| **API version rewrite** (#3) | API v1 → v2 | Reimplement as ASP.NET Core rewrite rule or API versioning middleware. |
| **ARR proxy rules** (#16, #17) | Payroll API Proxy, Document Service Proxy | **Cannot use IIS rewrite on App Service for reverse proxy.** Replace with Azure API Management, Azure Front Door, or an in-app `HttpClient`-based proxy middleware (e.g., YARP). Internal `.local` hostnames must be resolved via VNet integration + Private DNS Zones. |
| **HSTS outbound rule** | Add HSTS Header | **Drop.** Use `app.UseHsts()` already present in `Program.cs`. |

---

## 2. Windows Authentication Configuration

### 2.1 Current Configuration

| Setting | Value | Source |
|---------|-------|--------|
| Anonymous Authentication | **Disabled** | `web.config` line 28; `setup-iis.ps1` line 42 |
| Windows Authentication | **Enabled** | `web.config` line 29; `setup-iis.ps1` line 43 |
| Providers | Negotiate, NTLM | `web.config` line 30 |
| ASP.NET Core Auth Scheme | `IISDefaults.AuthenticationScheme` | `Program.cs` line 11 |
| NuGet Package | `Microsoft.AspNetCore.Authentication.Negotiate` 6.0.0 | `csproj` line 11 |
| Active Directory packages | `System.DirectoryServices` 7.0.1, `System.DirectoryServices.AccountManagement` 7.0.1 | `csproj` lines 14–15 |
| SQL Connection | `Integrated Security=true` (Windows auth to SQL Server) | `appsettings.json` line 10 |

### 2.2 Migration Strategy — Windows Authentication

**Risk: HIGH** — This is the most impactful dependency.

| Option | Description | Effort |
|--------|-------------|--------|
| **Option A — Azure AD (Entra ID) with EasyAuth** | Enable App Service Authentication (EasyAuth) with Microsoft Entra ID. Replace `[Authorize]` identity claims. Requires mapping AD users to Entra ID. Recommended for greenfield. | High |
| **Option B — Hybrid with Azure AD Domain Services** | Deploy Azure AD DS, join App Service to VNet, use Negotiate auth. Preserves Windows Auth but requires premium networking. | Medium |
| **Option C — Keep Windows Auth (App Service Environment)** | Deploy to ASE v3 with domain-joined VNet. Preserves existing auth but increases cost significantly. | Low code / High cost |

**SQL Server `Integrated Security`:** Must switch to Azure SQL with Managed Identity or SQL authentication. Integrated Security with Windows credentials is not available on App Service.

**`System.DirectoryServices` usage:** AD lookups (employee directory) must be replaced with Microsoft Graph API calls against Entra ID, or routed via VNet integration to an on-prem AD over ExpressRoute/VPN.

---

## 3. Virtual Directories

### 3.1 Current Configuration

| Virtual Path | Physical Path | Source |
|--------------|---------------|--------|
| `/` | `C:\inetpub\wwwroot\CascadeHRPortal` | `applicationHost.config` line 8 |
| `/documents` | `\\fileserver\hr-documents` | `applicationHost.config` line 9; `setup-iis.ps1` line 52 |
| `/payslips` | `\\fileserver\payslips` | `applicationHost.config` line 10; `setup-iis.ps1` line 53 |

The UNC paths reference an on-premises file server. These paths are also configured in `appsettings.json`:

| Setting | Value |
|---------|-------|
| `FileStorage:DocumentsPath` | `\\fileserver\hr-documents` |
| `FileStorage:PayslipsPath` | `\\fileserver\payslips` |
| `FileStorage:MaxFileSizeMB` | 10 |

### 3.2 Migration Strategy — Virtual Directories

**Azure App Service does not support IIS virtual directories pointing to UNC shares.**

| Option | Description | Effort |
|--------|-------------|--------|
| **Option A — Azure Blob Storage** | Migrate documents/payslips to Azure Blob Storage. Update `IDocumentService` to use Azure Blob SDK. Serve files via SAS tokens or Azure CDN. **Recommended.** | Medium |
| **Option B — Azure Files + VNet Mount** | Create Azure Files share, mount as virtual path in App Service. Requires VNet integration. Provides near-transparent migration. | Low–Medium |
| **Option C — Azure Files + Hybrid Connection** | Use Hybrid Connection to reach on-prem file server temporarily during migration. | Low (temporary) |

---

## 4. Application Pool Settings

### 4.1 Current Configuration

| Setting | Value | Source |
|---------|-------|--------|
| Pool Name | `CascadeHRPortalAppPool` | `applicationHost.config` line 19; `setup-iis.ps1` line 18 |
| Managed Runtime | (empty — No Managed Code) | `applicationHost.config` line 19; `setup-iis.ps1` line 19 |
| Pipeline Mode | Integrated | `applicationHost.config` line 19; `setup-iis.ps1` line 20 |
| Identity | NetworkService | `applicationHost.config` line 20; `setup-iis.ps1` line 22 |
| 32-bit Apps | Disabled | `setup-iis.ps1` line 21 |
| Hosting Model | InProcess | `web.config` line 8; `csproj` line 8 |
| Periodic Restart | Disabled (`00:00:00`) with scheduled restart at 02:00 AM | `applicationHost.config` lines 21–23; `setup-iis.ps1` lines 23–25 |

### 4.2 Migration Strategy — Application Pool Settings

| Setting | Azure App Service Equivalent |
|---------|------------------------------|
| Pipeline Mode (Integrated) | Always integrated on App Service — no action needed. |
| Identity (NetworkService) | App Service uses a managed identity. Create a System-assigned Managed Identity for Azure resource access. |
| 32-bit disabled | Configure as 64-bit in App Service Configuration → General Settings → Platform. |
| InProcess hosting | Supported on App Service. Keep `<AspNetCoreHostingModel>InProcess</AspNetCoreHostingModel>` in csproj. |
| Periodic restart at 02:00 | Not directly available. Use App Service "Auto-Heal" or schedule a restart via Azure Automation / Logic App if needed. Alternatively, use deployment slot swaps for zero-downtime restarts. |

---

## 5. ARR / Reverse-Proxy Rules

### 5.1 Current Configuration

Two URL Rewrite rules act as reverse proxies via IIS ARR (Application Request Routing):

| Rule | Internal Target | Headers Set |
|------|----------------|-------------|
| Payroll API Proxy (`^api/payroll/(.*)$`) | `http://payroll-internal.cascade.local/api/{R:1}` | `X-Forwarded-Host`, `X-Forwarded-For` |
| Document Service Proxy (`^documents/(.*)$`) | `http://docs-internal.cascade.local/{R:1}` | (none) |

Both targets are internal `.cascade.local` hostnames, implying on-premises services not directly reachable from Azure.

The `appsettings.json` also references the payroll service:

| Setting | Value |
|---------|-------|
| `PayrollApi:BaseUrl` | `http://payroll-internal.cascade.local/api` |
| `PayrollApi:ApiKey` | `PAY-2016-LEGACY-KEY-XYZ123` |
| `PayrollApi:Timeout` | 30 seconds |

### 5.2 Migration Strategy — ARR Proxy Rules

| Option | Description | Effort |
|--------|-------------|--------|
| **Option A — YARP (Yet Another Reverse Proxy)** | Add Microsoft YARP NuGet package to the app and configure proxy routes in `appsettings.json`. Requires VNet integration + Private DNS to resolve `.local` hostnames. **Recommended for app-level proxying.** | Medium |
| **Option B — Azure API Management** | Front both the HR Portal and backend services behind APIM. Provides throttling, caching, and API key management. Move the `PayrollApi:ApiKey` to Azure Key Vault. | Medium–High |
| **Option C — Azure Front Door / Application Gateway** | Use path-based routing at the infrastructure level. Best if multiple apps share the same domain. | High |

**Prerequisite for all options:** Deploy App Service with VNet Integration. Configure Azure Private DNS Zones to resolve `payroll-internal.cascade.local` and `docs-internal.cascade.local` to the on-prem servers via VPN/ExpressRoute.

---

## 6. Configuration Transforms

### 6.1 Current Configuration

Two XDT transform files exist:

| File | Environment | Key Changes |
|------|-------------|-------------|
| `IIS-Config/web.config.transform.prod` | Production | `stdoutLogEnabled=false`, `ASPNETCORE_ENVIRONMENT=Production`, `httpErrors errorMode=DetailedLocalOnly`, connection string → prod SQL server |
| `IIS-Config/web.config.transform.staging` | Staging | `stdoutLogEnabled=true`, `ASPNETCORE_ENVIRONMENT=Staging`, connection string → staging SQL server |

**Environment-specific connection strings:**

| Environment | Connection String |
|-------------|-------------------|
| Default (`appsettings.json`) | `Server=sql-cascade-hr-prod.cascade.local;Database=CascadeHR;Integrated Security=true;TrustServerCertificate=true;` |
| Production (transform) | `Server=sql-cascade-hr-prod.cascade.local;Database=CascadeHR;Integrated Security=true;` |
| Staging (transform) | `Server=sql-cascade-hr-staging.cascade.local;Database=CascadeHR_Staging;Integrated Security=true;` |

### 6.2 Migration Strategy — Configuration Transforms

**Azure App Service does not use XDT transforms.** Replace with:

| IIS Transform Feature | Azure App Service Equivalent |
|----------------------|------------------------------|
| `web.config.transform.*` | **App Service Configuration** (Application Settings & Connection Strings) in the Azure Portal or via ARM/Bicep templates. |
| `ASPNETCORE_ENVIRONMENT` | Set as an App Service Application Setting. Use deployment slots (Staging slot, Production slot) with slot-sticky settings. |
| `stdoutLogEnabled` | Use **App Service Diagnostics** or **Application Insights** instead of stdout file logging. |
| Connection strings per environment | Store in **App Service Connection Strings** (slot-sticky). Migrate to Azure SQL and use Managed Identity connection strings. |
| `httpErrors errorMode` | Configure via `web.config` deployed with the app (App Service supports a subset of `web.config` directives). |

**Secrets handling:** Move `PayrollApi:ApiKey` and connection strings to **Azure Key Vault**. Reference via App Service Key Vault References (`@Microsoft.KeyVault(...)`).

---

## 7. Custom Error Pages

### 7.1 Current Configuration

| Component | Configuration | Source |
|-----------|---------------|--------|
| ASP.NET Core error handler | `app.UseExceptionHandler("/Home/Error")` | `Program.cs` line 34 |
| Status code pages | `app.UseStatusCodePagesWithReExecute("/Error/{0}")` | `Program.cs` line 39 |
| Error controller | `HomeController.Error(int statusCode)` at route `/Error/{statusCode}` | `HomeController.cs` lines 19–31 |
| Handled codes | 403 → "Access Forbidden", 404 → "Page Not Found", 500 → "Internal Server Error" | `HomeController.cs` |
| IIS error mode (prod transform) | `httpErrors errorMode="DetailedLocalOnly"` | `web.config.transform.prod` line 11 |

### 7.2 Migration Strategy — Custom Error Pages

| Item | Action |
|------|--------|
| `UseExceptionHandler` / `UseStatusCodePagesWithReExecute` | **No change needed.** These are ASP.NET Core middleware and work on App Service. |
| `HomeController.Error` action | **No change needed.** Portable ASP.NET Core controller. |
| `httpErrors errorMode` in web.config | Can be kept in the deployed `web.config`. App Service respects this setting. Alternatively, remove and rely solely on ASP.NET Core error handling. |

---

## 8. SSL / TLS Settings

### 8.1 Current Configuration

| Setting | Value | Source |
|---------|-------|--------|
| HTTP binding | `*:80` | `applicationHost.config` line 13; `setup-iis.ps1` line 36 |
| HTTPS binding | `*:443` | `applicationHost.config` line 14; `setup-iis.ps1` line 37 |
| HTTPS redirect rule | Redirect HTTP → HTTPS (301) | `web.config` lines 15–19; `urlrewrite.config` lines 5–9 |
| HSTS outbound rule | `max-age=31536000; includeSubDomains` | `urlrewrite.config` lines 91–99 |
| `UseHsts()` | Enabled for non-Development environments | `Program.cs` line 35 |
| `UseHttpsRedirection()` | Enabled | `Program.cs` line 41 |
| SMTP SSL | `EnableSsl: false` (internal relay) | `appsettings.json` line 14 |

### 8.2 Migration Strategy — SSL / TLS Settings

| Item | Action |
|------|--------|
| SSL certificate | Upload to App Service or use **App Service Managed Certificate** (free) / **Azure Key Vault certificate**. Custom domains require certificate binding in App Service → Custom Domains. |
| HTTPS redirect | Enable "HTTPS Only" in App Service → TLS/SSL Settings. Remove IIS URL Rewrite HTTPS redirect rule. Keep `app.UseHttpsRedirection()` as defense-in-depth. |
| HSTS header | Already handled by `app.UseHsts()` in `Program.cs`. Remove the IIS outbound rule. |
| HTTP/HTTPS bindings | App Service manages these automatically. No manual binding configuration needed. |
| SMTP relay | Internal `smtp-relay.cascade.local` requires VNet integration or Hybrid Connection. Consider migrating to **Azure Communication Services** or **SendGrid**. |

---

## 9. Additional IIS Dependencies

### 9.1 In-Memory Session State

| Setting | Value | Source |
|---------|-------|--------|
| Session provider | `AddDistributedMemoryCache()` (in-process) | `Program.cs` line 21 |
| Idle timeout | 30 minutes | `Program.cs` line 23 |
| Cookie settings | HttpOnly, IsEssential | `Program.cs` lines 24–25 |

**Migration Strategy:** In-memory session does not survive App Service instance restarts or scale-out. Replace with **Azure Redis Cache** using `AddStackExchangeRedisCache()` for distributed session state.

### 9.2 Internal Service Dependencies

| Service | Endpoint | Protocol |
|---------|----------|----------|
| SQL Server | `sql-cascade-hr-prod.cascade.local` / `sql-cascade-hr-staging.cascade.local` | TCP 1433, Windows Auth |
| Payroll API | `http://payroll-internal.cascade.local/api` | HTTP, API Key |
| Document Service | `http://docs-internal.cascade.local` | HTTP |
| SMTP Relay | `smtp-relay.cascade.local:25` | SMTP, no SSL |
| File Server | `\\fileserver\hr-documents`, `\\fileserver\payslips` | SMB/UNC |

**Migration Strategy:** All internal `.cascade.local` services require **VNet Integration** with the App Service, plus either **ExpressRoute** or **Site-to-Site VPN** to reach on-premises. Azure Private DNS Zones must be configured for name resolution.

### 9.3 SMTP Configuration

| Setting | Value |
|---------|-------|
| Host | `smtp-relay.cascade.local` |
| Port | 25 |
| SSL | Disabled |
| From | `noreply@cascade-hr.com` |

**Migration Strategy:** Replace with **Azure Communication Services Email** or **SendGrid** (available as Azure Marketplace add-on). If keeping on-prem relay, route via VNet integration. Port 25 is blocked on Azure by default — use port 587 with TLS.

---

## 10. Migration Priority Matrix

| Priority | Item | Risk | Effort | Blocking |
|----------|------|------|--------|----------|
| 🔴 P0 | Windows Authentication → Entra ID | High | High | Yes |
| 🔴 P0 | SQL Integrated Security → Managed Identity / SQL Auth | High | Medium | Yes |
| 🟠 P1 | VNet Integration for internal services | High | Medium | Yes |
| 🟠 P1 | File shares → Azure Blob Storage / Azure Files | Medium | Medium | Yes |
| 🟠 P1 | ARR proxy rules → YARP or APIM | Medium | Medium | Yes |
| 🟡 P2 | URL rewrite rules → ASP.NET Core middleware | Low | Low–Medium | No |
| 🟡 P2 | Config transforms → App Service Configuration + Key Vault | Low | Low | No |
| 🟡 P2 | Session state → Azure Redis Cache | Medium | Low | No |
| 🟢 P3 | SMTP relay → Azure Communication Services / SendGrid | Low | Low | No |
| 🟢 P3 | SSL certificates → App Service Managed Certs | Low | Low | No |
| 🟢 P3 | Custom error pages (already portable) | None | None | No |
| 🟢 P3 | HSTS / HTTPS settings (already in middleware) | None | None | No |
