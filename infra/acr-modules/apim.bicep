param location string
param apimName string
param publisherEmail string
param publisherName string
param skuName string
param skuCapacity int
param logAnalyticsWorkspaceId string


// ─────────────────────────────────────────────
// APIM Service (system-assigned MSI for keyless auth to AI Foundry)
// ─────────────────────────────────────────────
resource resApimService 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
    }
  }
}



// ─────────────────────────────────────────────
// Diagnostic settings → Log Analytics
// ─────────────────────────────────────────────
resource resDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-log-analytics'
  scope: resApimService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output apimServiceId string = resApimService.id
output apimGatewayUrl string = resApimService.properties.gatewayUrl
output apimPrincipalId string = resApimService.identity.principalId
