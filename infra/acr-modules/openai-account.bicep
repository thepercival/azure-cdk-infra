param location string
param foundryResourceName string
param roleAssignments array
param logAnalyticsWorkspaceId string
param deployments array
param projects array
param sku object

@secure()
param administratorPrincipalId string

resource resOpenaiAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' = {
  name: foundryResourceName
  location: location
  kind: 'AIServices'
  sku: sku
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
resource foundryRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignments: {
  name: guid(resOpenaiAccount.id, administratorPrincipalId, roleAssignment.roleDefinitionId)
  scope: resOpenaiAccount
  properties: {
    principalId: administratorPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
    principalType: roleAssignment.principalType
  }
}]

// Diagnostic settings for Application Insights integration
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'openai-analytics-${resOpenaiAccount.name}'
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

module modAiModelDeployments 'br/modules:openai-modeldeployments:latest' = {
  name: 'modAiModelDeployments'
  params: {
    accountName: resOpenaiAccount.name
    deployments: deployments
    
  }
}

module modAiProjects 'br/modules:openai-project:latest' =  [for project in projects: {
  name: 'modAiProject-${project.name}'
  params: {
    accountName: resOpenaiAccount.name
    name: project.name
    description: project.description
    location: location
    roleAssignments: project.roleAssignments
  }
}
]

// Deploy budget alert for resource group
// module modBudget 'br/modules:budget:latest' = {
//   name: 'openai-account-budget'
//   params: {
//     budgetName: '${budget.name}'
//     amount: budget.amount
//     contactEmails: budget.contactEmails
//     startDate: budget.startDate
//   }
// }

output endpoint string = resOpenaiAccount.properties.endpoint
output resourceName string = foundryResourceName
output resourceId string = resOpenaiAccount.id
output principalId string = resOpenaiAccount.identity.principalId
output roleAssignments array = roleAssignments // [for assignment in roleAssignments: assignment.roleDefinitionId]
