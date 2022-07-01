param hostpoolName string
param registrationInfoToken string
param scaleSetName string
param vnetName string
param localAdminName string
param localAdminPassword string
param vmLocation string = 'westeurope'
param vmPrefix string = 'vm'
param vmSize string
param adminGroupPrincipalId string
param userGroupPrincipalId string
param environment string
param sharedGalleryImageId string

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: vnetName
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  name: '${vmPrefix}-identity'
  location: vmLocation
}

var virtualMachineAdministratorLoginRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1c0163c0-47e6-4577-8991-ea5c82e286e4')
resource roleAssignmentAdmin 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(adminGroupPrincipalId, virtualMachineAdministratorLoginRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: virtualMachineAdministratorLoginRoleId
    principalId: adminGroupPrincipalId
  }
}

var virtualMachineUserLoginRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')
resource roleAssignmentUser  'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userGroupPrincipalId, virtualMachineUserLoginRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: virtualMachineUserLoginRoleId
    principalId: userGroupPrincipalId
  }
}

resource vmScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2022-03-01' = {
  name: scaleSetName
  location: vmLocation
  sku:{
    name: vmSize
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${userAssignedIdentity.name}': {}
    }
  }
  properties: {
    orchestrationMode: 'Uniform'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      extensionProfile: {
        extensions: [
          {
            name: 'RegisterSessionHost'
            properties: {
              publisher: 'Microsoft.PowerShell'
              type: 'DSC'
              typeHandlerVersion: '2.77'
              autoUpgradeMinorVersion: true
              settings: {
                ModulesUrl: 'https://github.com/patrick-de-kruijf/AVD-Files/blob/main/avd/kdi/Configuration.zip?raw=true'
                ConfigurationFunction: 'Configuration.ps1\\AddSessionHost'
                Properties:{
                  hostPoolName: hostpoolName
                  registrationInfoToken: registrationInfoToken
                  profileLocation: '\\\\prof${environment}.file.core.windows.net\\profilecontainers'
                }
              }
            }
          }
          {
            name: 'AADLoginForWindows'
            properties: {
              publisher: 'Microsoft.Azure.ActiveDirectory'
              type: 'AADLoginForWindows'
              typeHandlerVersion: '1.0'
              autoUpgradeMinorVersion: true
            }
          }
        ]
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    primary: true
                    subnet: vnet.properties.subnets[0]
                  }
                }
              ]
              enableAcceleratedNetworking: true
            }
          }
        ]
      }
      osProfile: {
        adminPassword: localAdminPassword
        adminUsername: localAdminName
        computerNamePrefix: vmPrefix
        windowsConfiguration: {
          enableAutomaticUpdates: false
          provisionVMAgent: true
        }
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadOnly'
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
        imageReference: {
          id: sharedGalleryImageId
        }
      }
    }
    platformFaultDomainCount: 1
  }
}

// Only use if you use a machine that needs the AMD GPU driver
// resource gpuDriverExtension 'Microsoft.Compute/virtualMachineScaleSets/extensions@2022-03-01' = if (environment == 'prod') {
//   name: 'AMDGPUDriver'
//   parent: vmScaleSet
//   properties: {
//     publisher: 'Microsoft.HpcCompute'
//     type: 'AmdGpuDriverWindows'
//     typeHandlerVersion: '1.1'
//     autoUpgradeMinorVersion: true
//   }
// }
