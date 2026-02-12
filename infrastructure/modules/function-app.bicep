// =============================================================================
// Function App — BananaBot9000's brain
// Flex Consumption plan, Node.js runtime, file share for session persistence
// =============================================================================

@description('Function App name')
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

@description('Storage account name for Function App backing store')
param storageAccountName string

@description('Storage account resource ID')
param storageAccountId string

@description('Key Vault name')
param keyVaultName string

@description('Key Vault URI for app settings reference')
param keyVaultUri string

@description('File share name for SDK session persistence')
param fileShareName string

@description('Environment name')
param environment string

// -----------------------------------------------------------------------------
// Reference existing storage account
// -----------------------------------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// -----------------------------------------------------------------------------
// Flex Consumption Plan
// -----------------------------------------------------------------------------

resource flexPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${name}-plan'
  location: location
  tags: tags
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true // Linux
  }
}

// -----------------------------------------------------------------------------
// Function App
// -----------------------------------------------------------------------------

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: flexPlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        // Runtime config
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'NODE_ENV'
          value: environment == 'prod' ? 'production' : 'development'
        }
        // Storage connection
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountName
        }
        // Key Vault references — secrets stay in Key Vault
        {
          name: 'DISCORD_BOT_TOKEN'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=discord-bot-token)'
        }
        {
          name: 'ANTHROPIC_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=anthropic-api-key)'
        }
        {
          name: 'DISCORD_WEBHOOK_URL'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=discord-webhook-url)'
        }
        // Storage table names
        {
          name: 'TABLE_INBOX'
          value: 'inbox'
        }
        {
          name: 'TABLE_MEMORY'
          value: 'memory'
        }
        {
          name: 'TABLE_SCHEDULE'
          value: 'schedule'
        }
        {
          name: 'TABLE_SESSION_LOG'
          value: 'sessionlog'
        }
        // Blob lease config
        {
          name: 'LEASE_CONTAINER'
          value: 'locks'
        }
        {
          name: 'LEASE_BLOB_NAME'
          value: 'bananabot-singleton'
        }
        // File share for session persistence
        {
          name: 'SESSION_FILE_SHARE'
          value: fileShareName
        }
        // Key Vault URI for direct access if needed
        {
          name: 'KEY_VAULT_URI'
          value: keyVaultUri
        }
        // Identity
        {
          name: 'BOT_NAME'
          value: 'BananaBot9000'
        }
        {
          name: 'ENVIRONMENT'
          value: environment
        }
      ]
      // Concurrency control — singleton brain
      functionAppScaleLimit: 1
    }
  }
}

// -----------------------------------------------------------------------------
// RBAC — Function App Managed Identity permissions
// -----------------------------------------------------------------------------

// Storage Blob Data Contributor — for blob lease
resource blobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountId, functionApp.id, 'blob-contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Table Data Contributor — for table storage
resource tableRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountId, functionApp.id, 'table-contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Key Vault Secrets User — read secrets only
resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultName, functionApp.id, 'kv-secrets-user')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output principalId string = functionApp.identity.principalId
