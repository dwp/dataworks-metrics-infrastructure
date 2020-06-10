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

variable "lb_listener" {
  description = "ARN of the LB Listener"
  type        = string
}

variable "fqdn" {
  description = "Route53 FQDN"
  type        = string
}

variable "image" {
  type = string
}

variable "lb_security_group_id" {
  description = ""
  type        = string
}

variable "vpc" {}
variable "ecs_task_execution_role" {}
variable "ecs_cluster_main_log_group" {}
variable "ecs_cluster_main" {}

variable "fargate_cpu" {
  default = "256"
}

variable "fargate_memory" {
  default = "512"
}

variable "prom_port" {
  default = "9090"
}
