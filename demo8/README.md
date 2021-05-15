# Demo 8

```
## AWS Default profile
aws configure 

## AWS New profile
aws configure --profile deep-dive
export AWS_PROFILE=deep-dive

cd demo8

terraform version
## Output: Terraform v0.12.19

terraform init

terraform validate

terraform plan

terraform apply

terraform show

terraform destroy
```