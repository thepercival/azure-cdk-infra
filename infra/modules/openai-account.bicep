param location string
param foundryResourceName string
param accountRoleAssignments array
param logAnalyticsWorkspaceId string

@secure()
param administratorPrincipalId string

resource resOpenaiAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' = {
  name: foundryResourceName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S1'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: foundryResourceName
    publicNetworkAccess: 'Enabled'
    allowProjectManagement: true
  }
}

// Role assignments at account level (for account-wide management permissions)
resource foundryRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in accountRoleAssignments: {
  name: guid(resOpenaiAccount.id, administratorPrincipalId, assignment.roleDefinitionId)
  scope: resOpenaiAccount
  properties: {
    principalId: administratorPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
    principalType: assignment.principalType
  }
}]

// Diagnostic settings for Application Insights integration
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'send-to-log-analytics'
  scope: resOpenaiAccount
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

output endpoint string = resOpenaiAccount.properties.endpoint
output resourceName string = foundryResourceName
output resourceId string = resOpenaiAccount.id
output principalId string = resOpenaiAccount.identity.principalId
output accountRoleAssignments array = accountRoleAssignments // [for assignment in accountRoleAssignments: assignment.roleDefinitionId]
