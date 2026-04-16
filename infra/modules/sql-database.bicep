@description('Location for all resources')
param location string

@description('Environment name')
param environmentName string

@description('Base name for resources')
param baseName string = 'cascade-hr'

@description('SQL Server administrator login')
param sqlAdminLogin string

@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string

var sqlServerName = '${baseName}-sql-${environmentName}'
var sqlDatabaseName = '${baseName}-db-${environmentName}'

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
  }
}

// Allow Azure services to access the SQL Server
resource firewallRuleAzureServices 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2 GB
  }
}

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${sqlDatabase.name};'
