resource "aws_security_group" "blackbox" {
  count       = local.is_management_env ? 0 : 1
  name        = "blackbox"
  description = "Rules necesary for pulling container image and accessing blackbox instances"
  vpc_id      = data.terraform_remote_state.aws_sdx.outputs.vpc.vpc.id
  tags        = merge(local.tags, { Name = "blackbox" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_blackbox_egress_https" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.blackbox[0].id
  prefix_list_ids   = [data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.prefix_list_ids.s3]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_blackbox" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access blackbox nifi"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9115
  to_port                  = 9115
  security_group_id        = aws_security_group.blackbox[0].id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_prometheus_egress_blackbox" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows blackbox nifi to access prometheus"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9115
  to_port                  = 9115
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = aws_security_group.blackbox[0].id
}
