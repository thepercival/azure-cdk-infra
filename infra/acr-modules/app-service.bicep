param appServiceName string
param appKind string
param location string 
param additionEnvironmentVariables array
param linuxFxVersion string 
param appServicePlanId string
param applicationInsightsName string
 
resource resAppInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}    

var baseEnvironmentVariables = [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: resAppInsights.properties.ConnectionString
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~2'
  }
]

var environmentVariables = concat(baseEnvironmentVariables, additionEnvironmentVariables)

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
    siteConfig: {
      appSettings: environmentVariables
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
    }
  }
}


@description('webapp staging slot')
resource resWebAppSlot 'Microsoft.Web/sites/slots@2025-03-01' = {
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
    loganalyticsWorkspaceId: resAppInsights.properties.WorkspaceResourceId
  }
  dependsOn: [
    resAppService
  ]
}

output principalId string = resAppService.identity.principalId
output url string = 'https://${resAppService.properties.defaultHostName}'
