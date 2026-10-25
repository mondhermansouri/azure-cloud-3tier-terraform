# Tests unitaires du module data : comportement du failover group géo-redondant
# selon enable_geo_replication (assertions sur les `count`, connues au plan).

mock_provider "azurerm" {}
mock_provider "random" {}

variables {
  name_prefix         = "web3t-test"
  suffix              = "abc123"
  location            = "francecentral"
  location_secondary  = "northeurope"
  resource_group_name = "rg-web3t-test"
  tags                = {}
  sql_admin_login     = "sqladminuser"
  sql_sku             = "GP_Gen5_2"
  sql_max_size_gb     = 32

  data_subnet_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet-data-a",
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet-data-b",
  ]
  private_dns_zone_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net"
  key_vault_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv-dummy"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
  action_group_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Insights/actionGroups/ag"
}

# Géo-réplication désactivée -> ni serveur secondaire ni failover group
run "data_sans_georeplication" {
  command = plan

  module {
    source = "./modules/data"
  }

  variables {
    enable_geo_replication = false
  }

  assert {
    condition     = length(azurerm_mssql_failover_group.this) == 0
    error_message = "Sans géo-réplication, aucun failover group ne doit exister."
  }

  assert {
    condition     = length(azurerm_mssql_server.secondary) == 0
    error_message = "Sans géo-réplication, aucun serveur secondaire ne doit exister."
  }
}

# Géo-réplication activée -> serveur secondaire + failover group
run "data_avec_georeplication" {
  command = plan

  module {
    source = "./modules/data"
  }

  variables {
    enable_geo_replication = true
  }

  assert {
    condition     = length(azurerm_mssql_failover_group.this) == 1
    error_message = "Avec géo-réplication, un failover group doit exister."
  }

  assert {
    condition     = length(azurerm_mssql_server.secondary) == 1
    error_message = "Avec géo-réplication, un serveur secondaire doit exister."
  }
}
