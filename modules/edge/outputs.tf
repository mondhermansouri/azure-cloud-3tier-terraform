output "frontdoor_endpoint_hostname" {
  description = "Nom d'hôte public de l'endpoint Front Door."
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "frontdoor_profile_id" {
  description = "ID du profil Front Door."
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "waf_policy_id" {
  description = "ID de la politique WAF Front Door."
  value       = azurerm_cdn_frontdoor_firewall_policy.this.id
}

output "dns_zone_id" {
  description = "ID de la zone DNS publique (null si non créée)."
  value       = var.dns_zone_name != "" ? azurerm_dns_zone.this[0].id : null
}

output "dns_zone_name_servers" {
  description = "Serveurs de noms de la zone DNS (à déléguer chez le registrar)."
  value       = var.dns_zone_name != "" ? azurerm_dns_zone.this[0].name_servers : []
}
