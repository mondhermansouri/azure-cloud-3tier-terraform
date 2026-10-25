# Environnement TEST — proche prod mais dimensionné modérément.
environment        = "test"
project            = "web3t"
location           = "francecentral"
location_secondary = "northeurope"
availability_zones = ["1", "2"]

vnet_address_space = ["10.20.0.0/16"]
subnet_prefixes = {
  public_a = "10.20.1.0/24"
  public_b = "10.20.2.0/24"
  app_a    = "10.20.11.0/24"
  app_b    = "10.20.12.0/24"
  data_a   = "10.20.21.0/24"
  data_b   = "10.20.22.0/24"
  bastion  = "10.20.0.0/26"
  appgw    = "10.20.3.0/24"
}

app_service_sku = "P1v3"
app_autoscale = {
  min_capacity     = 2
  max_capacity     = 4
  default_capacity = 2
  cpu_scale_out    = 70
  cpu_scale_in     = 25
}

sql_sku                = "GP_Gen5_2"
sql_max_size_gb        = 32
enable_geo_replication = false

frontdoor_sku          = "Standard_AzureFrontDoor"
enable_ddos_protection = false

alert_emails = ["alerts@example.com"]

tags = {
  cost_center = "qa"
  owner       = "platform-team"
}
