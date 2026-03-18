variable "project_name" {
  description = "Project slug used for shared resource naming."
  type        = string
  default     = "paved-road-aws"
}

variable "aws_region" {
  description = "AWS region for the demo environment."
  type        = string
  default     = "ap-southeast-3"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "paved-road-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the shared VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
  default     = ["10.42.0.0/24", "10.42.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs."
  type        = list(string)
  default     = ["10.42.10.0/24", "10.42.11.0/24"]
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id."
  type        = string
  default     = null
  nullable    = true
}

variable "base_domain" {
  description = "Public base domain used for all exposed hostnames."
  type        = string
  default     = "salmanfrs.dev"
}

variable "ingress_public_hostname" {
  description = "Ingress load balancer hostname used as the DNS-only anchor target."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Additional tags applied to all cluster resources."
  type        = map(string)
  default     = {}
}
