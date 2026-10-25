# locals.tf
# Conventions de nommage et tags communs dérivés des variables.

locals {
  # Préfixe de nommage : <projet>-<env>  (ex: web3t-prod)
  name_prefix = "${var.project}-${var.environment}"

  # Suffixe court sans tiret pour les ressources à nom global contraint
  # (storage account, etc.). Le random_string ajoute l'unicité.
  name_compact = "${var.project}${var.environment}"

  common_tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
      stack       = "azure-web-3tiers"
    },
    var.tags
  )
}

# Suffixe aléatoire stable pour garantir l'unicité globale des noms
# (Storage Account, Key Vault, SQL Server, Front Door...).
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}
