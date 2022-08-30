targetScope = 'resourceGroup'
param location string = resourceGroup().location
param vnetIpRange string
param storageIpRange string
param storageFcnsId string
param fcnsIpRange string
param storageId string
param sqlId string
param uid string

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-${uid}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetIpRange
      ]
    }
    subnets: [
      {
        name: 'storage'
        properties: {
          addressPrefix: storageIpRange
        }
      }
      {
        name: 'fcns'
        properties: {
          addressPrefix: fcnsIpRange
          delegations: [
            {
              name: 'asp-delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource storagepe1auedns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  resource link 'virtualNetworkLinks@2020-06-01' = {
    name: 'privatelink.blob.${environment().suffixes.storage}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}

resource storagepe1tableauedns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.table.${environment().suffixes.storage}'
  location: 'global'
  resource link 'virtualNetworkLinks@2020-06-01' = {
    name: 'privatelink.table.${environment().suffixes.storage}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}

resource storagepe1queueauedns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.queue.${environment().suffixes.storage}'
  location: 'global'
  resource link 'virtualNetworkLinks@2020-06-01' = {
    name: 'privatelink.queue.${environment().suffixes.storage}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}

resource storagepe1 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'stg-${location}-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'stg${location}privatelink'
        properties: {
          privateLinkServiceId: storageFcnsId
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnet.id}/subnets/storage'
    }
  }
  resource dnsZoneBlob 'privateDnsZoneGroups@2022-01-01' = {
    name: 'stg-${location}-pe-dnszone'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'dnszoneconfig'
          properties: {
            privateDnsZoneId: storagepe1auedns.id
          }
        }
      ]
    }
  }
}
  
resource storagepe2 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'stg-${location}-queue-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'stg${location}queueprivatelink'
        properties: {
          privateLinkServiceId: storageId
          groupIds: [
            'queue'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnet.id}/subnets/storage'
    }
  }
  resource dnsZoneQueue 'privateDnsZoneGroups@2022-01-01' = {
    name: 'stg-${location}-pe-queue-dnszone'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'dnszoneconfig'
          properties: {
            privateDnsZoneId: storagepe1queueauedns.id
          }
        }
      ]
    }
  }
}

resource storagepe2secondary 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'stg-${location}-queue-secondary-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'stg${location}queueprivatelink'
        properties: {
          privateLinkServiceId: storageId
          groupIds: [
            'queue_secondary'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnet.id}/subnets/storage'
    }
  }
  resource dnsZoneQueue 'privateDnsZoneGroups@2022-01-01' = {
    name: 'stg-${location}-pe-queue-secondary-dnszone'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'dnszoneconfig'
          properties: {
            privateDnsZoneId: storagepe1queueauedns.id
          }
        }
      ]
    }
  }
}

resource storagepe3 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'stg-${location}-table-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'stg${location}tableprivatelink'
        properties: {
          privateLinkServiceId: storageFcnsId
          groupIds: [
            'table'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnet.id}/subnets/storage'
    }
  }
  resource dnsZoneTable 'privateDnsZoneGroups@2022-01-01' = {
    name: 'stg-${location}-pe-table-dnszone'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'dnszoneconfig'
          properties: {
            privateDnsZoneId: storagepe1tableauedns.id
          }
        }
      ]
    }
  }
}

resource sqlauedns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink${environment().suffixes.sqlServerHostname}'
  location: 'global'
  resource link 'virtualNetworkLinks@2020-06-01' = {
    name: 'privatelink${environment().suffixes.sqlServerHostname}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}

resource sqlpe1 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'sql-${location}-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'sql${location}privatelink'
        properties: {
          privateLinkServiceId: sqlId
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnet.id}/subnets/storage'
    }
  }
  resource dnsZoneSql 'privateDnsZoneGroups@2022-01-01' = {
    name: 'sql-${location}-pe-dnszone'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'dnszoneconfig'
          properties: {
            privateDnsZoneId: sqlauedns.id
          }
        }
      ]
    }
  }
}

resource appservice 'Microsoft.Web/serverfarms@2022-03-01' = if (location == 'australiaeast') {
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


output vnetId string = vnet.id

