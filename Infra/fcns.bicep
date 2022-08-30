targetScope = 'resourceGroup'
param location string = resourceGroup().location
param vnetId string
param stgName string
param stgFcnsName string
param sqlServerName string
param uid string
@secure()
param sqlPassword string

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = if (location == 'australiaeast') {
  name: stgName
}

resource storageFcns 'Microsoft.Storage/storageAccounts@2021-09-01' existing = if (location == 'australiaeast') {
  name: stgFcnsName
}

resource appservice 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-svc-${location}-${uid}'
  location: location
  sku: {
    name: 'S1'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  location: location
  name: 'grffcns-${location}-${uid}-appi'
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 30
    SamplingPercentage: 2
  }
}

resource fcnssyd 'Microsoft.Web/sites@2022-03-01' = {
  location: location
  name: 'grffcns-${location}-${uid}'
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: appservice.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0'
      alwaysOn: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appinsights.properties.ConnectionString
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageFcns.name};AccountKey=${storageFcns.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'StorageAccountSetting'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'StorageAccountSettingReplica'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net;QueueEndpoint=https://${storage.name}-secondary.queue.core.windows.net'
        }
        {
          name: 'SqlConnectionString'
          value: 'Server=tcp:${sqlServerName}${environment().suffixes.sqlServerHostname},1433;Database=Scheduledb;Initial Catalog=Scheduledb;Persist Security Info=False;User ID=santa;Password=${sqlPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30'
        }
      ]
    }
  }
  resource network 'networkConfig@2022-03-01' = {
    name: 'virtualNetwork'
    properties: {
      subnetResourceId: '${vnetId}/subnets/fcns'
    }
  }
}

output vnetId string = vnetId

