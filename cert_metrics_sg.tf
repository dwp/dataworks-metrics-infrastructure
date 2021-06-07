resource "aws_security_group" "cert_metrics" {
  name        = "cert_metrics"
  description = "Rules necesary for pulling container image and accessing other cert_metrics instances"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "cert_metrics" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_cert_metrics_egress_internet_proxy" {
  description              = "Allow Internet access via the proxy (for ACM-PCA)"
  type                     = "egress"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cert_metrics.id
  source_security_group_id = local.internet_proxy.sg
}

resource "aws_security_group_rule" "allow_cert_metrics_egress_https" {
  count             = length(local.roles)
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.cert_metrics.id
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[count.index]]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_cert_metrics" {
  description              = "Allows prometheus to access the certs metrics tasks"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.cert_metrics_port
  to_port                  = var.cert_metrics_port
  source_security_group_id = aws_security_group.prometheus.id
  security_group_id        = aws_security_group.cert_metrics.id
}

resource "aws_security_group_rule" "allow_prometheus_egress_cert_metrics" {
  description              = "Allows prometheus to access the certs metrics tasks"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.cert_metrics_port
  to_port                  = var.cert_metrics_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = aws_security_group.cert_metrics.id
}
