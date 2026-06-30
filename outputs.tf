output "destination_addresses" {
  description = "Destination email addresses added to Cloudflare"
  value       = [for addr in cloudflare_email_routing_address.this : addr.email]
}

output "email_aliases" {
  description = "Created email aliases"
  value       = { for k, v in cloudflare_email_routing_rule.aliases : k => v.actions[0].value }
}

output "custom_rule_ids" {
  description = "IDs of created custom email routing rules"
  value       = { for k, v in cloudflare_email_routing_rule.this : k => v.id }
}

output "catch_all_rule_id" {
  description = "ID of catch-all email routing rule (if created)"
  value       = length(cloudflare_email_routing_rule.catch_all) > 0 ? cloudflare_email_routing_rule.catch_all[0].id : null
}

output "spf_record" {
  description = "SPF TXT record for Cloudflare Email Routing"
  value       = var.add_spf_record && length(cloudflare_dns_record.spf) > 0 ? cloudflare_dns_record.spf[0].content : null
}
