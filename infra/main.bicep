param location string = resourceGroup().location
param environmentName string

module serviceBus './servicebus.bicep' = {
  name: 'servicebus'
  params: {
    serviceBusName: 'sb-cdk-${environmentName}'
    location: location
  }
}

output serviceBusNamespaceName string = serviceBus.outputs.serviceBusNamespaceName
output serviceBusEndpoint string = serviceBus.outputs.serviceBusEndpoint
output serviceBusHostname string = serviceBus.outputs.serviceBusHostname
