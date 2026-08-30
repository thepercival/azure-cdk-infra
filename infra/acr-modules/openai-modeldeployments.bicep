param accountName string
param deployments array

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2026-03-01' existing = {
  name: accountName
}

@batchSize(1)
resource modelDeployments 'Microsoft.CognitiveServices/accounts/deployments@2026-03-01' = [for deployment in deployments: {
  parent: foundryAccount
  name: deployment.deploymentName
  sku: {
    name: deployment.skuName
    capacity: deployment.capacity
  }
  properties: {
    model: {
      format: deployment.modelFormat
      name: deployment.modelName
      version: deployment.modelVersion
    }
  }
}]

output deploymentNames array = deployments // [for deployment in deployments: deployment.deploymentName]
