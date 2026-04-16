@description('Location for all resources')
param location string

@description('Environment name')
param environmentName string

@description('Base name for resources')
param baseName string = 'cascade-hr'

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('SQL Server connection string base (without credentials)')
param sqlConnectionString string

@description('Storage account name')
param storageAccountName string

@description('Storage blob endpoint')
param storageBlobEndpoint string

@description('Key Vault URI')
param keyVaultUri string

@description('App Configuration endpoint')
param appConfigurationEndpoint string

@description('Key Vault certificate secret ID for SSL binding (from Key Vault certificate)')
param keyVaultCertSecretId string = ''

@description('Key Vault resource ID for SSL certificate import')
param keyVaultId string = ''

@description('Key Vault certificate name for SSL binding')
param keyVaultCertName string = ''

@description('Custom domain name for SSL binding (leave empty to skip custom domain setup)')
param customDomainName string = ''

var appServicePlanName = '${baseName}-plan-${environmentName}'
var appServiceName = '${baseName}-app-${environmentName}'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  properties: {
    reserved: true // Required for Linux
  }
}

resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'KeyVault__Endpoint'
          value: keyVaultUri
        }
        {
          name: 'AppConfiguration__Endpoint'
          value: appConfigurationEndpoint
        }
        {
          name: 'Storage__BlobEndpoint'
          value: storageBlobEndpoint
        }
        {
          name: 'Storage__AccountName'
          value: storageAccountName
        }
      ]
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: sqlConnectionString
          type: 'SQLAzure'
        }
      ]
    }
  }
}

resource stagingSlot 'Microsoft.Web/sites/slots@2022-09-01' = {
  parent: appService
  name: 'staging'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'KeyVault__Endpoint'
          value: keyVaultUri
        }
        {
          name: 'AppConfiguration__Endpoint'
          value: appConfigurationEndpoint
        }
        {
          name: 'Storage__BlobEndpoint'
          value: storageBlobEndpoint
        }
        {
          name: 'Storage__AccountName'
          value: storageAccountName
        }
      ]
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: sqlConnectionString
          type: 'SQLAzure'
        }
      ]
    }
  }
}

// ──────────────────────────────────────────────
// SSL Certificate from Key Vault (conditional on custom domain)
// ──────────────────────────────────────────────
resource sslCertificate 'Microsoft.Web/certificates@2022-09-01' = if (!empty(customDomainName) && !empty(keyVaultId) && !empty(keyVaultCertName)) {
  name: '${appServiceName}-ssl-cert'
  location: location
  properties: {
    keyVaultId: keyVaultId
    keyVaultSecretName: keyVaultCertName
    serverFarmId: appServicePlan.id
    password: ''
  }
}

// ──────────────────────────────────────────────
// Custom domain hostname binding with SSL (conditional)
// ──────────────────────────────────────────────
resource customDomainBinding 'Microsoft.Web/sites/hostNameBindings@2022-09-01' = if (!empty(customDomainName)) {
  parent: appService
  name: customDomainName
  properties: {
    sslState: (!empty(keyVaultId) && !empty(keyVaultCertName)) ? 'SniEnabled' : 'Disabled'
    thumbprint: (!empty(keyVaultId) && !empty(keyVaultCertName)) ? sslCertificate.properties.thumbprint : null
  }
}

output appServiceId string = appService.id
output appServiceName string = appService.name
output appServiceDefaultHostName string = appService.properties.defaultHostName
output appServicePrincipalId string = appService.identity.principalId
output stagingSlotPrincipalId string = stagingSlot.identity.principalId
