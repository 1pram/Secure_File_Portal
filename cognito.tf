# ============================================================================
# Cognito User Pool (Authentication)
# ============================================================================

resource "aws_cognito_user_pool" "pool" {
  name = "${var.project}-users"

  password_policy {
    minimum_length    = 12
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  tags = local.tags
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "${var.project}-client"
  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  callback_urls = ["http://localhost:3000/callback"]
  logout_urls   = ["http://localhost:3000/logout"]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "${var.project}-${random_id.suffix.hex}"
  user_pool_id = aws_cognito_user_pool.pool.id
}

# -----------------------------------------------------------------------------
# Identity Pool (Maps Auth to IAM)
# -----------------------------------------------------------------------------
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.project}-identity"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client.id
    provider_name           = aws_cognito_user_pool.pool.endpoint
    server_side_token_check = false
  }
}

# -----------------------------------------------------------------------------
# IAM Role for Authenticated Users (Simplified - All get Viewer)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "authenticated" {
  name = "${var.project}-cognito-authenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "cognito-identity.amazonaws.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
        }
        "ForAnyValue:StringLike" = {
          "cognito-identity.amazonaws.com:amr" = "authenticated"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "authenticated_viewer" {
  role       = aws_iam_role.authenticated.name
  policy_arn = aws_iam_policy.viewer.arn
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    authenticated = aws_iam_role.authenticated.arn
  }
}