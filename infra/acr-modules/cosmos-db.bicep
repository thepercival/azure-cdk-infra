param accountName string
param location string
param databaseName string
param loganalyticsWorkspaceId string

resource resCosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: accountName
  location: location
  kind: 'MongoDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    capabilities: [
      { name: 'EnableMongo' }
      { name: 'EnableServerless' }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    apiProperties: {
      serverVersion: '7.0'
    }
    backupPolicy: {
      type: 'Continuous'
      continuousModeProperties: {
        tier: 'Continuous7Days'
      }
    }
  }
}

resource resDatabase 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2024-05-15' = {
  parent: resCosmosDb
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource resDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${accountName}-diagnostics'
  scope: resCosmosDb
  properties: {
    workspaceId: loganalyticsWorkspaceId
    metrics: [{ category: 'Requests', enabled: true }]
  }
}

output accountName string = resCosmosDb.name
