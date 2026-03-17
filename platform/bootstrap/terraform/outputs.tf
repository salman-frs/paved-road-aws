output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
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

output "terraform_state_bucket" {
  description = "Shared S3 bucket for Terraform state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_lock_table" {
  description = "DynamoDB lock table for Terraform state."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "github_bootstrap_role_arn" {
  description = "Role assumed by bootstrap workflows."
  value       = aws_iam_role.github_bootstrap.arn
}

output "github_service_stack_role_arn" {
  description = "Role assumed by service delivery workflows."
  value       = aws_iam_role.github_service_stack.arn
}

output "public_ingress_anchor_hostname" {
  description = "Stable DNS-only hostname that fronts the shared ingress load balancer."
  value       = local.ingress_anchor_hostname
}

output "platform_public_hosts" {
  description = "Public platform hostnames routed through Cloudflare."
  value       = keys(local.bootstrap_public_hosts)
}
