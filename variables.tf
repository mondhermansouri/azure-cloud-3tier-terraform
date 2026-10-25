# variables.tf
# Variables d'entrée de la configuration racine. Les valeurs concrètes sont
# définies par environnement dans environments/<env>/terraform.tfvars.

variable "subscription_id" {
  description = "ID d'abonnement Azure (sinon fourni via ARM_SUBSCRIPTION_ID)."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Nom de l'environnement (dev, test, prod)."
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment doit valoir dev, test ou prod."
  }
}

variable "project" {
  description = "Nom court du projet, utilisé pour le nommage des ressources."
  type        = string
  default     = "web3t"
}

variable "location" {
  description = "Région Azure principale."
  type        = string
  default     = "francecentral"
}

variable "location_secondary" {
  description = "Région Azure secondaire (réplication géo / failover SQL)."
  type        = string
  default     = "northeurope"
}

variable "availability_zones" {
  description = "Zones de disponibilité utilisées (le schéma montre Zone 1 / Zone 2)."
  type        = list(string)
  default     = ["1", "2"]
}

variable "tags" {
  description = "Tags communs appliqués à toutes les ressources."
  type        = map(string)
  default     = {}
}

# --- Réseau ---------------------------------------------------------------

variable "vnet_address_space" {
  description = "Espace d'adressage du Virtual Network (10.0.0.0/16 sur le schéma)."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  description = "Préfixes CIDR par rôle de sous-réseau (un par zone : A et B)."
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
  default = {
    public_a = "10.0.1.0/24"
    public_b = "10.0.2.0/24"
    app_a    = "10.0.11.0/24"
    app_b    = "10.0.12.0/24"
    data_a   = "10.0.21.0/24"
    data_b   = "10.0.22.0/24"
    bastion  = "10.0.0.0/26"
    appgw    = "10.0.3.0/24"
  }
}

# --- Compute (App Tier) ---------------------------------------------------

variable "app_service_sku" {
  description = "SKU du plan App Service (ex: P1v3 en prod, B1 en dev)."
  type        = string
  default     = "P1v3"
}

variable "app_autoscale" {
  description = "Paramètres d'autoscale du plan App Service."
  type = object({
    min_capacity     = number
    max_capacity     = number
    default_capacity = number
    cpu_scale_out    = number
    cpu_scale_in     = number
  })
  default = {
    min_capacity     = 2
    max_capacity     = 10
    default_capacity = 2
    cpu_scale_out    = 70
    cpu_scale_in     = 25
  }
}

variable "app_docker_image" {
  description = "Image conteneur de l'application (laisser vide pour un code deploy classique)."
  type        = string
  default     = ""
}

# --- Data (Data Tier) -----------------------------------------------------

variable "sql_admin_login" {
  description = "Login administrateur du serveur Azure SQL."
  type        = string
  default     = "sqladminuser"
}

variable "sql_sku" {
  description = "SKU/Tier de la base Azure SQL (ex: S1, GP_S_Gen5_2)."
  type        = string
  default     = "GP_Gen5_2"
}

variable "sql_max_size_gb" {
  description = "Taille max de la base SQL en Go."
  type        = number
  default     = 32
}

variable "enable_geo_replication" {
  description = "Active le failover group géo-redondant (Primaire/Secondaire du schéma)."
  type        = bool
  default     = true
}

# --- Edge / Sécurité ------------------------------------------------------

variable "dns_zone_name" {
  description = "Nom de la zone DNS publique (laisser vide pour ne pas en créer)."
  type        = string
  default     = ""
}

variable "frontdoor_sku" {
  description = "SKU Azure Front Door (Standard_AzureFrontDoor ou Premium_AzureFrontDoor)."
  type        = string
  default     = "Premium_AzureFrontDoor"
}

variable "enable_ddos_protection" {
  description = "Active un plan DDoS Protection Standard (coûteux : off en dev)."
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "Plages IP autorisées (admin/CI) pour les règles WAF/pare-feu."
  type        = list(string)
  default     = []
}

# --- Alerting -------------------------------------------------------------

variable "alert_emails" {
  description = "Adresses e-mail destinataires des alertes (Action Group)."
  type        = list(string)
  default     = []
}
