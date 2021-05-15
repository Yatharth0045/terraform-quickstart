# Demo 9

```
## AWS Default profile
aws configure 

## AWS New profile
aws configure --profile deep-dive
export AWS_PROFILE=deep-dive

cd demo9

terraform version
## Output: Terraform v0.12.19

terraform init

terraform validate

terraform plan

terraform apply

bash manaul-creation.sh

## Updated tf vars

terraform plan

## Make sure to change the ID values

terraform import "module.vpc.aws_subnet.private[2]" subnet-060b32edb4a99915b
terraform import "module.vpc.aws_subnet.public[2]" subnet-0cab8a2e7b08c2945
terraform import "module.vpc.aws_route_table.private[2]" rtb-0403dcb26136f6bcc
terraform import "module.vpc.aws_route_table_association.private[2]" subnet-060b32edb4a99915b/rtb-0403dcb26136f6bcc
terraform import "module.vpc.aws_route_table_association.public[2]" subnet-0cab8a2e7b08c2945/rtb-068c90cb5caae4dc4

terraform plan

terraform apply

terraform show

terraform destroy
```