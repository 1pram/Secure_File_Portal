# CloudTrail Logging + CloudWatch Alerting

# Dedicated CloudTrail Log Bucket

resource "aws_s3_bucket" "trail_logs" {
  bucket = "${var.project}-trail-${random_id.suffix.hex}"
  tags   = local.tags

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudTrail Bucket Policy

resource "aws_s3_bucket_policy" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.trail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.trail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudWatch Log Group for Real-Time Streaming

resource "aws_cloudwatch_log_group" "trail" {
  name              = "/aws/cloudtrail/${var.project}"
  retention_in_days = 90

  tags = local.tags
}

# CloudTrail with S3 Data Events

resource "aws_cloudtrail" "trail" {
  name                          = "${var.project}-trail"
  s3_bucket_name                = aws_s3_bucket.trail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cw.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.vault.arn}/"]
    }
  }

  depends_on = [aws_s3_bucket_policy.trail_logs]

  tags = local.tags
}

# IAM Role for CloudTrail → CloudWatch

resource "aws_iam_role" "cloudtrail_to_cw" {
  name = "${var.project}-cloudtrail-cw"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_to_cw" {
  name = "${var.project}-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_to_cw.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.trail.arn}:*"
    }]
  })
}


# CloudWatch Metric Filter (Counts GetObject Operations)

resource "aws_cloudwatch_log_metric_filter" "get_object_burst" {
  name           = "${var.project}-getobject-burst"
  log_group_name = aws_cloudwatch_log_group.trail.name
  pattern        = "{ ($.eventName = GetObject) }"

  metric_transformation {
    name      = "${var.project}-getobject-count"
    namespace = "${var.project}/security"
    value     = "1"
  }
}

# SNS Topic for Security Alerts

resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alerts"

  tags = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm (Triggers on Suspicious Activity)

resource "aws_cloudwatch_metric_alarm" "excess_downloads" {
  alarm_name          = "${var.project}-excess-downloads"
  namespace           = "${var.project}/security"
  metric_name         = "${var.project}-getobject-count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 100
  comparison_operator = "GreaterThanOrEqualToThreshold"
 
  alarm_description = "High number of object downloads in 5 minutes"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]

  tags = local.tags
}