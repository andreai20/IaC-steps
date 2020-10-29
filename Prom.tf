# Provider block
provider "aws" {
  region = "eu-west-1"
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
resource "aws_route_table_association" "Graf-public" {
  route_table_id = aws_route_table.rtable.id
  subnet_id      = aws_subnet.graf_net.id
}
#=================================
# Create security Groups for Prom
#===================================
resource "aws_security_group" "Prom_sg" {
  name = "Prometheus-Public"
  description = "Security group for Prometheus public subnet"
  vpc_id = aws_vpc.monitor.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    from_port = 9090
    protocol = "tcp"
    to_port = 9090
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]

  }
}
# ==========================================
// Create security Groups for Grafana
#===========================================
resource "aws_security_group" "Graf-sg" {
  name        = "Grafana Private subnet"
  description = "Security group for public subnet"
  vpc_id      = aws_vpc.monitor.id

  ingress {
    description = "SSH from Prometheus"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "server access to "
    from_port   = 3000
    protocol    = "tcp"
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Outbound to the world"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the first subnet and corresponding attributes
resource "aws_subnet" "prom_net" {
  cidr_block              = "10.8.1.0/24"
  vpc_id                  = aws_vpc.monitor.id
  availability_zone       = "eu-west-1a"
  tags = {
    Name = "Prometheus Private-subnet"
  }
}
# Create second subnet and corresponding attributes
resource "aws_subnet" "graf_net" {
  cidr_block        = "10.8.2.0/24"
  vpc_id            = aws_vpc.monitor.id
  map_public_ip_on_launch = "true"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "Grafana Public-Subnet"
  }
}
resource "aws_instance" "prometheus_server" {
  ami = "ami-0a89126afe50868cf"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.prom_net.id
  vpc_security_group_ids = [aws_security_group.Prom_sg.id]
  tags = {
    Name = "prometheus_server"
  }
}
resource "aws_instance" "grafana_server" {
  ami = "ami-0a89126afe50868cf"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.graf_net.id
  vpc_security_group_ids = [
    aws_security_group.Graf-sg.id]
  tags = {
    Name = "grafana_server"
  }
}