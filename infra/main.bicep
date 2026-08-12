param location string = resourceGroup().location
param environment string
@secure()
param administratorPrincipalId string

param logAnalyticsWorkspace object
param applicationInsights object
param serviceBus object
param openaiAccount object
param openaiDeployments array
param openaiProject object
param budget object
param dashboard object
param apim object

module modLogAnalyticsWorkspace 'br/modules:log-analytics-workspace:latest' = {
  name: 'logAnalyticsWorkspace'
  params: {
    logAnalyticsWorkspaceName: '${logAnalyticsWorkspace.name}-${environment}'
    location: location
  }
}

module modApplicationInsights 'br/modules:application-insights:latest' = {
  name: 'applicationInsights'
  params: {
    applicationInsightsName: '${applicationInsights.name}-${environment}'
    location: location
    logAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
  }
}

module modServicebus 'br/modules:servicebus:latest' = {
  name: 'serviceBus'
  params: {
    servicebusName: '${serviceBus.name}-${environment}'
    location: location
  }
}

module modOpenai 'br/modules:openai:latest' = if(openaiAccount.deployOnEnvironment == environment) {
  name: 'modOpenai'
  params: {
    location: location
    logAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
    openaiAccount: openaiAccount
    openaiProject: openaiProject
    openaiDeployments: openaiDeployments
    budget: budget
    administratorPrincipalId: administratorPrincipalId  
  }
}

module modOpenaiProject 'br/modules:openai-project:latest' = if(openaiAccount.deployOnEnvironment == environment) {
  name: 'modOpenaiProject'
  params: {
    accountName: openaiAccount.name
    projectName: openaiProject.name
    projectDescription: openaiProject.description
    projectLocation: openaiProject.location == '' ? location : openaiProject.location
    projectRoleAssignments: openaiProject.roleAssignments
  }
}
var openaiProjectEndpoint string = modOpenaiProject.outputs?.openaiProjectEndpoint

// Deploy monitoring dashboard for token usage and costs
module modDashboardOpenaiCosts 'dashboard-openai-costs.bicep' = {
  name: 'modDashboardOpenaiCosts'
  params: {
    dashboardName: dashboard.name
    location: location
    logAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
    aiServicesAccountName: openaiAccount.name
  }
}

module modApim 'br/modules:apim:latest' = {
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

module modApimOpenAi 'br/modules:apim-openai:latest' = if(openaiAccount.deployOnEnvironment == environment) {
  name: 'apimOpenAi'
  params: {
    apimName: '${apim.name}-${environment}'
    openaiEndpoint: openaiProjectEndpoint
    openaiAccountName: openaiProject.name
    tokenLimitTpmPerSubscription: apim.tokenLimitTpmPerSubscription
  }
}


output logAnalyticsWorkspaceId string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceName

output serviceBusNamespaceName string = modServicebus.outputs.serviceBusNamespaceName
output serviceBusEndpoint string = modServicebus.outputs.serviceBusEndpoint
output serviceBusHostname string = modServicebus.outputs.serviceBusHostname

output apimGatewayUrl string = modApim.outputs.apimGatewayUrl
output apimServiceId string = modApim.outputs.apimServiceId
