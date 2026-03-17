locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.service_name}"
  ingress_anchor_hostname = "ingress.${var.environment}.${var.base_domain}"
  service_public_hostname = coalesce(
    var.dns_name,
    "${var.service_name}.${var.environment}.${var.base_domain}"
  )

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Service     = var.service_name
      ManagedBy   = "terraform"
    },
    var.tags
  )

  oidc_subject = "system:serviceaccount:${var.kubernetes_namespace}:${var.service_account_name}"
  oidc_provider_host = replace(var.cluster_oidc_provider_url, "https://", "")
}

resource "aws_ecr_repository" "service" {
  name                 = "${var.environment}/${var.service_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

data "aws_iam_policy_document" "irsa_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:sub"
      values   = [local.oidc_subject]
    }
  }
}

resource "aws_iam_role" "service" {
  name               = "${local.name_prefix}-irsa"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json
  tags               = local.common_tags
}

resource "aws_s3_bucket" "backing_store" {
  count  = var.backing_dependency == "s3" ? 1 : 0
  bucket = replace("${local.name_prefix}-assets", "_", "-")
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "backing_store" {
  count  = var.backing_dependency == "s3" ? 1 : 0
  bucket = aws_s3_bucket.backing_store[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_sqs_queue" "backing_queue" {
  count = var.backing_dependency == "sqs" ? 1 : 0
  name  = "${local.name_prefix}-events"
  tags  = local.common_tags
}

data "aws_iam_policy_document" "service_access" {
  statement {
    sid = "SecretRead"

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:*:parameter${var.secret_path}",
      "arn:aws:ssm:${var.aws_region}:*:parameter${var.secret_path}/*"
    ]
  }

  dynamic "statement" {
    for_each = var.backing_dependency == "s3" ? [1] : []

    content {
      sid = "S3Access"

      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]

      resources = [
        aws_s3_bucket.backing_store[0].arn,
        "${aws_s3_bucket.backing_store[0].arn}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.backing_dependency == "sqs" ? [1] : []

    content {
      sid = "SqsAccess"

      actions = [
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage",
        "sqs:SendMessage"
      ]

      resources = [aws_sqs_queue.backing_queue[0].arn]
    }
  }
}

resource "aws_iam_role_policy" "service" {
  name   = "${local.name_prefix}-policy"
  role   = aws_iam_role.service.id
  policy = data.aws_iam_policy_document.service_access.json
}
