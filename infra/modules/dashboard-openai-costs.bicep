@description('Name of the dashboard')
param dashboardName string

@description('Azure region location')
param location string

// param administratorPrincipalId string

@description('Log Analytics Workspace resource ID')
param logAnalyticsWorkspaceId string

@description('AI Services account name for resource tagging')
param aiServicesAccountName string


// KQL Query for token usage per user-project
var tokenUsageByProjectTitle = 'Token Usage by User Project (Last 7 Days)'
var tokenUsageByProjectSubtitle = 'Prompt + Completion Tokens'
var tokenUsageByProjectKQL = '''
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| extend ProjectName = tostring(parse_json(properties_s).projectName)
| extend PromptTokens = toint(parse_json(properties_s).usage.prompt_tokens)
| extend CompletionTokens = toint(parse_json(properties_s).usage.completion_tokens)
| extend TotalTokens = PromptTokens + CompletionTokens
| where isnotempty(ProjectName)
| summarize TotalTokens = sum(TotalTokens) by bin(TimeGenerated, 1d), ProjectName
| order by TimeGenerated asc
'''

// KQL Query for token usage per model deployment
var tokenUsageByModelTitle = 'Token Usage by Model Deployment (Last 7 Days)'
var tokenUsageByModelSubtitle = 'Breakdown by deployment name'
var tokenUsageByModelKQL = '''
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| extend DeploymentName = tostring(parse_json(properties_s).deploymentName)
| extend PromptTokens = toint(parse_json(properties_s).usage.prompt_tokens)
| extend CompletionTokens = toint(parse_json(properties_s).usage.completion_tokens)
| extend TotalTokens = PromptTokens + CompletionTokens
| where isnotempty(DeploymentName)
| summarize TotalTokens = sum(TotalTokens) by bin(TimeGenerated, 1d), DeploymentName
| order by TimeGenerated asc
'''

// KQL Query for estimated costs per project
var costByProjectTitle = 'Estimated Costs by Project (Last 7 Days)'
var costByProjectSubtitle = 'Based on token usage (approximate)'
var costByProjectKQL = '''
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| extend ProjectName = tostring(parse_json(properties_s).projectName)
| extend ModelName = tostring(parse_json(properties_s).model)
| extend PromptTokens = toint(parse_json(properties_s).usage.prompt_tokens)
| extend CompletionTokens = toint(parse_json(properties_s).usage.completion_tokens)
| where isnotempty(ProjectName)
| extend EstimatedCost = (PromptTokens * 0.00001) + (CompletionTokens * 0.00003)
| summarize TotalCost = sum(EstimatedCost) by bin(TimeGenerated, 1d), ProjectName
| order by TimeGenerated asc
'''

// KQL Query for request count per project
var requestCountByProjectTitle = 'Request Count by Project (Last 7 Days)'
var requestCountByProjectSubtitle = 'Total API calls per user project'
var requestCountByProjectKQL = '''
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| extend ProjectName = tostring(parse_json(properties_s).projectName)
| where isnotempty(ProjectName)
| summarize RequestCount = count() by bin(TimeGenerated, 1d), ProjectName
| order by TimeGenerated asc
'''

// KQL Query for error rate per project
var errorRateByProjectTitle = 'Error Rate by Project (Last 7 Days)'
var errorRateByProjectSubtitle = 'Failed requests percentage'
var errorRateByProjectKQL = '''
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| extend ProjectName = tostring(parse_json(properties_s).projectName)
| extend StatusCode = toint(parse_json(properties_s).statusCode)
| where isnotempty(ProjectName)
| summarize 
    TotalRequests = count(),
    FailedRequests = countif(StatusCode >= 400)
    by bin(TimeGenerated, 1d), ProjectName
| extend ErrorRate = (FailedRequests * 100.0) / TotalRequests
| order by TimeGenerated asc
'''

// KQL Query for total token summary table
var tokenSummaryTitle = 'Token Usage Summary (Last 30 Days)'
var tokenSummarySubtitle = 'Aggregated by project and model'
var tokenSummaryKQL = '''
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where Category == "RequestResponse"
| where TimeGenerated > ago(30d)
| extend ProjectName = tostring(parse_json(properties_s).projectName)
| extend DeploymentName = tostring(parse_json(properties_s).deploymentName)
| extend PromptTokens = toint(parse_json(properties_s).usage.prompt_tokens)
| extend CompletionTokens = toint(parse_json(properties_s).usage.completion_tokens)
| extend TotalTokens = PromptTokens + CompletionTokens
| where isnotempty(ProjectName)
| summarize 
    TotalTokens = sum(TotalTokens),
    PromptTokens = sum(PromptTokens),
    CompletionTokens = sum(CompletionTokens),
    RequestCount = count(),
    EstimatedCost = sum((PromptTokens * 0.00001) + (CompletionTokens * 0.00003))
    by ProjectName, DeploymentName
| order by TotalTokens desc
'''

