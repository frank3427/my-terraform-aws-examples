# ------ Create a VPC 
resource "aws_vpc" "demo41" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo41-vpc" }
}


# ========== 2 Public subnets for bastion host and public ALB

# ------ Create an internet gateway in the new VPC
resource "aws_internet_gateway" "demo41-ig" {
  vpc_id = aws_vpc.demo41.id
  tags   = { Name = "demo41-igw" }
}

# ------ Create 2 public subnets
resource "aws_subnet" "demo41_public" {
  count                   = 2
  vpc_id                  = aws_vpc.demo41.id
  availability_zone       = "${var.aws_region}${var.az[count.index]}"
  cidr_block              = var.cidr_subnet_public[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo41-public-${var.az[count.index]}" }
}

# ------ Add a name and route rule to the default route table
resource "aws_default_route_table" "demo41" {
  default_route_table_id = aws_vpc.demo41.default_route_table_id
  tags                   = { Name = "demo41-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo41-ig.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource "aws_default_network_acl" "demo41" {
  default_network_acl_id = aws_vpc.demo41.default_network_acl_id
  tags                   = { Name = "demo41-acl" }
  subnet_ids             = [for subnet in aws_subnet.demo41_public : subnet.id]

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

  dynamic "ingress" {
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

  # allow HTTP access from test EIP
  ingress {
    protocol   = "tcp"
    rule_no    = 250
    action     = "allow"
    cidr_block = "${aws_eip.demo41_test.public_ip}/32"
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

  # allow access from private subnets (needed for traffic thru NAT gateway)
  dynamic "ingress" {
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
# resource aws_route_table demo41_public {
#   vpc_id = aws_vpc.demo41.id
#   tags   = { Name = "demo41-public-rt" }

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.demo41-ig.id
#   }
# }

# # ------ Associate the route table with subnets
# resource aws_route_table_association demo41_public_bastion {
#   subnet_id      = aws_subnet.demo41_public_bastion.id
#   route_table_id = aws_route_table.demo41_public.id
# }

# resource aws_route_table_association demo41_public_lb {
#   count          = 2
#   subnet_id      = aws_subnet.demo41_public_lb[count.index].id
#   route_table_id = aws_route_table.demo41_public.id
# }

# ========== Private subnets for ALB and web servers

# ------ Create an elastic IP address for the NAT gateway
resource "aws_eip" "demo41_natgw" {
  domain = "vpc"
  tags   = { Name = "demo41-natgw" }
}

# ------ Create a NAT gateway
resource "aws_nat_gateway" "demo41" {
  connectivity_type = "public"
  allocation_id     = aws_eip.demo41_natgw.id
  subnet_id         = aws_subnet.demo41_public[0].id
  tags              = { Name = "demo41-natgw" }
}

# ------ Create a new route table
resource "aws_route_table" "demo41_private" {
  vpc_id = aws_vpc.demo41.id
  tags   = { Name = "demo41-private-rt" }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo41.id
  }
}

# ------ Create a new network ACL for ALB private subnets
resource "aws_network_acl" "demo41_private_alb" {
  vpc_id     = aws_vpc.demo41.id
  tags       = { Name = "demo41-private-alb-acl" }
  subnet_ids = [for subnet in aws_subnet.demo41_private_alb : subnet.id]

  # allow all traffic 
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0" # var.cidr_vpc
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

# ------ Create a new network ACL for WebServer private subnets
resource "aws_network_acl" "demo41_private_websrv" {
  vpc_id     = aws_vpc.demo41.id
  tags       = { Name = "demo41-private-websrv-acl" }
  subnet_ids = [for subnet in aws_subnet.demo41_private_websrv : subnet.id]

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

# ------ Create 2 private subnets for the ALB
resource "aws_subnet" "demo41_private_alb" {
  count                   = 2
  vpc_id                  = aws_vpc.demo41.id
  availability_zone       = "${var.aws_region}${var.az[count.index]}"
  cidr_block              = var.cidr_subnets_private_lb[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "demo41-private-lb${count.index + 1}" }
}

# ------ Create 2 private subnets for the 2 web servers
resource "aws_subnet" "demo41_private_websrv" {
  count                   = 2
  vpc_id                  = aws_vpc.demo41.id
  availability_zone       = "${var.aws_region}${var.az[count.index]}"
  cidr_block              = var.cidr_subnets_private_websrv[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "demo41-private-websrv-${var.az[count.index]}" }
}

# ------ Associate the route table with ALB subnets
resource "aws_route_table_association" "demo41_private_alb" {
  count          = 2
  subnet_id      = aws_subnet.demo41_private_alb[count.index].id
  route_table_id = aws_route_table.demo41_private.id
}

# ------ Associate the route table with Web Server subnets
resource "aws_route_table_association" "demo41_private_websrv" {
  count          = 2
  subnet_id      = aws_subnet.demo41_private_websrv[count.index].id
  route_table_id = aws_route_table.demo41_private.id
}
