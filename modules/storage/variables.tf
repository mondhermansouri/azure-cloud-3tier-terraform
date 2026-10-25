variable "name_compact" {
  type        = string
  description = "Préfixe compact (sans tiret)."
}

variable "suffix" {
  type        = string
  description = "Suffixe aléatoire d'unicité globale."
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

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "Sous-réseaux autorisés."
  default     = []
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "Plages IP autorisées."
  default     = []
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Workspace Log Analytics."
}

variable "replication_type" {
  type        = string
  description = "Type de réplication du compte de stockage (LRS, ZRS, GRS, RAGRS)."
  default     = "ZRS"
}
