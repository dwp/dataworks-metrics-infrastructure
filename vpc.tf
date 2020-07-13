data "aws_availability_zones" "current" {}

module "vpc" {
  source                                   = "./modules/vpc"
  name                                     = var.name
  region                                   = data.aws_region.current.name
  is_management_env                        = local.is_management_env
  vpc_cidr_block                           = local.cidr_block[local.environment]
  interface_vpce_source_security_group_ids = local.is_management_env ? [aws_security_group.grafana[0].id, aws_security_group.thanos_query[0].id, aws_security_group.thanos_ruler[0].id, aws_security_group.alertmanager[0].id, aws_security_group.outofband[0].id, aws_security_group.prometheus.id] : [aws_security_group.prometheus.id]
  zone_count                               = local.zone_count
  zone_names                               = local.zone_names
  route_tables_public                      = aws_route_table.public
  common_tags                              = merge(local.tags, { Name = var.name })
}

resource "aws_eip" "prometheus_master_nat" {
  count = local.is_management_env ? local.zone_count : 0
  tags  = merge(local.tags, { Name = "${var.name}-nat-${local.zone_names[count.index]}" })
}

resource "aws_internet_gateway" "igw" {
  count  = local.is_management_env ? 1 : 0
  vpc_id = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags   = merge(local.tags, { Name = var.name })
}

resource "aws_subnet" "public" {
  count                = local.is_management_env ? local.zone_count : 0
  cidr_block           = cidrsubnet(local.cidr_block_mon_master_vpc[0], var.subnets.public.newbits, var.subnets.public.netnum + count.index)
  vpc_id               = module.vpc.outputs.vpcs[local.primary_role_index].id
  availability_zone_id = data.aws_availability_zones.current.zone_ids[count.index]
  tags                 = merge(local.tags, { Name = "${var.name}-public-${local.zone_names[count.index]}" })
}

resource "aws_route_table" "public" {
  count  = local.is_management_env ? local.zone_count : 0
  vpc_id = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags   = merge(local.tags, { Name = "${var.name}-public-${local.zone_names[count.index]}" })
}

resource "aws_route" "public" {
  count                  = local.is_management_env ? local.zone_count : 0
  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[local.primary_role_index].id
}

resource "aws_route_table_association" "public" {
  count          = local.is_management_env ? local.zone_count : 0
  route_table_id = aws_route_table.public[count.index].id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_security_group" "internet_proxy_endpoint" {
  count       = local.is_management_env ? 1 : 0
  name        = "proxy_vpc_endpoint"
  description = "Control access to the Internet Proxy VPC Endpoint"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_vpc_endpoint" "internet_proxy" {
  count               = local.is_management_env ? 1 : 0
  vpc_id              = module.vpc.outputs.vpcs[local.primary_role_index].id
  service_name        = data.terraform_remote_state.internet_egress.outputs.internet_proxy_service.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.internet_proxy_endpoint[local.primary_role_index].id]
  subnet_ids          = module.vpc.outputs.private_subnets[local.primary_role_index]
  private_dns_enabled = false
}

resource "aws_security_group_rule" "egress_internet_proxy" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow Internet access via the proxy"
  type                     = "egress"
  from_port                = 3128
  to_port                  = 3128
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internet_proxy_endpoint[0].id
  security_group_id        = aws_security_group.grafana[0].id
}

resource "aws_security_group_rule" "ingress_internet_proxy" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow proxy access from grafana"
  type                     = "ingress"
  from_port                = 3128
  to_port                  = 3128
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.grafana[0].id
  security_group_id        = aws_security_group.internet_proxy_endpoint[0].id
}
