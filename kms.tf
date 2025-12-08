# ============================================================================
# KMS Customer Managed Key (CMK) with Automatic Rotation
# ============================================================================

resource "aws_kms_key" "vault" {
  description             = "KMS CMK for ${var.project} S3 encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = local.tags
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${var.project}-s3"
  target_key_id = aws_kms_key.vault.key_id
}