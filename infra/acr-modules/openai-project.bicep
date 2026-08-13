param accountName string
param name string
param description string
param location string

param roleAssignments array

resource resOpenAiAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' existing = {
  name: accountName
}

resource resAiProject 'Microsoft.CognitiveServices/accounts/projects@2026-03-01' = {
  parent: resOpenAiAccount
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

// output endpoint string = resOpenAiAccount.properties.endpoint
output name string = resAiProject.name
output id string = resAiProject.id
output principalId string = resAiProject.identity.principalId
