output "storage_account_id" {
  description = "ID du compte de stockage."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Nom du compte de stockage."
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Endpoint Blob primaire."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "cdn_endpoint_hostname" {
  description = "Nom d'hôte de l'endpoint CDN."
  value       = azurerm_cdn_endpoint.this.fqdn
}
