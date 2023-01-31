# ------ Create a VPC 
resource aws_vpc cr3_r2 {
  provider             = aws.r2
  cidr_block           = var.cidr_vpc_r2
  enable_dns_hostnames = true
  tags                 = { Name = "cr3-r2-vpc" }
}

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway cr3_r2 {
  provider = aws.r2
  vpc_id   = aws_vpc.cr3_r2.id
  tags     = { Name = "cr3-r2-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table cr3_r2 {
  provider               = aws.r2
  default_route_table_id = aws_vpc.cr3_r2.default_route_table_id
  tags                   = { Name = "cr3-r2-public-rt" }

  route {
    cidr_block = var.cidr_vpc_r1
    gateway_id = aws_vpc_peering_connection.cr3_r1.id
  }
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cr3_r2.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl cr3_r2 {
  provider               = aws.r2
  default_network_acl_id = aws_vpc.cr3_r2.default_network_acl_id
  tags                   = { Name = "cr3-r2-acl" }
  subnet_ids             = [ aws_subnet.cr3_public_r2.id ]

  dynamic ingress {
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

  dynamic ingress {
    for_each = var.authorized_ips
    content {
      protocol   = "tcp"
      rule_no    = 200 + 10 * index(var.authorized_ips, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 80
      to_port    = 80
    }
  }

  # this is needed for yum
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # accept all traffic from peered VPC
  ingress {
    protocol   = -1
    rule_no    = 400
    action     = "allow"
    cidr_block = var.cidr_vpc_r1
    from_port  = 0
    to_port    = 0
  }

  # allow SSH from VPC in region #1
  ingress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = var.cidr_vpc_r1
    from_port  = 22
    to_port    = 22
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
resource aws_subnet cr3_public_r2 {
  provider                = aws.r2
  vpc_id                  = aws_vpc.cr3_r2.id
  availability_zone       = "${var.aws_region2}${var.az_dr}"
  cidr_block              = var.cidr_public_r2
  map_public_ip_on_launch = true
  tags                    = { Name = "cr3-r2-public" }
}

# ======== Peering connection to other VPC: ACCEPTER
resource aws_vpc_peering_connection_accepter cr3_r2 {
  provider                  = aws.r2
  vpc_peering_connection_id = aws_vpc_peering_connection.cr3_r1.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}