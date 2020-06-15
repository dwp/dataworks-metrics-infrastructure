resource "aws_route_table" "public" {
  vpc_id = module.vpc.vpc.id
  tags   = merge(local.tags, { Name = "${var.name}-public" })
}

resource "aws_route_table" "private" {
  count  = local.zone_count
  vpc_id = module.vpc.vpc.id
  tags   = merge(local.tags, { Name = "${var.name}-private-${local.zone_names[count.index]}" })
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = local.zone_count
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = local.zone_count
  route_table_id = aws_route_table.private[count.index].id
  subnet_id      = aws_subnet.private[count.index].id
}
