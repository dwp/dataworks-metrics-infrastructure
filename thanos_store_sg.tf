resource "aws_security_group" "thanos_store" {
  count       = local.is_management_env ? 1 : 0
  name        = "thanos-store"
  description = "Rules necesary for pulling container image and accessing other thanos instances"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "thanos-store" })

  lifecycle {
    create_before_destroy = true
  }
}
