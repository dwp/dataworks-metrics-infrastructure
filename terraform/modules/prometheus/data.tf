data "aws_region" "current" {}
data "aws_availability_zones" "current" {}

data "aws_ecr_repository" "prometheus" {
  name = "prometheus"
}
