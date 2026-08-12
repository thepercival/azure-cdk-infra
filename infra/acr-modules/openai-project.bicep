param accountName string
param name string
param description string
param location string

param roleAssignments array

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' existing = {
  name: accountName
}

resource resAiProject 'Microsoft.CognitiveServices/accounts/projects@2026-03-01' = {
  parent: foundryAccount
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: name
    description: description
  }
}

// Role assignments at project level
resource resProjectRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignments: if(roleAssignment.projectPrincipalId != null) {
  name: guid(resAiProject.id, roleAssignment.projectPrincipalId, roleAssignment.roleDefinitionId)
  scope: resAiProject
  properties: {
    principalId: roleAssignment.projectPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
    principalType: roleAssignment.projectPrincipalType
  }
}]

output openaiProjectEndpoint string = foundryAccount.properties.endpoint
output openaiProjectName string = resAiProject.name
output openaiProjectId string = resAiProject.id
output openaiProjectPrincipalId string = resAiProject.identity.principalId
