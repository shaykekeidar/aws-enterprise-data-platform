
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
        "repo:shaykekeidar@46778647/aws-enterprise-data-platform@1420430704"
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
