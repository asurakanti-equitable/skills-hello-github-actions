targetScope = 'resourceGroup'

@description('Azure region for the deployed resources.')
param location string = resourceGroup().location

@description('Globally unique name for the storage account.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Globally unique names for the key vaults to create.')
@minLength(2)
param keyVaultNames array

@description('The index document for the static website.')
param indexDocument string = 'index.html'

@description('The 404 document for the static website.')
param errorDocument404Path string = '404.html'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource staticWebsite 'Microsoft.Storage/storageAccounts/staticWebsite@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    enabled: true
    indexDocument: indexDocument
    error404Document: errorDocument404Path
  }
}

resource keyVaults 'Microsoft.KeyVault/vaults@2023-07-01' = [for keyVaultName in keyVaultNames: {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    publicNetworkAccess: 'Enabled'
    softDeleteRetentionInDays: 90
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
  }
}]

output staticWebsiteEndpoint string = storageAccount.properties.primaryEndpoints.web
output keyVaultIds array = [for (keyVaultName, index) in keyVaultNames: keyVaults[index].id]
