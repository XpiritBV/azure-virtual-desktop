//Define Azure Files parameters
param storageaccountlocation string = 'westeurope'
param storageaccountName string
param storageaccountkind string
param storageaccountglobalRedundancy string = 'Premium_LRS'

//Create Storage account
resource sa 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name : storageaccountName
  location : storageaccountlocation
  kind : storageaccountkind
  sku: {
    name: storageaccountglobalRedundancy
  }
}

output storageAccountName string = sa.name
