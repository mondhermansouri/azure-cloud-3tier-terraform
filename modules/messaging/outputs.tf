output "servicebus_namespace_id" {
  description = "ID du namespace Service Bus."
  value       = azurerm_servicebus_namespace.this.id
}

output "eventgrid_topic_id" {
  description = "ID du topic Event Grid."
  value       = azurerm_eventgrid_topic.this.id
}

output "eventgrid_topic_endpoint" {
  description = "Endpoint du topic Event Grid."
  value       = azurerm_eventgrid_topic.this.endpoint
}

output "function_app_hostname" {
  description = "Nom d'hôte par défaut de la Function App."
  value       = azurerm_linux_function_app.this.default_hostname
}
