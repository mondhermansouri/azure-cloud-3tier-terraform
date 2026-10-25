# modules/compute
# App Tier (Métier) : plan App Service (zone-redundant), App Services Web et API,
# autoscale piloté CPU, intégration VNet, lecture des secrets via Key Vault,
# et Application Gateway WAF_v2 en frontal régional.

locals {
  # Référence Key Vault pour injecter la chaîne de connexion SQL en app setting
  sql_conn_kv_ref = "@Microsoft.KeyVault(SecretUri=${var.sql_connection_secret_uri})"
}

# --- Plan App Service ------------------------------------------------------
resource "azurerm_service_plan" "this" {
  name                   = "asp-${var.name_prefix}"
  location               = var.location
  resource_group_name    = var.resource_group_name
  os_type                = "Linux"
  sku_name               = var.app_service_sku
  zone_balancing_enabled = length(var.availability_zones) > 1
  tags                   = var.tags
}

# --- Web App (présentation/métier) -----------------------------------------
resource "azurerm_linux_web_app" "web" {
  name                      = "app-${var.name_prefix}-web"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  service_plan_id           = azurerm_service_plan.this.id
  https_only                = true
  virtual_network_subnet_id = var.app_integration_subnet_id
  tags                      = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on              = true
    http2_enabled          = true
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    vnet_route_all_enabled = true

    dynamic "application_stack" {
      for_each = var.docker_image != "" ? [1] : []
      content {
        docker_image_name = var.docker_image
      }
    }

    ip_restriction_default_action = "Deny"

    # Seul l'Application Gateway (via le VNet) atteint l'App Service
    ip_restriction {
      name                      = "allow-vnet"
      priority                  = 100
      action                    = "Allow"
      virtual_network_subnet_id = var.appgw_subnet_id
    }
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    "SQL_CONNECTION_STRING"                 = local.sql_conn_kv_ref
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
    application_logs {
      file_system_level = "Information"
    }
  }
}

# --- API App (métier) ------------------------------------------------------
resource "azurerm_linux_web_app" "api" {
  name                      = "app-${var.name_prefix}-api"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  service_plan_id           = azurerm_service_plan.this.id
  https_only                = true
  virtual_network_subnet_id = var.app_integration_subnet_id
  tags                      = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on              = true
    http2_enabled          = true
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    vnet_route_all_enabled = true

    dynamic "application_stack" {
      for_each = var.docker_image != "" ? [1] : []
      content {
        docker_image_name = var.docker_image
      }
    }
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    "SQL_CONNECTION_STRING"                 = local.sql_conn_kv_ref
  }
}

# --- Accès Key Vault pour les identités managées des apps ------------------
resource "azurerm_role_assignment" "web_kv" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.web.identity[0].principal_id
}

resource "azurerm_role_assignment" "api_kv" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id
}

# --- Autoscale (le bloc "Azure Autoscale" du schéma) -----------------------
resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "autoscale-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_service_plan.this.id
  tags                = var.tags

  profile {
    name = "cpu-based"

    capacity {
      minimum = var.autoscale.min_capacity
      maximum = var.autoscale.max_capacity
      default = var.autoscale.default_capacity
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.autoscale.cpu_scale_out
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.autoscale.cpu_scale_in
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

# --- Application Gateway WAF_v2 (frontal régional L7) ----------------------
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "this" {
  name                = "waf-appgw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

locals {
  appgw_name    = "appgw-${var.name_prefix}"
  backend_pool  = "pool-appservice"
  http_setting  = "https-setting"
  frontend_ip   = "frontend-ip"
  frontend_port = "port-443"
  listener_name = "listener-https"
  routing_rule  = "rule-default"
  probe_name    = "probe-appservice"
}

resource "azurerm_application_gateway" "this" {
  name                = local.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = var.availability_zones
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id
  tags                = var.tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = local.frontend_port
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name  = local.backend_pool
    fqdns = [azurerm_linux_web_app.web.default_hostname]
  }

  probe {
    name                                      = local.probe_name
    protocol                                  = "Https"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = ["200-399"]
    }
  }

  backend_http_settings {
    name                                = local.http_setting
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = local.probe_name
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip
    frontend_port_name             = local.frontend_port
    protocol                       = "Http" # TLS terminé en amont par Front Door ; à passer en Https + certificat si exposition directe
  }

  request_routing_rule {
    name                       = local.routing_rule
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_pool
    backend_http_settings_name = local.http_setting
  }

  lifecycle {
    # Front Door / déploiements applicatifs peuvent modifier ces blocs hors Terraform
    ignore_changes = [backend_address_pool, backend_http_settings, probe]
  }
}

# --- Diagnostics + alerte CPU ----------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "web" {
  name                       = "diag-web"
  target_resource_id         = azurerm_linux_web_app.web.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  enabled_log {
    category = "AppServiceConsoleLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "alert-cpu-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_service_plan.this.id]
  description         = "CPU élevé sur le plan App Service."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/serverfarms"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = var.tags
}
