param planName string
param location string
param skuName string
param skuTier string
@description('Resource ID of log analytics workspace.')
param loganalyticsWorkspaceId string

resource resAppServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: planName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    reserved: true
  }
}

param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
}]

resource resPlanDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${planName}-diagnostics'
  scope: resAppServicePlan
  properties: {
    workspaceId: loganalyticsWorkspaceId
    metrics: diagnosticsMetrics
    logs: []  // serverfarms does not have meaningful logs
  }
}

output appServicePlanId string = resAppServicePlan.id
