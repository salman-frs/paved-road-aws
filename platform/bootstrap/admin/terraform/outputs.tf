output "terraform_state_bucket" {
  description = "Shared S3 bucket for Terraform state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_lock_table" {
  description = "DynamoDB lock table for Terraform state."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "github_service_stack_role_arn" {
  description = "Role assumed by service delivery workflows."
  value       = aws_iam_role.github_service_stack.arn
}
