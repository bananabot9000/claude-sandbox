// =============================================================================
// Event Grid Subscription — Wires the doorbell to BananaBot's Function
// =============================================================================

@description('Event Grid topic name')
param eventGridTopicName string

@description('Function App resource ID')
param functionAppId string

// -----------------------------------------------------------------------------
// Reference existing resources
// -----------------------------------------------------------------------------

resource topic 'Microsoft.EventGrid/topics@2024-06-01-preview' existing = {
  name: eventGridTopicName
}

// -----------------------------------------------------------------------------
// Event Grid Subscription — push events to Function HTTP endpoint
// -----------------------------------------------------------------------------

resource subscription 'Microsoft.EventGrid/topics/eventSubscriptions@2024-06-01-preview' = {
  parent: topic
  name: 'bananabot-wakeup'
  properties: {
    destination: {
      endpointType: 'AzureFunction'
      properties: {
        resourceId: '${functionAppId}/functions/wakeup'
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
    }
    filter: {
      includedEventTypes: [
        'BananaBot.DiscordMessage'
        'BananaBot.ScheduledWakeUp'
        'BananaBot.TimerCheck'
        'BananaBot.SelfPrompt'
      ]
    }
    retryPolicy: {
      maxDeliveryAttempts: 3
      eventTimeToLiveInMinutes: 5
    }
  }
}
