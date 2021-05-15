# PROVIDERS

# CONFIGURATION - added for Terraform 0.14

# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~>3.0"
#     }
#   }
# }

provider "aws" {
  profile = "default"
  region  = var.region
}