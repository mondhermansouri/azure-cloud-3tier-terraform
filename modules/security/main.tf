# modules/security
# Sécurité & Identité : Azure Key Vault (Secrets / Clés) avec RBAC,
# pare-feu réseau et journalisation vers Log Analytics.

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = substr("kv-${var.name_compact}-${var.suffix}", 0, 24)
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"
  tags                = var.tags

  # RBAC plutôt que les access policies (gestion des accès RBAC / PIM du schéma)
  rbac_authorization_enabled = true

  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  public_network_access_enabled = true

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }
}

# Le principal Terraform doit pouvoir gérer les secrets (création SQL pwd, etc.)
resource "azurerm_role_assignment" "admin_secrets" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_object_id
}

resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "diag-kv"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
