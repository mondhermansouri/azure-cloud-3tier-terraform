variable "name_prefix" {
  type        = string
  description = "Préfixe de nommage (<projet>-<env>)."
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

variable "vnet_address_space" {
  type        = list(string)
  description = "Espace d'adressage du VNet."
}

variable "subnet_prefixes" {
  type = object({
    public_a = string
    public_b = string
    app_a    = string
    app_b    = string
    data_a   = string
    data_b   = string
    bastion  = string
    appgw    = string
  })
  description = "Préfixes CIDR des sous-réseaux."
}

variable "availability_zones" {
  type        = list(string)
  description = "Zones de disponibilité."
}

variable "enable_ddos_protection" {
  type        = bool
  description = "Active un plan DDoS Protection Standard."
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Workspace Log Analytics pour les diagnostic settings."
}