resource resDashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: dashboardName
  location: location
  tags: {
    'hidden-title': dashboardName
    'ai-services-account': aiServicesAccountName
  }
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          // Token Usage by Project - Chart
          {
            position: {
              x: 0
              y: 0
              rowSpan: 4
              colSpan: 6
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceTypeMode'
                  isOptional: true
                }
                {
                  name: 'ComponentId'
                  isOptional: true
                }
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      logAnalyticsWorkspaceId
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: guid('token-usage-project-${dashboardName}')
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P7D'
                  isOptional: true
                }
                {
                  name: 'DashboardId'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: tokenUsageByProjectKQL
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'FrameControlChart'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  value: 'StackedColumn'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: tokenUsageByProjectTitle
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: tokenUsageByProjectSubtitle
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  value: {
                    xAxis: {
                      name: 'TimeGenerated'
                      type: 'datetime'
                    }
                    yAxis: [
                      {
                        name: 'TotalTokens'
                        type: 'long'
                      }
                    ]
                    splitBy: [
                      {
                        name: 'ProjectName'
                        type: 'string'
                      }
                    ]
                    aggregation: 'Sum'
                  }
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
            }
          }
          // Token Usage by Model - Chart
          {
            position: {
              x: 6
              y: 0
              rowSpan: 4
              colSpan: 6
            }
            metadata: {
              inputs: [
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      logAnalyticsWorkspaceId
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: guid('token-usage-model-${dashboardName}')
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P7D'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: tokenUsageByModelKQL
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'FrameControlChart'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  value: 'Line'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: tokenUsageByModelTitle
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: tokenUsageByModelSubtitle
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  value: {
                    xAxis: {
                      name: 'TimeGenerated'
                      type: 'datetime'
                    }
                    yAxis: [
                      {
                        name: 'TotalTokens'
                        type: 'long'
                      }
                    ]
                    splitBy: [
                      {
                        name: 'DeploymentName'
                        type: 'string'
                      }
                    ]
                    aggregation: 'Sum'
                  }
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
            }
          }
          // Estimated Costs by Project - Chart
          {
            position: {
              x: 0
              y: 4
              rowSpan: 4
              colSpan: 6
            }
            metadata: {
              inputs: [
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      logAnalyticsWorkspaceId
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: guid('cost-by-project-${dashboardName}')
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P7D'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: costByProjectKQL
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'FrameControlChart'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  value: 'StackedArea'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: costByProjectTitle
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: costByProjectSubtitle
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  value: {
                    xAxis: {
                      name: 'TimeGenerated'
                      type: 'datetime'
                    }
                    yAxis: [
                      {
                        name: 'TotalCost'
                        type: 'real'
                      }
                    ]
                    splitBy: [
                      {
                        name: 'ProjectName'
                        type: 'string'
                      }
                    ]
                    aggregation: 'Sum'
                  }
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
            }
          }
          // Request Count by Project - Chart
          {
            position: {
              x: 6
              y: 4
              rowSpan: 4
              colSpan: 6
            }
            metadata: {
              inputs: [
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      logAnalyticsWorkspaceId
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: guid('request-count-${dashboardName}')
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P7D'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: requestCountByProjectKQL
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'FrameControlChart'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  value: 'StackedColumn'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: requestCountByProjectTitle
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: requestCountByProjectSubtitle
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  value: {
                    xAxis: {
                      name: 'TimeGenerated'
                      type: 'datetime'
                    }
                    yAxis: [
                      {
                        name: 'RequestCount'
                        type: 'long'
                      }
                    ]
                    splitBy: [
                      {
                        name: 'ProjectName'
                        type: 'string'
                      }
                    ]
                    aggregation: 'Sum'
                  }
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
            }
          }
          // Error Rate by Project - Chart
          {
            position: {
              x: 0
              y: 8
              rowSpan: 4
              colSpan: 6
            }
            metadata: {
              inputs: [
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      logAnalyticsWorkspaceId
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: guid('error-rate-${dashboardName}')
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P7D'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: errorRateByProjectKQL
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'FrameControlChart'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  value: 'Line'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: errorRateByProjectTitle
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: errorRateByProjectSubtitle
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  value: {
                    xAxis: {
                      name: 'TimeGenerated'
                      type: 'datetime'
                    }
                    yAxis: [
                      {
                        name: 'ErrorRate'
                        type: 'real'
                      }
                    ]
                    splitBy: [
                      {
                        name: 'ProjectName'
                        type: 'string'
                      }
                    ]
                    aggregation: 'Avg'
                  }
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
            }
          }
          // Token Summary Table
          {
            position: {
              x: 6
              y: 8
              rowSpan: 4
              colSpan: 6
            }
            metadata: {
              inputs: [
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      logAnalyticsWorkspaceId
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: guid('token-summary-${dashboardName}')
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P30D'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: tokenSummaryKQL
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'AnalyticsGrid'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: tokenSummaryTitle
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: tokenSummarySubtitle
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
            }
          }
        ]
      }
    ]
    metadata: {
      model: {
        timeRange: {
          value: {
            relative: {
              duration: 7
              timeUnit: 'days'
            }
          }
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
        }
        filterLocale: {
          value: 'en-us'
        }
        filters: {
          value: {
            MsPortalFx_TimeRange: {
              model: {
                format: 'local'
                granularity: 'auto'
                relative: '7d'
              }
              displayCache: {
                name: 'Local Time'
                value: 'Past 7 days'
              }
              filteredPartIds: []
            }
          }
        }
      }
    }
  }
}

// Assign dashboard ownership to specified user
// resource dashboardRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(resDashboard.id, administratorPrincipalId, 'Owner')
//   scope: resDashboard
//   properties: {
//     principalId: administratorPrincipalId
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635') // Owner role
//     principalType: 'User'
//   }
// }

// Assign Reader role to all users for dashboard viewing
// resource dashboardReaderRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for user in users: {
//   name: guid(resDashboard.id, user.principalId, 'Reader')
//   scope: resDashboard
//   properties: {
//     principalId: user.principalId
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7') // Reader role
//     principalType: user.principalType
//   }
// }]

output dashboardId string = resDashboard.id
output dashboardName string = resDashboard.name
