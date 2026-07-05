# azure-cdk-infra

Core Azure infrastructure repository. Manages shared Azure resources via Bicep and GitHub Actions CI/CD across three environments: **dev**, **acc**, and **prd**.

## CI/CD Pipeline

| Trigger | Condition | Job | Environment |
|---|---|---|---|
| `push` | any branch except `main` | `deploy-dev` | dev |
| `pull_request` closed | `merged == true` into `main` | `deploy-acc` | acc |
| after `deploy-acc` succeeds | — | `deploy-prd` | prd |

Each job: creates the resource group if it does not exist → deploys the component Bicep with the matching `.bicepparam`.

## Infrastructure Overview

```mermaid
graph TB
    subgraph CI ["GitHub Actions"]
        WF["deploy-servicebus.yml"]
    end

    subgraph AZ ["Azure Tenant"]
        OIDC["CI App Registration\n(Federated OIDC Credential)"]

        subgraph DEV ["rg-core-dev"]
            SB_DEV["sb-core-dev\nService Bus · Standard"]
        end

        subgraph ACC ["rg-core-acc"]
            SB_ACC["sb-core-acc\nService Bus · Standard"]
        end

        subgraph PRD ["rg-core-prd"]
            SB_PRD["sb-core-prd\nService Bus · Standard"]
        end

    end

    WF -->|"OIDC login"| OIDC
    OIDC -->|"Bicep deployment"| DEV
    OIDC -->|"Bicep deployment"| ACC
    OIDC -->|"Bicep deployment"| PRD
```

## Components

### Service Bus (`infra/servicebus/`)

Azure Service Bus namespace per environment — **Standard tier** (pay-per-use / per operation pricing).

- SAS key authentication is disabled (`disableLocalAuth: true`) — RBAC only
- Role assignments are managed by the consuming project, not this repository

**Outputs**

| Output | Description |
|---|---|
| `serviceBusNamespaceName` | Name of the namespace |
| `serviceBusEndpoint` | Full HTTPS endpoint URL |
| `serviceBusHostname` | Hostname for SDK connections |

## Resource Groups

| Environment | Resource Group |
|---|---|
| dev | `rg-core-dev` |
| acc | `rg-core-acc` |
| prd | `rg-core-prd` |
