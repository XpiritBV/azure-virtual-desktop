// Define Networkin parameters
param vnetName string
param appvnetaddressPrefix string
param appsubnetPrefix string
param vnetLocation string = 'westeurope'
param subnetName string = 'avd'

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'nsg-avd-application'
  location: vnetLocation
  properties: {
    securityRules: [
      {
        name: 'rule-allow-rdp'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 150
          direction: 'Inbound'
        }
      }
    ]
  }
}

//Create Vnet and Subnet
resource vnet 'Microsoft.Network/virtualnetworks@2020-06-01' = {
  name: vnetName
  location: vnetLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        appvnetaddressPrefix
      ]
    }
    dhcpOptions: {

    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: appsubnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}
