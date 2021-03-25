resource "aws_vpc_peering_connection" "workflow_manager" {
  count       = local.is_management_env ? 0 : 1
  peer_vpc_id = data.terraform_remote_state.aws-azkaban.outputs.workflow_manager_vpc.vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_route" "workflow_manager_prometheus" {
  count                     = local.is_management_env ? 0 : length(data.terraform_remote_state.aws-azkaban.outputs.aws_route_table.workflow_manager_private)
  route_table_id            = data.terraform_remote_state.aws-azkaban.outputs.aws_route_table.workflow_manager_private[count.index].id
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.workflow_manager[0].id
}

resource "aws_route" "prometheus_workflow_manager" {
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = data.terraform_remote_state.aws-azkaban.outputs.workflow_manager_vpc.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.workflow_manager[0].id
}

resource "aws_security_group_rule" "azkaban_executor_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access azkaban_executor metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 5556
  to_port                  = 5556
  security_group_id        = data.terraform_remote_state.aws-azkaban.outputs.azkaban_executor_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_azkaban_executor" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access azkaban_executor metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 5556
  to_port                  = 5556
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws-azkaban.outputs.azkaban_executor_sg.id
}

resource "aws_security_group_rule" "azkaban_webserver_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access azkaban_webserver metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 5556
  to_port                  = 5556
  security_group_id        = data.terraform_remote_state.aws-azkaban.outputs.azkaban_webserver_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_azkaban_webserver" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access azkaban_webserver metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 5556
  to_port                  = 5556
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws-azkaban.outputs.azkaban_webserver_sg.id
}

resource "aws_security_group_rule" "azkaban_executor_allow_ingress_prometheus_9998" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access azkaban_executor metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9998
  to_port                  = 9998
  security_group_id        = data.terraform_remote_state.aws-azkaban.outputs.azkaban_executor_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_azkaban_executor_9998" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access azkaban_executor metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9998
  to_port                  = 9998
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws-azkaban.outputs.azkaban_executor_sg.id
}

resource "aws_security_group_rule" "azkaban_webserver_allow_ingress_prometheus_9998" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access azkaban_webserver metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9998
  to_port                  = 9998
  security_group_id        = data.terraform_remote_state.aws-azkaban.outputs.azkaban_webserver_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_azkaban_webserver_9998" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access azkaban_webserver metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9998
  to_port                  = 9998
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws-azkaban.outputs.azkaban_webserver_sg.id
}
