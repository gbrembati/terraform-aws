terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.30.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = var.region
  access_key = var.aws-access-key
  secret_key = var.aws-secret-key
}

resource "aws_route53_zone" "dns-zone" {
  name = var.dns-zone
  force_destroy = true

  tags = {
    "Resource Group" = "rg-${var.vpc-checkpoint}"
  }
}
resource "aws_resourcegroups_group" "resource-group-spoke" {
  count = length(var.spoke-env)
  name  = "rg-${lookup(var.spoke-env,count.index)[0]}"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "Resource Group",
          "Values": ["rg-${lookup(var.spoke-env,count.index)[0]}"]
        }
      ]
    }
    JSON
  }
}

# Create a VPC for our gateway
resource "aws_vpc" "vpc-spoke" {
  count       = length(var.spoke-env)
  cidr_block  = lookup(var.spoke-env,count.index)[1]
  tags = {
    Name = "vpc-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
}

resource "aws_route_table" "rt-main-vpc-spoke" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id

  tags = {
    Name = "rt-main-vpc-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}
resource "aws_main_route_table_association" "rt-to-vpc-spoke" {
  count          = length(var.spoke-env)
  vpc_id         = aws_vpc.vpc-spoke[count.index].id
  route_table_id = aws_route_table.rt-main-vpc-spoke[count.index].id
  depends_on = [aws_route_table.rt-main-vpc-spoke]  
}

resource "aws_security_group" "nsg-allow-all" {
  count       = length(var.spoke-env)
  name        = "nsg-vpc-${lookup(var.spoke-env,count.index)[0]}"
  description = "Allow inbound/outbound traffic"
  vpc_id      = aws_vpc.vpc-spoke[count.index].id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nsg-vpc-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}

# Create the Spoke Subnets
resource "aws_subnet" "net-gwlbe-spoke" {
  count       = length(var.spoke-env)
  vpc_id      = aws_vpc.vpc-spoke[count.index].id
  cidr_block  = lookup(var.spoke-env,count.index)[2]
  availability_zone = "${var.region}a"

  tags = {
    Name = "net-${lookup(var.spoke-env,count.index)[0]}-gwlbe"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}
resource "aws_subnet" "net-untrust-spoke" {
  count       = length(var.spoke-env)
  vpc_id      = aws_vpc.vpc-spoke[count.index].id
  cidr_block  = lookup(var.spoke-env,count.index)[3]
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "net-${lookup(var.spoke-env,count.index)[0]}-untrust"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
    x-chkp-gwlb-outbound = "0.0.0.0/0"
    x-chkp-gwlb-inbound = lookup(var.spoke-env,count.index)[3]
  }
  depends_on = [aws_vpc.vpc-spoke]
}
resource "aws_subnet" "net-trust-spoke" {
  count       = length(var.spoke-env)
  vpc_id      = aws_vpc.vpc-spoke[count.index].id
  cidr_block  = lookup(var.spoke-env,count.index)[4]
  availability_zone = "${var.region}a"

  tags = {
    Name = "net-${lookup(var.spoke-env,count.index)[0]}-trust"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
    x-chkp-gwlb-outbound = "0.0.0.0/0"
  }
  depends_on = [aws_vpc.vpc-spoke]
}

# The IGWs for the Spokes VPC and makes all the route-table w/ association
resource "aws_internet_gateway" "vpc-spoke-igw" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id
  tags = {
    Name = "igw-vpc-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}
resource "aws_route_table" "rt-spoke-igw" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id

  tags = {
    Name = "rt-igw-vpc-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke,aws_internet_gateway.vpc-spoke-igw]
}
resource "aws_route_table_association" "rt-to-igw-spoke" {
  count          = length(var.spoke-env)
  gateway_id     = aws_internet_gateway.vpc-spoke-igw[count.index].id
  route_table_id = aws_route_table.rt-spoke-igw[count.index].id
  depends_on = [aws_internet_gateway.vpc-spoke-igw,aws_route_table.rt-spoke-igw]  
}

resource "aws_route_table" "rt-net-gwlbe-spoke" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-spoke-igw[count.index].id
  }
  tags = {
    Name = "rt-net-${lookup(var.spoke-env,count.index)[0]}-gwlbe"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke,aws_internet_gateway.vpc-spoke-igw]
}
resource "aws_route_table_association" "rt-to-gwlbe-spoke" {
  count          = length(var.spoke-env)
  subnet_id      = aws_subnet.net-gwlbe-spoke[count.index].id
  route_table_id = aws_route_table.rt-net-gwlbe-spoke[count.index].id
  depends_on = [aws_subnet.net-gwlbe-spoke,aws_route_table.rt-net-gwlbe-spoke]  
}

resource "aws_route_table" "rt-net-untrust-spoke" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-spoke-igw[count.index].id
  }
  tags = {
    Name = "rt-net-${lookup(var.spoke-env,count.index)[0]}-untrust"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke,aws_internet_gateway.vpc-spoke-igw]
}
resource "aws_route_table_association" "rt-to-untrust-spoke" {
  count          = length(var.spoke-env)
  subnet_id      = aws_subnet.net-untrust-spoke[count.index].id
  route_table_id = aws_route_table.rt-net-untrust-spoke[count.index].id
  depends_on = [aws_subnet.net-untrust-spoke,aws_route_table.rt-net-untrust-spoke]  
}

