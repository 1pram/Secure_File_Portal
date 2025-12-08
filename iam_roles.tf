# ============================================================================
# IAM Policies with Path-Based Conditions
# ============================================================================

# -----------------------------------------------------------------------------
# Viewer Policy: Read-Only Access to viewer/ prefix
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "viewer" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.vault.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        var.vault_prefixes.viewer,
        "${var.vault_prefixes.viewer}*"
      ]
    }
  }

  statement {
    sid       = "ReadObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.vault.arn}/${var.vault_prefixes.viewer}*"]
  }
}

# -----------------------------------------------------------------------------
# Editor Policy: Read/Write Access to editor/ prefix
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "editor" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.vault.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        var.vault_prefixes.editor,
        "${var.vault_prefixes.editor}*"
      ]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.vault.arn}/${var.vault_prefixes.editor}*"]
  }
}

# -----------------------------------------------------------------------------
# Admin Policy: Full Access
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "admin" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.vault.arn,
      "${aws_s3_bucket.vault.arn}/*"
    ]
  }
}

# -----------------------------------------------------------------------------
# Create IAM Policies
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "viewer" {
  name   = "${var.project}-viewer"
  policy = data.aws_iam_policy_document.viewer.json
}

resource "aws_iam_policy" "editor" {
  name   = "${var.project}-editor"
  policy = data.aws_iam_policy_document.editor.json
}

resource "aws_iam_policy" "admin" {
  name   = "${var.project}-admin"
  policy = data.aws_iam_policy_document.admin.json
}