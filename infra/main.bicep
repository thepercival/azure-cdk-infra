param location string = resourceGroup().location
param environment string
param administratorPrincipalId string

param logAnalyticsWorkspace object
param serviceBus object
param openaiAccount object
param openaiProject object
param budget object
param dashboard object

module modLogAnalyticsWorkspace './modules/logAnalyticsWorkspace.bicep' = {
  name: 'logAnalyticsWorkspace'
  params: {
    logAnalyticsWorkspaceName: '${logAnalyticsWorkspace.name}-${environment}'
    location: location
  }
}

module modServicebus './modules/serviceBus.bicep' = {
  name: 'serviceBus'
  params: {
    servicebusName: '${serviceBus.name}-${environment}'
    location: location
  }
}

module modOpenaiAccount 'modules/openai-account.bicep' = if(openaiAccount.deployOnEnvironment == environment) {
  name: 'modOpenaiAccount'
  params: {
    location: location
    foundryResourceName: openaiAccount.name
    accountRoleAssignments: openaiAccount.accountRoleAssignments
    logAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
    administratorPrincipalId: administratorPrincipalId
  }
}


module modAiProjectAndDeployments 'modules/openai-project-and-deployments.bicep' = if(openaiAccount.deployOnEnvironment == environment) {
  name: 'modAiProject'
  params: {
    accountName: modOpenaiAccount.?outputs.resourceName ?? 'not possible'
    projectName: openaiProject.name
    projectDescription: openaiProject.description
    deployments: openaiProject.deployments
    roleAssignmentsTemplate: openaiProject.roleAssignmentsTemplate
    administratorPrincipalId: administratorPrincipalId
  }
}

// Deploy monitoring dashboard for token usage and costs
module modDashboardOpenaiCosts 'modules/dashboard-openai-costs.bicep' = if( openaiAccount.deployOnEnvironment == environment) {
  name: 'modDashboardOpenaiCosts'
  params: {
    dashboardName: dashboard.name
    location: dashboard.location
    logAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
    aiServicesAccountName: openaiAccount.name
    administratorPrincipalId: administratorPrincipalId
  }
}

// Deploy budget alert for resource group
module modBudget 'modules/budget.bicep' = if( openaiAccount.deployOnEnvironment == environment) {
  name: 'budget-foundry-dev'
  params: {
    budgetName: '${budget.name}'
    amount: budget.amount
    contactEmails: budget.contactEmails
    startDate: budget.startDate
  }
}

output logAnalyticsWorkspaceId string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceName

output serviceBusNamespaceName string = modServicebus.outputs.serviceBusNamespaceName
output serviceBusEndpoint string = modServicebus.outputs.serviceBusEndpoint
output serviceBusHostname string = modServicebus.outputs.serviceBusHostname
