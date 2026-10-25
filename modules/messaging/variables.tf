variable "name_prefix" {
  type        = string
  description = "Préfixe de nommage."
}

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

variable "log_analytics_workspace_id" {
  type        = string
  description = "Workspace Log Analytics."
}

variable "servicebus_sku" {
  type        = string
  description = "SKU Service Bus (Standard / Premium)."
  default     = "Standard"
}

variable "functions_sku" {
  type        = string
  description = "SKU du plan des Azure Functions (Y1 = consommation)."
  default     = "Y1"
}
