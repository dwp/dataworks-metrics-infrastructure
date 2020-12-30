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

resource "aws_kms_key" "monitoring_bucket_cmk" {
  count                   = local.is_management_env ? 1 : 0
  description             = "Monitoring Bucket Master Key"
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true
  policy = templatefile("monitoring_bucket_key_policy.tpl", {
    accounts            = join(",", values(local.account))
    breakglass_arn      = data.aws_iam_user.breakglass.arn
    ci_arn              = data.aws_iam_role.ci.arn
    administrator_arn   = data.aws_iam_role.administrator.arn
    aws_config_role_arn = data.aws_iam_role.aws_config.arn
  })
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

resource "random_id" "monitoring_bucket_id" {
  count       = local.is_management_env ? 1 : 0
  byte_length = 16
}

resource "random_id" "monitoring_bucket" {
  count       = local.is_management_env ? 1 : 0
  byte_length = 16
}

resource "aws_s3_bucket" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  bucket = local.environment[management-dev] ? random_id.monitoring_bucket_id[local.primary_role_index].hex : random_id.monitoring_bucket[local.primary_role_index].hex
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

resource "aws_s3_bucket_policy" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  bucket = aws_s3_bucket.monitoring[local.primary_role_index].id
  policy = templatefile("monitoring_bucket_policy.tpl", {
    accounts              = join(",", values(local.account))
    monitoring_bucket_arn = aws_s3_bucket.monitoring[count.index].arn
  })
}
