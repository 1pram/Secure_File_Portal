# ============================================================================
# Lambda Function for Pre-Signed URL Generation
# ============================================================================

# Package Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

# Lambda Policy
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project}-lambda-s3"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = ["${aws_s3_bucket.vault.arn}/*"]
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "presign" {
  function_name = "${var.project}-presign"
  handler       = "main.handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET        = aws_s3_bucket.vault.bucket
      VIEWER_PREFIX = var.vault_prefixes.viewer
      EDITOR_PREFIX = var.vault_prefixes.editor
      ADMIN_PREFIX  = var.vault_prefixes.admin
    }
  }

  tags = local.tags
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project}-api"
  protocol_type = "HTTP"

  tags = local.tags
}

# API Gateway Integration
resource "aws_apigatewayv2_integration" "lambda_int" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.presign.arn
  payload_format_version = "2.0"
}

# API Gateway Route
resource "aws_apigatewayv2_route" "presign_route" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /presign"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_int.id}"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true

  tags = local.tags
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "allow_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presign.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}