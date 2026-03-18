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

variable "github_repository" {
  description = "GitHub repo in owner/name form used to scope OIDC trust."
  type        = string
  default     = "salman-frs/paved-road-aws"
}

variable "github_default_branch" {
  description = "Default branch allowed to assume GitHub OIDC roles."
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Additional tags applied to all admin resources."
  type        = map(string)
  default     = {}
}
