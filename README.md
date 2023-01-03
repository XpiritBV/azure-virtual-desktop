# Azure Virtual Desktop
This repository contains the files for a basic Azure Virtual Desktop implementation with the Azure Image Builder

# Microsoft Azure configuration

You will need to create (at least) two Azure AD Groups:
AVD-Users
AVD-Admins

**You can name them however you want, one will be used for assignments of application to users and one to admins**

After you've created the accounts add their guid to the parameter files
```
"adminGroupPrincipalId": {
    "value":""
},
"userGroupPrincipalId": {
    "value":""
}
```

# Azure DevOps configuration

## Environments
You will need to create two environments:
1. Test
2. Prod

## Variable Group(s)
Name: **AVD**
- Subscription.Test = `subscriptionID for test environment`
- Subscription.Prod = `subscriptionID for prod environment, can be the same as for test`
- AzureResourceManagerConnection = `Name of your Azure Service Connection`
- LocalAdminName = `username of the localadmin account for the VMs`
- LocalAdminPassword = `password of the localadmin account for the VMs`
- FSLogixProfileStoragePrefix = `prefix for the FSLogix profile storage account`
- softwareStorageAccountName - `name of the storage account for the software`

## Pipeline(s)
Two (2) pipelines are used:
1. Image Builder and everything related `build.pipeline.yml`
2. Azure Virtual Desktop and everything related `avd.pipeline.yml`

You will have to execute the `build.pipeline.yml` first, in order for the `avd.pipeline.yml` to use a valid image

# Potential issues / bugs

## Microsoft.KeyVault not registered (during Image Build phase)
Register the Resource Provider `Microsoft.KeyVault` to the prod-subscription