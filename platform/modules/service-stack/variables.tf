variable "project_name" {
  description = "Project slug used for names and tags."
  type        = string
}

variable "service_name" {
  description = "DNS-safe service name."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "kubernetes_namespace" {
  description = "Namespace used by the service workload."
  type        = string
}

variable "service_account_name" {
  description = "Service account bound to the IRSA role."
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN from the EKS bootstrap."
  type        = string
}

variable "cluster_oidc_provider_url" {
  description = "OIDC issuer URL from the EKS bootstrap."
  type        = string
}

variable "secret_path" {
  description = "Secret path contract exposed to workloads."
  type        = string
}

variable "enable_public_dns" {
  description = "Whether to create a Cloudflare DNS record for the service."
  type        = bool
  default     = false
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id used for public DNS records."
  type        = string
  default     = null
  nullable    = true
}

variable "dns_name" {
  description = "Fully-qualified DNS name for the public record."
  type        = string
  default     = null
  nullable    = true
}

variable "base_domain" {
  description = "Base domain used to derive public hostnames."
  type        = string
  default     = "salmanfrs.dev"
}

variable "backing_dependency" {
  description = "Optional backing dependency. One of none, s3, sqs."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "s3", "sqs"], var.backing_dependency)
    error_message = "backing_dependency must be one of none, s3, or sqs."
  }
}

variable "tags" {
  description = "Additional tags applied to service resources."
  type        = map(string)
  default     = {}
}
