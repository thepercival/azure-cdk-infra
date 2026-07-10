param accountName string
param projectName string
param user object
param deploymentsTemplate array
param roleAssignmentsTemplate array

// Expand deployments for this user
var deployments = [for deployment in deploymentsTemplate: {
  deploymentName: '${deployment.deploymentName}-${user.principalName}'
  modelName: deployment.modelName
  modelVersion: deployment.modelVersion
  modelFormat: deployment.modelFormat
  capacity: deployment.capacity
}]

// Expand role assignments for this user
var roleAssignments = [for roleTemplate in roleAssignmentsTemplate: {
  principalName: user.principalName
  principalId: user.principalId
  principalType: user.principalType
  roleName: roleTemplate.roleName
  roleDefinitionId: roleTemplate.roleDefinitionId
}]

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' existing = {
  name: accountName
}

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2026-03-01' existing = {
  parent: foundryAccount
  name: projectName
}

resource modelDeployments 'Microsoft.CognitiveServices/accounts/projects/deployments@2026-03-01' = [for deployment in deployments: {
  parent: aiProject
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
resource projectRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignments: {
  name: guid(aiProject.id, assignment.principalId, assignment.roleDefinitionId)
  scope: aiProject
  properties: {
    principalId: assignment.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
    principalType: assignment.principalType
  }
}]

output deploymentNames array = [for deployment in deployments: deployment.deploymentName]
