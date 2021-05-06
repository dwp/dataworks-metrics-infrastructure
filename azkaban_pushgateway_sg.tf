resource "aws_security_group" "azkaban_pushgateway" {
  count       = local.is_management_env ? 0 : 1
  name        = "azkaban-pushgateway"
  description = "Rules necessary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_analytical_env_infra.outputs.vpc.aws_vpc.id
  tags        = merge(local.tags, { Name = "azkaban-pushgateway" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_azkaban_pushgateway_egress_https" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.azkaban_pushgateway[local.primary_role_index].id
  prefix_list_ids   = [data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.prefix_list_ids.s3]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_azkaban_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access azkaban pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.azkaban_pushgateway[0].id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_azkaban_ingress_azkaban_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows azkaban to access azkaban pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.azkaban_pushgateway[0].id
  source_security_group_id = data.terraform_remote_state.aws_analytical_env_app.outputs.emr_common_sg_id
}

resource "aws_security_group_rule" "allow_azkaban_egress_azkaban_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows azkaban to access azkaban pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_analytical_env_app.outputs.emr_common_sg_id
  source_security_group_id = aws_security_group.azkaban_pushgateway[0].id
}

resource "aws_security_group_rule" "allow_prometheus_egress_azkaban_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access azkaban pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = aws_security_group.azkaban_pushgateway[0].id
}
