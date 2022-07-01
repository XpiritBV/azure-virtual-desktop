targetScope = 'subscription'

param location string = 'westeurope'

param sigName string = 'avdsharedimagegallery'
param imageDefinitionName string = 'avd-shared-image'
param imagePublisher string = 'MicrosoftWindowsDesktop'
param imageOffer string = 'windows-11'
param imageSKU string = 'win11-21h2-avd'
param uamiName string = 'AIBUser'
param softwareStorageAccountName string

//Define Azure Files deployment parameters
param storageaccountkind string = 'FileStorage'
param storageaccountglobalRedundancy string = 'Premium_LRS'

resource rgsig 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rg-avd-image-gallery'
  location: location
}

module softwareStorage './Image/storage.bicep' = {
  name: 'softwareStorage'
  scope: resourceGroup(rgsig.name)
  params: {
    storageaccountlocation: location
    storageaccountName: softwareStorageAccountName
    storageaccountkind: storageaccountkind
    storageaccountglobalRedundancy: storageaccountglobalRedundancy
  }
}

module avdsig './Image/sharedImageGallery.bicep' = {
  name: 'avdsig'
  scope: rgsig
  params: {
    sigName: sigName
    sigLocation: rgsig.location
    imagePublisher: imagePublisher
    imageDefinitionName: imageDefinitionName
    imageOffer: imageOffer
    imageSKU: imageSKU
    uamiName: uamiName
    roleNameGalleryImage: 'SIGRole'
  }
}

output avdSigId string = avdsig.outputs.avdidoutput
