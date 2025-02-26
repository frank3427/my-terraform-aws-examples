# ------ Create a VPC for AWS private link CONSUMER (acct2_csm=consumer)
resource aws_vpc demo15c_acct2_csm {
  provider             = aws.acct2
  cidr_block           = var.acct2_csm_cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo15c-acct2_csm-vpc" }
}

# ========== Public subnet for bastion 

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo15c_acct2_csm {
  provider = aws.acct2
  vpc_id   = aws_vpc.demo15c_acct2_csm.id
  tags     = { Name = "demo15c-acct2_csm-igw" }
}

# ------ Create a subnet (use the default route table and default network ACL)
resource aws_subnet demo15c_acct2_csm_public {
  provider                = aws.acct2
  vpc_id                  = aws_vpc.demo15c_acct2_csm.id
  availability_zone       = "${var.acct2_region}${var.acct2_az}"
  cidr_block              = var.acct2_csm_cidr_subnet_public
  map_public_ip_on_launch = true
  tags                    = { Name = "demo15c-acct2_csm-public" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo15c_acct2_csm {
  provider               = aws.acct2
  default_route_table_id = aws_vpc.demo15c_acct2_csm.default_route_table_id
  tags                   = { Name = "demo15c-acct2_csm-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo15c_acct2_csm.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules 
#        (will be used by public subnet)
resource aws_default_network_acl demo15c_acct2_csm {
  provider               = aws.acct2
  default_network_acl_id = aws_vpc.demo15c_acct2_csm.default_network_acl_id
  tags                   = { Name = "demo15c-acct2_csm-public-acl" }
  subnet_ids             = [ aws_subnet.demo15c_acct2_csm_public.id ]

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
# resource aws_route_table demo15c_acct2_csm_public {
#   vpc_id = aws_vpc.demo15c_acct2_csm.id
#   tags   = { Name = "demo15c-acct2_csm-public-rt" }
  
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.demo15c_acct2_csm.id
#   }
# }

# # ------ Associate the route table with subnet
# resource aws_route_table_association demo15c_acct2_csm_public {
#   subnet_id      = aws_subnet.demo15c_acct2_csm_public.id
#   route_table_id = aws_route_table.demo15c_acct2_csm_public.id
# }
