##############################
# These resources are all deprecated and not used, but attached to dead instances in AWS so would need AWS tickets to destroy
##############################

resource "aws_security_group" "adg_pushgateway" {
  count       = local.is_management_env ? 0 : 1
  name        = "adg-pushgateway"
  description = "Rules necesary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  tags        = merge(local.tags, { Name = "adg-pushgateway" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "clive_pushgateway" {
  count       = local.is_management_env ? 0 : 1
  name        = "clive-pushgateway"
  description = "Rules necesary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  tags        = merge(local.tags, { Name = "clive-pushgateway" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "htme_pushgateway" {
  count       = local.is_management_env ? 0 : 1
  name        = "htme-pushgateway"
  description = "Rules necesary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  tags        = merge(local.tags, { Name = "htme-pushgateway" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "mongo_latest_pushgateway" {
  count       = local.is_management_env ? 0 : 1
  name        = "mongo-latest-pushgateway"
  description = "Rules necesary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  tags        = merge(local.tags, { Name = "mongo-latest-pushgateway" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "pdm_pushgateway" {
  count       = local.is_management_env ? 0 : 1
  name        = "pdm-pushgateway"
  description = "Rules necesary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  tags        = merge(local.tags, { Name = "pdm-pushgateway" })

  lifecycle {
    create_before_destroy = true
  }
}
