//Define avd deployment parameters
param hostpoolName string
param hostpoolFriendlyName string
param appgroupPrefix string
param workspaceName string
param workspaceNameFriendlyName string
param avdbackplanelocation string = 'westeurope'
param hostPoolType string = 'pooled'
param loadBalancerType string = 'BreadthFirst'
param logAnalyticsWorkspaceName string
param logAnalyticslocation string = 'westeurope'
param logAnalyticsWorkspaceSku string = 'pergb2018'
param logAnalyticsResourceGroup string
param avdBackplaneResourceGroup string
param adminGroupPrincipalId string
param userGroupPrincipalId string

param baseTime string = utcNow('u')
var add30Days = dateTimeAdd(baseTime, 'P30D')

//Create avd Hostpool
resource hp 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
  name: hostpoolName
  location: avdbackplanelocation
  properties: {
    friendlyName: hostpoolFriendlyName
    hostPoolType : hostPoolType
    loadBalancerType : loadBalancerType 
    maxSessionLimit: 12
    preferredAppGroupType: 'Desktop'
    customRdpProperty: 'drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:0;redirectprinters:i:0;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;use multimon:i:0;screen mode id:i:2;dynamic resolution:i:0;targetisaadjoined:i:1'
    registrationInfo: {
      expirationTime: add30Days
      token: null
      registrationTokenOperation: 'Update'
    }
  }
}

//Create AppGroups
var desktopVirtualUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
resource agDesktop 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: '${appgroupPrefix}-desktop'
  location: avdbackplanelocation
  properties: {
      applicationGroupType: 'Desktop'
      hostPoolArmPath: hp.id
  }
}
resource roleAssignmentDesktop 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(adminGroupPrincipalId, desktopVirtualUserRoleId, 'Desktop')
  scope: agDesktop
  properties: {
    roleDefinitionId: desktopVirtualUserRoleId
    principalId: adminGroupPrincipalId
  }
}
resource agAdmin 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: '${appgroupPrefix}-admin'
  location: avdbackplanelocation
  properties: {
      applicationGroupType: 'RemoteApp'
      hostPoolArmPath: hp.id
  }
}
resource roleAssignmentAdmin 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(adminGroupPrincipalId, desktopVirtualUserRoleId, 'Admin')
  scope: agAdmin
  properties: {
    roleDefinitionId: desktopVirtualUserRoleId
    principalId: adminGroupPrincipalId
  }
}
resource agUser 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
    name: '${appgroupPrefix}-user'
    location: avdbackplanelocation
    properties: {
        applicationGroupType: 'RemoteApp'
        hostPoolArmPath: hp.id
  }
}
resource roleAssignmentUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userGroupPrincipalId, desktopVirtualUserRoleId, 'User')
  scope: agUser
  properties: {
    roleDefinitionId: desktopVirtualUserRoleId
    principalId: userGroupPrincipalId
  }
}

//Create Applications
resource appTaskManager 'Microsoft.DesktopVirtualization/applicationGroups/applications@2021-09-03-preview' = {
  name: 'Task Manager'
  parent: agAdmin
  properties: {
    friendlyName: 'Task Manager' 
    applicationType: 'InBuilt'
    commandLineSetting: 'Require'
    commandLineArguments: '/7'
    filePath: 'C:\\Windows\\system32\\taskmgr.exe'
    iconPath: 'C:\\Windows\\system32\\taskmgr.exe'
    showInPortal: true
  }
}

resource appNotepad 'Microsoft.DesktopVirtualization/applicationGroups/applications@2021-09-03-preview' = {
  name: 'Notepad'
  parent: agUser
  properties: {
    friendlyName: 'Notepad' 
    applicationType: 'InBuilt'
    commandLineSetting: 'DoNotAllow'
    filePath: 'c:\\windows\\notepad.exe'
    iconPath: 'c:\\windows\\notepad.exe'
    showInPortal: true
  }
}
 
//Create avd Workspace
resource ws 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
  name: workspaceName
  location: avdbackplanelocation
  properties: {
      friendlyName: workspaceNameFriendlyName
      applicationGroupReferences: [
        agDesktop.id
        agAdmin.id
        agUser.id
      ]
  }
}

//Create Azure Log Analytics Workspace
module avdmonitor './avdLogAnalytics.bicep' = {
  name : 'LAWorkspace'
  scope: resourceGroup(logAnalyticsResourceGroup)
  params: {
    logAnalyticsWorkspaceName : logAnalyticsWorkspaceName
    logAnalyticslocation : logAnalyticslocation
    logAnalyticsWorkspaceSku : logAnalyticsWorkspaceSku
    hostpoolName : hp.name
    workspaceName : ws.name
    avdBackplaneResourceGroup : avdBackplaneResourceGroup
  }
}

output hostPoolToken string = reference(hp.id, '2019-12-10-preview').registrationInfo.token  
