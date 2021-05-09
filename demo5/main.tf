## RESOURCES

resource "random_integer" "random" {
  min = 1000
  max = 9999
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.network_address_space
  enable_dns_hostnames = "true"
  tags                 = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "vpc")) })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "igw")) })
}

resource "aws_subnet" "subnet" {
  count                   = var.subnet_count
  cidr_block              = cidrsubnet(var.network_address_space, var.subnet_count / 2, count.index)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "subnet", count.index + 1)) })
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "rt")) })
}

resource "aws_route_table_association" "rta-subnet" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_security_group" "elb-sg" {
  name   = "nginx_elb_sg"
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "elb", "sg")) })

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

resource "aws_security_group" "nginx-sg" {
  name        = "nginx_sg"
  description = "Allow ports for nginx"
  vpc_id      = aws_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "ec2", "sg")) })

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = [var.network_address_space]
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

resource "aws_elb" "web" {
  name            = "nginx-elb"
  subnets         = aws_subnet.subnet[*].id
  security_groups = [aws_security_group.elb-sg.id]
  instances       = concat(aws_instance.nginx1[*].id, aws_instance.nginx2[*].id)
  tags            = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "elb")) })


  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_instance" "nginx1" {
  count                  = var.linux_instance_count
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet[count.index % var.subnet_count].id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.nginx_profile.name
  tags                   = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "ec2", "linux", count.index + 1)) })

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    content = <<EOF
  access_key = 
  secret_key =
  security_token = 
  use_https = True
  bucket_location = US
  EOF

    destination = "/home/ec2-user/.s3cfg"
  }

  provisioner "file" {
    content     = <<EOF
  /var/log/nginx/*log {
    daily
    rotate 10
    missingok
    compress
    sharedscripts
    postrotate
    endscript
    lastaction
      INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id/`
      sudo /usr/local/bin/s3cmd sync --config=/home/ec2-user/.s3cfg /var/log/nginx/ s3://${aws_s3_bucket.web_bucket.id}/nginx/$INSTANCE_ID/
    endscript
  }

  EOF
    destination = "/home/ec2-user/nginx"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "sudo cp /home/ec2-user/.s3cfg /root/.s3cfg",
      "sudo cp /home/ec2-user/nginx /etc/logrotate.d/nginx",
      "sudo pip install s3cmd",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/index.html .",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/logo.png .",
      "sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html",
      "sudo cp /home/ec2-user/logo.png /usr/share/nginx/html/logo.png",
      "sudo logrotate -f /etc/logrotate.conf"
    ]
  }
}

resource "aws_instance" "nginx2" {
  count                  = var.ubuntu_instance_count
  ami                    = data.aws_ami.aws-ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet[count.index % var.subnet_count].id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.nginx_profile.name
  tags                   = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "ec2", "ubuntu", count.index + 1)) })


  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    content = <<EOF
access_key = 
secret_key =
security_token = 
use_https = True
bucket_location = US
  EOF

    destination = "/home/ubuntu/.s3cfg"
  }

  provisioner "file" {
    content     = <<EOF
/var/log/nginx/*log {
  daily
  rotate 10
  missingok
  compress
  sharedscripts
  postrotate
  endscript
  lastaction
    INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id/`
    sudo /usr/local/bin/s3cmd sync --config=/home/ubuntu/.s3cfg /var/log/nginx/ s3://${aws_s3_bucket.web_bucket.id}/nginx/$INSTANCE_ID/
  endscript
}
  EOF
    destination = "/home/ubuntu/nginx"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt install nginx -y",
      "sudo service nginx start",
      "sudo cp /home/ubuntu/.s3cfg /root/.s3cfg",
      "sudo cp /home/ubuntu/nginx /etc/logrotate.d/nginx",
      "sudo apt update",
      "sudo apt install python3-pip -y",
      "sudo pip3 install s3cmd",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/index.html .",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/logo.png .",
      "sudo rm /var/share/nginx/html/*.html",
      "sudo cp /home/ubuntu/index.html /var/www/html/index.html",
      "sudo cp /home/ubuntu/logo.png /var/www/html/logo.png",
      "sudo logrotate -f /etc/logrotate.conf"
    ]
  }
}

resource "aws_iam_role" "allow_nginx_s3" {
  name = "allow_nginx_s3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "nginx_profile" {
  name = "nginx_profile"
  role = aws_iam_role.allow_nginx_s3.name
}

resource "aws_iam_role_policy" "allow_s3_all" {
  name = "allow_s3_all"
  role = aws_iam_role.allow_nginx_s3.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${local.s3_bucket_name}",
        "arn:aws:s3:::${local.s3_bucket_name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "web_bucket" {
  bucket        = local.s3_bucket_name
  acl           = "private"
  force_destroy = true
  tags          = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "web")) })
}

resource "aws_s3_bucket_object" "website" {
  bucket = aws_s3_bucket.web_bucket.bucket
  key    = "/website/index.html"
  source = "./index.html"
}

resource "aws_s3_bucket_object" "graphic" {
  bucket = aws_s3_bucket.web_bucket.bucket
  key    = "/website/logo.png"
  source = "./logo.png"
}

# resource "azurerm_dns_cname_record" "elb" {
#   name                = "${var.environment_tag}-website"
#   zone_name           = var.dns_zone_name
#   resource_group_name = var.dns_resource_group
#   ttl                 = "30"
#   record              = aws_elb.web.dns_name
#   provider            = azurerm.arm-1

#   tags = merge(local.common_tags, { Name = join("-", list(var.environment_tag, "website")) })
# }
