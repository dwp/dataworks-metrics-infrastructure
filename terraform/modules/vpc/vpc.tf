module "vpc" {
  source                                     = "dwp/vpc/aws"
  version                                    = "2.0.6"
  vpc_name                                   = var.vpc_name
  region                                     = data.aws_region.current.name
  vpc_cidr_block                             = var.vpc_cidr_block
  interface_vpce_source_security_group_count = length(var.vpc_endpoint_source_sg_ids)
  interface_vpce_source_security_group_ids   = var.vpc_endpoint_source_sg_ids
  interface_vpce_subnet_ids                  = aws_subnet.private.*.id
  gateway_vpce_route_table_ids               = aws_route_table.private.*.id
  ec2autoscaling_endpoint                    = true
  ec2_endpoint                               = true
  ec2messages_endpoint                       = true
  kms_endpoint                               = true
  logs_endpoint                              = true
  monitoring_endpoint                        = true
  s3_endpoint                                = true
  ssm_endpoint                               = true
  ssmmessages_endpoint                       = true
  secretsmanager_endpoint                    = true
  ecrapi_endpoint                            = true
  ecrdkr_endpoint                            = true
  ecs_endpoint                               = true
  common_tags                                = merge(var.tags, { Name = var.name })
}
