variable "cloudflare_api_token" {
  description = "Cloudflare API token with Email Routing and DNS edit permissions (optional, use api_key + api_email if needed)."
  type        = string
  sensitive   = true
  default     = null
}

variable "cloudflare_api_email" {
  description = "Cloudflare account email (only required if using api_key instead of api_token)."
  type        = string
  default     = null
}

variable "cloudflare_api_key" {
  description = "Cloudflare Global API Key (only required if not using api_token)."
  type        = string
  sensitive   = true
  default     = null
}

variable "account_id" {
  description = "Cloudflare account ID (required for destination addresses)."
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID."
  type        = string
}

variable "email_routing_enabled" {
  description = "Enable Cloudflare Email Routing for the zone."
  type        = bool
  default     = true
}

variable "destination_addresses" {
  description = "List of destination email addresses (Terraform will add them and send verification emails)."
  type        = list(string)
  default     = []
}

variable "catch_all" {
  description = "Catch-all email routing rule configuration."
  type = object({
    enabled     = optional(bool, false)
    destination = optional(string, "")
  })
  default = {}
}

variable "email_aliases" {
  description = "Map of custom email aliases (e.g., contact@yourdomain.com) to their destination email addresses."
  type        = map(list(string))
  default     = {}
}

variable "custom_rules" {
  description = "List of custom email routing rules with matchers and actions."
  type = list(object({
    name     = string
    priority = number
    matchers = list(object({
      type  = string
      field = optional(string)
      value = optional(string)
    }))
    actions = list(object({
      type   = string
      values = list(string)
    }))
  }))
  default = []
}

variable "manage_dns_records" {
  description = "Manage DNS records (MX, SPF) for Cloudflare Email Routing — only set to true if Email Routing is not yet enabled on the zone"
  type        = bool
  default     = false
}

variable "add_spf_record" {
  description = "Add an SPF TXT record for Cloudflare Email Routing"
  type        = bool
  default     = true
}
