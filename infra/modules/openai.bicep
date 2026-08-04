param location string
param logAnalyticsWorkspaceId string
param openaiAccount object
param openaiProject object
param dashboard object
param budget object
@secure()
param administratorPrincipalId string

module modOpenaiAccount 'openai-account.bicep' = {
  name: 'modOpenaiAccount'
  params: {
    location: location
    foundryResourceName: openaiAccount.name
    accountRoleAssignments: openaiAccount.roleAssignments
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    administratorPrincipalId: administratorPrincipalId
  }
}

module modAiProjectAndDeployments 'openai-project-and-deployments.bicep' = {
  name: 'modAiProject'
  params: {
    accountName: modOpenaiAccount.outputs.resourceName
    projectName: openaiProject.name
    projectDescription: openaiProject.description
    projectLocation: openaiProject.location
    deployments: openaiProject.deployments
    projectRoleAssignments: openaiProject.roleAssignments
    administratorPrincipalId: administratorPrincipalId
  }
}

// Deploy monitoring dashboard for token usage and costs
module modDashboardOpenaiCosts 'dashboard-openai-costs.bicep' = {
  name: 'modDashboardOpenaiCosts'
  params: {
    dashboardName: dashboard.name
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    aiServicesAccountName: openaiAccount.name
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
