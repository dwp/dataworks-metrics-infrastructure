resource "aws_secretsmanager_secret" "monitoring-secrets" {
  count       = local.is_management_env
  name        = "/concourse/dataworks/monitoring/credentials"
  description = "Secret paramaters used to store credentials to be accessed within Concourse"
  tags        = merge(local.tags, { Name = var.name })
}