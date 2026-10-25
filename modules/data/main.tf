# modules/data
# Data Tier (Données) : Azure SQL — serveur Primaire + serveur Secondaire
# avec Failover Group (réplication géo-redondante), private endpoint,
# secrets stockés dans Key Vault, diagnostics et alerte DTU.

# Mot de passe admin généré et conservé dans Key Vault
resource "random_password" "sql" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# --- Serveur SQL primaire --------------------------------------------------
resource "azurerm_mssql_server" "primary" {
  name                          = "sql-${var.name_prefix}-${var.suffix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = random_password.sql.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = var.tags
}

# --- Serveur SQL secondaire (région secondaire) ----------------------------
resource "azurerm_mssql_server" "secondary" {
  count                         = var.enable_geo_replication ? 1 : 0
  name                          = "sql-${var.name_prefix}-sec-${var.suffix}"
  location                      = var.location_secondary
  resource_group_name           = var.resource_group_name
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = random_password.sql.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = var.tags
}

# --- Base de données -------------------------------------------------------
resource "azurerm_mssql_database" "this" {
  name                 = "sqldb-${var.name_prefix}"
  server_id            = azurerm_mssql_server.primary.id
  sku_name             = var.sql_sku
  max_size_gb          = var.sql_max_size_gb
  zone_redundant       = true
  storage_account_type = "Geo"
  tags                 = var.tags

  short_term_retention_policy {
    retention_days = 7
  }
}

# --- Failover Group (réplication géo-redondante du schéma) -----------------
resource "azurerm_mssql_failover_group" "this" {
  count     = var.enable_geo_replication ? 1 : 0
  name      = "fog-${var.name_prefix}-${var.suffix}"
  server_id = azurerm_mssql_server.primary.id
  databases = [azurerm_mssql_database.this.id]

  partner_server {
    id = azurerm_mssql_server.secondary[0].id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}

# --- Private endpoint vers le sous-réseau data -----------------------------
resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_ids[0]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-sql"
    private_connection_resource_id = azurerm_mssql_server.primary.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-dns"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

# --- Secrets dans Key Vault ------------------------------------------------
resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = random_password.sql.result
  key_vault_id = var.key_vault_id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "sql_connection_string" {
  name = "sql-connection-string"
  value = format(
    "Server=tcp:%s,1433;Database=%s;User ID=%s;Password=%s;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;",
    var.enable_geo_replication ? "${azurerm_mssql_failover_group.this[0].name}.database.windows.net" : azurerm_mssql_server.primary.fully_qualified_domain_name,
    azurerm_mssql_database.this.name,
    var.sql_admin_login,
    random_password.sql.result
  )
  key_vault_id = var.key_vault_id
  tags         = var.tags
}

# --- Diagnostics + alerte ---------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "sql" {
  name                       = "diag-sqldb"
  target_resource_id         = azurerm_mssql_database.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLInsights"
  }
  enabled_log {
    category = "Errors"
  }
  enabled_metric {
    category = "Basic"
  }
}

resource "azurerm_monitor_metric_alert" "sql_dtu" {
  name                = "alert-sql-dtu-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_mssql_database.this.id]
  description         = "Consommation DTU élevée sur la base SQL."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = var.tags
}
