variable "name" {
  description = "cluster name, used in dns"
  type        = string
  default     = "monitoring"
}

variable "prometheus_version" {
  description = "prometheus version to use"
  type        = string
  default     = "2.23.0"
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
  default = "512"
}

variable "fargate_memory" {
  default = "512"
}

variable "receiver_cpu" {
  default = "512"
}

variable "receiver_memory" {
  default = "1024"
}

variable "store_cpu" {
  default = "1024"
}

variable "https_port" {
  default = 443
}

variable "ulimits" {
  default = 999999
}

variable "internet_proxy_port" {}
variable "grafana_port" {}
variable "prometheus_port" {}
variable "thanos_port_grpc" {}
variable "thanos_port_remote_write" {}
variable "thanos_port_http" {}
variable "alertmanager_port" {}
variable "cloudwatch_exporter_port" {}
variable "pushgateway_port" {}
variable "json_exporter_port" {}
variable "jmx_port" {}

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

variable "metrics_ecs_cluster_asg_max" {
  description = "Max metrics asg size"
  default = {
    development    = 3
    qa             = 3
    integration    = 3
    preprod        = 5
    production     = 5
    management     = 5
    management-dev = 5
  }
}

variable "metrics_ecs_cluster_ec2_size" {
  default = {
    development    = "t3.large"
    qa             = "t3.large"
    integration    = "t3.large"
    preprod        = "t3.large"
    production     = "t3.large"
    management     = "t3.large"
    management-dev = "t3.large"
  }
}

variable "ecs_hardened_ami_id" {
  description = "The AMI ID of the latest/pinned ECS Hardened AMI Image"
  type        = string
}
