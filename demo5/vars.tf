## VARIABLES

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "region" {
  default = "us-east-1"
}
variable "network_address_space" {
  default = "10.1.0.0/16"
}

variable "bucket_name_prefix" {}
variable "billing_code_tag" {}
variable "environment_tag" {}

variable "arm_subscription_id" {}
variable "arm_principal" {}
variable "arm_password" {}
variable "tenant_id" {}
variable "dns_zone_name" {}
variable "dns_resource_group" {}
variable "ubuntu_instance_count" {
  default = 2
}
variable "linux_instance_count" {
  default = 2
}
variable "subnet_count" {
  default = 2
}

## LOCALS

locals {
  common_tags = {
    BillingCode = var.billing_code_tag
    Environment = var.environment_tag
  }
  s3_bucket_name = join("-", list(var.bucket_name_prefix, var.environment_tag, random_integer.random.result))
}