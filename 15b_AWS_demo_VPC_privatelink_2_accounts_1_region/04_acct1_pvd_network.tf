# ------ Create a VPC for AWS private link PROVIDER (acct1_pvd=provider)
resource aws_vpc demo15b_acct1_pvd {
  provider             = aws.acct1
  cidr_block           = var.acct1_pvd_cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo15b-acct1_pvd-vpc" }
}

# ========== Public subnet for bastion and ELB_NLB

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo15b_acct1_pvd {
  provider = aws.acct1
  vpc_id   = aws_vpc.demo15b_acct1_pvd.id
  tags     = { Name = "demo15b-acct1_pvd-igw" }
}

# ------ Create a subnet (use the default route table and default network ACL)
resource aws_subnet demo15b_acct1_pvd_public {
  provider                = aws.acct1
  vpc_id                  = aws_vpc.demo15b_acct1_pvd.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.acct1_pvd_cidr_subnet_public
  map_public_ip_on_launch = true
  tags                    = { Name = "demo15b-acct1_pvd-public" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo15b_acct1_pvd {
  provider               = aws.acct1
  default_route_table_id = aws_vpc.demo15b_acct1_pvd.default_route_table_id
  tags                   = { Name = "demo15b-acct1_pvd-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo15b_acct1_pvd.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules 
#        (will be used by public subnet)
resource aws_default_network_acl demo15b_acct1_pvd {
  provider               = aws.acct1
  default_network_acl_id = aws_vpc.demo15b_acct1_pvd.default_network_acl_id
  tags                   = { Name = "demo15b-acct1_pvd-public-acl" }
  subnet_ids             = [ aws_subnet.demo15b_acct1_pvd_public.id ]

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

  # Allow HTTP access from CONSUMER VPC (via PRIVATELINK)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.acct2_csm_cidr_subnet_public
    from_port  = 80
    to_port    = 80
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

  # allow access from private subnet (needed for traffic thru NAT gateway)
  ingress {
    protocol   = -1
    rule_no    = 400
    action     = "allow"
    cidr_block = var.acct1_pvd_cidr_subnet_private
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

# # ------ Create a new route table
# resource aws_route_table demo15b_acct1_pvd_public {
#   vpc_id = aws_vpc.demo15b_acct1_pvd.id
#   tags   = { Name = "demo15b-acct1_pvd-public-rt" }
  
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.demo15b_acct1_pvd.id
#   }
# }

# # ------ Associate the route table with subnet
# resource aws_route_table_association demo15b_acct1_pvd_public {
#   subnet_id      = aws_subnet.demo15b_acct1_pvd_public.id
#   route_table_id = aws_route_table.demo15b_acct1_pvd_public.id
# }

# ========== Private subnet for web servers

# ------ Create an elastic IP address for the NAT gateway
resource aws_eip demo15b_acct1_pvd_natgw {
  provider = aws.acct1
  domain   = "vpc"
  tags     = { Name = "demo15b-acct1_pvd-natgw" }
}

# ------ Create a NAT gateway
resource aws_nat_gateway demo15b_acct1_pvd {
  provider          = aws.acct1
  connectivity_type = "public"
  allocation_id     = aws_eip.demo15b_acct1_pvd_natgw.id
  subnet_id         = aws_subnet.demo15b_acct1_pvd_public.id
  tags              = { Name = "demo15b-acct1_pvd-natgw" }
}

# ------ Create a new route table
resource aws_route_table demo15b_acct1_pvd_private {
  provider = aws.acct1
  vpc_id   = aws_vpc.demo15b_acct1_pvd.id
  tags     = { Name = "demo15b-acct1_pvd-private-rt" }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo15b_acct1_pvd.id
  }
}

# ------ Create a new network ACL for private subnet
resource aws_network_acl demo15b_acct1_pvd_private {
  provider   = aws.acct1
  vpc_id     = aws_vpc.demo15b_acct1_pvd.id
  tags       = { Name = "demo15b-acct1_pvd-private-acl" }
  subnet_ids = [ aws_subnet.demo15b_acct1_pvd_private.id ]

  # allow all traffic from public subnet
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.acct1_pvd_cidr_subnet_public
    from_port  = 0
    to_port    = 0
  }
  
  # needed
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

  ingress {
    protocol   = "tcp"
    rule_no    = 388
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
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
resource aws_subnet demo15b_acct1_pvd_private {
  provider                = aws.acct1
  vpc_id                  = aws_vpc.demo15b_acct1_pvd.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.acct1_pvd_cidr_subnet_private
  map_public_ip_on_launch = false
  tags                    = { Name = "demo15b-acct1_pvd-private" }
}

# ------ Associate the route table with subnet
resource aws_route_table_association demo15b_acct1_pvd_private {
  provider       = aws.acct1
  subnet_id      = aws_subnet.demo15b_acct1_pvd_private.id
  route_table_id = aws_route_table.demo15b_acct1_pvd_private.id
}