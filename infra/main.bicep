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

@description('Minimum number of App Service instances for autoscale')
param minInstanceCount int = 1

@description('Maximum number of App Service instances for autoscale')
param maxInstanceCount int = 5

@description('Default number of App Service instances for autoscale')
param defaultInstanceCount int = 2

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
// Azure Key Vault (with self-signed dev certificate)
// ──────────────────────────────────────────────
module keyVault 'modules/key-vault.bicep' = {
  name: 'key-vault-deployment'
  params: {
    location: location
    environmentName: environmentName
    baseName: baseName
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
    keyVaultUri: keyVault.outputs.keyVaultUri
    appConfigurationEndpoint: appConfiguration.properties.endpoint
  }
}

// ──────────────────────────────────────────────
// Auto-Scaling for App Service Plan
// ──────────────────────────────────────────────
module autoscale 'modules/autoscale.bicep' = {
  name: 'autoscale-deployment'
  params: {
    location: location
    environmentName: environmentName
    baseName: baseName
    appServicePlanId: appService.outputs.appServicePlanId
    minInstanceCount: minInstanceCount
    maxInstanceCount: maxInstanceCount
    defaultInstanceCount: defaultInstanceCount
  }
}

// ──────────────────────────────────────────────
// RBAC: App Service managed identity → Key Vault Secrets User
// ──────────────────────────────────────────────
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource kvSecretsRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultRef.id, appService.outputs.appServicePrincipalId, keyVaultSecretsUserRoleId)
  scope: keyVaultRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: appService.outputs.appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ──────────────────────────────────────────────
// RBAC: App Service managed identity → Key Vault Certificate User
// ──────────────────────────────────────────────
var keyVaultCertificateUserRoleId = 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba'

resource kvCertificateRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultRef.id, appService.outputs.appServicePrincipalId, keyVaultCertificateUserRoleId)
  scope: keyVaultRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultCertificateUserRoleId)
    principalId: appService.outputs.appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Reference the Key Vault for RBAC scope
resource keyVaultRef 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVault.outputs.keyVaultName
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
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultCertSecretId string = keyVault.outputs.selfSignedCertSecretId
output appConfigurationName string = appConfiguration.name
output applicationInsightsName string = monitoring.outputs.applicationInsightsConnectionString
