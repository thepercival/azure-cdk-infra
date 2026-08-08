param location string
param servicebusName string

resource serviceBusNamespace 'Microsoft.serviceBus/namespaces@2026-01-01' = {
  name: servicebusName
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

output serviceBusNamespaceName string = servicebusName
output serviceBusEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint
output serviceBusHostname string = '${servicebusName}.serviceBus.windows.net'
