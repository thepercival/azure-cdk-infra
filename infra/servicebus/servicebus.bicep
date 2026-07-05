param environmentName string
param location string = resourceGroup().location

var serviceBusName = 'sb-core-${environmentName}'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2026-01-01' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    // Disable SAS key authentication — RBAC only
    disableLocalAuth: true
  }
}

output serviceBusNamespaceName string = serviceBusName
output serviceBusEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint
output serviceBusHostname string = '${serviceBusName}.servicebus.windows.net'
