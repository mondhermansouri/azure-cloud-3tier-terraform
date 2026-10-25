# modules/networking
# Front Tier réseau : Virtual Network 10.0.0.0/16, sous-réseaux par zone
# (public / app / data), NAT Gateway, Azure Bastion, NSG, zones DNS privées
# et (optionnel) plan DDoS Protection Standard.

# --- Plan DDoS Protection (optionnel) -------------------------------------
resource "azurerm_network_ddos_protection_plan" "this" {
  count               = var.enable_ddos_protection ? 1 : 0
  name                = "ddos-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# --- Virtual Network ------------------------------------------------------
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = azurerm_network_ddos_protection_plan.this[0].id
      enable = true
    }
  }
}

# --- Sous-réseaux ----------------------------------------------------------
# Public (présentation) : exposition NAT/LB
resource "azurerm_subnet" "public_a" {
  name                 = "snet-public-a"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefixes.public_a]
}

resource "azurerm_subnet" "public_b" {
  name                 = "snet-public-b"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefixes.public_b]
}

# App (métier) : délégué à App Service pour l'intégration VNet
resource "azurerm_subnet" "app_a" {
  name                 = "snet-app-a"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefixes.app_a]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Sql", "Microsoft.Storage"]

  delegation {
    name = "appservice-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "app_b" {
  name                 = "snet-app-b"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefixes.app_b]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Sql", "Microsoft.Storage"]
}

# Data (données) : private endpoints SQL
resource "azurerm_subnet" "data_a" {
  name                 = "snet-data-a"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefixes.data_a]
  service_endpoints    = ["Microsoft.Sql"]
}

resource "azurerm_subnet" "data_b" {
  name                 = "snet-data-b"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefixes.data_b]
  service_endpoints    = ["Microsoft.Sql"]
}

# Application Gateway (sous-réseau dédié requis)
resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefixes.appgw]
}

# Azure Bastion (le nom du sous-réseau DOIT être AzureBastionSubnet)
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefixes.bastion]
}

# --- NAT Gateway (sortie internet maîtrisée pour les subnets privés) -------
resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                    = "natgw-${var.name_prefix}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Association NAT GW aux sous-réseaux App (sortie internet pour le métier)
resource "azurerm_subnet_nat_gateway_association" "app_a" {
  subnet_id      = azurerm_subnet.app_a.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_subnet_nat_gateway_association" "app_b" {
  subnet_id      = azurerm_subnet.app_b.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

# --- Network Security Groups ----------------------------------------------
resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-AppGw-HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "data" {
  name                = "nsg-data-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-App-SQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefixes    = [var.subnet_prefixes.app_a, var.subnet_prefixes.app_b]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app_a" {
  subnet_id                 = azurerm_subnet.app_a.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "app_b" {
  subnet_id                 = azurerm_subnet.app_b.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "data_a" {
  subnet_id                 = azurerm_subnet.data_a.id
  network_security_group_id = azurerm_network_security_group.data.id
}

resource "azurerm_subnet_network_security_group_association" "data_b" {
  subnet_id                 = azurerm_subnet.data_b.id
  network_security_group_id = azurerm_network_security_group.data.id
}

# --- Azure Bastion (accès admin sécurisé sans IP publique sur les VMs) -----
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = "bastion-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

# --- Zones DNS privées (Private DNS - zones privées du schéma) -------------
locals {
  private_dns_zones = {
    sql        = "privatelink.database.windows.net"
    blob       = "privatelink.blob.core.windows.net"
    vault      = "privatelink.vaultcore.azure.net"
    sites      = "privatelink.azurewebsites.net"
    servicebus = "privatelink.servicebus.windows.net"
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = local.private_dns_zones
  name                  = "link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

# --- Diagnostic settings du VNet ------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "diag-vnet"
  target_resource_id         = azurerm_virtual_network.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "AllMetrics"
  }
}
