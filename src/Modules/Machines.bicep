targetScope = 'subscription'

param environment string
param location string
param localAdminName string
param localAdminPassword string
param adminGroupPrincipalId string
param userGroupPrincipalId string
param vmsize string // = 'Standard_NV4as_v4'
param registrationInfoToken string
param appvnetaddressPrefix string = 'ignored'
param appsubnetPrefix string = 'ignored'
param sharedGalleryImageId string
param FSLogixProfileStoragePrefix string

var hostpoolName = 'avd-hostpool-${environment}'

module vm 'virtualMachine/deploy.bicep' = {
  name: 'vm'
  params: {
    resourceGroupName: 'rg-avd-${environment}'
    registrationInfoToken: registrationInfoToken
    scaleSetName: 'avd-scaleset-${environment}'
    hostpoolName: hostpoolName
    location: location
    vnetName: 'vnet-avd-${environment}-001'
    localAdminName: localAdminName
    localAdminPassword: localAdminPassword
    vmName: 'vm-${environment}'
    vmSize: vmsize
    adminGroupPrincipalId: adminGroupPrincipalId
    userGroupPrincipalId: userGroupPrincipalId
    environment: environment
    sharedGalleryImageId: sharedGalleryImageId
    FSLogixProfileStoragePrefix: FSLogixProfileStoragePrefix
  }
}
