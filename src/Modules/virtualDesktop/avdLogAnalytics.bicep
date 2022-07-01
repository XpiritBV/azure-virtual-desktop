//Define Log Analytics parameters
param logAnalyticsWorkspaceName string
param logAnalyticslocation string = 'westeurope'
param logAnalyticsWorkspaceSku string = 'pergb2018'
param hostpoolName string
param workspaceName string
param avdBackplaneResourceGroup string

//Creaye Log Analytics Workspace
resource avdla 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name : logAnalyticsWorkspaceName
  location : logAnalyticslocation
  properties : {
    sku: {
      name : logAnalyticsWorkspaceSku
    }
  }
}

//Create Diagnotic Setting for avd components
module avdmonitor './avdMonitorDiag.bicep' = {
  name : 'avdDiagnostics'
  scope: resourceGroup(avdBackplaneResourceGroup)
  params: {
    logAnalyticslocation : logAnalyticslocation
    logAnalyticsWorkspaceID : avdla.id
    hostpoolName : hostpoolName
    workspaceName : workspaceName
  }
}

