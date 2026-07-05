param environmentName string
param location string = resourceGroup().location

module serviceBus './servicebus.bicep' = {
  name: 'servicebus'
  params: {
    environmentName: environmentName
    location: location
  }
}

output serviceBusNamespaceName string = serviceBus.outputs.serviceBusNamespaceName
output serviceBusEndpoint string = serviceBus.outputs.serviceBusEndpoint
output serviceBusHostname string = serviceBus.outputs.serviceBusHostname
