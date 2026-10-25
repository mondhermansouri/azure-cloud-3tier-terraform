# Environnement DEV — coûts minimisés, pas de géo-réplication ni DDoS.
environment        = "dev"
project            = "web3t"
location           = "francecentral"
location_secondary = "northeurope"
availability_zones = ["1", "2"]

vnet_address_space = ["10.10.0.0/16"]
subnet_prefixes = {
  public_a = "10.10.1.0/24"
  public_b = "10.10.2.0/24"
  app_a    = "10.10.11.0/24"
  app_b    = "10.10.12.0/24"
  data_a   = "10.10.21.0/24"
  data_b   = "10.10.22.0/24"
  bastion  = "10.10.0.0/26"
  appgw    = "10.10.3.0/24"
}

app_service_sku = "B1"
app_autoscale = {
  min_capacity     = 1
  max_capacity     = 2
  default_capacity = 1
  cpu_scale_out    = 75
  cpu_scale_in     = 25
}

sql_sku                = "GP_S_Gen5_1" # serverless, faible coût
sql_max_size_gb        = 32
enable_geo_replication = false

frontdoor_sku          = "Standard_AzureFrontDoor"
enable_ddos_protection = false

alert_emails = ["secopsag01@evoxai.ca"]

tags = {
  cost_center = "rnd"
  owner       = "platform-team"
}
