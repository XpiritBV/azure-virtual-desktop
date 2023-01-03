targetScope = 'subscription'

param location string = 'westeurope'
param environment string

//Define avd deployment parameters
param resourceGroupName string
param hostpoolName string
param hostpoolFriendlyName string
param appgroupPrefix string
param workspaceName string
param workspaceNameFriendlyName string
param hostPoolType string = 'pooled'
param loadBalancerType string = 'BreadthFirst'
param logAnalyticsWorkspaceName string

//Define Networking deployment parameters
param vnetName string 
param appvnetaddressPrefix string 
param appsubnetPrefix string
param subnetName string 

//Define Azure Files deployment parameters
param storageaccountkind string = 'FileStorage'
param storageaccountglobalRedundancy string = 'Premium_LRS'
param fileshareFolderName string = 'profilecontainers'
param FSLogixProfileStoragePrefix string

param adminGroupPrincipalId string
param userGroupPrincipalId string

//Create Resource Groups
resource rgavd 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupName
  location: location
}

module avdFileServices './avdFileServices.bicep' = {
  name: 'avdFileServices'
  scope: resourceGroup(rgavd.name)
  params: {
    storageaccountlocation: location
    storageaccountName: '${FSLogixProfileStoragePrefix}${environment}'
    storageaccountkind: storageaccountkind
    storageaccountglobalRedundancy: storageaccountglobalRedundancy
    fileshareFolderName: fileshareFolderName
  }
}

//Create avd backplane objects and configure Log Analytics Diagnostics Settings
module avdbackplane 'avdBackplane.bicep' = {
  name: 'avdbackplane'
  scope: resourceGroup(rgavd.name)
  params: {
    hostpoolName: hostpoolName
    hostpoolFriendlyName: hostpoolFriendlyName
    appgroupPrefix: appgroupPrefix
    workspaceName: workspaceName
    workspaceNameFriendlyName: workspaceNameFriendlyName
    avdbackplanelocation: location
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsResourceGroup: rgavd.name
    avdBackplaneResourceGroup: rgavd.name
    adminGroupPrincipalId: adminGroupPrincipalId
    userGroupPrincipalId: userGroupPrincipalId
  }
}

//Create avd Netwerk and Subnet
module avdNetwork './avdNetwork.bicep' = {
  name: 'avdnetwork'
  scope: resourceGroup(rgavd.name)
  params: {
    vnetName: vnetName
    appvnetaddressPrefix: appvnetaddressPrefix
    appsubnetPrefix: appsubnetPrefix
    vnetLocation: location
    subnetName: subnetName
  }
}

output vnetName string = vnetName
output subnetName string = subnetName
output registrationInfoToken string = avdbackplane.outputs.hostPoolToken
output fslogixshare string = avdFileServices.outputs.fslogixshare
output storageAccountName string = avdFileServices.outputs.storageAccountName
