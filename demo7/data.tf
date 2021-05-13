## DATA

data "aws_availability_zones" "available" {}

data "template_file" "public_cidrsubnet" {
  count    = var.subnet_count[terraform.workspace]
  template = "$${cidrsubnet(vpc_cidr,8,current_count)}"
  #   template = cidrsubnet(vpc_cidr,8,current_count)
  vars = {
    "vpc_cidr"      = var.network_address_space[terraform.workspace]
    "current_count" = count.index
  }
}