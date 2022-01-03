targetScope = 'subscription'

// Resource Group Parameters
param groupName string = 'clusterless-hpc'
param location string = 'southcentralus'

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: groupName
  location: location
}

// Create a Managed User Identity for Azure Batch
module batchIdentity 'modules/user_identity.bicep' = {
  name: 'user_identity'
  scope: resourceGroup
  params: {
    name: '${groupName}-identity'
  }
}

// Create Storage Account
module storage 'modules/azure_storage.bicep' = {
  name: 'azure_storage'
  scope: resourceGroup
  params: {
    principalId: batchIdentity.outputs.principalId
  }
  dependsOn: [
    batchIdentity
  ]
}
