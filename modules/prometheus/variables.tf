variable "name" {
  description = "common name"
  type        = string
}

variable "tags" {
  description = "tags to apply to aws resource"
  type        = map(string)
}

variable "role" {
  description = "The role of prometheus, either master or slave"
  type        = string
}

variable "prometheus_version" {
  description = "version of prometheus"
  type        = string
}

variable "s3_prefix" {
  type = string
}

variable "mgmt" {}
variable "aws_subnets_private" {}

variable "aws_vpc" {}

variable "s3_prefix_list_id" {
  type = string
}

variable "lb_listener" {
  type = string
}

variable "fqdn" {
  type = string
}

variable "fargate_cpu" {
  default = "256"
}

variable "fargate_memory" {
  default = "512"
}

variable "prom_port" {
  default = "9090"
}
