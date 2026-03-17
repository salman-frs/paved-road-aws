locals {
  public_dns_enabled = var.enable_public_dns && var.cloudflare_zone_id != null
}

resource "cloudflare_dns_record" "service" {
  count = local.public_dns_enabled ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = local.service_public_hostname
  type    = "CNAME"
  content = local.ingress_anchor_hostname
  ttl     = 1
  proxied = true
  comment = "Public service hostname routed through the shared ingress anchor."
}
