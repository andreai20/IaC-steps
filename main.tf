# Provider block
provider "aws" {
  region = "us-east-1"
}
# Create VPC
resource "aws_vpc" "monitor" {
  cidr_block = "10.8.0.0/16"
  tags = {
    Name = "Monitor"
  }
}
# Create the Internet gateway
resource "aws_internet_gateway" "monitor" {
  vpc_id = aws_vpc.monitor.id

  tags = {
    Name = "monitor-gateway"
  }
}
# Create the route table and attach to VPC - note vpc id
resource "aws_route_table" "rtable" {
  vpc_id = aws_vpc.monitor.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.monitor.id
  }
}
# create route association for the public subnet alone as it's required to be internet facing
resource "aws_route_table_association" "prom-public" {
  route_table_id = aws_route_table.rtable.id
  subnet_id = aws_subnet.prom_net.id
}

# Create the first subnet and corresponding attributes
resource "aws_subnet" "prom_net" {
 cidr_block        = "10.8.1.0/24"
 vpc_id            = aws_vpc.monitor.id
  map_public_ip_on_launch = "true"
 availability_zone = "us-east-1a"
 tags = {
   Name = "Prometheus Public-subnet"
 }
}
# Create second subnet and corresponding attributes
resource "aws_subnet" "graf_net" {
  cidr_block        = "10.8.2.0/24"
vpc_id            = aws_vpc.monitor.id
  availability_zone = "us-east-1b"
  tags = {
    Name = "Grafana"
 }
}
# Bonus third subnet added
resource "aws_subnet" "kibana_net" {
  cidr_block        = "10.8.3.0/24"
  vpc_id            = aws_vpc.monitor.id
  availability_zone = "us-east-1c"
  tags = {
    Name = "Kibana"
  }
}
