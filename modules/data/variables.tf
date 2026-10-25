variable "name_prefix" {
  type        = string
  description = "Préfixe de nommage."
}

variable "suffix" {
  type        = string
  description = "Suffixe aléatoire d'unicité globale."
}

variable "location" {
  type        = string
  description = "Région Azure principale."
}

variable "location_secondary" {
  type        = string
  description = "Région Azure secondaire (réplica failover)."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group cible."
}

variable "tags" {
  type        = map(string)
  description = "Tags communs."
  default     = {}
}

variable "sql_admin_login" {
  type        = string
  description = "Login administrateur SQL."
}

variable "sql_sku" {
  type        = string
  description = "SKU de la base SQL."
}

variable "sql_max_size_gb" {
  type        = number
  description = "Taille max de la base (Go)."
}

variable "enable_geo_replication" {
  type        = bool
  description = "Active le failover group géo-redondant."
  default     = true
}

variable "data_subnet_ids" {
  type        = list(string)
  description = "Sous-réseaux data (private endpoint + règles VNet)."
}

variable "private_dns_zone_id" {
  type        = string
  description = "Zone DNS privée privatelink.database.windows.net."
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault où stocker le mot de passe et la chaîne de connexion."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Workspace Log Analytics."
}

variable "action_group_id" {
  type        = string
  description = "Action Group pour les alertes."
}
