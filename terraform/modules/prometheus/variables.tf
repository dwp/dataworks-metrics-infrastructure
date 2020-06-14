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
variable "vpc" {}
variable "lb" {}

variable "fargate_cpu" {
  default = "256"
}

variable "fargate_memory" {
  default = "512"
}

variable "prom_port" {
  default = "9090"
}
