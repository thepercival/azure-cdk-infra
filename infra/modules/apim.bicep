param location string
param apimName string
param publisherEmail string
param publisherName string
param skuName string
param skuCapacity int
// param openaiEndpoint string
// param openaiAccountName string
param logAnalyticsWorkspaceId string
// param tokenLimitTpmPerSubscription int = 10000

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
// Named value: AI Foundry endpoint (for reference in policies / portal)
// ─────────────────────────────────────────────
// resource resNamedValueEndpoint 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
//   parent: resApimService
//   name: 'foundry-openai-endpoint'
//   properties: {
//     displayName: 'foundry-openai-endpoint'
//     value: openaiEndpoint
//     secret: false
//   }
// }

// ─────────────────────────────────────────────
// Backend: AI Foundry OpenAI endpoint with circuit breaker
// Trips on HTTP 429 (throttle) and 5xx; respects Retry-After header
// ─────────────────────────────────────────────
// resource resBackend 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
//   parent: resApimService
//   name: 'foundry-openai-backend'
//   properties: {
//     description: 'Azure AI Foundry / OpenAI backend'
//     url: '${openaiEndpoint}openai'
//     protocol: 'http'
//     circuitBreaker: {
//       rules: [
//         {
//           name: 'openaiCircuitBreaker'
//           failureCondition: {
//             count: 3
//             errorReasons: [ 'Server Errors' ]
//             interval: 'PT10S'
//             statusCodeRanges: [
//               { min: 429, max: 429 }
//               { min: 500, max: 599 }
//             ]
//           }
//           tripDuration: 'PT60S'
//           acceptRetryAfter: true
//         }
//       ]
//     }
//   }
// }

// ─────────────────────────────────────────────
// API: Azure OpenAI / AI Foundry (OpenAI-compatible surface)
// api-key header mirrors the Azure OpenAI SDK contract so clients need no changes
// ─────────────────────────────────────────────
// resource resApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
//   parent: resApimService
//   name: 'azure-openai'
//   properties: {
//     displayName: 'Azure OpenAI'
//     description: 'Azure AI Foundry OpenAI-compatible gateway API'
//     path: 'openai'
//     protocols: [ 'https' ]
//     subscriptionRequired: true
//     subscriptionKeyParameterNames: {
//       header: 'api-key'
//       query: 'api-key'
//     }
//     serviceUrl: '${openaiEndpoint}openai'
//     isCurrent: true
//   }
// }

// ─────────────────────────────────────────────
// AI Gateway policy (applied to all operations on the API):
//   1. Authenticate APIM → AI Foundry via managed identity (no API keys in config)
//   2. Token-rate-limit per subscription key (cost control)
//   3. Emit token-usage metrics to Azure Monitor (observability)
//   4. Route to AI Foundry backend
// ─────────────────────────────────────────────
// var policyXml = '<policies><inbound><base /><authentication-managed-identity resource="https://cognitiveservices.azure.com" output-token-variable-name="msi-access-token" /><set-header name="Authorization" exists-action="override"><value>@("Bearer " + (string)context.Variables["msi-access-token"])</value></set-header><azure-openai-token-limit counter-key="@(context.Subscription.Id)" tokens-per-minute="${tokenLimitTpmPerSubscription}" estimate-prompt-tokens="true" remaining-tokens-header-name="x-ratelimit-remaining-tokens" remaining-tokens-variable-name="remainingTokens" /><azure-openai-emit-token-metric namespace="AzureOpenAI"><dimension name="Subscription ID" value="@(context.Subscription.Id)" /><dimension name="API Name" value="@(context.Api.Name)" /><dimension name="Operation ID" value="@(context.Operation.Id)" /></azure-openai-emit-token-metric><set-backend-service backend-id="foundry-openai-backend" /></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'

// resource resApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-06-01-preview' = {
//   parent: resApi
//   name: 'policy'
//   properties: {
//     format: 'rawxml'
//     value: policyXml
//   }
// }

// ─────────────────────────────────────────────
// Role assignment: APIM MSI → Cognitive Services User on AI Foundry account
// Enables keyless authentication from the gateway to the model backend
// ─────────────────────────────────────────────
// resource resFoundryAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' existing = {
//   name: openaiAccountName
// }

// resource resRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   // Cognitive Services User: a97b65f3-24c7-4388-baec-2e87135dc908
//   name: guid(resApimService.id, resFoundryAccount.id, 'a97b65f3-24c7-4388-baec-2e87135dc908')
//   scope: resFoundryAccount
//   properties: {
//     principalId: resApimService.identity.principalId
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')
//     principalType: 'ServicePrincipal'
//   }
// }

// ─────────────────────────────────────────────
// Diagnostic settings → Log Analytics
// ─────────────────────────────────────────────
resource resDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
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
