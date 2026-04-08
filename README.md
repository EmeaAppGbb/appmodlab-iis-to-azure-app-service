# 🎮 IIS to Azure App Service Migration Lab 🚀

```
 ██▓ ██▓  ██████     ▄▄▄█████▓ ▒█████      ▄████▄   ██▓     ▒█████   █    ██ ▓█████▄ 
▓██▒▓██▒▒██    ▒     ▓  ██▒ ▓▒▒██▒  ██▒   ▒██▀ ▀█  ▓██▒    ▒██▒  ██▒ ██  ▓██▒▒██▀ ██▌
▒██▒▒██▒░ ▓██▄       ▒ ▓██░ ▒░▒██░  ██▒   ▒▓█    ▄ ▒██░    ▒██░  ██▒▓██  ▒██░░██   █▌
░██░░██░  ▒   ██▒    ░ ▓██▓ ░ ▒██   ██░   ▒▓▓▄ ▄██▒▒██░    ▒██   ██░▓▓█  ░██░░▓█▄   ▌
░██░░██░▒██████▒▒      ▒██▒ ░ ░ ████▓▒░   ▒ ▓███▀ ░░██████▒░ ████▓▒░▒▒█████▓ ░▒████▓ 
░▓  ░▓  ▒ ▒▓▒ ▒ ░      ▒ ░░   ░ ▒░▒░▒░    ░ ░▒ ▒  ░░ ▒░▓  ░░ ▒░▒░▒░ ░▒▓▒ ▒ ▒  ▒▒▓  ▒ 
 ▒ ░ ▒ ░░ ░▒  ░ ░        ░      ░ ▒ ▒░      ░  ▒   ░ ░ ▒  ░  ░ ▒ ▒░ ░░▒░ ░ ░  ░ ▒  ▒ 
 ▒ ░ ▒ ░░  ░  ░        ░      ░ ░ ░ ▒     ░          ░ ░   ░ ░ ░ ▒   ░░░ ░ ░  ░ ░  ░ 
 ░   ░        ░                   ░ ░     ░ ░          ░  ░    ░ ░     ░        ░    
                                          ░                                    ░      
```

## 🌟 **LEVEL SELECT: IIS FORTRESS → CLOUD MIGRATION** 🌟

Welcome to the **ultimate migration quest** — transporting your battle-tested IIS fortress 🏰 from the server room to the stratosphere ☁️! This lab takes you through a **classic .NET migration journey**: decommissioning on-prem IIS infrastructure and launching into Azure App Service with zero downtime, auto-scaling superpowers, and managed certificates that never expire.

This is the **fastest win** for cloud adoption and the most common Azure migration path for .NET web workloads. Time to dust off those legacy configs and give them a cloud makeover! ✨

---

## 📡 **MISSION BRIEFING: OVERVIEW**

**Business Domain:** 🏢 **Cascade Human Resources** — Employee Self-Service HR Portal  
**Legacy System:** ASP.NET Core 6.0 running on **IIS 10** (Windows Server 2019)  
**Mission:** Migrate to **Azure App Service** with modern auth, storage, and deployment

### 🔌 **RACK MOUNTED: The Legacy Stack**

Your on-premises HR portal is **fully IIS-dependent**:
- ⚙️ **IIS URL Rewrite Module 2.1** — 20+ complex rewrite rules
- 🛡️ **Windows Authentication** (Negotiate/NTLM via IIS)
- 📂 **IIS Virtual Directories** — pointing to network file shares (`\\fileserver\hr-documents`)
- 🔐 **SSL Certificate** — PFX file bound to IIS site
- 🔄 **Application Request Routing (ARR)** — reverse proxy to internal payroll service
- 🏊 **Application Pool** — specific identity, recycling at 2:00 AM daily
- 📝 **Custom HTTP Modules** — request logging in the IIS pipeline
- 🗂️ **Web.config Transforms** — environment-specific settings
- 🗄️ **SQL Server 2019** — on a separate server with trusted connection via app pool identity

### 🚀 **CLOUD LIFT-OFF: Target Architecture**

