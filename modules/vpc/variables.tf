variable "region" {}
variable "vpc_cidr_block" {}
variable "interface_vpce_source_security_group_ids" {}
variable "route_tables_public" {}
variable "common_tags" {}
variable "zone_count" {}
variable "zone_names" {}
variable "name" {}

variable "subnets" {
  description = "define sizes for subnets using Terraform cidrsubnet function. For an empty /24 VPC, the defaults will create /28 public subnets and /26 private subnets, one of each in each AZ."
  type        = map(map(number))
  default = {
    public = {
      newbits = 4
      netnum  = 0
    }
    private = {
      newbits = 2
      netnum  = 1
    }
  }
}
