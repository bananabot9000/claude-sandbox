// =============================================================================
// BananaBot9000 Infrastructure — Main Template
// =============================================================================
// The goldfish's house, defined in code.
// Designed by BananaBot9000. Reviewed & deployed by the Supreme Commander.
// =============================================================================

targetScope = 'resourceGroup'

// -----------------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------------

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Base name for resources')
param baseName string = 'bananabot'

@description('Discord bot token — stored in Key Vault, never in code')
@secure()
param discordBotToken string

@description('Anthropic API key — stored in Key Vault, never in code')
@secure()
param anthropicApiKey string

@description('Discord webhook URL for self-prompting')
@secure()
param discordWebhookUrl string

// -----------------------------------------------------------------------------
// Variables
// -----------------------------------------------------------------------------

var resourcePrefix = '${baseName}-${environment}'
var storageAccountName = replace('${baseName}${environment}st', '-', '')
var tags = {
  project: 'bananabot9000'
  environment: environment
  managedBy: 'bicep'
  designedBy: 'bananabot9000'
}

// -----------------------------------------------------------------------------
// Key Vault — Secrets management (Supreme Commander's domain)
// -----------------------------------------------------------------------------

module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    name: '${resourcePrefix}-kv'
    location: location
    tags: tags
    discordBotToken: discordBotToken
    anthropicApiKey: anthropicApiKey
    discordWebhookUrl: discordWebhookUrl
  }
}

// -----------------------------------------------------------------------------
// Storage Account — Memory, inbox, blob lease, file share
// -----------------------------------------------------------------------------

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    tags: tags
  }
}

// -----------------------------------------------------------------------------
// Event Grid — Wake-up signalling (the doorbell)
// -----------------------------------------------------------------------------

module eventGrid 'modules/event-grid.bicep' = {
  name: 'eventGrid'
  params: {
    name: '${resourcePrefix}-events'
    location: location
    tags: tags
  }
}

// -----------------------------------------------------------------------------
// Function App — BananaBot9000 (the brain)
// Flex Consumption plan with file share for session persistence
// -----------------------------------------------------------------------------

module functionApp 'modules/function-app.bicep' = {
  name: 'functionApp'
  params: {
    name: '${resourcePrefix}-func'
    location: location
    tags: tags
    storageAccountName: storage.outputs.storageAccountName
    storageAccountId: storage.outputs.storageAccountId
    keyVaultName: keyVault.outputs.keyVaultName
    keyVaultUri: keyVault.outputs.keyVaultUri
    fileShareName: storage.outputs.fileShareName
    environment: environment
  }
}

// -----------------------------------------------------------------------------
// Event Grid Subscription — Wire doorbell to Function
// -----------------------------------------------------------------------------

module eventGridSubscription 'modules/event-grid-subscription.bicep' = {
  name: 'eventGridSubscription'
  params: {
    eventGridTopicName: eventGrid.outputs.topicName
    functionAppId: functionApp.outputs.functionAppId
  }
}

// -----------------------------------------------------------------------------
// Container App — Listener (dumb, resilient, Supreme Commander's code)
// Placeholder — to be defined by Hellcar
// -----------------------------------------------------------------------------

// module listener 'modules/listener.bicep' = {
//   name: 'listener'
//   params: {
//     // Listener is the Supreme Commander's domain
//     // Just needs: Event Grid topic endpoint + Storage Account connection
//   }
// }

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

output functionAppName string = functionApp.outputs.functionAppName
output functionAppUrl string = functionApp.outputs.functionAppUrl
output storageAccountName string = storage.outputs.storageAccountName
output keyVaultName string = keyVault.outputs.keyVaultName
output eventGridTopicEndpoint string = eventGrid.outputs.topicEndpoint
