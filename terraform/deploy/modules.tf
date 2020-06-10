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
  parent_domain_name    = local.parent_domain_name[local.environment]
  vpc                   = module.vpc.outputs
  whitelist_cidr_blocks = var.whitelist_cidr_blocks
}

module "prometheus_master" {
  source = "../modules/prometheus"

  name                       = var.name
  role                       = "master"
  prometheus_version         = var.prometheus_version
  image                      = data.terraform_remote_state.management.outputs.ecr_prometheus_url
  lb_listener                = module.lb.outputs.lb_listener
  lb_security_group_id       = module.lb.outputs.security_group_id
  fqdn                       = module.lb.outputs.fqdn
  vpc                        = module.vpc.outputs
  ecs_task_execution_role    = data.terraform_remote_state.management.outputs.ecs_task_execution_role
  ecs_cluster_main           = data.terraform_remote_state.management.outputs.ecs_cluster_main
  ecs_cluster_main_log_group = data.terraform_remote_state.management.outputs.ecs_cluster_main_log_group
  tags                       = merge(local.tags, { Name = "prometheus" })
}

module "prometheus_slave" {
  source = "../modules/prometheus"

  name                       = var.name
  role                       = "slave"
  prometheus_version         = var.prometheus_version
  image                      = data.terraform_remote_state.management.outputs.ecr_prometheus_url
  lb_listener                = module.lb.outputs.lb_listener
  lb_security_group_id       = module.lb.outputs.security_group_id
  fqdn                       = module.lb.outputs.fqdn
  vpc                        = module.vpc.outputs
  ecs_task_execution_role    = data.terraform_remote_state.management.outputs.ecs_task_execution_role
  ecs_cluster_main           = data.terraform_remote_state.management.outputs.ecs_cluster_main
  ecs_cluster_main_log_group = data.terraform_remote_state.management.outputs.ecs_cluster_main_log_group
  tags                       = merge(local.tags, { Name = "prometheus" })
}
