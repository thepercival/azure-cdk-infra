@description('Budget name')
param budgetName string

@description('Budget amount in EUR')
param amount int

@description('Email addresses to receive budget alerts')
param contactEmails array

@description('Budget start date (YYYY-MM-DD)')
param startDate string

@description('Threshold percentages for alerts')
param thresholds array = [
  80
  90
  100
]

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: budgetName
  properties: {
    timePeriod: {
      startDate: startDate
    }
    timeGrain: 'Monthly'
    amount: amount
    category: 'Cost'
    notifications: {
      alert80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: thresholds[0]
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
      alert90: {
        enabled: true
        operator: 'GreaterThan'
        threshold: thresholds[1]
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
      alert100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: thresholds[2]
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
    }
  }
}

output budgetName string = budget.name
output budgetId string = budget.id
