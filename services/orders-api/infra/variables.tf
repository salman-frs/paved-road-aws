variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "cluster_oidc_provider_arn" {
  type = string
}

variable "cluster_oidc_provider_url" {
  type = string
}

variable "enable_public_dns" {
  type    = bool
  default = true
}

variable "cloudflare_zone_id" {
  type    = string
  default = null
}

variable "base_domain" {
  type    = string
  default = "salmanfrs.dev"
}

variable "backing_dependency" {
  type    = string
  default = "sqs"
}
