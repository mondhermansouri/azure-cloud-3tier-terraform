# main.tf
# Configuration racine : crée le resource group et compose les modules
# représentant l'architecture "Application Web 3 Tiers" du schéma.

data "azurerm_client_config" "current" {}

# Resource group principal de la stack applicative
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

# ---------------------------------------------------------------------------
# Services transverses : observabilité (créés en premier, sans dépendances)
# Azure Monitor / Log Analytics / Action Groups (Supervision & Alerting).
# ---------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
  alert_emails        = var.alert_emails
}

# ---------------------------------------------------------------------------
# Front Tier (Présentation) — réseau : VNet, sous-réseaux par zone,
# NAT Gateway, Bastion, NSG, zones DNS privées, plan DDoS.
# ---------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  name_prefix                = local.name_prefix
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  tags                       = local.common_tags
  vnet_address_space         = var.vnet_address_space
  subnet_prefixes            = var.subnet_prefixes
  availability_zones         = var.availability_zones
  enable_ddos_protection     = var.enable_ddos_protection
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
}

# ---------------------------------------------------------------------------
# Sécurité & Identité — Azure Key Vault (Secrets / Clés).
# ---------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  name_prefix                = local.name_prefix
  name_compact               = local.name_compact
  suffix                     = random_string.suffix.result
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  tags                       = local.common_tags
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  admin_object_id            = data.azurerm_client_config.current.object_id
  allowed_subnet_ids         = [module.networking.subnet_ids.app_a, module.networking.subnet_ids.app_b]
  allowed_ip_ranges          = var.allowed_ip_ranges
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
}

# ---------------------------------------------------------------------------
# Stockage & Contenu — Blob Storage, Azure Files, CDN.
# ---------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"

  name_compact               = local.name_compact
  suffix                     = random_string.suffix.result
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  tags                       = local.common_tags
  allowed_subnet_ids         = [module.networking.subnet_ids.app_a, module.networking.subnet_ids.app_b]
  allowed_ip_ranges          = var.allowed_ip_ranges
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
}

# ---------------------------------------------------------------------------
# Data Tier (Données) — Azure SQL Primaire + Secondaire (géo-réplication).
# ---------------------------------------------------------------------------
module "data" {
  source = "./modules/data"

  name_prefix                = local.name_prefix
  suffix                     = random_string.suffix.result
  location                   = var.location
  location_secondary         = var.location_secondary
  resource_group_name        = azurerm_resource_group.main.name
  tags                       = local.common_tags
  sql_admin_login            = var.sql_admin_login
  sql_sku                    = var.sql_sku
  sql_max_size_gb            = var.sql_max_size_gb
  enable_geo_replication     = var.enable_geo_replication
  data_subnet_ids            = [module.networking.subnet_ids.data_a, module.networking.subnet_ids.data_b]
  private_dns_zone_id        = module.networking.private_dns_zone_ids["sql"]
  key_vault_id               = module.security.key_vault_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  action_group_id            = module.monitoring.action_group_id
}

# ---------------------------------------------------------------------------
# App Tier (Métier) — App Service (Web/API), Autoscale, Application Gateway.
# ---------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  name_prefix                    = local.name_prefix
  location                       = var.location
  resource_group_name            = azurerm_resource_group.main.name
  tags                           = local.common_tags
  app_service_sku                = var.app_service_sku
  autoscale                      = var.app_autoscale
  docker_image                   = var.app_docker_image
  app_integration_subnet_id      = module.networking.subnet_ids.app_a
  appgw_subnet_id                = module.networking.subnet_ids.appgw
  availability_zones             = var.availability_zones
  key_vault_id                   = module.security.key_vault_id
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  log_analytics_workspace_id     = module.monitoring.log_analytics_workspace_id
  action_group_id                = module.monitoring.action_group_id
  sql_connection_secret_uri      = module.data.sql_connection_secret_uri
  allowed_ip_ranges              = var.allowed_ip_ranges
}

# ---------------------------------------------------------------------------
# Edge / Global — Azure Front Door (Global Entry) + WAF + DNS public.
# ---------------------------------------------------------------------------
module "edge" {
  source = "./modules/edge"

  name_prefix         = local.name_prefix
  suffix              = random_string.suffix.result
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
  frontdoor_sku       = var.frontdoor_sku
  origin_hostname     = module.compute.app_service_default_hostname
  dns_zone_name       = var.dns_zone_name
  allowed_ip_ranges   = var.allowed_ip_ranges
}

# ---------------------------------------------------------------------------
# Messagerie & Intégration — Service Bus, Event Grid, Azure Functions.
# ---------------------------------------------------------------------------
module "messaging" {
  source = "./modules/messaging"

  name_prefix                = local.name_prefix
  name_compact               = local.name_compact
  suffix                     = random_string.suffix.result
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  tags                       = local.common_tags
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
}
