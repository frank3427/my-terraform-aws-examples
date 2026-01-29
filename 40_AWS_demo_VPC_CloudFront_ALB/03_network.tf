# ------ Create a VPC 
resource aws_vpc demo40 {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo40-vpc" }
}


# ========== Public subnet for bastion host

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo40-ig {
  vpc_id = aws_vpc.demo40.id
  tags   = { Name = "demo40-igw" }
}

# ------ Create a subnet for bastion
resource aws_subnet demo40_public_bastion {
  vpc_id                  = aws_vpc.demo40.id
  availability_zone      = "${var.aws_region}${var.bastion_az}"
  cidr_block              = var.cidr_subnet_public_bastion
  map_public_ip_on_launch = true
  tags                    = { Name = "demo40-public-bastion" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo40 {
  default_route_table_id = aws_vpc.demo40.default_route_table_id
  tags   = { Name = "demo40-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo40-ig.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo40 {
  default_network_acl_id = aws_vpc.demo40.default_network_acl_id
  tags                   = { Name = "demo40-acl" }
  subnet_ids             = [ aws_subnet.demo40_public_bastion.id ]

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
  
  # allow access from private subnets (needed for traffic thru NAT gateway)
  dynamic ingress {
    for_each = var.cidr_subnets_private_websrv
    content {
      protocol   = -1
      rule_no    = 300 + 10 * index(var.cidr_subnets_private_websrv, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 0  
      to_port    = 0
    } 
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
# resource aws_route_table demo40_public {
#   vpc_id = aws_vpc.demo40.id
#   tags   = { Name = "demo40-public-rt" }
  
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.demo40-ig.id
#   }
# }

# # ------ Associate the route table with subnets
# resource aws_route_table_association demo40_public_bastion {
#   subnet_id      = aws_subnet.demo40_public_bastion.id
#   route_table_id = aws_route_table.demo40_public.id
# }

# resource aws_route_table_association demo40_public_lb {
#   count          = 2
#   subnet_id      = aws_subnet.demo40_public_lb[count.index].id
#   route_table_id = aws_route_table.demo40_public.id
# }

# ========== Public subnets for ALB

# ------ Create a new network ACL for ALB public subnets
resource aws_network_acl demo40_private_alb {
  vpc_id     = aws_vpc.demo40.id
  tags       = { Name = "demo40-public-alb-acl" }
  subnet_ids = [ for subnet in aws_subnet.demo40_public_alb: subnet.id ]

  # allow all traffic 
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"  # var.cidr_vpc
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

# ------ Create 2 public subnets for the ALB, using default route table
resource aws_subnet demo40_public_alb {
  count                   = 2
  vpc_id                  = aws_vpc.demo40.id
  availability_zone       = "${var.aws_region}${var.websrv_az[count.index]}"
  cidr_block              = var.cidr_subnets_public_lb[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo40-public-lb${count.index+1}" }
}

# ========== Private subnets for web servers

# ------ Create an elastic IP address for the NAT gateway
resource aws_eip demo40_natgw {
  domain   = "vpc"
  tags     = { Name = "demo40-natgw" }
}

# ------ Create a NAT gateway
resource aws_nat_gateway demo40 {
  connectivity_type = "public"
  allocation_id     = aws_eip.demo40_natgw.id
  subnet_id         = aws_subnet.demo40_public_bastion.id
  tags              = { Name = "demo40-natgw" }
}

# ------ Create a new route table
resource aws_route_table demo40_private {
  vpc_id = aws_vpc.demo40.id
  tags   = { Name = "demo40-private-rt" }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo40.id
  }
}

# ------ Create a new network ACL for WebServer private subnets
resource aws_network_acl demo40_private_websrv {
  vpc_id     = aws_vpc.demo40.id
  tags       = { Name = "demo40-private-websrv-acl" }
  subnet_ids = [ for subnet in aws_subnet.demo40_private_websrv: subnet.id ]

  # allow all traffic from vpc
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 0
    to_port    = 0
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

# ------ Create 2 private subnets for the 2 web servers
resource aws_subnet demo40_private_websrv {
  count                   = 2
  vpc_id                  = aws_vpc.demo40.id
  availability_zone       = "${var.aws_region}${var.websrv_az[count.index]}"
  cidr_block              = var.cidr_subnets_private_websrv[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "demo40-private-websrv-${var.websrv_az[count.index]}" }
}

# ------ Associate the route table with web servers subnets
resource aws_route_table_association demo40_private_websrv {
  count          = 2
  subnet_id      = aws_subnet.demo40_private_websrv[count.index].id
  route_table_id = aws_route_table.demo40_private.id
}

