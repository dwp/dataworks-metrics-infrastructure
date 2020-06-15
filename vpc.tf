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
