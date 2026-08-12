param location string = resourceGroup().location
param environment string
@secure()
param administratorPrincipalId string

param logAnalyticsWorkspace object
param applicationInsights object
param serviceBus object
param openaiAccount object
param budget object
param apim object

module modLogAnalyticsWorkspace 'acr-modules/log-analytics-workspace.bicep' = {
  name: 'logAnalyticsWorkspace'
  params: {
    logAnalyticsWorkspaceName: '${logAnalyticsWorkspace.name}-${environment}'
    location: location
  }
}

module modApplicationInsights 'acr-modules/application-insights.bicep' = {
  name: 'applicationInsights'
  params: {
    applicationInsightsName: '${applicationInsights.name}-${environment}'
    location: location
    logAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
  }
}

// Deploy budget alert for resource group
module modBudget 'acr-modules/resourcegroup-budget.bicep' = {
  name: 'resourcegroup-${resourceGroup().name}-budget'
  params: {
    budgetName: 'resourcegroup-${resourceGroup().name}-budget'
    amount: budget.amount
    contactEmails: budget.contactEmails
    startDate: budget.startDate
  }
}

module modApim 'acr-modules/apim.bicep' = {
  name: 'apim'
  params: {
    location: location
    apimName: '${apim.name}-${environment}'
    publisherEmail: apim.publisherEmail
    publisherName: apim.publisherName
    skuName: apim.sku[environment].name
    skuCapacity: apim.sku[environment].capacity
    logAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
  }
}

module modServicebus 'acr-modules/servicebus.bicep' = {
  name: 'serviceBus'
  params: {
    servicebusName: '${serviceBus.name}-${environment}'
    location: location
  }
}
module modOpenaiAccount 'acr-modules/openai-account.bicep' = if(openaiAccount.deployOnEnvironment == environment) {
  name: 'modOpenaiAccount'
  params: {
    location: location
    sku: openaiAccount.sku
    foundryResourceName: openaiAccount.name
    roleAssignments: openaiAccount.roleAssignments
    logAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
    administratorPrincipalId: administratorPrincipalId
    deployments: openaiAccount.deployments
    projects: openaiAccount.projects
    dashboard: openaiAccount.dashboard
    apiGateway: openaiAccount.apiGateway
    environment: environment
  }
}

output logAnalyticsWorkspaceId string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceName

output serviceBusNamespaceName string = modServicebus.outputs.serviceBusNamespaceName
output serviceBusEndpoint string = modServicebus.outputs.serviceBusEndpoint
output serviceBusHostname string = modServicebus.outputs.serviceBusHostname

output apimGatewayUrl string = modApim.outputs.apimGatewayUrl
output apimServiceId string = modApim.outputs.apimServiceId
