locals {
  catch_all_enabled = var.catch_all.enabled && var.catch_all.destination != ""
  mx_servers = [
    { server = "route1.mx.cloudflare.net", priority = 1 },
    { server = "route2.mx.cloudflare.net", priority = 2 },
    { server = "route3.mx.cloudflare.net", priority = 3 }
  ]
}

# Destination Addresses (Terraform adds them, Cloudflare sends verification emails)
resource "cloudflare_email_routing_address" "this" {
  for_each = var.email_routing_enabled ? toset(var.destination_addresses) : toset([])

  account_id = var.account_id
  email      = each.value
}

# Alias Rules
resource "cloudflare_email_routing_rule" "aliases" {
  for_each = var.email_routing_enabled ? var.email_aliases : {}

  zone_id  = var.zone_id
  name     = "alias-${each.key}"
  enabled  = true
  priority = 10

  matcher {
    type  = "literal"
    field = "to"
    value = each.key
  }

  action {
    type  = "forward"
    value = each.value
  }

  depends_on = [cloudflare_email_routing_address.this]
}

# Catch-All Rule (implemented as a regular rule)
resource "cloudflare_email_routing_rule" "catch_all" {
  count = var.email_routing_enabled && local.catch_all_enabled ? 1 : 0

  zone_id  = var.zone_id
  name     = "catch-all"
  enabled  = var.catch_all.enabled
  priority = 100

  matcher {
    type = "all"
  }

  action {
    type  = "forward"
    value = [var.catch_all.destination]
  }

  depends_on = [cloudflare_email_routing_address.this]
}

# Custom Rules
resource "cloudflare_email_routing_rule" "this" {
  for_each = var.email_routing_enabled ? { for r in var.custom_rules : r.name => r } : {}

  zone_id  = var.zone_id
  name     = each.value.name
  priority = each.value.priority
  enabled  = true

  dynamic "matcher" {
    for_each = each.value.matchers
    content {
      type  = matcher.value.type
      field = lookup(matcher.value, "field", null)
      value = lookup(matcher.value, "value", null)
    }
  }

  dynamic "action" {
    for_each = each.value.actions
    content {
      type  = action.value.type
      value = action.value.values
    }
  }

  depends_on = [cloudflare_email_routing_address.this]
}

# DNS Records for Email Routing (only set manage_dns_records = true if Email Routing is not yet enabled)
resource "cloudflare_record" "mx" {
  for_each = var.email_routing_enabled && var.manage_dns_records ? { for idx, mx in local.mx_servers : idx => mx } : {}

  zone_id  = var.zone_id
  name     = "@"
  type     = "MX"
  content  = each.value.server
  priority = each.value.priority
  ttl      = 1
}

# SPF Record (optional)
resource "cloudflare_record" "spf" {
  count = var.email_routing_enabled && var.add_spf_record ? 1 : 0

  zone_id         = var.zone_id
  name            = "@"
  type            = "TXT"
  content         = "v=spf1 include:_spf.mx.cloudflare.net ~all"
  ttl             = 1
  allow_overwrite = true
}