resource "aws_route_table" "rt-net-trust-spoke" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id

  tags = {
    Name = "rt-net-${lookup(var.spoke-env,count.index)[0]}-trust"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke,aws_internet_gateway.vpc-spoke-igw]
}
resource "aws_route_table_association" "rt-to-trust-spoke" {
  count          = length(var.spoke-env)
  subnet_id      = aws_subnet.net-trust-spoke[count.index].id
  route_table_id = aws_route_table.rt-net-trust-spoke[count.index].id
  depends_on = [aws_subnet.net-trust-spoke,aws_route_table.rt-net-trust-spoke]  
}

# Deploy NGINX test VMs
resource "aws_security_group" "nsg-allow-http" {
  count       = length(var.spoke-env)
  name        = "nsg-allow-http-${lookup(var.spoke-env,count.index)[0]}"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.vpc-spoke[count.index].id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nsg-allow-http-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}
resource "aws_security_group" "nsg-allow-ssh" {
  count       = length(var.spoke-env)
  name        = "nsg-allow-ssh-${lookup(var.spoke-env,count.index)[0]}"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.vpc-spoke[count.index].id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "nsg-allow-ssh-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}

resource "aws_network_interface" "nic-vm-spoke-nginx" {
  count           = length(var.spoke-env)
  subnet_id       = aws_subnet.net-untrust-spoke[count.index].id
  security_groups = [aws_security_group.nsg-allow-http[count.index].id,aws_security_group.nsg-allow-ssh[count.index].id]

  tags = {
    Name = "nic-vm-nginx-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_subnet.net-untrust-spoke,aws_security_group.nsg-allow-http,aws_security_group.nsg-allow-ssh]
}

resource "aws_instance" "vm-spoke-nginx" {
  count         = length(var.spoke-env)
  ami           = "ami-0498e52ec6fd76d1a"
  instance_type = "t2.micro"
  key_name      = var.linux-keypair

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nic-vm-spoke-nginx[count.index].id
  }

  tags = {
    Name = "vm-nginx-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_network_interface.nic-vm-spoke-nginx]
}

resource "aws_route53_record" "dns-vm-spoke-nginx" {
  count   = length(var.spoke-env)
  zone_id = aws_route53_zone.dns-zone.zone_id
  name    = "nginx-${lookup(var.spoke-env,count.index)[0]}.${var.dns-zone}"
  type    = "A"
  ttl     = "30"
  records = [aws_instance.vm-spoke-nginx[count.index].public_ip]
  depends_on = [aws_instance.vm-spoke-nginx]
}
