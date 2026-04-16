# SSL/TLS Migration Guide: IIS to Azure App Service

This guide covers migrating SSL/TLS certificates from IIS (PFX-bound) to Azure App Service, including multiple approaches for managing certificates in Azure.

## Table of Contents

- [Overview](#overview)
- [What Changes in the Migration](#what-changes-in-the-migration)
- [Approach 1: App Service Managed Certificates (Recommended)](#approach-1-app-service-managed-certificates-recommended)
- [Approach 2: Key Vault Certificates](#approach-2-key-vault-certificates)
- [Approach 3: Upload PFX Directly](#approach-3-upload-pfx-directly)
- [HTTPS Enforcement](#https-enforcement)
- [TLS Version Configuration](#tls-version-configuration)
- [Removing IIS URL Rewrite HTTPS Redirect](#removing-iis-url-rewrite-https-redirect)
- [Development and Testing](#development-and-testing)
- [Troubleshooting](#troubleshooting)

---

## Overview

In IIS, SSL is configured by:
1. Importing a PFX certificate into the Windows certificate store
2. Binding the certificate to a site on port 443
3. Using URL Rewrite rules to redirect HTTP → HTTPS

In Azure App Service, SSL is handled at the platform level:
- The default `*.azurewebsites.net` hostname has a **free, platform-managed SSL certificate** — no action needed
- Custom domains require one of three certificate approaches (described below)
- HTTPS enforcement is a single platform setting (`httpsOnly: true`)
- TLS version is configured at the platform level (`minTlsVersion: '1.2'`)

## What Changes in the Migration

| IIS Concept | Azure App Service Equivalent |
|---|---|
| PFX in Windows cert store | Key Vault certificate or App Service certificate |
| IIS HTTPS binding on port 443 | App Service hostname binding with SNI SSL |
| URL Rewrite HTTP→HTTPS redirect | `httpsOnly: true` property |
| TLS version in Schannel registry | `minTlsVersion` site property |
| Self-signed cert for dev | Key Vault self-signed certificate |

---

## Approach 1: App Service Managed Certificates (Recommended)

**Best for:** Custom domains where you want zero certificate management overhead.

App Service can automatically provision and renew a free TLS certificate for your custom domains.

### Prerequisites
- A custom domain already mapped to your App Service (CNAME or A record verified)
- App Service plan at **Basic (B1)** tier or higher

### Steps

1. **Add a custom domain to your App Service:**
   ```bash
   az webapp config hostname add \
     --webapp-name cascade-hr-app-dev \
     --resource-group your-rg \
     --hostname www.example.com
   ```

2. **Create a managed certificate:**
   ```bash
   az webapp config ssl create \
     --name cascade-hr-app-dev \
     --resource-group your-rg \
     --hostname www.example.com
   ```

3. **Bind the certificate:**
   ```bash
   az webapp config ssl bind \
     --name cascade-hr-app-dev \
     --resource-group your-rg \
     --certificate-thumbprint <thumbprint-from-step-2> \
     --ssl-type SNI
   ```

### Limitations
- Only supports apex domains and single-level subdomains
- No wildcard certificate support
- Certificate renewal is automatic (managed by Azure)

---

## Approach 2: Key Vault Certificates

**Best for:** Enterprise environments with existing certificate lifecycle management, wildcard certificates, or CA-issued certificates.

This is the approach used in our infrastructure code (`infra/modules/key-vault.bicep`).

### Step 1: Store Certificate in Key Vault

**Option A — Import an existing PFX (migrating from IIS):**
```bash
# Export PFX from IIS/Windows (on source server)
# Then import into Key Vault:
az keyvault certificate import \
  --vault-name cascade-hr-kv-dev \
  --name my-ssl-cert \
  --file ./my-cert.pfx \
  --password "<pfx-password>"
```

**Option B — Create a self-signed certificate (dev/test only):**
```bash
az keyvault certificate create \
  --vault-name cascade-hr-kv-dev \
  --name dev-self-signed-cert \
  --policy "$(az keyvault certificate get-default-policy)"
```

> **Note:** Our Bicep template (`infra/modules/key-vault.bicep`) automatically creates a self-signed certificate for development/testing.

### Step 2: Grant App Service Access to Key Vault

The App Service managed identity needs the **Key Vault Secrets User** and **Key Vault Certificate User** roles. This is already configured in `infra/main.bicep` via RBAC role assignments.

### Step 3: Import Certificate into App Service

```bash
az webapp config ssl import \
  --name cascade-hr-app-dev \
  --resource-group your-rg \
  --key-vault cascade-hr-kv-dev \
  --key-vault-certificate-name my-ssl-cert
```

### Step 4: Bind to Custom Domain

```bash
az webapp config ssl bind \
  --name cascade-hr-app-dev \
  --resource-group your-rg \
  --certificate-thumbprint <thumbprint> \
  --ssl-type SNI
```

### Certificate Renewal
- Key Vault can auto-renew certificates (configured with `lifetimeActions` in Bicep)
- App Service periodically syncs with Key Vault (within 24 hours of renewal)
- For immediate sync: `az webapp config ssl import` again

---

## Approach 3: Upload PFX Directly

**Best for:** Quick migration when you already have a PFX file and don't need Key Vault.

### Steps

1. **Upload the PFX certificate:**
   ```bash
   az webapp config ssl upload \
     --name cascade-hr-app-dev \
     --resource-group your-rg \
     --certificate-file ./my-cert.pfx \
     --certificate-password "<pfx-password>"
   ```

2. **Bind to custom domain:**
   ```bash
   az webapp config ssl bind \
     --name cascade-hr-app-dev \
     --resource-group your-rg \
     --certificate-thumbprint <thumbprint> \
     --ssl-type SNI
   ```

> **Note:** This approach requires manual certificate renewal. For automated renewal, use Approach 1 or 2.

---

## HTTPS Enforcement

In IIS, HTTPS redirect was done via URL Rewrite rules like:

```xml
<rule name="Redirect to HTTPS" stopProcessing="true">
  <match url="(.*)" />
  <conditions>
    <add input="{HTTPS}" pattern="off" ignoreCase="true" />
  </conditions>
  <action type="Redirect" url="https://{HTTP_HOST}/{R:1}" redirectType="Permanent" />
</rule>
```

**In Azure App Service**, this is replaced by a single setting:

```bicep
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  properties: {
    httpsOnly: true  // Automatically redirects HTTP to HTTPS (301)
  }
}
```

Or via CLI:
```bash
az webapp update --name cascade-hr-app-dev --resource-group your-rg --set httpsOnly=true
```

**Action:** Remove IIS URL Rewrite HTTPS redirect rules from your `web.config` — they are no longer needed and may cause redirect loops.

---

## TLS Version Configuration

In IIS, TLS versions were configured via Windows Registry (Schannel settings). In App Service, it's a platform property:

```bicep
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  properties: {
    siteConfig: {
      minTlsVersion: '1.2'  // Rejects TLS 1.0 and 1.1 connections
    }
  }
}
```

Our infrastructure enforces TLS 1.2 minimum on both production and staging slots.

---

## Removing IIS URL Rewrite HTTPS Redirect

After migration, clean up IIS-specific configuration:

1. **Remove URL Rewrite rules** from `web.config` that handle HTTP→HTTPS redirect
2. **Remove `<rewrite>` section** if it only contained the HTTPS redirect rule
3. **Verify** that `httpsOnly: true` is set on the App Service (already configured in our Bicep)

Example — remove this from `web.config`:
```xml
<system.webServer>
  <rewrite>
    <rules>
      <rule name="Redirect to HTTPS" stopProcessing="true">
        <match url="(.*)" />
        <conditions>
          <add input="{HTTPS}" pattern="off" ignoreCase="true" />
        </conditions>
        <action type="Redirect" url="https://{HTTP_HOST}/{R:1}" redirectType="Permanent" />
      </rule>
    </rules>
  </rewrite>
</system.webServer>
```

---

## Development and Testing

For local development and testing:

- The infrastructure provisions a **self-signed certificate** in Key Vault (`dev-self-signed-cert`) via `infra/modules/key-vault.bicep`
- This certificate is for development/testing purposes only — **do not use in production**
- The default `*.azurewebsites.net` hostname includes free platform-managed SSL, so no certificate configuration is needed for basic testing

### Verifying SSL Configuration

```bash
# Check HTTPS-only setting
az webapp show --name cascade-hr-app-dev --resource-group your-rg \
  --query "httpsOnly"

# Check TLS version
az webapp config show --name cascade-hr-app-dev --resource-group your-rg \
  --query "minTlsVersion"

# List SSL certificates bound to the app
az webapp config ssl list --resource-group your-rg

# Test HTTPS connectivity
curl -vI https://cascade-hr-app-dev.azurewebsites.net
```

---

## Troubleshooting

| Issue | Cause | Solution |
|---|---|---|
| Redirect loop after migration | IIS URL Rewrite rules still in `web.config` | Remove the HTTPS redirect rewrite rule |
| Certificate not found in App Service | Key Vault RBAC not configured | Verify managed identity has Key Vault Secrets User and Certificate User roles |
| TLS handshake failure | Client using TLS 1.0/1.1 | Update client or (temporarily) lower `minTlsVersion` |
| Custom domain SSL not working | DNS not verified or cert not bound | Verify domain ownership and run `az webapp config ssl bind` |
| Key Vault cert not syncing | App Service sync delay (up to 24h) | Re-import with `az webapp config ssl import` |
| 403 on Key Vault access | Wrong RBAC role | Ensure both Secrets User and Certificate User roles are assigned |
