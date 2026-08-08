param location string = resourceGroup().location
param environment string
@secure()
param administratorPrincipalId string

param logAnalyticsWorkspace object
param serviceBus object
param containerRegistry object
param openaiAccount object
param openaiDeployments array
param openaiProject object
param budget object
param dashboard object
param apim object

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
    openaiDeployments: openaiDeployments
    dashboard: dashboard
    budget: budget
    administratorPrincipalId: administratorPrincipalId  
  }
}

module modContainerRegistry './modules/containerRegistry.bicep' = {
  name: 'containerRegistry'
  params: {
    // ACR names are alphanumeric-only, so no dash separator before environment
    name: '${containerRegistry.name}${environment}'
    location: location
    skuName: containerRegistry.sku[environment]
  }
}

module modApim './modules/apim.bicep' = {
  name: 'apim'
  params: {
    location: location
    apimName: '${apim.name}-${environment}'
    publisherEmail: apim.publisherEmail
    publisherName: apim.publisherName
    skuName: apim.sku[environment].name
    skuCapacity: apim.sku[environment].capacity
    // openaiEndpoint: modOpenai.outputs.endpoint
    // openaiAccountName: openaiAccount.name
    logAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
    // tokenLimitTpmPerSubscription: apim.tokenLimitTpmPerSubscription
  }
}

output logAnalyticsWorkspaceId string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceName

output serviceBusNamespaceName string = modServicebus.outputs.serviceBusNamespaceName
output serviceBusEndpoint string = modServicebus.outputs.serviceBusEndpoint
output serviceBusHostname string = modServicebus.outputs.serviceBusHostname

output apimGatewayUrl string = modApim.outputs.apimGatewayUrl
output apimServiceId string = modApim.outputs.apimServiceId

output acrLoginServer string = modContainerRegistry.outputs.loginServer
output acrRegistryName string = modContainerRegistry.outputs.registryName
