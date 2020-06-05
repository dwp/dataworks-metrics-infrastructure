variable "name" {
  description = "common name"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "tags" {
  description = "tags to apply to aws resource"
  type        = map(string)
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}
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

variable "whitelist_cidr_blocks" {
  description = "list of allowed cidr blocks"
  type        = list(string)
}

variable "internet_proxy_fqdn" {
  description = "FQDN of the Internet Proxy"
  type        = string
}

variable "internet_proxy_service_name" {
  description = "Internet Proxy VPC Endpoint Service name"
  type        = string
}

variable "vpc_endpoint_source_sg_ids" {
  description = "Security group IDs of consumers of VPC endpoint services"
  type        = list(string)
}
