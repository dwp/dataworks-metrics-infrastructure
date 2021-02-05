resource "aws_security_group" "adg_pushgateway" {
  count       = local.is_management_env ? 0 : 1
  name        = "adg-pushgateway"
  description = "Rules necesary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  tags        = merge(local.tags, { Name = "adg-pushgateway" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_adg_pushgateway_egress_https" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.adg_pushgateway[local.primary_role_index].id
  prefix_list_ids   = [data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.prefix_list_ids.s3]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_adg_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access ADG pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.adg_pushgateway[0].id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_adg_ingress_adg_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows ADG to access ADG pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.adg_pushgateway[0].id
  source_security_group_id = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
}

resource "aws_security_group_rule" "allow_adg_egress_adg_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows ADG to access ADG pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
  source_security_group_id = aws_security_group.adg_pushgateway[0].id
}

resource "aws_security_group_rule" "allow_htme_ingress_adg_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows HTME to access ADG pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.adg_pushgateway[0].id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.htme_sg.id
}

resource "aws_security_group_rule" "allow_htme_egress_adg_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows HTME to access ADG pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_internal_compute.outputs.htme_sg.id
  source_security_group_id = aws_security_group.adg_pushgateway[0].id
}
  