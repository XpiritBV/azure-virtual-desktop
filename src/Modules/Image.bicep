targetScope = 'subscription'

param sharedImageGalleryId string
param imageDefinitionName string = 'avd-shared-image'
param imagePublisher string = 'MicrosoftWindowsDesktop'
param imageOffer string = 'windows-11'
param imageSKU string = 'win11-21h2-avd'
param uamiName string = 'AIBUser'

param softwareStorageAccountName string
param softwareFileShare string

resource rgsig 'Microsoft.Resources/resourceGroups@2020-06-01' existing = {
  name: 'rg-avd-image-gallery'
}

//Create AIB Image and optionally build and add version to SIG Definition
module avdaib './Image/imageBuilder.bicep' = {
  name: 'avdimagebuilder-${imageDefinitionName}'
  scope: rgsig
  params: {
    siglocation: rgsig.location
    uamiName: uamiName
    imagePublisher: imagePublisher
    imageOffer: imageOffer
    imageSKU: imageSKU
    galleryImageId: sharedImageGalleryId 
    softwareStorageAccountName: softwareStorageAccountName
    softwareFileShare: softwareFileShare
  }
}

output imageTemplateId string = avdaib.outputs.imageTemplateId
output buildVMImageId string = avdaib.outputs.buildVMImageId
