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

variable "alert_emails" {
  type        = list(string)
  description = "Destinataires e-mail des alertes (Action Group)."
  default     = []
}

variable "log_retention_days" {
  type        = number
  description = "Rétention des logs Log Analytics (jours)."
  default     = 30
}
