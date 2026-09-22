import { FoundryProjectRoleAssignment } from './types.bicep'

param accountName string
param name string
param description string
param location string
param roleAssignments FoundryProjectRoleAssignment[]

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
module modFoundryProjectRoleAssignments './openai-project-roleassignments.bicep' = {
  name: 'modFoundryProjectRoleAssignments'
  params: {
    foundryProjectName: name
    roleAssignments: roleAssignments
  }
}


// output endpoint string = resOpenAiAccount.properties.endpoint
output name string = resAiProject.name
output id string = resAiProject.id
output principalId string = resAiProject.identity.principalId
