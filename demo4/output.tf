## OUTPUT

output "aws_elb_public_dns" {
  value = aws_elb.web.dns_name
}

output "linux-instance-ip" {
  value = aws_instance.nginx1.public_ip
}

output "ubuntu-instance-ip" {
  value = aws_instance.nginx2.public_ip
}