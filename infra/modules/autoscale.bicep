@description('Location for the autoscale resource')
param location string

@description('Environment name')
param environmentName string

@description('Base name for resources')
param baseName string = 'cascade-hr'

@description('Resource ID of the App Service Plan to scale')
param appServicePlanId string

@description('Minimum number of instances')
param minInstanceCount int = 1

@description('Maximum number of instances')
param maxInstanceCount int = 5

@description('Default number of instances')
param defaultInstanceCount int = 2

var autoscaleSettingName = '${baseName}-autoscale-${environmentName}'

resource autoscaleSetting 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: autoscaleSettingName
  location: location
  properties: {
    enabled: true
    targetResourceUri: appServicePlanId
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: string(minInstanceCount)
          maximum: string(maxInstanceCount)
          default: string(defaultInstanceCount)
        }
        rules: [
          // Scale-out: CPU > 70% for 10 minutes
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlanId
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          // Scale-in: CPU < 30% for 10 minutes
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlanId
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          // Scale-out: HTTP requests > 100 per instance for 5 minutes
          {
            metricTrigger: {
              metricName: 'HttpQueueLength'
              metricResourceUri: appServicePlanId
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 100
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}

output autoscaleSettingId string = autoscaleSetting.id
output autoscaleSettingName string = autoscaleSetting.name
