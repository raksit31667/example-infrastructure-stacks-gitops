locals {
  role_name = "${var.service_name}-${var.environment}-irsa"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "main" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.tags, {
    Name = local.role_name
  })
}

data "aws_iam_policy_document" "elasticache" {
  statement {
    effect  = "Allow"
    actions = ["elasticache:Connect"]
    resources = [
      var.elasticache_arn,
      var.elasticache_user_arn,
    ]
  }
}

resource "aws_iam_role_policy" "elasticache" {
  name   = "${local.role_name}-elasticache"
  role   = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.elasticache.json
}

data "aws_iam_policy_document" "secret" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [var.secret_arn]
  }
}

resource "aws_iam_role_policy" "secret" {
  name   = "${local.role_name}-secret"
  role   = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.secret.json
}
