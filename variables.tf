variable "name" {
  description = "cluster name, used in dns"
  type        = string
  default     = "monitoring"
}

variable "prometheus_version" {
  description = "prometheus version to use"
  type        = string
  default     = "2.18.1"
}

variable "parent_domain_name" {
  description = "parent domain name for monitoring"
  type        = string
}

variable "whitelist_cidr_blocks" {
  description = "list of allowed cidr blocks"
  type        = list(string)
}

variable "primary" {
  description = "Name used for primary role"
  type        = string
  default     = "master"
}

variable "secondary" {
  description = "Name used for secondary role"
  type        = string
  default     = "slave"
}

variable "platform_version" {
  description = "ECS Service platform version"
  type        = string
  default     = "1.4.0"
}

variable "fargate_cpu" {
  default = "256"
}

variable "fargate_memory" {
  default = "512"
}

variable "https_port" {
  default = 443
}

variable "internet_proxy_port" {}
variable "grafana_port" {}
variable "prometheus_port" {}
variable "thanos_port_grpc" {}
variable "thanos_port_http" {}
variable "alertmanager_port" {}
variable "cloudwatch_exporter_port" {}

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
