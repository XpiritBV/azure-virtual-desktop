param siglocation string
param roleNameAIBCustom string = '${'AIBRole'}${utcNow()}'
param uamiName string
param uamiId string = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', uamiName)
param imageTemplateName string = '${'AVD-VM-Template'}-${utcNow('dd-MM-yyyy-HH-mm')}'
param outputname string = uniqueString(resourceGroup().name)
param galleryImageId string
param imagePublisher string
param imageOffer string
param imageSKU string
param rgname string = resourceGroup().name

param softwareStorageAccountName string
param softwareFileShare string

resource managedidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: uamiName
}

resource softwareStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: softwareStorageAccountName
}

resource fs 'Microsoft.Storage/storageAccounts/fileServices@2021-09-01' = {
  name: 'default'
  parent: softwareStorageAccount
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: false
    }
  }
}

var softwareStorageAccountKey = softwareStorageAccount.listKeys().keys[0].value

// Create Image Template in SIG Resource Group
resource imageTemplateName_resource 'Microsoft.VirtualMachineImages/imageTemplates@2021-10-01' = {
  name: imageTemplateName
  location: siglocation
  tags: {
    imagebuilderTemplate: 'AzureImageBuilderSIG'
    userIdentity: 'enabled'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedidentity.id}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 180
    vmProfile: {
      vmSize: 'Standard_DS2_v2'
      osDiskSizeGB: 127
    }
    source: {
      type: 'PlatformImage'
      publisher: imagePublisher
      offer: imageOffer
      sku: imageSKU
      version: 'latest'
    }
    customize: [
      // {
      //   // Optimize OS for use with Azure Virtual Desktop
      //   type: 'PowerShell'
      //   name: 'OptimizeOS'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: 'https://raw.githubusercontent.com/XpiritBV/azvmimagebuilder/feature/fix-main/solutions/14_Building_Images_WVD/1_Optimize_OS_for_WVD.ps1'
      // }
      // {
      //   // Install Windows updates
      //   type: 'WindowsUpdate'
      //   searchCriteria: 'IsInstalled=0'
      //   filters: [
      //     'exclude:$_.Title -like \'*Preview*\''
      //     'include:$true'
      //   ]
      //   updateLimit: 40
      // }
      // {
      //   // Restart after Windows updates have completed
      //   type: 'WindowsRestart'
      //   restartCheckCommand: 'write-host \'restarting post Windows Updates\''
      //   restartTimeout: '5m'
      // }
      // {
      //   // Map a storage account as a drive on the image (during build) and use files to do actions (install software etc)
      //   type: 'PowerShell'
      //   name: 'Install Something'
      //   runElevated: true
      //   runAsSystem: false
      //   inline: [
      //     'cmd.exe /C "cmdkey /add:${softwareStorageAccountName}.file.core.windows.net /user:localhost\\${softwareStorageAccountName} /pass:${softwareStorageAccountKey}"'
      //     'New-PSDrive -Name Z -PSProvider FileSystem -Root "\\\\${softwareStorageAccountName}.file.core.windows.net\\${softwareFileShare}"'
      //     // Use the drive to perform installations, copy installers locally first, since it might not run directly from the network drive
      //   ]
      // }
      // {
      //   type: 'WindowsRestart'
      //   restartCheckCommand: 'write-host \'restarting post Install\''
      //   restartTimeout: '5m'
      // }
    ]
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: galleryImageId
        runOutputName: outputname
        artifactTags: {
          source: 'avd11'
          baseosimg: 'windows11'
        }
        replicationRegions: []
      }
    ]
  }
}

//Create Role Definition with Image Builder to run Image Build and execute container cli script
resource aibdef 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(roleNameAIBCustom)
  properties: {
    roleName: roleNameAIBCustom
    description: 'Custom role for AIB to invoke build of VM Template from deployment'
    permissions: [
      {
        actions: [
          'Microsoft.VirtualMachineImages/imageTemplates/Run/action'
          'Microsoft.Storage/storageAccounts/*'
          'Microsoft.ContainerInstance/containerGroups/*'
          'Microsoft.Resources/deployments/*'
          'Microsoft.Resources/deploymentScripts/*'
        ]
      }
    ]
    assignableScopes: [
      resourceGroup().id
    ]
  }
}

// Map AIB Runner Custom Role Assignment to Managed Identity
resource aibrunnerassignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, aibdef.id, managedidentity.id)
  properties: {
    roleDefinitionId: aibdef.id
    principalId: managedidentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Map Managed Identity Operator Role to to Managed Identity - Not required if not running Powershell Deployment Script for AIB
resource miorole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830', managedidentity.id)
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830'
    principalId: managedidentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Run Deployment Script to Start build of Virtual Machine Image using AIB
resource scriptName_BuildVMImage 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'BuildVMImage'
  location: siglocation
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    forceUpdateTag: '1'
    azPowerShellVersion: '5.9'
    arguments: ''
    scriptContent: 'Invoke-AzResourceAction -ResourceName ${imageTemplateName} -ResourceGroupName ${rgname} -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2021-10-01" -Action Run -Force'
    timeout: 'PT5M'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    imageTemplateName_resource
  ]
}

output buildVMImageId string = scriptName_BuildVMImage.id
output imageTemplateId string = imageTemplateName_resource.id
