terraform {
  required_version = ">= 1.5"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  email   = var.cloudflare_api_email != null ? var.cloudflare_api_email : null
  api_key = var.cloudflare_api_key != null ? var.cloudflare_api_key : null
}
