resource "cloudflare_dns_record" "ingress_anchor" {
  count = local.bootstrap_dns_enabled ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = local.ingress_anchor_hostname
  type    = "CNAME"
  content = var.ingress_public_hostname
  ttl     = 1
  proxied = false
  comment = "DNS-only ingress anchor for the dev platform environment."
}

resource "cloudflare_dns_record" "bootstrap_public_hosts" {
  for_each = local.bootstrap_dns_enabled ? local.bootstrap_public_hosts : {}

  zone_id = var.cloudflare_zone_id
  name    = each.key
  type    = "CNAME"
  content = local.ingress_anchor_hostname
  ttl     = 1
  proxied = each.value
  comment = "Public platform endpoint routed through the shared ingress anchor."
}
