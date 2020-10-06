resource "aws_security_group" "monitoring_common" {
  count       = length(module.vpc.outputs.vpcs.*.id)
  name        = "monitoring-common-pull-s3-${local.roles[count.index]}"
  description = "Rules necesary for pulling container image"
  vpc_id      = module.vpc.outputs.vpcs[count.index].id
  tags        = merge(local.tags, { Name = "monitoring-common-pull-s3-${local.roles[count.index]}" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_cloudwatch_exporter_egress_https" {
  count             = length(module.vpc.outputs.vpcs.*.id)
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.monitoring_common[count.index].id
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[count.index]]
}
