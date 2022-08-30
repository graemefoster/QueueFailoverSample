targetScope = 'resourceGroup'
param location string = resourceGroup().location
param uid string 
@secure()
param sqlPassword string


resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  
  name: 'stg${uid}'
  kind: 'StorageV2'
  location: location
  sku: {
    name: 'Standard_RAGRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
  }

  resource queueServices 'queueServices@2021-09-01' = {
    name: 'default'
    properties: {
    }
  }
}


resource storageFcns 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  
  name: 'stgfcns${uid}'
  kind: 'StorageV2'
  location: location
  sku: {
    name: 'Standard_RAGRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
  }

  resource queueServices 'queueServices@2021-09-01' = {
    name: 'default'
    properties: {
    }
  }
}

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-09-01' = {
  name: '${storage.name}/default/test-queue'
  properties: {
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: 'sql${uid}srv'
  location: location
  properties: {
    administratorLogin: 'santa'
    administratorLoginPassword: sqlPassword
    publicNetworkAccess: 'Enabled'
  }
}

resource db 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  name: 'Scheduledb'
  location: location
  parent: sqlServer
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

output stgId string = storage.id
output storageFcnsId string = storageFcns.id
output stgFcnsName string = storageFcns.name
output stgName string = storage.name
output sqlServerName string = sqlServer.name
output sqlId string = sqlServer.id
