targetScope = 'subscription'

param location string = 'westeurope'
param environment string

//Define deployment parameters
param resourceGroupName string
param hostpoolName string
param registrationInfoToken string
param scaleSetName string
param vnetName string
param localAdminName string
param localAdminPassword string
param vmName string
param vmSize string
param adminGroupPrincipalId string
param userGroupPrincipalId string
param sharedGalleryImageId string

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name : resourceGroupName
  location : location
}

module vmScaleSet 'vmScaleSet.bicep' = {
  name:  vmName
  scope: resourceGroup(rg.name)
  params: {
    hostpoolName: hostpoolName
    registrationInfoToken: registrationInfoToken
    scaleSetName: scaleSetName
    vnetName: vnetName
    localAdminName: localAdminName
    localAdminPassword: localAdminPassword
    vmLocation: location
    vmPrefix: 'vm-${environment}'
    vmSize: vmSize
    adminGroupPrincipalId: adminGroupPrincipalId
    userGroupPrincipalId: userGroupPrincipalId
    environment: environment
    sharedGalleryImageId: sharedGalleryImageId
  }
}
