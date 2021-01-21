resource "aws_secretsmanager_secret" "monitoring_secrets" {
  count = local.is_management_env ? 1 : 0
  name        = "/concourse/dataworks/monitoring/credentials"
  description = "Secret paramaters used to store credentials to be accessed within Concourse"
  tags        = merge(local.tags, { Name = var.name })
}
