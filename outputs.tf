# outputs.tf
# Sorties principales de la stack.

output "resource_group_name" {
  description = "Resource group principal."
  value       = azurerm_resource_group.main.name
}

output "frontdoor_endpoint_hostname" {
  description = "Point d'entrée public Azure Front Door (Global Entry)."
  value       = module.edge.frontdoor_endpoint_hostname
}

output "app_service_hostname" {
  description = "Nom d'hôte par défaut de l'App Service (App Tier)."
  value       = module.compute.app_service_default_hostname
}

output "app_gateway_public_ip" {
  description = "IP publique de l'Application Gateway."
  value       = module.compute.app_gateway_public_ip
}

output "sql_server_fqdn" {
  description = "FQDN du serveur Azure SQL primaire."
  value       = module.data.sql_server_fqdn
}

output "sql_failover_group_name" {
  description = "Nom du failover group géo-redondant (vide si désactivé)."
  value       = module.data.failover_group_name
}

output "key_vault_uri" {
  description = "URI du Key Vault."
  value       = module.security.key_vault_uri
}

output "log_analytics_workspace_id" {
  description = "ID du workspace Log Analytics."
  value       = module.monitoring.log_analytics_workspace_id
}

output "storage_account_name" {
  description = "Nom du compte de stockage (Blob/Files)."
  value       = module.storage.storage_account_name
}

output "cdn_endpoint_hostname" {
  description = "Nom d'hôte de l'endpoint CDN."
  value       = module.storage.cdn_endpoint_hostname
}
