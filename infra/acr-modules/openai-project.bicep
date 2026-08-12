param accountName string
param projectName string
param projectDescription string
param projectLocation string

param projectRoleAssignments array

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

// Role assignments at project level
resource resProjectRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for projectRoleAssignment in projectRoleAssignments: if(projectRoleAssignment.projectPrincipalId != null) {
  name: guid(resAiProject.id, projectRoleAssignment.projectPrincipalId, projectRoleAssignment.roleDefinitionId)
  scope: resAiProject
  properties: {
    principalId: projectRoleAssignment.projectPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', projectRoleAssignment.roleDefinitionId)
    principalType: projectRoleAssignment.projectPrincipalType
  }
}]

output openaiProjectEndpoint string = foundryAccount.properties.endpoint
output openaiProjectName string = resAiProject.name
output openaiProjectId string = resAiProject.id
output openaiProjectPrincipalId string = resAiProject.identity.principalId
