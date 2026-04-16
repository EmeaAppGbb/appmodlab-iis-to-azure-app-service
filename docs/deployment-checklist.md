# Cascade HR Portal — Pre-Deployment Checklist

Use this checklist before deploying to Azure App Service to ensure all dependencies are in place.

---

## 1. Entra ID App Registration

- [ ] App registration created in Microsoft Entra ID (Azure AD)
- [ ] Redirect URI configured: `https://<app-service-name>.azurewebsites.net/signin-oidc`
- [ ] Client ID and Tenant ID recorded
- [ ] ID tokens enabled under **Authentication** > **Implicit grant and hybrid flows**
- [ ] API permissions granted (e.g., `User.Read`) and admin consent provided
- [ ] App Service Easy Auth configured with the registered application (if using built-in auth)

## 2. Azure Resources Provisioned

- [ ] Resource Group created
- [ ] App Service Plan created (Linux or Windows, .NET 9 runtime)
- [ ] App Service created and assigned to the plan
- [ ] Azure SQL Database provisioned and firewall rules configured
- [ ] Azure Blob Storage account created with containers: `hr-documents`, `payslips`
- [ ] Application Insights resource created and linked to App Service
- [ ] Azure Key Vault provisioned
- [ ] App Service Managed Identity enabled and granted Key Vault access policies

## 3. Connection Strings Configured

- [ ] `ConnectionStrings__HRDatabase` set to Azure SQL connection string
- [ ] `AzureStorage__ConnectionString` set to Blob Storage connection string
- [ ] `PayrollApi__BaseUrl` updated to the cloud-accessible payroll API endpoint
- [ ] `SmtpSettings` updated for cloud-compatible email delivery (e.g., SendGrid, Azure Communication Services)
- [ ] All connection strings use **App Service Configuration** or **Key Vault References** (not plain text in appsettings.json)

## 4. Key Vault Secrets Populated

- [ ] `HRDatabase-ConnectionString` — Azure SQL connection string
- [ ] `AzureStorage-ConnectionString` — Blob Storage connection string
- [ ] `PayrollApi-ApiKey` — Payroll integration API key
- [ ] `ApplicationInsights-ConnectionString` — Application Insights connection string
- [ ] App Service configuration entries use Key Vault reference syntax:
      `@Microsoft.KeyVault(SecretUri=https://<vault-name>.vault.azure.net/secrets/<secret-name>)`

## 5. Deployment Slot Settings

- [ ] **Staging** deployment slot created
- [ ] Slot-sticky settings configured for environment-specific values:
  - `ASPNETCORE_ENVIRONMENT` (`Staging` vs `Production`)
  - `ApplicationInsights__ConnectionString` (separate instance per slot, if desired)
- [ ] Auto-swap or manual swap strategy documented
- [ ] Smoke tests defined for slot warm-up

## 6. Health Check Verification

- [ ] App Service **Health Check** path configured (e.g., `/health` or `/Home/Index`)
- [ ] Health check endpoint validates:
  - Application startup (HTTP 200)
  - Database connectivity
  - Blob Storage reachability
- [ ] Health check threshold and failure actions reviewed in App Service settings
- [ ] Application Insights availability test configured (optional)
- [ ] Alerts configured for health check failures and key metrics (response time, error rate)

---

## Post-Deployment Verification

- [ ] Application loads without errors at `https://<app-service-name>.azurewebsites.net`
- [ ] Authentication flow works end-to-end (login → redirect → authenticated pages)
- [ ] Database operations succeed (leave requests, timesheets)
- [ ] Document upload/download works via Blob Storage
- [ ] Application Insights receives telemetry data
- [ ] Logs are flowing in App Service **Log Stream** and/or Application Insights
