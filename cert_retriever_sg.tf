resource "aws_security_group" "cert_retriever" {
  name        = "cert_retriever"
  description = "Rules necesary for pulling container image and accessing other cert_retriever instances"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "cert_retriever" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_cert_retriever_egress_internet_proxy" {
  description              = "Allow Internet access via the proxy (for ACM-PCA)"
  type                     = "egress"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cert_retriever.id
  source_security_group_id = local.internet_proxy.sg
}

resource "aws_security_group_rule" "allow_cert_retriever_egress_https" {
  count             = length(local.roles)
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.cert_retriever.id
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[count.index]]
}

