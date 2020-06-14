data "aws_region" "current" {}
data "aws_availability_zones" "current" {}

data "aws_vpc" "concourse" {
  cidr_block = var.concourse_cidr_block
}
