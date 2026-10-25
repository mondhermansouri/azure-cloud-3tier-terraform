variable "name_prefix" {
  type        = string
  description = "Préfixe de nommage."
}

variable "name_compact" {
  type        = string
  description = "Préfixe compact (sans tiret) pour noms contraints."
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

variable "tenant_id" {
  type        = string
  description = "Tenant Entra ID."
}

variable "admin_object_id" {
  type        = string
  description = "Object ID du principal exécutant Terraform (accès admin)."
}

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "Sous-réseaux autorisés à accéder au Key Vault."
  default     = []
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "Plages IP autorisées (admin/CI)."
  default     = []
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Workspace Log Analytics pour les diagnostic settings."
}
