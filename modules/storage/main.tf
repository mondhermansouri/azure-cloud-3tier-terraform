# modules/storage
# Stockage & Contenu : Azure Blob Storage (fichiers, images, documents),
# Azure Files (partages de fichiers) et Azure CDN (contenu statique / caching).

resource "azurerm_storage_account" "this" {
  name                     = substr("st${var.name_compact}${var.suffix}", 0, 24)
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags

  https_traffic_only_enabled    = true
  public_network_access_enabled = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices", "Logging", "Metrics"]
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }
}

# Conteneurs Blob : fichiers, images, documents
resource "azurerm_storage_container" "content" {
  for_each              = toset(["images", "documents", "uploads"])
  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Partage de fichiers (Azure Files)
resource "azurerm_storage_share" "this" {
  name               = "appshare"
  storage_account_id = azurerm_storage_account.this.id
  quota              = 100
}

# --- CDN (caching / contenu statique) -------------------------------------
resource "azurerm_cdn_profile" "this" {
  name                = "cdn-${var.name_compact}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard_Microsoft"
  tags                = var.tags
}

resource "azurerm_cdn_endpoint" "this" {
  name                = "cdne-${var.name_compact}-${var.suffix}"
  profile_name        = azurerm_cdn_profile.this.name
  location            = var.location
  resource_group_name = var.resource_group_name
  origin_host_header  = azurerm_storage_account.this.primary_blob_host
  tags                = var.tags

  origin {
    name      = "blob-origin"
    host_name = azurerm_storage_account.this.primary_blob_host
  }

  is_https_allowed = true
  is_http_allowed  = false
}

resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "diag-blob"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_metric {
    category = "Transaction"
  }
}
