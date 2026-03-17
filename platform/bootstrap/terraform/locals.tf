data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  cluster_version    = "1.35"
  demo_environment   = "dev"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  default_tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "terraform"
      Scope     = "bootstrap"
    },
    var.tags
  )

  github_subjects = [
    "repo:${var.github_repository}:ref:refs/heads/${var.github_default_branch}",
    "repo:${var.github_repository}:pull_request"
  ]

  ingress_anchor_hostname = "ingress.${local.demo_environment}.${var.base_domain}"
}
