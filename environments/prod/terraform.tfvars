# Environnement PROD — haute dispo, géo-réplication et DDoS activés.
environment        = "prod"
project            = "web3t"
location           = "francecentral"
location_secondary = "northeurope"
availability_zones = ["1", "2"]

vnet_address_space = ["10.30.0.0/16"]
subnet_prefixes = {
  public_a = "10.30.1.0/24"
  public_b = "10.30.2.0/24"
  app_a    = "10.30.11.0/24"
  app_b    = "10.30.12.0/24"
  data_a   = "10.30.21.0/24"
  data_b   = "10.30.22.0/24"
  bastion  = "10.30.0.0/26"
  appgw    = "10.30.3.0/24"
}

app_service_sku = "P2v3"
app_autoscale = {
  min_capacity     = 3
  max_capacity     = 10
  default_capacity = 3
  cpu_scale_out    = 65
  cpu_scale_in     = 30
}

sql_sku                = "BC_Gen5_4" # Business Critical pour la résilience
sql_max_size_gb        = 128
enable_geo_replication = true

frontdoor_sku          = "Premium_AzureFrontDoor"
enable_ddos_protection = true

# Restreindre l'accès admin / CI aux plages connues
allowed_ip_ranges = []

alert_emails = ["alerts@example.com"]

tags = {
  cost_center = "production"
  owner       = "platform-team"
  criticality = "high"
}
