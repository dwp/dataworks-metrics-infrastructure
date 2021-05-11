resource "aws_security_group" "alertmanager_sns_forwarder" {
  count       = local.is_management_env ? 1 : 0
  name        = "alertmanager-sns-forwarder"
  description = "Rules necesary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  tags        = merge(local.tags, { Name = "alertmanager-sns-forwarder" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_alertmanager_sns_forwarder_egress_https" {
  count             = local.is_management_env ? 1 : 0
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.alertmanager_sns_forwarder[local.primary_role_index].id
  prefix_list_ids   = [data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.prefix_list_ids.s3]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_alertmanager_sns_forwarder" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows prometheus to access the alertmanager SNS forwarder"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9087
  to_port                  = 9087
  security_group_id        = aws_security_group.alertmanager_sns_forwarder[0].id
  source_security_group_id = aws_security_group.prometheus.id
}
