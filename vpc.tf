data "aws_availability_zones" "current" {}

module "vpc" {
  source                                   = "./modules/vpc"
  name                                     = var.name
  region                                   = data.aws_region.current.name
  vpc_cidr_block                           = local.cidr_block[local.environment]
  interface_vpce_source_security_group_ids = aws_security_group.web.*.id
  zone_count                               = local.zone_count
  zone_names                               = local.zone_names
  route_tables_public                      = aws_route_table.public
  common_tags                              = merge(local.tags, { Name = var.name })
}

resource "aws_internet_gateway" "igw" {
  count  = length(local.roles)
  vpc_id = module.vpc.outputs.vpc_ids[count.index]
  tags   = merge(local.tags, { Name = var.name })
}

resource "aws_route_table" "public" {
  count  = length(local.roles)
  vpc_id = module.vpc.outputs.vpc_ids[count.index]
  tags   = merge(local.tags, { Name = "${var.name}-public" })
}

resource "aws_route" "public" {
  count                  = length(local.roles)
  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[count.index].id
}

resource "aws_security_group" "internet_proxy_endpoint" {
  count       = length(local.roles)
  name        = "proxy_vpc_endpoint"
  description = "Control access to the Internet Proxy VPC Endpoint"
  vpc_id      = module.vpc.outputs.vpc_ids[count.index]
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_vpc_endpoint" "internet_proxy" {
  count               = length(local.roles)
  vpc_id              = module.vpc.outputs.vpc_ids[count.index]
  service_name        = data.terraform_remote_state.internet_egress.outputs.internet_proxy_service.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.internet_proxy_endpoint[count.index].id]
  subnet_ids          = module.vpc.outputs.private_subnets[count.index]
  private_dns_enabled = false
}
