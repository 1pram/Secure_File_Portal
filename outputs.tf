# Outputs

output "vault_bucket" {
  value       = aws_s3_bucket.vault.bucket
  description = "Name of the secure vault bucket"
}

output "api_endpoint" {
  value       = aws_apigatewayv2_api.http.api_endpoint
  description = "Invoke URL for pre-signed URL API"
}

output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.pool.id
  description = "Cognito User Pool ID"
}

output "cognito_user_pool_client_id" {
  value       = aws_cognito_user_pool_client.client.id
  description = "Cognito User Pool Client ID"
}

output "cognito_domain" {
  value       = aws_cognito_user_pool_domain.domain.domain
  description = "Cognito Hosted UI domain"
}

output "cognito_identity_pool_id" {
  value       = aws_cognito_identity_pool.main.id
  description = "Cognito Identity Pool ID"
}

output "cloudtrail_bucket" {
  value       = aws_s3_bucket.trail_logs.bucket
  description = "S3 bucket containing CloudTrail audit logs"
}