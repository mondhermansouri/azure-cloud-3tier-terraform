output "log_analytics_workspace_id" {
  description = "ID du workspace Log Analytics."
  value       = azurerm_log_analytics_workspace.this.id
}

output "app_insights_connection_string" {
  description = "Chaîne de connexion Application Insights."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "Instrumentation key Application Insights."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "action_group_id" {
  description = "ID de l'Action Group pour les alertes."
  value       = azurerm_monitor_action_group.this.id
}
