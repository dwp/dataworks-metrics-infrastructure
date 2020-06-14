module "prometheus_master" {
  source = "./modules/prometheus"

  name                = var.name
  role                = "master"
  prometheus_version  = var.prometheus_version
  aws_subnets_private = aws_subnet.private
  aws_vpc             = module.vpc.vpc
  s3_prefix_list_id   = module.vpc.s3_prefix_list_id
  lb_listener         = aws_lb_listener.https.arn
  fqdn                = aws_route53_record.prometheus.fqdn
  mgmt                = data.terraform_remote_state.management.outputs
  s3_prefix           = "monitoring/prometheus"
  tags                = merge(local.tags, { Name = "prometheus" })
}

module "prometheus_slave" {
  source = "./modules/prometheus"

  name                = var.name
  role                = "slave"
  prometheus_version  = var.prometheus_version
  aws_subnets_private = aws_subnet.private
  aws_vpc             = module.vpc.vpc
  s3_prefix_list_id   = module.vpc.s3_prefix_list_id
  lb_listener         = aws_lb_listener.https.arn
  fqdn                = aws_route53_record.prometheus.fqdn
  mgmt                = data.terraform_remote_state.management.outputs
  s3_prefix           = "monitoring/prometheus"
  tags                = merge(local.tags, { Name = "prometheus" })
}
