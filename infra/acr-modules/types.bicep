// Shared user-defined types for acr-modules bicep files.

@export()
@description('A single RBAC role assignment on a Foundry (Cognitive Services) account.')
type FoundryAccountRoleAssignmentTemplate = {
  @description('Just for documentation purposes — the principal.')
  principalName: string

  @description('Type of the principal being assigned the role.')
  principalType: string?

  @description('GUID of the built-in or custom role definition to assign. Must match the Foundry Project Manager role.')
  roleDefinitionId: 'eadc314b-1a2d-4efa-be10-5d325db5065e'

  @description('Human-readable role name, for documentation purposes only — not used by the deployment.')
  roleName: 'Foundry Project Manager'
}

@export()
@description('A FoundryAccountRoleAssignment after principalId has been resolved (never null).')
type FoundryAccountRoleAssignment = {
  principalId: string
  principalType: 'User' | 'ServicePrincipal' | 'Group'
  roleDefinitionId: 'eadc314b-1a2d-4efa-be10-5d325db5065e'
  roleName: 'Foundry Project Manager'
}
