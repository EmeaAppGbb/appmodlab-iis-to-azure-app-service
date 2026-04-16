@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string

@description('SQL Server administrator login')
param sqlAdminLogin string

@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string

@description('Base name for resources')
param baseName string = 'cascade-hr'

var keyVaultName = '${baseName}-kv-${environmentName}'
var appConfigName = '${baseName}-appconf-${environmentName}'

// ──────────────────────────────────────────────
// Monitoring (Log Analytics + Application Insights)
// ──────────────────────────────────────────────
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    location: location
    environmentName: environmentName
    baseName: baseName
  }
}

// ──────────────────────────────────────────────
// Storage Account with blob containers
// ──────────────────────────────────────────────
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    environmentName: environmentName
    baseName: baseName
  }
}

// ──────────────────────────────────────────────
// Azure SQL Database
// ──────────────────────────────────────────────
module sqlDatabase 'modules/sql-database.bicep' = {
  name: 'sql-deployment'
  params: {
    location: location
    environmentName: environmentName
    baseName: baseName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

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
  }
}

// ──────────────────────────────────────────────
// Azure App Configuration
// ──────────────────────────────────────────────
resource appConfiguration 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: appConfigName
  location: location
  sku: {
    name: 'free'
  }
}

// ──────────────────────────────────────────────
// App Service (with staging slot & managed identity)
// ──────────────────────────────────────────────
module appService 'modules/app-service.bicep' = {
  name: 'app-service-deployment'
  params: {
    location: location
    environmentName: environmentName
    baseName: baseName
    appInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    appInsightsInstrumentationKey: monitoring.outputs.applicationInsightsInstrumentationKey
    sqlConnectionString: sqlDatabase.outputs.connectionString
    storageAccountName: storage.outputs.storageAccountName
    storageBlobEndpoint: storage.outputs.primaryBlobEndpoint
    keyVaultUri: keyVault.properties.vaultUri
    appConfigurationEndpoint: appConfiguration.properties.endpoint
  }
}

// ──────────────────────────────────────────────
// RBAC: App Service managed identity → Key Vault Secrets User
// ──────────────────────────────────────────────
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appService.outputs.appServicePrincipalId, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: appService.outputs.appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ──────────────────────────────────────────────
// RBAC: App Service managed identity → Storage Blob Data Contributor
// ──────────────────────────────────────────────
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.outputs.storageAccountId, appService.outputs.appServicePrincipalId, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: appService.outputs.appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Reference the storage account for RBAC scope
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storage.outputs.storageAccountName
}

// ──────────────────────────────────────────────
// RBAC: App Service managed identity → App Configuration Data Reader
// ──────────────────────────────────────────────
var appConfigDataReaderRoleId = '516239f1-63e1-4d78-a4de-a74fb236a071'

resource appConfigRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appConfiguration.id, appService.outputs.appServicePrincipalId, appConfigDataReaderRoleId)
  scope: appConfiguration
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', appConfigDataReaderRoleId)
    principalId: appService.outputs.appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────
output appServiceDefaultHostName string = appService.outputs.appServiceDefaultHostName
output appServiceName string = appService.outputs.appServiceName
output sqlServerFqdn string = sqlDatabase.outputs.sqlServerFqdn
output storageAccountName string = storage.outputs.storageAccountName
output keyVaultName string = keyVault.name
output appConfigurationName string = appConfiguration.name
output applicationInsightsName string = monitoring.outputs.applicationInsightsConnectionString
