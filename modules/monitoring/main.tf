# modules/monitoring
# Services transverses d'observabilité : Log Analytics (Centralisation logs),
# Application Insights (Logs / Metrics) et Action Group (Supervision & Alerting).

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.tags
}

# Action Group : route des alertes vers les destinataires (Email / SMS / ITSM)
resource "azurerm_monitor_action_group" "this" {
  name                = "ag-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = substr(replace(var.name_prefix, "-", ""), 0, 12)
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = { for i, e in var.alert_emails : i => e }
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}
