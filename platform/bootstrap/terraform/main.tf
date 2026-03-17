provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.default_tags
  }
}

provider "cloudflare" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name                    = var.cluster_name
  kubernetes_version      = local.cluster_version

  addons = {
    vpc-cni = {
      before_compute = true
    }
    kube-proxy = {}
    coredns    = {}
  }

  endpoint_public_access                   = true
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 2
      max_size       = 3
    }
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-${data.aws_caller_identity.current.account_id}-tfstate"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_subjects
    }
  }
}

data "aws_iam_policy_document" "bootstrap_permissions" {
  statement {
    sid = "BootstrapCore"

    actions = [
      "acm:*",
      "autoscaling:*",
      "cloudformation:*",
      "dynamodb:*",
      "ec2:*",
      "eks:*",
      "elasticloadbalancing:*",
      "iam:*",
      "kms:*",
      "logs:*",
      "s3:*",
      "ssm:*"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "service_permissions" {
  statement {
    sid = "ServiceStack"

    actions = [
      "ecr:*",
      "iam:*",
      "s3:*",
      "sqs:*",
      "ssm:*",
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "github_bootstrap" {
  name               = "${var.project_name}-github-bootstrap"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

resource "aws_iam_role_policy" "github_bootstrap" {
  name   = "${var.project_name}-github-bootstrap"
  role   = aws_iam_role.github_bootstrap.id
  policy = data.aws_iam_policy_document.bootstrap_permissions.json
}

resource "aws_iam_role" "github_service_stack" {
  name               = "${var.project_name}-github-service-stack"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

resource "aws_iam_role_policy" "github_service_stack" {
  name   = "${var.project_name}-github-service-stack"
  role   = aws_iam_role.github_service_stack.id
  policy = data.aws_iam_policy_document.service_permissions.json
}
