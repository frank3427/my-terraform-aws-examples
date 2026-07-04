# ------ Create a VPC 
resource "aws_vpc" "demo07_r2" {
  provider             = aws.r2
  cidr_block           = var.cidr_vpc_r2
  enable_dns_hostnames = true
  tags                 = { Name = "demo07-vpc-r2" }
}

# ------ Create an internet gateway in the new VPC
resource "aws_internet_gateway" "demo07_r2" {
  provider = aws.r2
  vpc_id   = aws_vpc.demo07_r2.id
  tags     = { Name = "demo07-igw-r2" }
}

# ------ Add a name and route rule to the default route table
resource "aws_default_route_table" "demo07_r2" {
  provider               = aws.r2
  default_route_table_id = aws_vpc.demo07_r2.default_route_table_id
  tags                   = { Name = "demo07-rt-r2" }

  route {
    cidr_block = var.cidr_public_r1
    gateway_id = aws_vpc_peering_connection.demo07_r1.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo07_r2.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource "aws_default_network_acl" "demo07_r2" {
  provider               = aws.r2
  default_network_acl_id = aws_vpc.demo07_r2.default_network_acl_id
  tags                   = { Name = "demo07_r2-acl" }
  subnet_ids             = [aws_subnet.demo07_public_r2.id]

  dynamic "ingress" {
    for_each = var.authorized_ips
    content {
      protocol   = "tcp"
      rule_no    = 100 + 10 * index(var.authorized_ips, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 22
      to_port    = 22
    }
  }

  # this is needed for yum
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # accept all traffic from peered VPC
  ingress {
    protocol   = -1
    rule_no    = 300
    action     = "allow"
    cidr_block = var.cidr_vpc_r1
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

# ------ Create a subnet (use the default route table and default network ACL)
resource "aws_subnet" "demo07_public_r2" {
  provider                = aws.r2
  vpc_id                  = aws_vpc.demo07_r2.id
  availability_zone       = "${var.aws_region2}${var.az}"
  cidr_block              = var.cidr_public_r2
  map_public_ip_on_launch = true
  tags                    = { Name = "demo07-public-r2" }
}

# ------ Create a security group for the EC2 instance
resource "aws_security_group" "demo07_sg_r2" {
  provider    = aws.r2
  name        = "demo07-sg-r2"
  description = "Description for demo07-sg-r2"
  vpc_id      = aws_vpc.demo07_r2.id
  tags        = { Name = "demo07-sg-r2" }
}

# ------ Peering connection to other VPC: ACCEPTER
resource "aws_vpc_peering_connection_accepter" "demo07_r2" {
  provider                  = aws.r2
  vpc_peering_connection_id = aws_vpc_peering_connection.demo07_r1.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}


resource "aws_vpc_security_group_ingress_rule" "demo07_sg_r2_ingress_ssh_0" {
  provider          = aws.r2
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo07_sg_r2.id
  description       = "allow SSH access from authorized public IP addresses"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo07_sg_r2-sgr-ingress-ssh-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo07_sg_r2_ingress_all_1" {
  provider          = aws.r2
  security_group_id = aws_security_group.demo07_sg_r2.id
  description       = "allow traffic from other VPC"
  ip_protocol       = "-1"
  cidr_ipv4         = var.cidr_public_r1
  tags              = { Name = "demo07_sg_r2-sgr-ingress-all-1" }
}

resource "aws_vpc_security_group_egress_rule" "demo07_sg_r2_egress_all_2" {
  provider          = aws.r2
  security_group_id = aws_security_group.demo07_sg_r2.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo07_sg_r2-sgr-egress-all-2" }
}
