# modules/edge
# Edge / Global : Azure Front Door (Global Entry) avec WAF managé + DDoS au
# niveau plateforme, et zone DNS publique optionnelle (Azure DNS).

# --- Zone DNS publique (optionnelle) ---------------------------------------
resource "azurerm_dns_zone" "this" {
  count               = var.dns_zone_name != "" ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# --- Front Door (profil + endpoint) ----------------------------------------
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = "afd-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  sku_name            = var.frontdoor_sku
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "fde-${var.name_prefix}-${var.suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = "og-appservice"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    interval_in_seconds = 30
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  name                          = "origin-appservice"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id

  enabled                        = true
  host_name                      = var.origin_hostname
  origin_host_header             = var.origin_hostname
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = "route-default"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this.id]

  enabled                = true
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
}

# --- WAF (politique managée OWASP, rattachée via Security Policy) ----------
resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                = "wafafd${replace(var.name_prefix, "-", "")}"
  resource_group_name = var.resource_group_name
  sku_name            = var.frontdoor_sku
  enabled             = true
  mode                = "Prevention"
  tags                = var.tags

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  dynamic "custom_rule" {
    for_each = length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      name     = "AllowAdminIPs"
      enabled  = true
      priority = 1
      type     = "MatchRule"
      action   = "Allow"

      match_condition {
        match_variable     = "RemoteAddr"
        operator           = "IPMatch"
        negation_condition = false
        match_values       = var.allowed_ip_ranges
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  name                     = "secpol-${var.name_prefix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
