# Tests d'intégration de la configuration racine.
# Exécutés en `command = plan` avec des providers MOCKÉS : aucune
# authentification Azure ni ressource réelle. Vérifie le nommage, le câblage
# inter-modules et le comportement conditionnel par environnement.

mock_provider "azurerm" {
  # azurerm_client_config valide ses UUID au plan : on fournit des GUID valides.
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      client_id       = "00000000-0000-0000-0000-000000000004"
    }
  }
}
mock_provider "azuread" {}
mock_provider "random" {}

# Variables par défaut communes aux runs (surchargées par run si besoin)
variables {
  project = "web3t"
}

# --- DEV : pas de géo-réplication, pas de DDoS ----------------------------
run "dev_plan" {
  command = plan

  variables {
    environment            = "dev"
    enable_geo_replication = false
    enable_ddos_protection = false
  }

  assert {
    condition     = azurerm_resource_group.main.name == "rg-web3t-dev"
    error_message = "Le resource group doit s'appeler rg-web3t-dev."
  }

  assert {
    condition     = module.networking.vnet_name == "vnet-web3t-dev"
    error_message = "Le VNet doit s'appeler vnet-web3t-dev."
  }

  assert {
    condition     = output.sql_failover_group_name == ""
    error_message = "En dev (géo-réplication désactivée), le failover group doit être vide."
  }

  assert {
    condition     = module.networking.ddos_protection_plan_id == null
    error_message = "En dev, aucun plan DDoS ne doit être créé."
  }
}

# --- PROD : géo-réplication + DDoS activés --------------------------------
# Le seul fait que le plan soit calculable avec geo+DDoS activés couvre le
# chemin prod. Les assertions sur les ressources conditionnelles (count) sont
# faites dans les tests unitaires de module (valeurs connues au plan).
run "prod_plan" {
  command = plan

  variables {
    environment            = "prod"
    enable_geo_replication = true
    enable_ddos_protection = true
  }

  assert {
    condition     = azurerm_resource_group.main.name == "rg-web3t-prod"
    error_message = "Le resource group doit s'appeler rg-web3t-prod."
  }

  assert {
    condition     = module.networking.vnet_name == "vnet-web3t-prod"
    error_message = "Le VNet doit s'appeler vnet-web3t-prod."
  }
}
