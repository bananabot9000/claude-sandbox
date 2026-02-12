// =============================================================================
// Key Vault — Cerberus in the cloud
// Secrets go in, secrets stay in. Unlike BananaBot's first security audit.
// =============================================================================

@description('Key Vault resource name')
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

@secure()
param discordBotToken string

@secure()
param anthropicApiKey string

@secure()
param discordWebhookUrl string

// -----------------------------------------------------------------------------
// Key Vault
// -----------------------------------------------------------------------------

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false // dev environment, keep it simple
    networkAcls: {
      defaultAction: 'Allow' // tighten in prod
      bypass: 'AzureServices'
    }
  }
}

// -----------------------------------------------------------------------------
// Secrets
// -----------------------------------------------------------------------------

resource secretDiscordToken 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'discord-bot-token'
  properties: {
    value: discordBotToken
  }
}

resource secretAnthropicKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'anthropic-api-key'
  properties: {
    value: anthropicApiKey
  }
}

resource secretWebhookUrl 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'discord-webhook-url'
  properties: {
    value: discordWebhookUrl
  }
}

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

output keyVaultName string = vault.name
output keyVaultUri string = vault.properties.vaultUri
output keyVaultId string = vault.id
