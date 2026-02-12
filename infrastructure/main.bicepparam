using 'main.bicep'

param location = 'australiaeast'
param environment = 'dev'
param baseName = 'bananabot'

// Secrets — provided at deployment time, never committed
param discordBotToken = readEnvironmentVariable('DISCORD_BOT_TOKEN', '')
param anthropicApiKey = readEnvironmentVariable('ANTHROPIC_API_KEY', '')
param discordWebhookUrl = readEnvironmentVariable('DISCORD_WEBHOOK_URL', '')
