## VARIABLES

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "region" {
  default = "us-east-1"
}
variable "network_address_space" {
  type = map(string)
  default = {
    Development = "10.0.0.0/16"
    UAT         = "10.1.0.0/16"
    Production  = "10.2.0.0/16"
  }
}
variable "instance_size" {
  type = map(string)
}
variable "bucket_name_prefix" {}
variable "billing_code_tag" {}
# variable "environment_tag" {}

variable "arm_subscription_id" {}
variable "arm_principal" {}
variable "arm_password" {}
variable "tenant_id" {}
variable "dns_zone_name" {}
variable "dns_resource_group" {}
variable "ubuntu_instance_count" {
  type = map(number)
  default = {
    Development = 1
    UAT         = 2
    Production  = 3
  }
}
variable "linux_instance_count" {
  type = map(number)
  default = {
    Development = 1
    UAT         = 2
    Production  = 3
  }
}
variable "subnet_count" {
  type = map(number)
  default = {
    Development = 2
    UAT         = 2
    Production  = 3
  }
}

## LOCALS

locals {
  env_name = lower(terraform.workspace)

  common_tags = {
    BillingCode = var.billing_code_tag
    Environment = local.env_name
  }
  s3_bucket_name = join("-", list(var.bucket_name_prefix, local.env_name, random_integer.random.result))
}
