# terraform-cloudflare-email-routing

This Terraform project provisions **Cloudflare Email Routing** with complete configuration: custom email aliases, catch-all, custom rules, and optional **DNS records** (MX, SPF).

---

## What is Cloudflare Email Routing?

Cloudflare Email Routing is a free email forwarding service that lets you create custom email addresses at your domain and forward them to your existing inbox (Gmail, Outlook, etc.) without hosting your own mail server.

Key features:
- **Unlimited forwarding addresses** — create any email@yourdomain.com
- **Catch-all routing** — forward every email that doesn't match a specific rule
- **Custom rules** — route by recipient, with priority ordering
- **Automatic DNS management** — MX and SPF records are created for you (optional)
- **Privacy** — your real inbox address stays hidden behind your domain

---

## Prerequisites

- **Terraform** >= 1.5 — [install](https://developer.hashicorp.com/terraform/downloads)
- **Cloudflare account** — [sign up](https://dash.cloudflare.com/)
- **Domain on Cloudflare** — your domain must use Cloudflare's nameservers

---

## Setup Guide

### Step 1: Get your Zone ID

1. Log in to the [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select your domain
3. Copy the **Zone ID** from the right sidebar under **API**

### Step 2: Get your Authentication Credentials

Choose either **Option A** (API Token, more secure) or **Option B** (Global API Key, more reliable):

#### Option A: API Token (Recommended for Security)

1. Go to **My Profile → API Tokens** → **Create Token** → **Create Custom Token**
2. Add permissions:
   - **Zone → Email Routing Rules → Write**
   - **Zone → DNS → Edit** (to manage DNS records)
3. Under **Zone Resources**, select your domain
4. Click **Continue to summary** → **Create Token**
5. Copy the token immediately

#### Option B: Global API Key (More Reliable)

1. Go to **My Profile → API Tokens**
2. Scroll down to **Global API Key**
3. Click **View**, enter your password, and copy the key

### Step 3: Configure Terraform

```bash
git clone <your-repo> && cd terraform-cloudflare-email-routing
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# Option 1: API Token (recommended for security)
# cloudflare_api_token = "your-api-token"

# Option 2: Global API Key + Email (more reliable)
cloudflare_api_email = "your-cloudflare-account-email@example.com"
cloudflare_api_key   = "your-global-api-key"

zone_id = "your-zone-id"

email_aliases = {
  "contact@yourdomain.com"  = ["hello@example.com"],
  "support@yourdomain.com"  = ["hello@example.com", "admin@example.com"]
}

catch_all = {
  enabled     = false
  destination = "admin@example.com"
}

custom_rules = [
  {
    name     = "forward-marketing"
    priority = 0
    matchers = [
      {
        type  = "literal"
        field = "to"
        value = "marketing@example.com"
      }
    ]
    actions = [
      {
        type   = "forward"
        values = ["hello@example.com"]
      }
    ]
  }
]

# Optional: manage DNS records (MX, SPF) — only set manage_dns_records to true if Email Routing is not yet enabled
manage_dns_records = false
add_spf_record = true
```

```bash
terraform init
terraform plan
terraform apply
```

### Step 4: Verify Destination Addresses

Each destination address will receive a verification email. You must click the link before email is forwarded. Check your inbox and confirm each address.

---

## Variables

| Variable | Description | Type | Required | Default |
|----------|-------------|------|----------|---------|
| `cloudflare_api_token` | Cloudflare API token (recommended for security) | `string` | no | `null` |
| `cloudflare_api_email` | Cloudflare account email (required if using `cloudflare_api_key`) | `string` | no | `null` |
| `cloudflare_api_key` | Cloudflare Global API Key (more reliable if API token has issues) | `string` | no | `null` |
| `account_id` | Cloudflare account ID (required for destination addresses) | `string` | yes | — |
| `zone_id` | Cloudflare zone ID | `string` | yes | — |
| `email_routing_enabled` | Enable Cloudflare Email Routing for the zone | `bool` | no | `true` |
| `destination_addresses` | List of destination email addresses (Terraform adds them, Cloudflare sends verification emails) | `list(string)` | no | `[]` |
| `email_aliases` | Map of custom email aliases (e.g., contact@yourdomain.com) to destination addresses | `map(list(string))` | no | `{}` |
| `catch_all` | Catch-all email routing rule configuration | `object` | no | `{}` |
| `custom_rules` | List of custom email routing rules with matchers and actions | `list(object)` | no | `[]` |
| `manage_dns_records` | Manage DNS records (MX, SPF) for Cloudflare Email Routing — only set to true if Email Routing is not yet enabled on the zone | `bool` | no | `false` |
| `add_spf_record` | Add an SPF TXT record for Cloudflare Email Routing | `bool` | no | `true` |

### Custom Rule Format

```hcl
{
  name     = "rule-name"
  priority = 0
  matchers = [
    {
      type  = "literal"   # or "all"
      field = "to"        # required when type = "literal"
      value = "user@example.com"
    }
  ]
  actions = [
    {
      type   = "forward"
      values = ["destination@example.com"]
    }
  ]
}
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `destination_addresses` | Destination email addresses added to Cloudflare |
| `email_aliases` | Created email aliases and their destination addresses |
| `custom_rule_ids` | IDs of created custom email routing rules |
| `catch_all_rule_id` | ID of catch-all email routing rule (if created) |
| `spf_record` | SPF TXT record for Cloudflare Email Routing (if created) |

---

## Important Notes

- **Address verification** — destination addresses must be manually verified in the Cloudflare Dashboard first (go to Email → Email Routing → Destination Addresses)
- **DNS records** — MX records (`route1`, `route2`, `route3.mx.cloudflare.net`) are automatically managed by Cloudflare when Email Routing is enabled, so `manage_dns_records` should stay false in most cases
- **Catch-all + custom rules** — rules are evaluated by priority. The catch-all is set to priority 100 to catch everything unmatched.
- **Rule ordering** — `priority` determines evaluation order (0 = first). Higher numbers run later.
- **Authentication** — use `cloudflare_api_key` + `cloudflare_api_email` if you run into permission errors with API tokens