After migration, you'll be running on **Azure App Service** with:
- ☁️ **Azure App Service** (Linux or Windows plan)
- 🆔 **Entra ID + Easy Auth** (replacing Windows Auth)
- 🗂️ **Azure Blob Storage** (replacing virtual directories)
- 🔐 **App Service Managed Certificates** (or Azure Key Vault)
- 🔄 **ASP.NET Core Middleware** (replacing IIS URL Rewrite)
- 🎰 **Deployment Slots** (blue-green deployments, zero downtime)
- 📊 **Auto-Scaling Rules** (CPU + request count based)
- 📈 **Application Insights** (observability++)
- ⚙️ **Azure App Configuration + Key Vault** (config management)
- 🌐 **Azure Application Gateway / Front Door** (replacing ARR proxy)
- 🗃️ **Azure SQL Database with Managed Identity**

---

## 🎯 **ACHIEVEMENTS UNLOCKED: What You'll Learn**

By completing this lab, you'll master:

✅ **IIS Configuration Auditing** — Catalog URL rewrites, virtual dirs, auth settings, handlers  
✅ **URL Rewrite Migration** — Convert IIS rewrite rules to ASP.NET Core middleware  
✅ **Authentication Modernization** — Windows Auth → Entra ID Easy Auth  
✅ **File Storage Migration** — Virtual directories → Azure Blob Storage SDK  
✅ **App Service Deployment** — Deployment slots, auto-scaling, managed certificates  
✅ **Blue-Green Deployments** — Zero-downtime swaps with staging slots  
✅ **Infrastructure as Code** — Bicep templates for App Service, SQL, Blob, Key Vault  
✅ **CI/CD Pipelines** — GitHub Actions with slot swaps  

---

## 🕹️ **PREREQUISITES: PLAYER STATS**

Before you boot up this quest, make sure you have:

- 🧑‍💻 **ASP.NET Core experience** (and IIS administration knowledge)
- ☁️ **Azure subscription** with Contributor access
- 🛠️ **Azure CLI** installed and authenticated
- 🔧 **.NET 9 SDK** (solution targets .NET 9, legacy is .NET 6)
- 🆔 **Basic understanding of Entra ID / Azure AD**
- 🖥️ **GitHub Copilot CLI** (for step-by-step guidance)

---

## ⚡ **QUICK START: INSERT COIN**

```bash
# 🎮 CLONE THE REPOSITORY
git clone https://github.com/EmeaAppGbb/appmodlab-iis-to-azure-app-service.git
cd appmodlab-iis-to-azure-app-service

# 🔀 START WITH THE LEGACY BRANCH
git checkout legacy

# 📋 REVIEW THE LAB GUIDE
# Open APPMODLAB.md for full walkthrough

# 🚀 BEGIN YOUR MIGRATION
# Follow the step-by-step branches:
# step-1-iis-assessment
# step-2-url-rewrite-migration
# step-3-auth-migration
# step-4-storage-migration
# step-5-app-service-deploy
```

---

## 🗺️ **PROJECT STRUCTURE: MAP LAYOUT**

```
CascadeHRPortal/
├── 🏗️ CascadeHRPortal.sln                 # Solution file
├── 🌐 CascadeHRPortal.Web/                # Main web application
│   ├── 📄 CascadeHRPortal.Web.csproj
│   ├── 🚀 Program.cs
│   ├── ⚙️ web.config                      # IIS-specific configuration (legacy)
│   ├── 🎮 Controllers/
│   │   ├── LeaveController.cs             # Leave request management
│   │   ├── TimesheetController.cs         # Timesheet submission
│   │   ├── PayslipController.cs           # Payslip viewing
│   │   ├── ProfileController.cs           # Employee profile
│   │   ├── BenefitsController.cs          # Benefits enrollment
│   │   └── DirectoryController.cs         # Employee directory
│   ├── 👁️ Views/                           # Razor views
│   ├── 📦 wwwroot/                         # Static assets
│   └── ⚙️ appsettings.json                 # Connection strings, SMTP config
├── ⚙️ CascadeHRPortal.Services/           # Business logic layer
│   ├── LeaveService.cs
│   ├── TimesheetService.cs
│   ├── PayrollIntegration.cs              # External payroll API calls
│   └── DocumentService.cs                 # File access (legacy virtual dirs)
├── 🖥️ IIS-Config/                          # IIS-specific configurations
│   ├── applicationHost.config             # IIS site settings
│   ├── urlrewrite.config                  # 20+ URL rewrite rules
│   ├── web.config.transform.staging       # Staging transform
│   ├── web.config.transform.prod          # Production transform
│   └── setup-iis.ps1                      # PowerShell IIS setup
├── 🗄️ Database/
│   └── schema.sql                         # HR database schema
├── ☁️ Infrastructure/                      # Bicep templates (solution branch)
│   ├── main.bicep                         # Main deployment
│   ├── app-service.bicep                  # App Service with slots
│   ├── sql.bicep                          # Azure SQL Database
│   ├── storage.bicep                      # Blob Storage
│   └── monitoring.bicep                   # Application Insights
└── 🚀 .github/workflows/
    └── deploy.yml                         # CI/CD pipeline (solution branch)
```

