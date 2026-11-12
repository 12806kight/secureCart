resource "aws_vpc" "securecart-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.securecart-vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.type == "public"

  tags = {
    Name        = "${each.value.type}-subnet-${each.value.az}"
    Environment = "development"
  }
}

resource "aws_internet_gateway" "igw_TS" {
  vpc_id = aws_vpc.securecart-vpc.id

  tags = {
    Name = "internet gateway securecart"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.securecart-vpc.id

  route {
    cidr_block = var.public_route_cidr_block
    gateway_id = aws_internet_gateway.igw_TS.id
  }

  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = { for key, value in var.subnets : key => value if value.type == "public" }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public_rt.id
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_security_group" "nat_sg" {
  name        = "${var.project}-nat-sg"
  description = "Allows outbound HTTP/HTTPS traffic from private subnets through NAT instance"
  vpc_id      = aws_vpc.securecart-vpc.id

  ingress {
    description = "Allow HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for k, v in var.subnets : v.cidr_block if v.type == "private"]
  }

  ingress {
    description = "Allow HTTP from private subnets for apt package updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for k, v in var.subnets : v.cidr_block if v.type == "private"]
  }

  egress {
    description = "Allow outbound HTTPS to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound HTTP to internet for apt repositories"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-nat-sg"
  }
}

resource "aws_instance" "nat_instance" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.this["public_a"].id
  vpc_security_group_ids      = [aws_security_group.nat_sg.id]
  associate_public_ip_address = true
  source_dest_check           = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y iptables-services
              systemctl enable iptables
              systemctl start iptables
              echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
              sysctl -p
              PRIMARY_IF=$(ip route | grep default | awk '{print $5}')
              iptables -t nat -A POSTROUTING -o "$PRIMARY_IF" -j MASQUERADE
              service iptables save
              EOF

  tags = {
    Name        = "${var.project}-nat-instance"
    Environment = "development"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.securecart-vpc.id

  route {
    cidr_block           = var.private_route_cidr_block
    network_interface_id = aws_instance.nat_instance.primary_network_interface_id
  }

  tags = {
    Name = "${var.project}-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = { for key, value in var.subnets : key => value if value.type == "private" }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private_rt.id
}
