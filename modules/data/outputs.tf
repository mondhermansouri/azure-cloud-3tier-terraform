output "sql_server_id" {
  description = "ID du serveur SQL primaire."
  value       = azurerm_mssql_server.primary.id
}

output "sql_server_fqdn" {
  description = "FQDN du serveur SQL primaire."
  value       = azurerm_mssql_server.primary.fully_qualified_domain_name
}

output "database_id" {
  description = "ID de la base de données."
  value       = azurerm_mssql_database.this.id
}

output "failover_group_name" {
  description = "Nom du failover group (vide si géo-réplication désactivée)."
  value       = var.enable_geo_replication ? azurerm_mssql_failover_group.this[0].name : ""
}

output "sql_connection_secret_uri" {
  description = "URI (sans version) du secret Key Vault contenant la chaîne de connexion."
  value       = azurerm_key_vault_secret.sql_connection_string.versionless_id
}
