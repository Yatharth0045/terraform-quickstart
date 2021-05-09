## PROVIDERS

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

# provider "azurerm" {
#   subscription_id = var.arm_subscription_id
#   client_id       = var.arm_principal
#   client_secret   = var.arm_password
#   tenant_id       = var.tenant_id
#   alias           = "arm-1"
# }