provider "aws" {
  version = "~> 2.57.0"
  region  = var.region
  alias   = "management_dns"

  assume_role {
    role_arn = "arn:aws:iam::${var.accounts["management"]}:role/${var.assume_role}"
  }
}
