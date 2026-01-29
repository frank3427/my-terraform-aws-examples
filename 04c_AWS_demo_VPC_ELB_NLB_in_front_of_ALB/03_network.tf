# ------ Create a VPC 
resource "aws_vpc" "demo04c" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo04c-vpc" }
}

# ========== Public subnets for bastion and NLB

# ------ Create an internet gateway in the new VPC
resource "aws_internet_gateway" "demo04c-ig" {
  vpc_id = aws_vpc.demo04c.id
  tags   = { Name = "demo04c-igw" }
}

# ------ Create a subnet for bastion
resource "aws_subnet" "demo04c_public_bastion" {
  vpc_id                  = aws_vpc.demo04c.id
  availability_zone       = "${var.aws_region}${var.bastion_az}"
  cidr_block              = var.cidr_subnet_public_bastion
  map_public_ip_on_launch = true
  tags                    = { Name = "demo04c-public-bastion" }
}

# ------ Create 2 subnets for the NLB (public)
resource "aws_subnet" "demo04c_public_nlb" {
  count                   = 2
  vpc_id                  = aws_vpc.demo04c.id
  availability_zone       = "${var.aws_region}${var.websrv_az[count.index]}"
  cidr_block              = var.cidr_subnets_public_nlb[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo04c-public-nlb${count.index + 1}" }
}

# ------ Add a name and route rule to the default route table (public)
resource "aws_default_route_table" "demo04c" {
  default_route_table_id = aws_vpc.demo04c.default_route_table_id
  tags                   = { Name = "demo04c-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo04c-ig.id
  }
}

# ========== Private subnets for ALB and EC2 web servers instances

# ------ Create 2 subnets for the ALB (private)
resource "aws_subnet" "demo04c_private_alb" {
  count                   = 2
  vpc_id                  = aws_vpc.demo04c.id
  availability_zone       = "${var.aws_region}${var.websrv_az[count.index]}"
  cidr_block              = var.cidr_subnets_private_alb[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "demo04c-private-alb${count.index + 1}" }
}

# ------ Create 2 subnets for the webservers (private)
resource "aws_subnet" "demo04c_private_websrv" {
  count                   = 2
  vpc_id                  = aws_vpc.demo04c.id
  availability_zone       = "${var.aws_region}${var.websrv_az[count.index]}"
  cidr_block              = var.cidr_subnets_private_websrv[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "demo04c-private-websrv${count.index + 1}" }
}

# ------ Create a NAT gateway for private subnets
resource "aws_eip" "demo04c_nat" {
  domain = "vpc"
  tags   = { Name = "demo04c-nat-eip" }
}

resource "aws_nat_gateway" "demo04c_nat" {
  allocation_id = aws_eip.demo04c_nat.id
  subnet_id     = aws_subnet.demo04c_public_nlb[0].id
  tags          = { Name = "demo04c-nat-gw" }
}

# ------ Create route table for private subnets
resource "aws_route_table" "demo04c_private" {
  vpc_id = aws_vpc.demo04c.id
  tags   = { Name = "demo04c-private-rt" }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo04c_nat.id
  }
}

# ------ Associate private subnets with private route table
resource "aws_route_table_association" "demo04c_private_alb" {
  count          = 2
  subnet_id      = aws_subnet.demo04c_private_alb[count.index].id
  route_table_id = aws_route_table.demo04c_private.id
}

resource "aws_route_table_association" "demo04c_private_websrv" {
  count          = 2
  subnet_id      = aws_subnet.demo04c_private_websrv[count.index].id
  route_table_id = aws_route_table.demo04c_private.id
}

# ------ Add a name to the default network ACL
resource "aws_default_network_acl" "demo04c" {
  default_network_acl_id = aws_vpc.demo04c.default_network_acl_id
  tags                   = { Name = "demo04c-acl" }
  subnet_ids = concat(
    [aws_subnet.demo04c_public_bastion.id],
    aws_subnet.demo04c_public_nlb[*].id,
    aws_subnet.demo04c_private_alb[*].id,
    aws_subnet.demo04c_private_websrv[*].id
  )

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}
