# ------ Create a VPC 
resource aws_vpc demo44 {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo44-vpc" }
}

# ========== Public subnet for EC2 instance

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo44 {
  vpc_id = aws_vpc.demo44.id
  tags   = { Name = "demo44-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo44 {
  default_route_table_id = aws_vpc.demo44.default_route_table_id
  tags                   = { Name = "demo44-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo44.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo44 {
  default_network_acl_id = aws_vpc.demo44.default_network_acl_id
  tags                   = { Name = "demo44-acl" }
  subnet_ids             = [ aws_subnet.demo44_public.id ]

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

  # this is needed for yum
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
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
resource aws_subnet demo44_public {
  vpc_id                  = aws_vpc.demo44.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet_pub
  map_public_ip_on_launch = true
  tags                    = { Name = "demo44-public" }
}

# ========== Private subnet for Elasticache Memcached cluster

# ------ Create an elastic IP address for the NAT gateway
resource aws_eip demo44_natgw {
  domain   = "vpc"
  tags     = { Name = "demo44-natgw" }
}

# ------ Create a NAT gateway
resource aws_nat_gateway demo44 {
  connectivity_type = "public"
  allocation_id     = aws_eip.demo44_natgw.id
  subnet_id         = aws_subnet.demo44_public.id
  tags              = { Name = "demo44-natgw" }
}

# ------ Create a new route table
resource aws_route_table demo44_private {
  vpc_id = aws_vpc.demo44.id
  tags   = { Name = "demo44-private-rt" }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo44.id
  }
}

# ------ Create a new network ACL for private subnet
resource aws_network_acl demo44_private {
  vpc_id     = aws_vpc.demo44.id
  tags       = { Name = "demo44-private-acl" }
  subnet_ids = [ aws_subnet.demo44_private.id ]

  # allow all traffic from public subnet
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_subnet_pub
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

# ------ Create the private subnet
resource aws_subnet demo44_private {
  vpc_id                  = aws_vpc.demo44.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet_priv
  map_public_ip_on_launch = false
  tags                    = { Name = "demo44-private" }
}

# ------ Associate the route table with subnet
resource aws_route_table_association demo44_private {
  subnet_id      = aws_subnet.demo44_private.id
  route_table_id = aws_route_table.demo44_private.id
}

