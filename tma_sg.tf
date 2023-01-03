resource "aws_security_group" "tma" {
  name        = "tma"
  description = "Rules necesary for pulling container image and accessing other tma instances"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "tma" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_tma_egress_internet_proxy" {
  description              = "Allow Internet access via the proxy (for ACM-PCA)"
  type                     = "egress"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.tma.id
  source_security_group_id = local.internet_proxy.sg
}

resource "aws_security_group_rule" "allow_tma_egress_https" {
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.tma.id
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[0]]
}

#resource "aws_security_group" "secondary_internet_proxy_endpoint" {
#  name        = "secondary_proxy_vpc_endpoint"
#  description = "Control access to the Internet Proxy VPC Endpoint"
#  vpc_id      = data.terraform_remote_state.internet_egress.outputs.vpcs[0].id
#  tags        = merge(local.tags, { Name = "ztma" })
#}