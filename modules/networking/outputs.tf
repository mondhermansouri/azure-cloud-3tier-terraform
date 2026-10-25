output "vnet_id" {
  description = "ID du Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Nom du Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map des IDs de sous-réseaux par rôle."
  value = {
    public_a = azurerm_subnet.public_a.id
    public_b = azurerm_subnet.public_b.id
    app_a    = azurerm_subnet.app_a.id
    app_b    = azurerm_subnet.app_b.id
    data_a   = azurerm_subnet.data_a.id
    data_b   = azurerm_subnet.data_b.id
    appgw    = azurerm_subnet.appgw.id
    bastion  = azurerm_subnet.bastion.id
  }
}

output "private_dns_zone_ids" {
  description = "Map des IDs de zones DNS privées par clé (sql, blob, vault, sites, servicebus)."
  value       = { for k, z in azurerm_private_dns_zone.this : k => z.id }
}

output "nat_gateway_id" {
  description = "ID de la NAT Gateway."
  value       = azurerm_nat_gateway.this.id
}

output "ddos_protection_plan_id" {
  description = "ID du plan DDoS (null si désactivé)."
  value       = var.enable_ddos_protection ? azurerm_network_ddos_protection_plan.this[0].id : null
}
