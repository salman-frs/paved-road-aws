data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  cluster_version    = "1.35"
  demo_environment   = "dev"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  default_tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "terraform"
      Scope     = "bootstrap-cluster"
    },
    var.tags
  )

  ingress_anchor_hostname = "ingress.${local.demo_environment}.${var.base_domain}"

  bootstrap_public_hosts = {
    "argocd.${var.base_domain}"    = true
    "backstage.${var.base_domain}" = true
    "grafana.${var.base_domain}"   = true
  }

  bootstrap_dns_enabled = var.cloudflare_zone_id != null && var.ingress_public_hostname != null
}
