output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "Bootstrap VPC id."
  value       = module.vpc.vpc_id
}

output "cluster_endpoint" {
  description = "EKS control plane endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN used by IRSA."
  value       = module.eks.oidc_provider_arn
}

output "cluster_oidc_provider_url" {
  description = "OIDC issuer URL used by IRSA."
  value       = module.eks.cluster_oidc_issuer_url
}

output "public_ingress_anchor_hostname" {
  description = "Stable DNS-only hostname that fronts the shared ingress load balancer."
  value       = local.ingress_anchor_hostname
}

output "platform_public_hosts" {
  description = "Public platform hostnames routed through Cloudflare."
  value       = keys(local.bootstrap_public_hosts)
}