---

## 🏰 **LEGACY STACK: THE OLD FORTRESS**

### 🔧 **IIS Configuration Details**

Your IIS setup includes:

| Component | Configuration |
|-----------|---------------|
| 🔄 **URL Rewrite Rules** | Legacy URL redirects, API versioning, trailing slash normalization |
| 🏊 **Application Pool** | .NET CLR No Managed Code, recycling at 2:00 AM daily |
| 📂 **Virtual Directories** | `/documents` → `\\fileserver\hr-documents`<br>`/payslips` → `\\fileserver\payslips` |
| 🛡️ **Authentication** | Windows Authentication enabled, Anonymous disabled |
| ❌ **Error Pages** | Custom 403/404/500 error pages |
| 📝 **Logging** | Custom HTTP module for request logging |
| 🔐 **SSL** | PFX certificate from internal CA bound to port 443 |
| 🔀 **ARR Proxy** | `/api/payroll/*` → internal payroll service |

### 🗃️ **Database Schema**

- 👥 **Employees** — EmployeeId, FirstName, LastName, Email, Department, Manager, HireDate, Status
- 🏖️ **LeaveRequests** — RequestId, EmployeeId, LeaveType, StartDate, EndDate, Status, ApproverId, Notes
- ⏰ **Timesheets** — TimesheetId, EmployeeId, WeekStartDate, Hours, ProjectCode, Status, ApprovedBy
- 🏥 **Benefits** — BenefitId, EmployeeId, PlanType, CoverageLevel, EffectiveDate, EndDate
- 📄 **Documents** — DocumentId, EmployeeId, DocumentType, FilePath, UploadDate, Category

### 🚨 **Legacy Anti-Patterns Detected**

- 🔗 **IIS-specific URL rewrite rules** — not portable to other hosts
- 📂 **Virtual directories** — pointing to network file shares
- 🛡️ **Windows Authentication** — tightly coupled to IIS/Active Directory
- 🔄 **Config transforms** — web.config.transform for environment management
- 📝 **Custom HTTP module** — IIS pipeline dependency
- 🔀 **ARR proxy rules** — routing to internal services
- 🔐 **Manual SSL certificate management** — PFX files
- 🔑 **Application pool identity** — used for SQL Server trusted connection
- ❓ **No health check endpoints**
- 🚫 **Manual deployment** — Web Deploy publish from Visual Studio

---

## ☁️ **TARGET ARCHITECTURE: THE CLOUD COMMAND CENTER**

### 🎯 **Architecture Description**

The IIS-hosted application moves to **Azure App Service** with minimal code changes but **massive infrastructure modernization**:

| Legacy Component | Azure Replacement | 🎮 Migration Level |
|------------------|-------------------|--------------------|
| 🔄 IIS URL Rewrite | ASP.NET Core Middleware | ⭐⭐⭐ |
| 🛡️ Windows Authentication | Entra ID + Easy Auth | ⭐⭐⭐⭐ |
| 📂 Virtual Directories | Azure Blob Storage | ⭐⭐⭐ |
| 🔄 Config Transforms | App Configuration + Key Vault | ⭐⭐ |
| 🔐 SSL Certificate | Managed Certificates | ⭐ |
| 🔀 ARR Proxy | Application Gateway / Front Door | ⭐⭐⭐⭐ |
| 🚀 Manual Deployment | Deployment Slots + GitHub Actions | ⭐⭐⭐ |

---

## 🎮 **LAB WALKTHROUGH: STAGE SELECT**

### 🗺️ **Branch Structure: Level Progression**

