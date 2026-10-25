# modules/messaging
# Messagerie & Intégration : Azure Service Bus (Queues / Topics),
# Event Grid (Évènements) et Azure Functions (traitement serverless).

# --- Service Bus -----------------------------------------------------------
resource "azurerm_servicebus_namespace" "this" {
  name                = "sb-${var.name_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.servicebus_sku
  tags                = var.tags
}

resource "azurerm_servicebus_queue" "work" {
  name         = "work-items"
  namespace_id = azurerm_servicebus_namespace.this.id

  partitioning_enabled = false
  max_delivery_count   = 10
}

resource "azurerm_servicebus_topic" "events" {
  name         = "domain-events"
  namespace_id = azurerm_servicebus_namespace.this.id
}

resource "azurerm_servicebus_subscription" "events_processor" {
  name               = "events-processor"
  topic_id           = azurerm_servicebus_topic.events.id
  max_delivery_count = 10
}

# --- Event Grid ------------------------------------------------------------
resource "azurerm_eventgrid_topic" "this" {
  name                = "egt-${var.name_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# --- Azure Functions (traitement serverless) -------------------------------
resource "azurerm_storage_account" "functions" {
  name                     = substr("stfn${var.name_compact}${var.suffix}", 0, 24)
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_service_plan" "functions" {
  name                = "asp-fn-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.functions_sku
  tags                = var.tags
}

resource "azurerm_linux_function_app" "this" {
  name                = "func-${var.name_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.functions.id

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  https_only                 = true
  tags                       = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "SERVICEBUS_CONNECTION"    = azurerm_servicebus_namespace.this.default_primary_connection_string
    "EVENTGRID_TOPIC_ENDPOINT" = azurerm_eventgrid_topic.this.endpoint
  }
}

resource "azurerm_monitor_diagnostic_setting" "servicebus" {
  name                       = "diag-sb"
  target_resource_id         = azurerm_servicebus_namespace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "AllMetrics"
  }
}
