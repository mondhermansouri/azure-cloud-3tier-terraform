output "app_service_default_hostname" {
  description = "Nom d'hôte par défaut de la Web App."
  value       = azurerm_linux_web_app.web.default_hostname
}

output "api_default_hostname" {
  description = "Nom d'hôte par défaut de l'API App."
  value       = azurerm_linux_web_app.api.default_hostname
}

output "app_service_id" {
  description = "ID de la Web App."
  value       = azurerm_linux_web_app.web.id
}

output "app_gateway_id" {
  description = "ID de l'Application Gateway."
  value       = azurerm_application_gateway.this.id
}

output "app_gateway_public_ip" {
  description = "IP publique de l'Application Gateway."
  value       = azurerm_public_ip.appgw.ip_address
}

output "service_plan_id" {
  description = "ID du plan App Service."
  value       = azurerm_service_plan.this.id
}
