import { FoundryProjectRoleAssignment } from 'types.bicep'

param foundryProjectName string
param roleAssignments FoundryProjectRoleAssignment[]

resource resFoundryProject 'Microsoft.CognitiveServices/accounts/projects@2026-03-01' existing = {
  name: foundryProjectName
}

resource resProjectRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignments: {
  name: guid(resFoundryProject.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
  scope: resFoundryProject
  properties: {
    principalId: roleAssignment.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
    principalType: roleAssignment.principalType
  }
}]
