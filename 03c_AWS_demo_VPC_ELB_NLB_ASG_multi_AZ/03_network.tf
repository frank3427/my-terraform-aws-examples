# ------ Create a VPC 
resource aws_vpc demo03c {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo03c-vpc" }
}

# ========== Public subnets for bastion and ELB_NLB

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo03c-ig {
  vpc_id = aws_vpc.demo03c.id
  tags   = { Name = "demo03c-igw" }
}

# ------ Create 1 public subnet per AZ, needed for mulmlti-AZ NLB (use the default route table and default network ACL)
resource aws_subnet demo03c_public {
  count                   = var.nb_az
  vpc_id                  = aws_vpc.demo03c.id
  availability_zone       = "${var.aws_region}${var.az[count.index]}"
  cidr_block              = var.cidr_subnet_public[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo03c-public-az-${var.az[count.index]}" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo03c {
  default_route_table_id = aws_vpc.demo03c.default_route_table_id
  tags   = { Name = "demo03c-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo03c-ig.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
#        (will be used by public subnet)
resource aws_default_network_acl demo03c {
  default_network_acl_id = aws_vpc.demo03c.default_network_acl_id
  tags                   = { Name = "demo03c-acl" }
  subnet_ids             = [ for subnet in aws_subnet.demo03c_public: subnet.id ]
 
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

  # allow access from private subnets (needed for traffic thru NAT gateway)

  dynamic ingress {
    for_each = var.cidr_subnet_private
    content {
      protocol   = "all"
      rule_no    = 400 + 10 * index(var.cidr_subnet_private, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 0
      to_port    = 0
    }
  }

  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# # ------ Create a new route table
# resource aws_route_table demo03b_public {
#   vpc_id = aws_vpc.demo03b.id
#   tags   = { Name = "demo03b-public-rt" }
  
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.demo03b-ig.id
#   }
# }

# # ------ Associate the route table with subnet
# resource aws_route_table_association demo03b_public {
#   subnet_id      = aws_subnet.demo03b_public.id
#   route_table_id = aws_route_table.demo03b_public.id
# }

# ========== Private subnets for web servers

# ------ Create elastic IP addresses for the NAT gateways (1 per AZ/NAT gateway)
resource aws_eip demo03c_natgw {
  count    = var.nb_az
  domain   = "vpc"
  tags     = { Name = "demo03c-natgw-az-${var.az[count.index]}" }
}

# ------ Create NAT gateways (1 per AZ)
resource aws_nat_gateway demo03c {
  count             = var.nb_az
  connectivity_type = "public"
  allocation_id     = aws_eip.demo03c_natgw[count.index].id
  subnet_id         = aws_subnet.demo03c_public[count.index].id
  tags              = { Name = "demo03c-natgw-az-${var.az[count.index]}" }
}

# ------ Create new route tables (1 per AZ)
resource aws_route_table demo03c_private {
  count  = var.nb_az
  vpc_id = aws_vpc.demo03c.id
  tags   = { Name = "demo03c-private-rt-az-${var.az[count.index]}" }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo03c[count.index].id
  }
}

# ------ Create a new network ACL for private subnets
resource aws_network_acl demo03c_private {
  vpc_id     = aws_vpc.demo03c.id
  tags       = { Name = "demo03c-private-acl" }
  subnet_ids = [ for subnet in aws_subnet.demo03c_private: subnet.id ]
  
  # allow all traffic from public subnets
  dynamic ingress {
    for_each = var.cidr_subnet_public
    content {
      protocol   = "all"
      rule_no    = 100 + 10 * index(var.cidr_subnet_public, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 0
      to_port    = 0
    }
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

  # this is needed for Session Manager
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# ------ Create the private subnets (1 per AZ)
resource aws_subnet demo03c_private {
  count                   = var.nb_az
  vpc_id                  = aws_vpc.demo03c.id
  availability_zone       = "${var.aws_region}${var.az[count.index]}"
  cidr_block              = var.cidr_subnet_private[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "demo03c-private-az-${var.az[count.index]}" }
}

# ------ Associate the route tables with private subnets
resource aws_route_table_association demo03c_private {
  count          = var.nb_az        
  subnet_id      = aws_subnet.demo03c_private[count.index].id
  route_table_id = aws_route_table.demo03c_private[count.index].id
}