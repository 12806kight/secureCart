resource "aws_vpc" "securecart-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

##################################
# Subnets
##################################

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

#Route Table

resource "aws_route_table" "securecart-public-rt" {
  vpc_id = aws_vpc.securecart-vpc.id

  tags = {
    Name = "Secure Cart Route Table"
  }
}

#our internet gateway allows communication between the internet and our vpc
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
    Name = "our public route table which makes our public subnets public by routing traffic to the internet gateway"
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = { for key, value in var.subnets : key => value if value.type == "public" }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat_eip" { 
  domain = "vpc"

  tags = {
    Name = "our nat gateway elastic ip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  
  subnet_id     = aws_subnet.this[keys({ for key, value in var.subnets : key => value if value.type == "public" })[0]].id

  tags = {
    Name = "our nat gateway"
  }
  depends_on = [aws_internet_gateway.igw_TS] 
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.securecart-vpc.id

  route {
    cidr_block = var.private_route_cidr_block
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = { 
    Name = "our private route table which keeps our private subnets PRIVATE by routing traffic to the internet gateway"
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = { for key, value in var.subnets : key => value if value.type == "private" }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private_rt.id
}
