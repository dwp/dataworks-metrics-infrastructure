variable "name" {
  description = "common name"
  type        = string
}

variable "lb_name" {
  description = "load balancer name"
  type        = string
}

variable "tags" {
  description = "tags to apply to aws resource"
  type        = map(string)
}

variable "region" {
  type = string
}

variable "assume_role" {
  type = string
}

variable "accounts" {
  type = map(string)
}

variable "zone_id" {
  type = string
}

variable "parent_domain_name" {}
variable "vpc" {}
variable "whitelist_cidr_blocks" {}
