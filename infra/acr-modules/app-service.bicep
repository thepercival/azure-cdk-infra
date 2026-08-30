param appServiceName string
param appKind string
param location string 
param additionEnvironmentVariables array
param linuxFxVersion string 
param appServicePlanId string
param appInsightsConnectionString string
param appInsightsWorkspaceResourceId string
param withStagingSlot bool
param restrictToApim bool = false
param startupCommand string = 'node dist/server.js'

var baseEnvironmentVariables = [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsightsConnectionString
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~2'
  }
]

var environmentVariables = concat(baseEnvironmentVariables, additionEnvironmentVariables)



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

var siteConfigBase = {
  appSettings: environmentVariables
  linuxFxVersion: linuxFxVersion
  minTlsVersion: '1.2'  
  appCommandLine: startupCommand
}

var siteConfig = restrictToApim ? union(siteConfigBase, {
  ipSecurityRestrictions: apimOnlyRestrictions
  ipSecurityRestrictionsDefaultAction: 'Deny'
  scmIpSecurityRestrictions: apimOnlyRestrictions
  scmIpSecurityRestrictionsDefaultAction: 'Deny'
}) : siteConfigBase

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
    siteConfig: siteConfig
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
    siteConfig: {
      appSettings: environmentVariables
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
    }
  }
}

// STICKY SLOT CONFIGURATION
// resource resAppServiceSlotConfig 'Microsoft.Web/sites/config@2024-04-01' = {
//   parent: resAppService
//   name: 'slotConfigNames'
//   properties: {
//     appSettingNames: concat([
//       'API_TOKEN'
//       'API_BASEURL'
//     ], slotSqlAppSettingNames)
//   }
// }

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
