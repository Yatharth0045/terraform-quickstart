#! /bin/bash

# If you don't have jq installed, you're going to need it
sudo apt install jq -y

# First let's get the existing VPC id
vpc_id=$(aws ec2 describe-vpcs --filters Name="tag:Name",Values="primary-vpc" \
  --query 'Vpcs[0].VpcId' --output text)

echo "VPC Id: ${vpc_id}"

# Get the third AZ in the region
az=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[2].ZoneId' --output text)

echo "AZ: ${az}"

# Create a new public subnet in the VPC
pub_subnet=$(aws ec2 create-subnet --availability-zone-id $az \
  --cidr-block "10.0.2.0/24" --vpc-id $vpc_id)

pub_subnet_id=$(echo $pub_subnet | jq .Subnet.SubnetId -r)

echo "Public-subnet-id: ${pub_subnet_id}"

# Create a new private subnet in the VPC
priv_subnet=$(aws ec2 create-subnet --availability-zone-id $az \
  --cidr-block "10.0.12.0/24" --vpc-id $vpc_id)

priv_subnet_id=$(echo $priv_subnet | jq .Subnet.SubnetId -r)

echo "Private-subnet-id: ${priv_subnet_id}"

# Create a private route table for priv_subnet
priv_rt=$(aws ec2 create-route-table --vpc-id $vpc_id)

priv_rt_id=$(echo $priv_rt | jq .RouteTable.RouteTableId -r)

echo "Private-Route-Table: ${priv_rt_id}"

# Associate route table with private subnet
aws ec2 associate-route-table --route-table-id $priv_rt_id --subnet-id ${priv_subnet_id}

echo "privateRouteTableAssoc: $priv_subnet_id/$priv_rt_id"

# Get the public route table
pub_rt_id=$(aws ec2 describe-route-tables --filters Name="vpc-id",Values=$vpc_id \
  Name="tag:Name",Values="primary-vpc-public" \
  --query RouteTables[0].RouteTableId --output text)

# Associate the public route table with pub_subnet
aws ec2 associate-route-table --route-table-id $pub_rt_id --subnet-id $pub_subnet_id

echo "publicRouteTableAssoc: $pub_subnet_id/$pub_rt_id"
