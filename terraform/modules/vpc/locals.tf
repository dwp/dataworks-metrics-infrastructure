locals {
  zone_count = length(data.aws_availability_zones.current.zone_ids)
  zone_names = data.aws_availability_zones.current.names

  route_table_cidr_combinations = [
    # in pair, element zero is a route table ID and element one is a cidr block,
    # in all unique combinations.
    for pair in setproduct(aws_route_table.private.*.id, var.whitelist_cidr_blocks) : {
      rtb_id = pair[0]
      cidr   = pair[1]
    }
  ]
}
