data "aws_caller_identity" "current" {}

locals {
  default_tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "terraform"
      Scope     = "bootstrap-admin"
    },
    var.tags
  )

  github_subjects = [
    "repo:${var.github_repository}:ref:refs/heads/${var.github_default_branch}",
    "repo:${var.github_repository}:pull_request"
  ]
}
