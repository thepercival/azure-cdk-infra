param location string = resourceGroup().location
param environment string
@secure()
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

module modOpenai 'modules/openai.bicep' = if(openaiAccount.deployOnEnvironment == environment) {
  name: 'modOpenai'
  params: {
    location: location
    logAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
    openaiAccount: openaiAccount
    openaiProject: openaiProject
    dashboard: dashboard
    budget: budget
    administratorPrincipalId: administratorPrincipalId  
  }
}

output logAnalyticsWorkspaceId string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceName

output serviceBusNamespaceName string = modServicebus.outputs.serviceBusNamespaceName
output serviceBusEndpoint string = modServicebus.outputs.serviceBusEndpoint
output serviceBusHostname string = modServicebus.outputs.serviceBusHostname
