param apimName string
param openaiAccountName string
param tokenLimitTpmPerSubscription string

var openaiEndpoint = 'https://${openaiAccountName}.cognitiveservices.azure.com/'

// ─────────────────────────────────────────────
// APIM Service (system-assigned MSI for keyless auth to AI Foundry)
// ─────────────────────────────────────────────
resource resApimService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimName  
}


// ─────────────────────────────────────────────
// Named value: AI Foundry endpoint (for reference in policies / portal)
// ─────────────────────────────────────────────
resource resNamedValueEndpoint 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  parent: resApimService
  name: 'openai-${openaiAccountName}-endpoint'
  properties: {
    displayName: 'foundry-openai-${openaiAccountName}-endpoint'
    value: openaiEndpoint
    secret: false
  }
}

// ─────────────────────────────────────────────
// Backend: AI Foundry OpenAI endpoint with circuit breaker
// Trips on HTTP 429 (throttle) and 5xx; respects Retry-After header
//
//
resource resBackend 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  parent: resApimService
  name: 'openai-${openaiAccountName}-backend'
  properties: {
    description: 'Azure OpenAI backend'
    url: '${openaiEndpoint}openai'
    protocol: 'http'
    circuitBreaker: {
      rules: [
        {
          name: 'openaiCircuitBreaker'
          failureCondition: {
            count: 3
            errorReasons: [ 'Server Errors' ]
            interval: 'PT10S'
            statusCodeRanges: [
              { min: 429, max: 429 }
              { min: 500, max: 599 }
            ]
          }
          tripDuration: 'PT60S'
          acceptRetryAfter: true
        }
      ]
    }
  }
}

// ─────────────────────────────────────────────
// API: Azure OpenAI / AI Foundry (OpenAI-compatible surface)
// api-key header mirrors the Azure OpenAI SDK contract so clients need no changes
// ─────────────────────────────────────────────
resource resApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  parent: resApimService
  name: 'azure-openai-${openaiAccountName}'
  properties: {
    displayName: 'Azure OpenAI ${openaiAccountName}'
    description: 'Azure OpenAI ${openaiAccountName} OpenAI-compatible gateway API'
    path: 'openai'
    protocols: [ 'https' ]
    subscriptionRequired: true
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
    serviceUrl: '${openaiEndpoint}openai'
    isCurrent: true
  }
}

// ─────────────────────────────────────────────
// AI Gateway policy (applied to all operations on the API):
//   1. Authenticate APIM → AI Foundry via managed identity (no API keys in config)
//   2. Token-rate-limit per subscription key (cost control)
//   3. Emit token-usage metrics to Azure Monitor (observability)
//   4. Route to AI Foundry backend
// ─────────────────────────────────────────────
// {TOKEN_LIMIT} is substituted at deploy time from the tokenLimitTpmPerSubscription parameter
var policyXmlTmp = replace(loadTextContent('apim-openai-policy.xml'), '{TOKEN_LIMIT}', string(tokenLimitTpmPerSubscription))
var policyXml = replace(policyXmlTmp, '{OPENAI_ACCOUNT_NAME}', openaiAccountName)

resource resApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-06-01-preview' = {
  parent: resApi
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: policyXml
  }
}

// ─────────────────────────────────────────────
// Role assignment: APIM MSI → Cognitive Services User on AI Foundry account
// Enables keyless authentication from the gateway to the model backend
// ─────────────────────────────────────────────
resource resFoundryAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' existing = {
  name: openaiAccountName
}

resource resRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // Cognitive Services User: a97b65f3-24c7-4388-baec-2e87135dc908
  name: guid(resApimService.id, resFoundryAccount.id, 'a97b65f3-24c7-4388-baec-2e87135dc908')
  scope: resFoundryAccount
  properties: {
    principalId: resApimService.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')
    principalType: 'ServicePrincipal'
  }
}



output apimServiceId string = resApimService.id
output apimGatewayUrl string = resApimService.properties.gatewayUrl
output apimPrincipalId string = resApimService.identity.principalId
