targetScope = 'subscription'

param environment string
param location string
param adminGroupPrincipalId string
param userGroupPrincipalId string
param appvnetaddressPrefix string
param appsubnetPrefix string
param vmSize string = 'ignored'

var hostpoolName = 'avd-hostpool-${environment}'

module vd 'virtualDesktop/deploy.bicep' = {
  name: 'vd'
  params: {
    resourceGroupName: 'rg-avd-${environment}'
    location: location
    environment: environment
    hostpoolName: hostpoolName
    hostpoolFriendlyName: 'AVD Host Pool ${environment}'
    appgroupPrefix: 'avd-appgroup-${environment}' 
    workspaceName: 'avd-workspace-${environment}'
    workspaceNameFriendlyName: 'Xpirit AVD setup (${environment})'
    vnetName: 'vnet-avd-${environment}-001'
    subnetName: 'snet-avd-${environment}-001'
    adminGroupPrincipalId: adminGroupPrincipalId
    userGroupPrincipalId: userGroupPrincipalId
    appvnetaddressPrefix: appvnetaddressPrefix
    appsubnetPrefix: appsubnetPrefix
    logAnalyticsWorkspaceName: 'law-avd-${environment}-001'
  }
}

output registrationInfoToken string = vd.outputs.registrationInfoToken
