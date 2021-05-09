aws_access_key        = ""
aws_secret_key        = ""
private_key_path      = "~/Downloads/yatharth-demo.pem"
key_name              = "yatharth-demo"
bucket_name_prefix    = "yatharth-bucket"
billing_code_tag      = "ACCT12345"
arm_subscription_id   = ""
arm_principal         = ""
arm_password          = ""
tenant_id             = ""
dns_zone_name         = "globamantics.xyz"
dns_resource_group    = "dns"
ubuntu_instance_count = {
    Development = 1
    UAT         = 2
    Production  = 3
  }
linux_instance_count  = {
    Development = 1
    UAT         = 2
    Production  = 3
  }
instance_size = {
  Development = "t2.micro"
  UAT         = "t2.micro"
  Production  = "t2.micro"
}