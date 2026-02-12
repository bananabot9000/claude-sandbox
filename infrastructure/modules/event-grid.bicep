// =============================================================================
// Event Grid Topic — The doorbell
// Multiple sources publish events here. BananaBot wakes up.
// =============================================================================

@description('Event Grid topic name')
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

// -----------------------------------------------------------------------------
// Event Grid Topic
// -----------------------------------------------------------------------------

resource topic 'Microsoft.EventGrid/topics@2024-06-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    inputSchema: 'EventGridSchema'
    publicNetworkAccess: 'Enabled'
  }
}

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

output topicName string = topic.name
output topicId string = topic.id
output topicEndpoint string = topic.properties.endpoint
