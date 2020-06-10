module "vpc" {
  source = "../modules/vpc"

  name                        = var.name
  vpc_name                    = "prometheus"
  tags                        = local.tags
  vpc_cidr_block              = local.cidr_block[local.environment].mon-master-vpc
  whitelist_cidr_blocks       = concat(var.whitelist_cidr_blocks)
  internet_proxy_fqdn         = data.terraform_remote_state.internet_egress.outputs.internet_proxy_service.dns_name
  internet_proxy_service_name = data.terraform_remote_state.internet_egress.outputs.internet_proxy_service.service_name
  vpc_endpoint_source_sg_ids  = [module.prometheus_master.outputs.security_group.id, module.prometheus_slave.outputs.security_group.id]
  concourse_cidr_block        = local.cidr_block[local.environment].ci-cd-vpc
}

module "lb" {
  source = "../modules/loadbalancer"

  name                  = var.name
  lb_name               = var.name
  tags                  = local.tags
  region                = var.region
  accounts              = local.account
  assume_role           = var.assume_role
  parent_domain_name    = local.parent_domain_name[local.environment]
  vpc                   = module.vpc.outputs
  zone_id               = data.terraform_remote_state.management.outputs.dataworks_zone.id
  whitelist_cidr_blocks = var.whitelist_cidr_blocks
}

module "prometheus_master" {
  source = "../modules/prometheus"

  name                       = var.name
  role                       = "master"
  prometheus_version         = var.prometheus_version
  lb                         = module.lb.outputs
  vpc                        = module.vpc.outputs
  mgmt                       = data.terraform_remote_state.management.outputs
  s3_prefix                  = "monitoring/prometheus"
  tags                       = merge(local.tags, { Name = "prometheus" })
}

module "prometheus_slave" {
  source = "../modules/prometheus"

  name                       = var.name
  role                       = "slave"
  prometheus_version         = var.prometheus_version
  lb                         = module.lb.outputs
  vpc                        = module.vpc.outputs
  mgmt                       = data.terraform_remote_state.management.outputs
  s3_prefix                  = "monitoring/prometheus"
  tags                       = merge(local.tags, { Name = "prometheus" })
}