| Branch | Description | 🎯 Objective |
|--------|-------------|--------------|
| 🏠 `main` | Completed lab with APPMODLAB.md | Reference & documentation |
| 🏰 `legacy` | IIS-hosted application | **START HERE** — The fortress |
| ✅ `solution` | Azure App Service-hosted app | **END GOAL** — Cloud victory |
| 🔍 `step-1-iis-assessment` | IIS configuration audit | Catalog all IIS dependencies |
| 🔄 `step-2-url-rewrite-migration` | Convert rewrite rules | ASP.NET Core middleware |
| 🆔 `step-3-auth-migration` | Windows Auth → Entra ID | Easy Auth setup |
| 📂 `step-4-storage-migration` | Virtual dirs → Blob Storage | Azure Storage SDK |
| 🚀 `step-5-app-service-deploy` | App Service deployment | Slots, scaling, CI/CD |

### 🕹️ **Using GitHub Copilot CLI**

This lab is designed to be completed with **GitHub Copilot CLI** guiding you through each step:

```bash
# 🔍 STEP 1: IIS ASSESSMENT
git checkout step-1-iis-assessment
gh copilot suggest "help me audit IIS URL rewrite rules in urlrewrite.config"
gh copilot suggest "what IIS-specific features need migration in web.config"

# 🔄 STEP 2: URL REWRITE MIGRATION
git checkout step-2-url-rewrite-migration
gh copilot suggest "convert this IIS URL rewrite rule to ASP.NET Core middleware"
gh copilot suggest "create RewriteMiddleware for legacy URL compatibility"

# 🆔 STEP 3: AUTHENTICATION MIGRATION
git checkout step-3-auth-migration
gh copilot suggest "configure Entra ID app registration for Easy Auth"
gh copilot suggest "replace Windows Authentication with Entra ID in ASP.NET Core"

# 📂 STEP 4: STORAGE MIGRATION
git checkout step-4-storage-migration
gh copilot suggest "replace IIS virtual directory access with Azure Blob Storage"
gh copilot suggest "update DocumentService to use Azure.Storage.Blobs SDK"

# 🚀 STEP 5: APP SERVICE DEPLOYMENT
git checkout step-5-app-service-deploy
gh copilot suggest "create Azure App Service with deployment slots using Bicep"
gh copilot suggest "configure auto-scaling rules for App Service based on CPU"
gh copilot suggest "set up GitHub Actions workflow with slot swap deployment"
```

### 📋 **Step-by-Step Journey**

#### 🔍 **LEVEL 1: IIS Configuration Audit**
- Catalog all URL rewrite rules (`urlrewrite.config`)
- Document virtual directory mappings
- Export Windows Authentication settings
- Review custom HTTP modules and handlers
- Create migration checklist

#### 🔄 **LEVEL 2: URL Rewrite Migration**
- Translate IIS rewrite rules to ASP.NET Core `RewriteMiddleware`
- Handle legacy URL redirects (301/302)
- Implement API versioning rewrites
- Test all URL patterns
- Remove IIS URL Rewrite Module dependency

#### 🆔 **LEVEL 3: Authentication Migration**
- Create Entra ID app registration
- Configure redirect URIs and API permissions
- Enable App Service Easy Auth
- Update authorization policies
- Test user authentication flow
- Remove Windows Authentication

#### 📂 **LEVEL 4: File Storage Migration**
- Create Azure Blob Storage account
- Migrate files from network shares to containers
- Update `DocumentService` to use Azure Storage SDK
- Configure managed identity access
- Remove virtual directory dependencies
- Test document upload/download

#### 🚀 **LEVEL 5: App Service Deployment**
- Create App Service plan (choose Linux or Windows)
- Deploy application to staging slot
- Configure app settings from App Configuration
- Set up Key Vault references for secrets
- Configure managed certificate for SSL
- Create auto-scaling rules (CPU & request count)
- Set up GitHub Actions CI/CD
- Perform slot swap to production
- Validate all HR portal features

---

## ⏱️ **DURATION: TIME ATTACK**

**Estimated Completion Time:** ⏰ **3–5 hours**

- 🔍 Step 1 (IIS Assessment): ~30 minutes
- 🔄 Step 2 (URL Rewrite Migration): ~45 minutes
- 🆔 Step 3 (Authentication Migration): ~1 hour
- 📂 Step 4 (Storage Migration): ~1 hour
- 🚀 Step 5 (App Service Deployment): ~1.5–2 hours

💡 **Pro Tip:** Use GitHub Copilot CLI to speed-run the migration — it's like having a strategy guide built into your terminal!

---

## 📚 **RESOURCES: POWER-UPS**

