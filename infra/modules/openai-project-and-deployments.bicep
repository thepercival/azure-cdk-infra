param accountName string
param projectName string
param projectDescription string
param deployments array
param projectRoleAssignments array
@secure()
param administratorPrincipalId string

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' existing = {
  name: accountName
}

resource resAiProject 'Microsoft.CognitiveServices/accounts/projects@2026-03-01' = {
  parent: foundryAccount
  name: projectName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectName
    description: projectDescription
  }
}

resource modelDeployments 'Microsoft.CognitiveServices/accounts/projects/deployments@2026-03-01' = [for deployment in deployments: {
  parent: resAiProject
  name: deployment.deploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: deployment.capacity
  }
  properties: {
    model: {
      format: deployment.modelFormat
      name: deployment.modelName
      version: deployment.modelVersion
    }
  }
}]

// Role assignments at project level
resource resProjectRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for projectRoleAssignment in projectRoleAssignments: {
  name: guid(resAiProject.id, administratorPrincipalId, projectRoleAssignment.roleDefinitionId)
  scope: resAiProject
  properties: {
    principalId: administratorPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', projectRoleAssignment.roleDefinitionId)
    principalType: projectRoleAssignment.principalType
  }
}]

output deploymentNames array = deployments // [for deployment in deployments: deployment.deploymentName]
