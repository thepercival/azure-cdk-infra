param appServiceName string
param appKind string
param location string 
param additionalSharedEnvironmentVariables array
param additionalProductionOnlyEnvironmentVariables array = []
param additionalStagingOnlyEnvironmentVariables array = []
param linuxFxVersion string 
param appServicePlanId string
param appInsightsConnectionString string
param appInsightsWorkspaceResourceId string
param withStagingSlot bool
param restrictToApim bool = false
param startupCommand string = 'node dist/server.js'

var baseSharedEnvironmentVariables = [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsightsConnectionString
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~2'
  }
]

var sharedEnvironmentVariables = concat(baseSharedEnvironmentVariables, additionalSharedEnvironmentVariables)
var stagingEnvironmentVariables = concat(sharedEnvironmentVariables, additionalStagingOnlyEnvironmentVariables)
var productionEnvironmentVariables = concat(sharedEnvironmentVariables, additionalProductionOnlyEnvironmentVariables)

// only settings that can actually differ between slots need to be sticky
var stickyAppSettingNames = [for item in concat(additionalProductionOnlyEnvironmentVariables, additionalStagingOnlyEnvironmentVariables): item.name]

var apimOnlyRestrictions = [
  {
    name: 'AllowAPIM'
    description: 'Allow inbound traffic from APIM only'
    action: 'Allow'
    priority: 100
    tag: 'ServiceTag'
    ipAddress: 'ApiManagement'
  }
]
var apimRestrictionConfig = {
  ipSecurityRestrictions: apimOnlyRestrictions
  ipSecurityRestrictionsDefaultAction: 'Deny'
  scmIpSecurityRestrictions: apimOnlyRestrictions
  scmIpSecurityRestrictionsDefaultAction: 'Deny'
}
var siteConfigCommon = {
  linuxFxVersion: linuxFxVersion
  minTlsVersion: '1.2'  
  appCommandLine: startupCommand
}

var siteConfigWithApim = restrictToApim ? union(siteConfigCommon, apimRestrictionConfig) : siteConfigCommon

resource resAppService 'Microsoft.Web/sites@2025-03-01' = {
  name: appServiceName
  location: location
  kind: appKind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId    
    httpsOnly: true
    siteConfig: union(siteConfigWithApim, { appSettings: productionEnvironmentVariables })
  }
}


@description('webapp staging slot')
resource resWebAppSlot 'Microsoft.Web/sites/slots@2025-03-01' = if(withStagingSlot) {
  parent: resAppService
  name: 'staging'
  location: location
  kind: appKind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // only appSettings/appCommandLine differ from production — restrictions must stay identical
    siteConfig: union(siteConfigWithApim, { appSettings: stagingEnvironmentVariables })
  }
}

@description('marks settings that differ per slot as sticky, so a swap does not move their values, define seperate above')
resource resAppServiceSlotConfig 'Microsoft.Web/sites/config@2024-04-01' = if(withStagingSlot) {
  parent: resAppService
  name: 'slotConfigNames'
  properties: {
    appSettingNames: stickyAppSettingNames
  }
  dependsOn: [
    resWebAppSlot
  ]
}

var diagnosticsKind = contains(toLower(appKind), 'functionapp') ? 'functionapp' : 'webapp'
module diagnostics 'app-diagnostics.bicep' = {
  name: '${appServiceName}-appdiagnostics'
  params: {
    appServiceName: appServiceName
    kind: diagnosticsKind
    loganalyticsWorkspaceId: appInsightsWorkspaceResourceId
  }
  dependsOn: [
    resAppService
  ]
}

output principalId string = resAppService.identity.principalId
output url string = 'https://${resAppService.properties.defaultHostName}'
