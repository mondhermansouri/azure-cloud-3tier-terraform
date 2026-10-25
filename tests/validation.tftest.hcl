# Tests des règles de validation des variables (cas d'échec attendus).

mock_provider "azurerm" {
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

# Un environnement hors (dev/test/prod) doit être rejeté par la validation.
run "rejette_environnement_invalide" {
  command = plan

  variables {
    environment = "staging"
  }

  expect_failures = [
    var.environment,
  ]
}

# Les environnements valides ne doivent PAS déclencher d'échec de validation.
run "accepte_environnement_valide" {
  command = plan

  variables {
    environment = "test"
  }

  assert {
    condition     = var.environment == "test"
    error_message = "L'environnement test doit être accepté."
  }
}
