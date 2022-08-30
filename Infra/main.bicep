targetScope = 'subscription'
param location string = deployment().location
param code string
@secure()
param sqlPassword string
var uid = '${code}${uniqueString(subscription().id)}'

resource sydrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'failover-syd-${uid}'
  location: location
  properties: {
  }

}

resource melrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'failover-mel-${uid}'
  location: 'australiasoutheast'
  properties: {
  }
}

module stg 'main-stg.bicep' = {
  scope: sydrg
  name: 'storage'
  params: {
    uid: uid
    location: location
    sqlPassword: sqlPassword
  }
}

module sydney 'networks.bicep' = {
  name: 'syd'
  scope: sydrg
  params: {
    location: location
    storageId: stg.outputs.stgId
    storageFcnsId: stg.outputs.storageFcnsId
    sqlId: stg.outputs.sqlId
    vnetIpRange: '10.0.0.0/16'
    storageIpRange: '10.0.1.0/24'
    fcnsIpRange: '10.0.2.0/24'
    uid: uid
  }
}

module functions 'fcns.bicep' = {
  name: 'fcns'
  scope: sydrg
  params: {
    location: location
    stgFcnsName: stg.outputs.stgFcnsName
    stgName: stg.outputs.stgName
    vnetId: sydney.outputs.vnetId
    sqlServerName: stg.outputs.sqlServerName
    sqlPassword: sqlPassword
    uid: uid
  }
}

module mel 'networks.bicep' = {
  name: 'mel'
  scope: melrg
  params: {
    location: 'australiasoutheast'
    storageId: stg.outputs.stgId
    storageFcnsId: stg.outputs.storageFcnsId
    sqlId: stg.outputs.sqlId
    vnetIpRange: '10.1.0.0/16'
    storageIpRange: '10.1.1.0/24'
    fcnsIpRange: '10.1.2.0/24'
    uid: uid
  }
}
