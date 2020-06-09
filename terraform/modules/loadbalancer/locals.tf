locals {
  fqdn = join(".", [var.lb_name, var.parent_domain_name])
}
