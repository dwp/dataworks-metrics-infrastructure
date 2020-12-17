data "aws_secretsmanager_secret" "dataworks_secrets" {
  count = local.is_management_env ? 1 : 0
  name  = "/concourse/dataworks/dataworks-secrets"
}

data "aws_secretsmanager_secret" "dataworks" {
  count = local.is_management_env ? 1 : 0
  name  = "/concourse/dataworks/dataworks"
}

data "aws_secretsmanager_secret_version" "dataworks" {
  count     = local.is_management_env ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.dataworks[local.primary_role_index].id
}

resource "random_id" "monitoring_bucket" {
  count       = local.is_management_env ? 1 : 0
  byte_length = 16
}

resource "aws_kms_key" "monitoring_bucket_cmk" {
  count                   = local.is_management_env ? 1 : 0
  description             = "Monitoring Bucket Master Key"
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true
  policy                  = <<POLICY
 {
   "Version": "2012-10-17",
   "Sid": "Allow access for cross account RW",
   "Statement": {
     "Effect": "Allow",
     "Action": [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
      "kms:List*",
      "kms:Get*"
    ],
     "Resource": "*"
     "Principal": {"AWS": [
        "arn:aws:iam::${local.account.development}:role/prometheus",
        "arn:aws:iam::${local.account.qa}:role/prometheus",
        "arn:aws:iam::${local.account.integration}:role/prometheus",
        "arn:aws:iam::${local.account.preprod}:role/prometheus",
        "arn:aws:iam::${local.account.production}:role/prometheus"
      ]}
    }
   }
 }
 POLICY
  tags = merge(
    local.tags,
    map("Name", "Monitoring bucket key"),
    map("ProtectsSensitiveData", "False")
  )
}

resource "aws_kms_alias" "monitoring_bucket_cmk_alias" {
  count         = local.is_management_env ? 1 : 0
  target_key_id = aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].key_id
  name          = "alias/monitoring_bucket_cmk"
}

resource "aws_s3_bucket" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  bucket = random_id.monitoring_bucket[local.primary_role_index].hex
  acl    = "private"
  tags = merge(
    local.tags,
    map("Name", "Metrics Store")
  )

  versioning {
    # explictly disabled; Thanos manages its own data lifecycle so there is no need to version objects or add lifecycle rules
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  logging {
    target_bucket = data.terraform_remote_state.security-tools.outputs.logstore_bucket.id
    target_prefix = "S3Logs/${local.tags.Name}-monitoring-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  bucket = aws_s3_bucket.monitoring[local.primary_role_index].id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

data "aws_iam_policy_document" "monitoring_bucket_enforce_https" {
  count = local.is_management_env ? 1 : 0
  statement {
    sid     = "BlockHTTP"
    effect  = "Deny"
    actions = ["*"]

    resources = [
      aws_s3_bucket.monitoring[local.primary_role_index].arn,
      "${aws_s3_bucket.monitoring[local.primary_role_index].arn}/*",
    ]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
  statement {
    sid    = "AllowCrossAccountRW"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [aws_s3_bucket.monitoring[local.primary_role_index].arn,
      "${aws_s3_bucket.monitoring[local.primary_role_index].arn}/*",
    ]

    principals {
      identifiers = [
        "arn:aws:iam::${local.account.development}:role/prometheus",
        "arn:aws:iam::${local.account.qa}:role/prometheus",
        "arn:aws:iam::${local.account.integration}:role/prometheus",
        "arn:aws:iam::${local.account.preprod}:role/prometheus",
        "arn:aws:iam::${local.account.production}:role/prometheus"
      ]
      type = "AWS"
    }
  }
  statement {
    sid    = "AllowCrossAccountKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [
      "${local.is_management_env ? aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].arn : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.key}",
    ]

    principals {
      identifiers = [
        "arn:aws:iam::${local.account.development}:role/prometheus",
        "arn:aws:iam::${local.account.qa}:role/prometheus",
        "arn:aws:iam::${local.account.integration}:role/prometheus",
        "arn:aws:iam::${local.account.preprod}:role/prometheus",
        "arn:aws:iam::${local.account.production}:role/prometheus"
      ]
      type = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  bucket = aws_s3_bucket.monitoring[local.primary_role_index].id
  policy = local.is_management_env ? data.aws_iam_policy_document.monitoring_bucket_enforce_https[local.primary_role_index].json : "{}"
}
