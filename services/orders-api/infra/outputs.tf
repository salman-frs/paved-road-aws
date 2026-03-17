output "iam_role_arn" {
  value = module.service_stack.iam_role_arn
}

output "ecr_repository_url" {
  value = module.service_stack.ecr_repository_url
}
