@description('Location for all resources')
param location string

@description('Environment name')
param environmentName string

@description('Base name for resources')
param baseName string = 'cascade-hr'

// Storage account names must be 3-24 chars, lowercase alphanumeric only
var storageAccountName = replace('${baseName}st${environmentName}', '-', '')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource hrDocumentsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServices
  name: 'hr-documents'
  properties: {
    publicAccess: 'None'
  }
}

resource payslipsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServices
  name: 'payslips'
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
