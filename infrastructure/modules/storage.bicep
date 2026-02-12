// =============================================================================
// Storage Account — BananaBot's memory and inbox
// Table Storage for messages & memory, Blob for lease, File Share for SDK session
// =============================================================================

@description('Storage account name (no hyphens, max 24 chars)')
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

// -----------------------------------------------------------------------------
// Storage Account
// -----------------------------------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS' // locally redundant, fine for dev
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// -----------------------------------------------------------------------------
// Table Storage — Messages, memory, schedule
// -----------------------------------------------------------------------------

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

// Inbox — pending messages from Discord
resource inboxTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = {
  parent: tableService
  name: 'inbox'
}

// Memory — persistent state, identity, banana counts
resource memoryTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = {
  parent: tableService
  name: 'memory'
}

// Schedule — self-scheduled wake-ups
resource scheduleTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = {
  parent: tableService
  name: 'schedule'
}

// Session log — continuity tracking
resource sessionLogTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = {
  parent: tableService
  name: 'sessionlog'
}

// -----------------------------------------------------------------------------
// Blob Storage — Lease container for singleton lock
// -----------------------------------------------------------------------------

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource leaseContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'locks'
  properties: {
    publicAccess: 'None'
  }
}

// -----------------------------------------------------------------------------
// File Share — SDK session persistence (Flex Consumption requirement)
// -----------------------------------------------------------------------------

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource functionFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileService
  name: 'bananabot-session'
  properties: {
    shareQuota: 1 // 1 GB, plenty for session state
  }
}

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output fileShareName string = functionFileShare.name
