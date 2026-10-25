variable "name_prefix" {
  type        = string
  description = "Préfixe de nommage."
}

variable "suffix" {
  type        = string
  description = "Suffixe aléatoire d'unicité globale."
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

variable "frontdoor_sku" {
  type        = string
  description = "SKU Front Door (Standard_AzureFrontDoor / Premium_AzureFrontDoor)."
}

variable "origin_hostname" {
  type        = string
  description = "Nom d'hôte de l'origine (App Service / Application Gateway)."
}

variable "dns_zone_name" {
  type        = string
  description = "Zone DNS publique (vide = pas de zone)."
  default     = ""
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "Plages IP autorisées (règles WAF custom)."
  default     = []
}
