
# Account-wide GitHub Actions OIDC identity provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Component = "CICD"
  }
}

# Allow only this repository's main branch to assume the role
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    sid     = "GitHubActionsOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        #"repo:shaykekeidar/aws-enterprise-data-platform:ref:refs/heads/main"
        #"repo:shaykekeidar@46778647/aws-enterprise-data-platform@1420430704"
        "repo:shaykekeidar@46778647/aws-enterprise-data-platform@1420430704:ref:refs/heads/main"
      ]
    }
  }
}

# Dedicated DEV pipeline role
resource "aws_iam_role" "github_actions_dev" {
  name = "enterprise-data-platform-github-actions-dev"

  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Component = "CICD"
  }
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_dev.arn
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}


# Allow the DEV GitHub Actions pipeline to inspect AWS resources
# during Terraform Plan, without permission to modify infrastructure.

resource "aws_iam_role_policy_attachment" "github_actions_dev_readonly" {
  role       = aws_iam_role.github_actions_dev.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}


# GitHub Actions DEV - Terraform remote state access

data "aws_iam_policy_document" "github_actions_dev_state" {

  statement {
    sid    = "ListDevState"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::enterprise-data-platform-tfstate-057461015409"
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "dev/central-platform/terraform.tfstate",
        "dev/central-platform/terraform.tfstate.tflock"
      ]
    }
  }

  statement {
    sid    = "ReadDevState"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::enterprise-data-platform-tfstate-057461015409/dev/central-platform/terraform.tfstate",
      "arn:aws:s3:::enterprise-data-platform-tfstate-057461015409/dev/central-platform/terraform.tfstate.tflock"
    ]
  }

  statement {
    sid    = "ManageDevStateLock"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::enterprise-data-platform-tfstate-057461015409/dev/central-platform/terraform.tfstate.tflock"
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_dev_state" {
  name   = "enterprise-data-platform-dev-state-access"
  role   = aws_iam_role.github_actions_dev.id
  policy = data.aws_iam_policy_document.github_actions_dev_state.json
}

# prod configuration

# Dedicated PROD GitHub Actions role

resource "aws_iam_role" "github_actions_prod" {
  name = "enterprise-data-platform-github-actions-prod"

  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Component   = "CICD"
    Environment = "prod"
  }
}

# Read-only permissions for PROD Terraform Plan

resource "aws_iam_role_policy_attachment" "github_actions_prod_readonly" {
  role       = aws_iam_role.github_actions_prod.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}


# GitHub Actions PROD - Terraform remote state access

data "aws_iam_policy_document" "github_actions_prod_state" {

  statement {
    sid    = "ListProdState"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::enterprise-data-platform-tfstate-057461015409"
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "prod/central-platform/terraform.tfstate",
        "prod/central-platform/terraform.tfstate.tflock"
      ]
    }
  }

  statement {
    sid    = "ReadProdState"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::enterprise-data-platform-tfstate-057461015409/prod/central-platform/terraform.tfstate",
      "arn:aws:s3:::enterprise-data-platform-tfstate-057461015409/prod/central-platform/terraform.tfstate.tflock"
    ]
  }

  statement {
    sid    = "ManageProdStateLock"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::enterprise-data-platform-tfstate-057461015409/prod/central-platform/terraform.tfstate.tflock"
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_prod_state" {
  name   = "enterprise-data-platform-prod-state-access"
  role   = aws_iam_role.github_actions_prod.id
  policy = data.aws_iam_policy_document.github_actions_prod_state.json
}

output "github_actions_prod_role_arn" {
  value = aws_iam_role.github_actions_prod.arn
}


