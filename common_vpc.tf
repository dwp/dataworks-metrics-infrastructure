data "aws_availability_zones" "current" {}

module "vpc" {
  source            = "./modules/vpc"
  name              = var.name
  region            = data.aws_region.current.name
  is_management_env = local.is_management_env
  vpc_cidr_block    = local.cidr_block[local.environment]
  interface_vpce_source_security_group_ids = local.is_management_env ? [
    aws_security_group.grafana[0].id,
    aws_security_group.thanos_query[0].id,
    aws_security_group.thanos_ruler[0].id,
    aws_security_group.alertmanager[0].id,
    aws_security_group.outofband[0].id,
    aws_security_group.prometheus.id,
    aws_security_group.cloudwatch_exporter.id,
    aws_security_group.thanos_store[0].id,
    aws_security_group.metrics_cluster.id,
    aws_security_group.mgmt_metrics_cluster[0].id,
    aws_security_group.cert_metrics.id
    ] : [
    aws_security_group.prometheus.id,
    aws_security_group.cloudwatch_exporter.id,
    aws_security_group.pdm_exporter[0].id,
    aws_security_group.hbase_exporter[0].id,
    aws_security_group.metrics_cluster.id,
    aws_security_group.cert_metrics.id
  ]
  zone_count          = local.zone_count
  zone_names          = local.zone_names
  route_tables_public = aws_route_table.public
  common_tags         = merge(local.tags, { Name = var.name })
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

resource "aws_security_group" "secondary_internet_proxy_endpoint" {
  name        = "secondary_proxy_vpc_endpoint"
  description = "Control access to the Internet Proxy VPC Endpoint"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
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
  tags                = merge(local.tags, { Name = var.name })
}

resource "aws_vpc_endpoint" "secondary_internet_proxy" {
  vpc_id              = module.vpc.outputs.vpcs[local.secondary_role_index].id
  service_name        = data.terraform_remote_state.internet_egress.outputs.internet_proxy_service.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.secondary_internet_proxy_endpoint.id]
  subnet_ids          = module.vpc.outputs.private_subnets[local.secondary_role_index]
  private_dns_enabled = false
  tags                = merge(local.tags, { Name = var.name })
}

resource "aws_security_group" "tanium_service_endpoint" {
  name        = "tanium_service_endpoint"
  description = "Control access to the Tanium Service VPC Endpoint"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
}
resource "aws_vpc_endpoint" "tanium_service" {
  vpc_id              = module.vpc.outputs.vpcs[local.primary_role_index].id
  service_name        = local.tanium_service_name[local.environment]
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.tanium_service_endpoint.id]
  subnet_ids          = module.vpc.outputs.private_subnets[local.primary_role_index]
  private_dns_enabled = false
  tags = {
    Name = "tanium-service"
  }
}

resource "aws_security_group" "secondary_tanium_service_endpoint" {
  name        = "secondary_tanium_service_endpoint"
  description = "Control access to the Tanium Service VPC Endpoint"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
}

resource "aws_vpc_endpoint" "secondary_tanium_service" {
  vpc_id              = module.vpc.outputs.vpcs[local.secondary_role_index].id
  service_name        = local.tanium_service_name[local.environment]
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.secondary_tanium_service_endpoint.id]
  subnet_ids          = module.vpc.outputs.private_subnets[local.secondary_role_index]
  private_dns_enabled = false
  tags = {
    Name = "tanium-service"
  }
}

resource "aws_security_group_rule" "grafana_egress_internet_proxy" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow Grafana internet access via the proxy"
  type                     = "egress"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internet_proxy_endpoint[0].id
  security_group_id        = aws_security_group.grafana[0].id
}

resource "aws_security_group_rule" "grafana_ingress_internet_proxy" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow proxy access from Grafana"
  type                     = "ingress"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.grafana[0].id
  security_group_id        = aws_security_group.internet_proxy_endpoint[0].id
}

resource "aws_security_group_rule" "cert_metrics_ingress_internet_proxy" {
  description              = "Allow proxy access from cert retriever"
  type                     = "ingress"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cert_metrics.id
  security_group_id        = aws_security_group.secondary_internet_proxy_endpoint.id
}

resource "aws_security_group_rule" "alertmanager_egress_internet_proxy" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow Alertmanager internet access via the proxy"
  type                     = "egress"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internet_proxy_endpoint[0].id
  security_group_id        = aws_security_group.alertmanager[0].id
}

resource "aws_security_group_rule" "alertmanager_ingress_internet_proxy" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow proxy access from Alertmanager"
  type                     = "ingress"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alertmanager[0].id
  security_group_id        = aws_security_group.internet_proxy_endpoint[0].id
}
