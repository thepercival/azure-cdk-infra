param appServiceName string

@description('The kind of the app.')
@allowed([
  'functionapp'
  'webapp'
])
param kind string

@description('Resource ID of log analytics workspace.')
param loganalyticsWorkspaceId string

param diagnosticLogCategoriesToEnable array = kind == 'functionapp' ? [
  'FunctionAppLogs'
] : [
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]


var diagnosticsLogs = [for category in diagnosticLogCategoriesToEnable: {
  category: category
  enabled: true
}]

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
}]

resource resAppServiceName 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

resource resADiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appServiceName}-diagnostics'
  scope: resAppServiceName
  properties: {
    workspaceId:  loganalyticsWorkspaceId
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
}
