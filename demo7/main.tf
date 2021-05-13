## RESOURCES

resource "random_integer" "random" {
  min = 1000
  max = 9999
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = "${local.env_name}-vpc"
  version = "2.15.0"

  cidr            = var.network_address_space[terraform.workspace]
  azs             = slice(data.aws_availability_zones.available.names, 0, var.subnet_count[terraform.workspace])
  public_subnets  = data.template_file.public_cidrsubnet[*].rendered
  private_subnets = []

  tags = local.common_tags
}

resource "aws_security_group" "elb-sg" {
  name   = "nginx_elb_sg"
  vpc_id = module.vpc.vpc_id
  tags   = merge(local.common_tags, { Name = join("-", list(local.env_name, "elb", "sg")) })

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = -1
    to_port     = 0
  }
}

module "bucket" {
  source = "./modules/s3"
  name = local.s3_bucket_name
  common_tags = local.common_tags
}

resource "aws_s3_bucket_object" "website" {
  bucket = module.bucket.bucket.id
  key    = "/website/index.html"
  source = "./index.html"
}

resource "aws_s3_bucket_object" "graphic" {
  bucket = module.bucket.bucket.id
  key    = "/website/logo.png"
  source = "./logo.png"
}