# Backend distant DEV (Azure Storage).
# Le resource group / storage account doivent préexister (bootstrap one-time).
resource_group_name  = "rg-tfstate"
storage_account_name = "sttfstateweb3t"
container_name       = "tfstate"
key                  = "dev.terraform.tfstate"
