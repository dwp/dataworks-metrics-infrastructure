resource "aws_vpc_peering_connection" "peering" {
  peer_vpc_id   = data.aws_vpc.concourse.id
  vpc_id        = module.vpc.vpc.id
  auto_accept   = true
  tags          = merge(var.tags, { Name = "prometheus_pcx" })
}