### 🔧 **Official Documentation**
- 📘 [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- 🔄 [IIS to App Service Migration Guide](https://learn.microsoft.com/en-us/azure/app-service/app-service-migration-guide)
- 🆔 [App Service Easy Auth](https://learn.microsoft.com/en-us/azure/app-service/overview-authentication-authorization)
- 🎰 [Deployment Slots](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots)
- 📊 [Auto-Scaling in App Service](https://learn.microsoft.com/en-us/azure/app-service/manage-scale-up)
- 🗂️ [Azure Blob Storage SDK](https://learn.microsoft.com/en-us/azure/storage/blobs/)

### 🛠️ **Tools & References**
- 🔧 [ASP.NET Core URL Rewrite Middleware](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/url-rewriting)
- 🔐 [Azure Key Vault References](https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references)
- ⚙️ [Azure App Configuration](https://learn.microsoft.com/en-us/azure/azure-app-configuration/)
- 🚀 [GitHub Actions for Azure](https://learn.microsoft.com/en-us/azure/developer/github/github-actions)

### 🎮 **Community**
- 💬 Questions? Open an issue in the repository
- 🌟 Completed the lab? Drop a star and share your experience!
- 🤝 Contributions welcome — PRs for improvements appreciated

---

## 🔌 **DECOMMISSION COMPLETE: GAME OVER**

Congratulations, **Cloud Migrator**! 🎉 You've successfully transported your IIS fortress from the server room to Azure App Service. Your HR portal now runs with:

✅ **Zero-downtime deployments** (blue-green slot swaps)  
✅ **Auto-scaling** (handle traffic spikes like a boss)  
✅ **Managed certificates** (SSL that never expires)  
✅ **Modern authentication** (Entra ID with Easy Auth)  
✅ **Cloud-native storage** (Azure Blob Storage)  
✅ **Full observability** (Application Insights)  

**Achievement Unlocked:** 🏆 **IIS Migration Master**

Now go forth and migrate all the .NET workloads! The cloud awaits. ☁️✨

---

```
 ▄████▄   ██▓     ▒█████   █    ██ ▓█████▄     ██▓     ██▓  █████▒▄▄▄█████▓ ▒█████    █████▒  █████▒
▒██▀ ▀█  ▓██▒    ▒██▒  ██▒ ██  ▓██▒▒██▀ ██▌   ▓██▒    ▓██▒▓██   ▒ ▓  ██▒ ▓▒▒██▒  ██▒▓██   ▒ ▓██   ▒ 
▒▓█    ▄ ▒██░    ▒██░  ██▒▓██  ▒██░░██   █▌   ▒██░    ▒██▒▒████ ░ ▒ ▓██░ ▒░▒██░  ██▒▒████ ░ ▒████ ░ 
▒▓▓▄ ▄██▒▒██░    ▒██   ██░▓▓█  ░██░░▓█▄   ▌   ▒██░    ░██░░▓█▒  ░ ░ ▓██▓ ░ ▒██   ██░░▓█▒  ░ ░▓█▒  ░ 
▒ ▓███▀ ░░██████▒░ ████▓▒░▒▒█████▓ ░▒████▓    ░██████▒░██░░▒█░      ▒██▒ ░ ░ ████▓▒░░▒█░    ░▒█░    
░ ░▒ ▒  ░░ ▒░▓  ░░ ▒░▒░▒░ ░▒▓▒ ▒ ▒  ▒▒▓  ▒    ░ ▒░▓  ░░▓   ▒ ░      ▒ ░░   ░ ▒░▒░▒░  ▒ ░     ▒ ░    
  ░  ▒   ░ ░ ▒  ░  ░ ▒ ▒░ ░░▒░ ░ ░  ░ ▒  ▒    ░ ░ ▒  ░ ▒ ░ ░          ░      ░ ▒ ▒░  ░       ░      
░          ░ ░   ░ ░ ░ ▒   ░░░ ░ ░  ░ ░  ░      ░ ░    ▒ ░ ░ ░      ░      ░ ░ ░ ▒   ░ ░     ░ ░    
░ ░          ░  ░    ░ ░     ░        ░           ░  ░ ░                       ░ ░                   
░                                   ░                                                                

           🚀 PRESS START TO MIGRATE AGAIN 🚀
```

---

**Lab Created By:** EmeaAppGbb  
**Category:** Infrastructure Modernization  
**Tags:** `IIS` `Azure App Service` `Migration` `ASP.NET Core` `.NET` `Entra ID` `Deployment Slots` `Auto-Scaling`

**🎮 INSERT COIN TO CONTINUE...**
