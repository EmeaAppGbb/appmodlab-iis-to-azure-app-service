@description('Location for all resources')
param location string

@description('Environment name')
param environmentName string

@description('Base name for resources')
param baseName string = 'cascade-hr'

@description('Certificate common name for the self-signed dev/test certificate')
param selfSignedCertCN string = 'cascade-hr-dev.azurewebsites.net'

@description('Certificate validity in months')
param certValidityInMonths int = 12

var keyVaultName = '${baseName}-kv-${environmentName}'

// ──────────────────────────────────────────────
// Azure Key Vault
// ──────────────────────────────────────────────
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enabledForDeployment: true
    enabledForTemplateDeployment: true
  }
}

// ──────────────────────────────────────────────
// Self-signed certificate for development/testing
// NOTE: Do NOT use self-signed certificates in production.
// For production, use App Service Managed Certificates or
// import a CA-issued certificate into Key Vault.
// ──────────────────────────────────────────────
resource selfSignedCert 'Microsoft.KeyVault/vaults/certificates@2023-02-01' = {
  parent: keyVault
  name: 'dev-self-signed-cert'
  properties: {
    issuerParameters: {
      name: 'Self'
    }
    keyProperties: {
      exportable: true
      keySize: 2048
      keyType: 'RSA'
      reuseKey: true
    }
    secretProperties: {
      contentType: 'application/x-pkcs12'
    }
    x509CertificateProperties: {
      subject: 'CN=${selfSignedCertCN}'
      subjectAlternativeNames: {
        dnsNames: [
          selfSignedCertCN
        ]
      }
      validityInMonths: certValidityInMonths
      keyUsage: [
        'digitalSignature'
        'keyEncipherment'
      ]
      ekus: [
        '1.3.6.1.5.5.7.3.1' // Server Authentication
      ]
    }
    lifetimeActions: [
      {
        action: {
          actionType: 'AutoRenew'
        }
        trigger: {
          daysBeforeExpiry: 30
        }
      }
    ]
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output selfSignedCertSecretId string = selfSignedCert.properties.secretId
output selfSignedCertName string = selfSignedCert.name
