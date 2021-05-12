resource "aws_security_group" "mongo_latest_pushgateway" {
  count       = local.is_management_env ? 0 : 1
  name        = "mongo-latest-pushgateway"
  description = "Rules necesary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  tags        = merge(local.tags, { Name = "mongo-latest-pushgateway" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_mongo_latest_pushgateway_egress_https" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.mongo_latest_pushgateway[local.primary_role_index].id
  prefix_list_ids   = [data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.prefix_list_ids.s3]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_mongo_latest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows inbound traffic from prometheus to mongo latest pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.mongo_latest_pushgateway[0].id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_prometheus_egress_mongo_latest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access mongo latest pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = aws_security_group.mongo_latest_pushgateway[0].id
}

resource "aws_security_group_rule" "allow_mongo_latest_egress_mongo_latest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows mongo latest to access mongo latest pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.dataworks_aws_mongo_latest.outputs.mongo_latest_common_sg.id
  source_security_group_id = aws_security_group.mongo_latest_pushgateway[0].id
}

resource "aws_security_group_rule" "allow_mongo_latest_ingress_mongo_latest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows mongo latest to access mongo latest pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.mongo_latest_pushgateway[0].id
  source_security_group_id = data.terraform_remote_state.dataworks_aws_mongo_latest.outputs.mongo_latest_common_sg.id
}
