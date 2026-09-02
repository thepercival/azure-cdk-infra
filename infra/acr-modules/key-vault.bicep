param location string
param keyVaultName string
param logAnalyticsWorkspaceId string
param roleAssignments array

resource resKeyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
    enabledForTemplateDeployment: true
  }
}

resource resRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignments: {
  name: guid(resKeyVault.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
  scope: resKeyVault
  properties: {
    principalId: roleAssignment.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
    principalType: roleAssignment.principalType
  }
}]

resource resDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-log-analytics'
  scope: resKeyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output keyVaultId string = resKeyVault.id
output keyVaultName string = resKeyVault.name
output keyVaultUri string = resKeyVault.properties.vaultUri
