# providers.tf
# Authentification via Service Principal + secret.
# Les variables ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_TENANT_ID / ARM_SUBSCRIPTION_ID
# sont lues automatiquement par le provider depuis l'environnement (cf. GitHub Actions).

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }

  # subscription_id est requis par azurerm v4 ; fourni via ARM_SUBSCRIPTION_ID
  # ou explicitement par variable si besoin.
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
}

provider "azuread" {}

provider "random" {}
