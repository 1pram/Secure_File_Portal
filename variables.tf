# ============================================================================
# Input Variables
# ============================================================================

variable "aws_region" {
  description = "AWS region where all resources will be deployed"
  type        = string
}

variable "project" {
  description = "Short project name used for tagging and naming resources"
  type        = string
  default     = "secure-file-portal"
}

variable "alert_email" {
  description = "Email address to receive security alerts from CloudWatch"
  type        = string
}

variable "vault_prefixes" {
  description = "S3 key prefixes that map to different IAM role permissions"
  type = object({
    viewer = string
    editor = string
    admin  = string
  })

  default = {
    viewer = "docs/viewer/"
    editor = "docs/editor/"
    admin  = "docs/admin/"
  }
}
