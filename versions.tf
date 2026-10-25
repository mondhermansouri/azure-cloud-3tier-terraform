# versions.tf
# Contraintes de versions Terraform et providers.
# Le bloc backend est volontairement "partiel" : la configuration concrète
# (resource group / storage account / clé d'état) est injectée par environnement
# via `terraform init -backend-config=environments/<env>/backend.tfvars`.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
    # Valeurs fournies via -backend-config (voir environments/<env>/backend.tfvars)
    # resource_group_name  = "..."
    # storage_account_name = "..."
    # container_name       = "tfstate"
    # key                  = "<env>.terraform.tfstate"
  }
}
