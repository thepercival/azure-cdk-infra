param accountName string
param projectName string
param projectDescription string
param projectLocation string
param deployments array
param projectRoleAssignments array
@secure()
param administratorPrincipalId string
param administratorPrincipalType string = 'User'

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' existing = {
  name: accountName
}

resource resAiProject 'Microsoft.CognitiveServices/accounts/projects@2026-03-01' = {
  parent: foundryAccount
  name: projectName
  location: projectLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectName
    description: projectDescription
  }
}

@batchSize(1)
resource modelDeployments 'Microsoft.CognitiveServices/accounts/deployments@2026-03-01' = [for deployment in deployments: {
  parent: foundryAccount
  name: deployment.deploymentName
  dependsOn: [resAiProject]
  sku: {
    name: deployment.skuName
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
    principalType: administratorPrincipalType
  }
}]

output deploymentNames array = deployments // [for deployment in deployments: deployment.deploymentName]
