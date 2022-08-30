# Azure Storage Failover Sample

## TLDR;


``` 
cd infra
az deployment sub  create --template-file .\main.bicep --parameters sqlPassword=<complex-password> ```
```

## Scenario

This sample application allows you to play with Azure Storage Queue Failover. It deploys a function app that can produce and consume from a queue, as-well as a SQL database that is used to schedule messages.

Everything is deployed using Private Endpoints to demonstrate failover in a secure environment.

## Diagrams
(generated by [Azure Diagrams](https://github.com/graemefoster/AzureResourceMap))

### Simple deployment diagram of Region 1

![AzureSimple](./Simple%20Diagram.png)

### Expanded deployment diagram of Region 2

![AzureSimple](./Expanded%20Diagram.png)
