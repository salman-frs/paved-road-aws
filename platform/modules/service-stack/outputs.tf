output "iam_role_arn" {
  description = "IRSA role ARN bound to the service account."
  value       = aws_iam_role.service.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL used by service delivery."
  value       = aws_ecr_repository.service.repository_url
}

output "secret_path" {
  description = "Secret path contract exposed to workloads."
  value       = var.secret_path
}

output "dns_name" {
  description = "Created DNS name when public DNS is enabled."
  value       = local.public_dns_enabled ? local.service_public_hostname : null
}

output "s3_bucket_name" {
  description = "Optional S3 bucket backing dependency."
  value       = var.backing_dependency == "s3" ? aws_s3_bucket.backing_store[0].bucket : null
}

output "sqs_queue_url" {
  description = "Optional SQS queue backing dependency."
  value       = var.backing_dependency == "sqs" ? aws_sqs_queue.backing_queue[0].url : null
}
