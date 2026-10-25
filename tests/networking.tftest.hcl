# Tests unitaires du module networking (exécuté isolément via `module { source }`).
# Vérifie le nommage des sous-réseaux, les plages CIDR et le nombre de zones DNS.

mock_provider "azurerm" {}

run "networking_unit" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    name_prefix         = "web3t-dev"
    location            = "francecentral"
    resource_group_name = "rg-web3t-dev"
    tags                = {}
    vnet_address_space  = ["10.0.0.0/16"]
    subnet_prefixes = {
      public_a = "10.0.1.0/24"
      public_b = "10.0.2.0/24"
      app_a    = "10.0.11.0/24"
      app_b    = "10.0.12.0/24"
      data_a   = "10.0.21.0/24"
      data_b   = "10.0.22.0/24"
      bastion  = "10.0.0.0/26"
      appgw    = "10.0.3.0/24"
    }
    availability_zones         = ["1", "2"]
    enable_ddos_protection     = false
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
  }

  assert {
    condition     = azurerm_virtual_network.this.name == "vnet-web3t-dev"
    error_message = "Le VNet doit s'appeler vnet-web3t-dev."
  }

  # Contrainte Azure : le sous-réseau Bastion DOIT s'appeler AzureBastionSubnet
  assert {
    condition     = azurerm_subnet.bastion.name == "AzureBastionSubnet"
    error_message = "Le sous-réseau Bastion doit s'appeler AzureBastionSubnet."
  }

  assert {
    condition     = azurerm_subnet.app_a.address_prefixes[0] == "10.0.11.0/24"
    error_message = "Le sous-réseau app_a doit porter le préfixe 10.0.11.0/24."
  }

  # 5 zones DNS privées attendues (sql, blob, vault, sites, servicebus)
  assert {
    condition     = length(azurerm_private_dns_zone.this) == 5
    error_message = "5 zones DNS privées doivent être créées."
  }

  # Délégation App Service présente sur le sous-réseau app_a
  assert {
    condition     = azurerm_subnet.app_a.delegation[0].service_delegation[0].name == "Microsoft.Web/serverFarms"
    error_message = "Le sous-réseau app_a doit être délégué à Microsoft.Web/serverFarms."
  }

  # DDoS désactivé ici -> aucun plan créé (count connu au plan)
  assert {
    condition     = length(azurerm_network_ddos_protection_plan.this) == 0
    error_message = "Sans DDoS, aucun plan de protection ne doit être créé."
  }
}

# DDoS activé -> exactement un plan de protection
run "networking_ddos_active" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    name_prefix         = "web3t-prod"
    location            = "francecentral"
    resource_group_name = "rg-web3t-prod"
    tags                = {}
    vnet_address_space  = ["10.30.0.0/16"]
    subnet_prefixes = {
      public_a = "10.30.1.0/24"
      public_b = "10.30.2.0/24"
      app_a    = "10.30.11.0/24"
      app_b    = "10.30.12.0/24"
      data_a   = "10.30.21.0/24"
      data_b   = "10.30.22.0/24"
      bastion  = "10.30.0.0/26"
      appgw    = "10.30.3.0/24"
    }
    availability_zones         = ["1", "2"]
    enable_ddos_protection     = true
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
  }

  assert {
    condition     = length(azurerm_network_ddos_protection_plan.this) == 1
    error_message = "Avec DDoS activé, un plan de protection doit être créé."
  }
}
