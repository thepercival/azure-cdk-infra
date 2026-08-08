param location string = resourceGroup().location
param environment string
param containerRegistry object

resource resContainerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: '${containerRegistry.name}${environment}'
  location: location
  sku: {
    name: containerRegistry.sku[environment]
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output acrLoginServer string = resContainerRegistry.properties.loginServer
output acrRegistryName string = resContainerRegistry.name
