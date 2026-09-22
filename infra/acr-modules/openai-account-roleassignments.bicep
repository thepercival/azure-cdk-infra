import { FoundryAccountRoleAssignment } from 'types.bicep'

param openAiAccountName string
param roleAssignments FoundryAccountRoleAssignment[]

resource resOpenaiAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' existing = {
  name: openAiAccountName
}

// Role assignments at account level (for account-wide management permissions)
resource foundryRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignments: {
  name: guid(resOpenaiAccount.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
  scope: resOpenaiAccount
  properties: {
    principalId: roleAssignment.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
    principalType: roleAssignment.principalType
  }
}]
