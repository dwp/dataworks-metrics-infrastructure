resource "aws_subnet" "private" {
  count                = local.zone_count
  cidr_block           = cidrsubnet(module.vpc.vpc.cidr_block, var.subnets.private.newbits, var.subnets.private.netnum + count.index)
  vpc_id               = module.vpc.vpc.id
  availability_zone_id = data.aws_availability_zones.current.zone_ids[count.index]
  tags                 = merge(var.tags, { Name = "${var.name}-private-${local.zone_names[count.index]}" })
}

resource "aws_route_table" "private" {
  count  = local.zone_count
  vpc_id = module.vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-private-${local.zone_names[count.index]}" })
}

resource "aws_route_table_association" "private" {
  count          = local.zone_count
  route_table_id = aws_route_table.private[count.index].id
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_route" "route" {
  count                     = local.zone_count
  route_table_id            = aws_route_table.private[count.index].id
  destination_cidr_block    = var.concourse_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}
