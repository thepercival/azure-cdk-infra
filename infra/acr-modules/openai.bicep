param location string
param logAnalyticsWorkspaceId string
param openaiAccount object
param openaiProject object
param openaiDeployments array
param dashboard object
param budget object
@secure()
param administratorPrincipalId string

module modOpenaiAccount 'openai-account.bicep' = {
  name: 'modOpenaiAccount'
  params: {
    location: location
    sku: openaiAccount.sku
    foundryResourceName: openaiAccount.name
    accountRoleAssignments: openaiAccount.roleAssignments
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    administratorPrincipalId: administratorPrincipalId
  }
}


module modAiModelDeployments 'openai-modeldeployments.bicep' = {
  name: 'modAiModelDeployments'
  params: {
    accountName: modOpenaiAccount.outputs.resourceName
    deployments: openaiDeployments
  }
}

module modAiProjects 'openai-project.bicep' = {
  name: 'modAiProject'
  params: {
    accountName: modOpenaiAccount.outputs.resourceName
    projectName: openaiProject.name
    projectDescription: openaiProject.description
    projectLocation: location
    projectRoleAssignments: openaiProject.roleAssignments    
  }
}


// Deploy budget alert for resource group
module modBudget 'budget.bicep' = {
  name: 'budget-foundry-dev'
  params: {
    budgetName: '${budget.name}'
    amount: budget.amount
    contactEmails: budget.contactEmails
    startDate: budget.startDate
  }
}

output endpoint string = modOpenaiAccount.outputs.endpoint
output accountName string = modOpenaiAccount.outputs.resourceName
