data "aws_availability_zones" "current" {}

module "vpc" {
  source                                     = "dwp/vpc/aws"
  version                                    = "2.0.6"
  vpc_name                                   = "prometheus"
  region                                     = data.aws_region.current.name
  vpc_cidr_block                             = local.cidr_block[local.environment].mon-master-vpc
  interface_vpce_source_security_group_count = length([aws_security_group.web[0].id, aws_security_group.web[1].id])
  interface_vpce_source_security_group_ids   = [aws_security_group.web[0].id, aws_security_group.web[1].id]
  interface_vpce_subnet_ids                  = aws_subnet.private.*.id
  gateway_vpce_route_table_ids               = aws_route_table.private.*.id
  kms_endpoint                               = true
  logs_endpoint                              = true
  monitoring_endpoint                        = true
  s3_endpoint                                = true
  ecrapi_endpoint                            = true
  ecrdkr_endpoint                            = true
  ecs_endpoint                               = true
  common_tags                                = merge(local.tags, { Name = var.name })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = module.vpc.vpc.id
  tags   = merge(local.tags, { Name = var.name })
}

resource "aws_eip" "nat" {
  count = local.zone_count
  tags  = merge(local.tags, { Name = "${var.name}-nat-${local.zone_names[count.index]}" })
}

resource "aws_subnet" "public" {
  count                   = local.zone_count
  cidr_block              = cidrsubnet(module.vpc.vpc.cidr_block, var.subnets.public.newbits, var.subnets.public.netnum + count.index)
  vpc_id                  = module.vpc.vpc.id
  availability_zone_id    = data.aws_availability_zones.current.zone_ids[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${var.name}-public-${local.zone_names[count.index]}" })
}

resource "aws_subnet" "private" {
  count                = local.zone_count
  cidr_block           = cidrsubnet(module.vpc.vpc.cidr_block, var.subnets.private.newbits, var.subnets.private.netnum + count.index)
  vpc_id               = module.vpc.vpc.id
  availability_zone_id = data.aws_availability_zones.current.zone_ids[count.index]
  tags                 = merge(local.tags, { Name = "${var.name}-private-${local.zone_names[count.index]}" })
}

resource "aws_nat_gateway" "nat" {
  count         = local.zone_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(local.tags, { Name = "${var.name}-nat-${local.zone_names[count.index]}" })
}
