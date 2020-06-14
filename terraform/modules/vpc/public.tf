resource "aws_internet_gateway" "igw" {
  vpc_id = module.vpc.vpc.id
  tags   = merge(var.tags, { Name = var.name })
}

resource "aws_subnet" "public" {
  count                   = local.zone_count
  cidr_block              = cidrsubnet(module.vpc.vpc.cidr_block, var.subnets.public.newbits, var.subnets.public.netnum + count.index)
  vpc_id                  = module.vpc.vpc.id
  availability_zone_id    = data.aws_availability_zones.current.zone_ids[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.name}-public-${local.zone_names[count.index]}" })
}

resource "aws_route_table" "public" {
  vpc_id = module.vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route_table_association" "public" {
  count          = local.zone_count
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
