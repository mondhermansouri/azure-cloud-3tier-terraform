variable "name_prefix" {
  type        = string
  description = "Préfixe de nommage."
}

variable "location" {
  type        = string
  description = "Région Azure."
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

variable "app_service_sku" {
  type        = string
  description = "SKU du plan App Service."
}

variable "autoscale" {
  type = object({
    min_capacity     = number
    max_capacity     = number
    default_capacity = number
    cpu_scale_out    = number
    cpu_scale_in     = number
  })
  description = "Paramètres d'autoscale."
}

variable "docker_image" {
  type        = string
  description = "Image conteneur (vide = stack code par défaut)."
  default     = ""
}

variable "app_integration_subnet_id" {
  type        = string
  description = "Sous-réseau délégué pour l'intégration VNet de l'App Service."
}

variable "appgw_subnet_id" {
  type        = string
  description = "Sous-réseau dédié à l'Application Gateway."
}

variable "availability_zones" {
  type        = list(string)
  description = "Zones de disponibilité."
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault dont l'App Service doit lire les secrets."
}

variable "app_insights_connection_string" {
  type        = string
  description = "Chaîne de connexion Application Insights."
  sensitive   = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Workspace Log Analytics."
}

variable "action_group_id" {
  type        = string
  description = "Action Group pour les alertes."
}

variable "sql_connection_secret_uri" {
  type        = string
  description = "URI Key Vault (sans version) de la chaîne de connexion SQL."
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "Plages IP autorisées."
  default     = []
}
