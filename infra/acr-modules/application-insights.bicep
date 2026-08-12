param location string
param applicationInsightsName string
param logAnalyticsWorkspaceId string

resource resApplicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output applicationInsightsId string = resApplicationInsights.id
output applicationInsightsName string = resApplicationInsights.name
output connectionString string = resApplicationInsights.properties.ConnectionString
output instrumentationKey string = resApplicationInsights.properties.InstrumentationKey
