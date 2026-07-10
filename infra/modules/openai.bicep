param location string
param foundryResourceName string
param users array
param projectTemplate object
param accountRoleAssignments array = []
param logAnalyticsWorkspaceId string

// Transform users + projectTemplate into projects array
var projects = [for user in users: {
  name: '${projectTemplate.name}-${user.principalName}'
  displayName: '${projectTemplate.displayName} - ${user.principalName}'
  description: '${projectTemplate.description} for ${user.principalName}'
  user: user
  roleAssignmentsTemplate: projectTemplate.roleAssignments
  deploymentsTemplate: projectTemplate.deployments
}]

resource foundryResource 'Microsoft.CognitiveServices/accounts@2026-03-01' = {
  name: foundryResourceName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
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

resource aiProjects 'Microsoft.CognitiveServices/accounts/projects@2026-03-01' = [for project in projects: {
  parent: foundryResource
  name: project.name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: project.displayName
    description: project.description
  }
}]

// Deploy models to each project using child module
// Process 1 project at a time for sequential deployment
@batchSize(1)
module projectDeployments 'openai-project-deployments.bicep' = [for (project, i) in projects: {
  name: 'deployments-${project.name}'
  params: {
    accountName: foundryResource.name
    projectName: aiProjects[i].name
    user: project.user
    deploymentsTemplate: project.deploymentsTemplate
    roleAssignmentsTemplate: project.roleAssignmentsTemplate
  }
  dependsOn: [
    aiProjects[i]
  ]
}]

// Role assignments at account level (for account-wide management permissions)
resource foundryRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in accountRoleAssignments: {
  name: guid(foundryResource.id, assignment.principalId, assignment.roleDefinitionId)
  scope: foundryResource
  properties: {
    principalId: assignment.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
    principalType: assignment.?principalType ?? 'User'
  }
}]

// Diagnostic settings for Application Insights integration
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'send-to-log-analytics'
  scope: foundryResource
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

output endpoint string = foundryResource.properties.endpoint
output resourceName string = foundryResourceName
output principalId string = foundryResource.identity.principalId
output projects array = [for (project, i) in projects: {
  name: aiProjects[i].name
  displayName: project.displayName
  endpoint: '${foundryResource.properties.endpoint}projects/${aiProjects[i].name}/'
  deployments: projectDeployments[i].outputs.deploymentNames
}]
