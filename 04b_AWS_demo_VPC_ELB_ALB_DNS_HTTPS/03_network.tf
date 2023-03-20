# ------ Create a VPC 
resource aws_vpc demo04b {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo04b-vpc" }
}

# ========== Public subnets for bastion and ELB_ALB

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo04b-ig {
  vpc_id = aws_vpc.demo04b.id
  tags   = { Name = "demo04b-igw" }
}

# ------ Create a subnet for bastion
resource aws_subnet demo04b_public_bastion {
  vpc_id                  = aws_vpc.demo04b.id
  availability_zone      = "${var.aws_region}${var.bastion_az}"
  cidr_block              = var.cidr_subnet_public_bastion
  map_public_ip_on_launch = true
  tags                    = { Name = "demo04b-public-bastion" }
}

# ------ Create 2 subnets for the ELB
resource aws_subnet demo04b_public_lb {
  count                   = 2
  vpc_id                  = aws_vpc.demo04b.id
  availability_zone       = "${var.aws_region}${var.websrv_az[count.index]}"
  cidr_block              = var.cidr_subnets_public_lb[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo04b-public-lb${count.index+1}" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo04b {
  default_route_table_id = aws_vpc.demo04b.default_route_table_id
  tags   = { Name = "demo04b-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo04b-ig.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo04b {
  default_network_acl_id = aws_vpc.demo04b.default_network_acl_id
  tags                   = { Name = "demo04b-acl" }
  subnet_ids             = [ aws_subnet.demo04b_public_bastion.id, aws_subnet.demo04b_public_lb[0].id, aws_subnet.demo04b_public_lb[1].id ]

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
      from_port  = 443
      to_port    = 443
    }
  }

  dynamic ingress {
    for_each = var.authorized_ips
    content {
      protocol   = "tcp"
      rule_no    = 205 + 10 * index(var.authorized_ips, ingress.value)
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
    for_each = var.cidr_subnets_private_websrv
    content {
      protocol   = -1
      rule_no    = 400 + 10 * index(var.cidr_subnets_private_websrv, ingress.value)
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
# resource aws_route_table demo04b_public {
#   vpc_id = aws_vpc.demo04b.id
#   tags   = { Name = "demo04b-public-rt" }
  
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.demo04b-ig.id
#   }
# }

# # ------ Associate the route table with subnets
# resource aws_route_table_association demo04b_public_bastion {
#   subnet_id      = aws_subnet.demo04b_public_bastion.id
#   route_table_id = aws_route_table.demo04b_public.id
# }

# resource aws_route_table_association demo04b_public_lb {
#   count          = 2
#   subnet_id      = aws_subnet.demo04b_public_lb[count.index].id
#   route_table_id = aws_route_table.demo04b_public.id
# }

# ========== Private subnets for web servers

# ------ Create an elastic IP address for the NAT gateway
resource aws_eip demo04b_natgw {
  vpc      = true
  tags     = { Name = "demo04b-natgw" }
}

# ------ Create a NAT gatewat
resource aws_nat_gateway demo04b {
  connectivity_type = "public"
  allocation_id     = aws_eip.demo04b_natgw.id
  subnet_id         = aws_subnet.demo04b_public_bastion.id
  tags              = { Name = "demo04b-natgw" }
}

# ------ Create a new route table
resource aws_route_table demo04b_private {
  vpc_id = aws_vpc.demo04b.id
  tags   = { Name = "demo04b-private-rt" }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo04b.id
  }
}

# ------ Create a new network ACL for private subnets
resource aws_network_acl demo04b_private {
  vpc_id     = aws_vpc.demo04b.id
  tags       = { Name = "demo04b-private-acl" }
  subnet_ids = [ for subnet in aws_subnet.demo04b_private_websrv: subnet.id ]

  # allow all traffic from vpc
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 0
    to_port    = 0
  }
  
  # # needed
  # dynamic ingress {
  #   for_each = var.authorized_ips
  #   content {
  #     protocol   = "tcp"
  #     rule_no    = 200 + 10 * index(var.authorized_ips, ingress.value)
  #     action     = "allow"
  #     cidr_block = ingress.value
  #     from_port  = 80
  #     to_port    = 80
  #   }
  # }

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
resource aws_subnet demo04b_private_websrv {
  count                   = 2
  vpc_id                  = aws_vpc.demo04b.id
  availability_zone       = "${var.aws_region}${var.websrv_az[count.index]}"
  cidr_block              = var.cidr_subnets_private_websrv[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "demo04b-private-websrv${count.index+1}" }
}

# ------ Associate the route table with subnets
resource aws_route_table_association demo04b_private_websrv {
  count          = 2
  subnet_id      = aws_subnet.demo04b_private_websrv[count.index].id
  route_table_id = aws_route_table.demo04b_private.id
}