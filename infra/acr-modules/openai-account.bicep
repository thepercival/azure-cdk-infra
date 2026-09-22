import { FoundryAccountRoleAssignment } from 'types.bicep'

param environment string
param location string
param openAiAccountName string
param roleAssignments FoundryAccountRoleAssignment[]
param logAnalyticsWorkspaceId string
param deployments array
param projects array
param dashboard object
param sku object
param apiGateway object

resource resOpenaiAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' = {
  name: openAiAccountName
  location: location
  kind: 'AIServices'
  sku: sku
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: openAiAccountName
    publicNetworkAccess: 'Enabled'
    allowProjectManagement: true
  }
}

module modOpenaiAccountRoleAssignment './openai-account-roleassignments.bicep' = {
  name: 'modOpenaiAccountRoleAssignment'
  params: {
    openAiAccountName: resOpenaiAccount.name
    roleAssignments: roleAssignments
  }
}



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

module modAiProjects 'openai-project.bicep' = [for project in projects: if(project.deploy[environment]) {
  name: 'modAiProject-${project.name}'
  dependsOn: [ modAiModelDeployments ]
  params: {
    accountName: resOpenaiAccount.name
    name: '${project.name}-${environment}'
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
    openaiAccountName: resOpenaiAccount.name
    tokenLimitTpmPerSubscription: apiGateway.tokenLimitTpmPerSubscription
  }
}


output endpoint string = resOpenaiAccount.properties.endpoint
output resourceName string = resOpenaiAccount.name
output resourceId string = resOpenaiAccount.id
output principalId string = resOpenaiAccount.identity.principalId
output roleAssignments array = roleAssignments // [for assignment in roleAssignments: assignment.roleDefinitionId]
