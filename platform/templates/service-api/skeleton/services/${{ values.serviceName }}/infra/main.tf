terraform {
  required_version = ">= 1.6.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.36.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "= 5.18.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {}

module "service_stack" {
  source = "../../../platform/modules/service-stack"

  project_name              = "paved-road-aws"
  service_name              = "${{ values.serviceName }}"
  environment               = var.environment
  aws_region                = var.aws_region
  kubernetes_namespace      = "${{ values.serviceName }}-${var.environment}"
  service_account_name      = "${{ values.serviceName }}"
  cluster_oidc_provider_arn = var.cluster_oidc_provider_arn
  cluster_oidc_provider_url = var.cluster_oidc_provider_url
  secret_path               = "/paved-road-aws/${var.environment}/${{ values.serviceName }}/app"
  enable_public_dns         = var.enable_public_dns
  cloudflare_zone_id        = var.cloudflare_zone_id
  dns_name                  = var.enable_public_dns ? "${{ values.serviceName }}.${var.environment}.${var.base_domain}" : null
  backing_dependency        = var.backing_dependency
  base_domain               = var.base_domain
}
