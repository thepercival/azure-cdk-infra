// ACR name: alphanumeric only, 5-50 chars, globally unique
@minLength(5)
@maxLength(50)
param name string

param location string

@allowed(['Basic', 'Standard', 'Premium'])
param skuName string = 'Basic'

resource resContainerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output loginServer string = resContainerRegistry.properties.loginServer
output registryName string = resContainerRegistry.name
