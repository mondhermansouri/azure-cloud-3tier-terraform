output "key_vault_id" {
  description = "ID du Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  description = "URI du Key Vault."
  value       = azurerm_key_vault.this.vault_uri
}

output "key_vault_name" {
  description = "Nom du Key Vault."
  value       = azurerm_key_vault.this.name
}
