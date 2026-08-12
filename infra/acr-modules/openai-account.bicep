param environment string
param location string
param foundryResourceName string
param roleAssignments array
param logAnalyticsWorkspaceId string
param deployments array
param projects array
param dashboard object
param sku object
param apiGateway object

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

module modAiModelDeployments 'openai-modeldeployments.bicep' = {
  name: 'modAiModelDeployments'
  params: {
    accountName: resOpenaiAccount.name
    deployments: deployments
    
  }
}

module modAiProjects 'openai-project.bicep' =  [for project in projects: {
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

// Deploy monitoring dashboard for token usage and costs
module modDashboardOpenaiCosts 'openai-account-dashboard.bicep' = {
  name: 'modDashboardOpenaiCosts'
  params: {
    dashboardName: '${dashboard.namePrefix}-${resOpenaiAccount.name}'
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    aiServicesAccountName: resOpenaiAccount.name
  }
}



module modApimOpenAi 'apim-openai.bicep' = {
  name: 'apimOpenAi'
  params: {
    apimName: '${apiGateway.name}-${environment}'
    openaiAccountName: foundryResourceName
    tokenLimitTpmPerSubscription: apiGateway.tokenLimitTpmPerSubscription
  }
}


output endpoint string = resOpenaiAccount.properties.endpoint
output resourceName string = foundryResourceName
output resourceId string = resOpenaiAccount.id
output principalId string = resOpenaiAccount.identity.principalId
output roleAssignments array = roleAssignments // [for assignment in roleAssignments: assignment.roleDefinitionId]
