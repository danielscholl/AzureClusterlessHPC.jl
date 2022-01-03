targetScope = 'subscription'

param prefix string = 'iac'

// Resource Group Parameters
param groupName string = '${prefix}-bicep'
param location string = 'centralus'

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: groupName
  location: location
}

// Create Storage Account
module storage 'modules/azure_storage.bicep' = {
  name: 'azure_storage'
  scope: resourceGroup
  params: {}
}
