param api object
param apiManagementName string
param backend object
param openapiLink string

@description('Browser origins allowed to call this API (CORS). Leave empty to add no CORS policy.')
param corsOrigins array = []

resource resApiManagement 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementName
}

resource resApiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2022-08-01' = {
  parent: resApiManagement
  name: api.versionSet.name
  properties: api.versionSet.properties
}

var updatedApiProperties = union(api.properties, {
  apiVersionSetId: resApiVersionSet.id
  format: 'openapi-link'
  value: openapiLink
})

module modApimBackend './apim-api-backend.bicep' = {
  name: 'apim-api-backend-${backend.name}'
  params: {
    apiManagementName: apiManagementName
    name: backend.name
    url: backend.url
    backendDescription: backend.description
    protocol: 'http'
  }
}

resource resApi 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  parent: resApiManagement
  name: api.name
  properties: updatedApiProperties
  dependsOn: [modApimBackend]
}

var subscriptionName = '${api.name}-appservice'

module modProduct './apim-product.bicep' = {
  name: api.product.name
  params: {
    apiName: api.name
    apiManagementName: apiManagementName
    product: api.product
    subscriptionName: subscriptionName
  }
  dependsOn: [resApi]
}

// Preflight (OPTIONS) requests are answered by the cors policy itself; no OPTIONS operations are needed.
// Multi-line strings do not interpolate, hence format().
var corsOriginsXml = join(map(corsOrigins, origin => '<origin>${origin}</origin>'), '')
var corsPolicy = empty(corsOrigins) ? '' : format('''

    <cors allow-credentials="false">
      <allowed-origins>{0}</allowed-origins>
      <allowed-methods preflight-result-max-age="300">
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>PATCH</method>
        <method>DELETE</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>Authorization</header>
        <header>Content-Type</header>
      </allowed-headers>
    </cors>''', corsOriginsXml)

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' = {
  name: 'policy'
  parent: resApi
  properties: {
    format: 'rawxml'
    value: format('''
<policies>
  <inbound>
    <base />{0}
    <set-backend-service backend-id="{1}" />
  </inbound>
  <backend>
    <forward-request />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
''', corsPolicy, backend.name)
  }
}

output subscriptionName string = subscriptionName
