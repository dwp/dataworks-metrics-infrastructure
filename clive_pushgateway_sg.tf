resource "aws_security_group_rule" "allow_clive_pushgateway_egress_https" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.vpce_security_groups.clive_pushgateway_vpce_security_group.id
  prefix_list_ids   = [data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.prefix_list_ids.s3]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_clive_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows inbound traffic from prometheus to clive pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_internal_compute.outputs.vpce_security_groups.clive_pushgateway_vpce_security_group.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_clive_ingress_clive_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows Clive to access Clive pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_internal_compute.outputs.vpce_security_groups.clive_pushgateway_vpce_security_group.id
  source_security_group_id = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
}

resource "aws_security_group_rule" "allow_clive_egress_clive_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows Clive to access Clive pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.vpce_security_groups.clive_pushgateway_vpce_security_group.id
}

resource "aws_security_group_rule" "allow_prometheus_egress_clive_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access clive pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.vpce_security_groups.clive_pushgateway_vpce_security_group.id
}
