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

variable "s3_prefix" {
  default = "monitoring/prometheus"
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
