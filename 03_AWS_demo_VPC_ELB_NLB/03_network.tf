# ------ Create a VPC 
resource aws_vpc demo03 {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo03-vpc" }
}

# ========== Public subnet for bastion and ELB_NLB

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo03-ig {
  vpc_id = aws_vpc.demo03.id
  tags   = { Name = "demo03-igw" }
}

# ------ Create a subnet (use the default route table and default network ACL)
resource aws_subnet demo03_public {
  vpc_id                  = aws_vpc.demo03.id
  availability_zone      = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet_public
  map_public_ip_on_launch = true
  tags                    = { Name = "demo03-public" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo03 {
  default_route_table_id = aws_vpc.demo03.default_route_table_id
  tags   = { Name = "demo03-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo03-ig.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo03 {
  default_network_acl_id = aws_vpc.demo03.default_network_acl_id
  tags                   = { Name = "demo03-acl" }
  subnet_ids             = [ aws_subnet.demo03_public.id ]

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
    rule_no    = 150
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
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
# resource aws_route_table demo03_public {
#   vpc_id = aws_vpc.demo03.id
#   tags   = { Name = "demo03-public-rt" }
  
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.demo03-ig.id
#   }
# }

# # ------ Associate the route table with subnet
# resource aws_route_table_association demo03_public {
#   subnet_id      = aws_subnet.demo03_public.id
#   route_table_id = aws_route_table.demo03_public.id
# }

# ========== Private subnet for web servers

# ------ Create an elastic IP address for the NAT gateway
resource aws_eip demo03_natgw {
  vpc      = true
  tags     = { Name = "demo03-natgw" }
}

# ------ Create a NAT gatewat
resource aws_nat_gateway demo03 {
  connectivity_type = "public"
  allocation_id     = aws_eip.demo03_natgw.id
  subnet_id         = aws_subnet.demo03_public.id
  tags              = { Name = "demo03-natgw" }
}

# ------ Create a new route table
resource aws_route_table demo03_private {
  vpc_id = aws_vpc.demo03.id
  tags   = { Name = "demo03-private-rt" }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo03.id
  }
}

# ------ Create the private subnet
resource aws_subnet demo03_private {
  vpc_id                  = aws_vpc.demo03.id
  availability_zone      = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet_private
  map_public_ip_on_launch = false
  tags                    = { Name = "demo03-private" }
}

# ------ Associate the route table with subnet
resource aws_route_table_association demo03_private {
  subnet_id      = aws_subnet.demo03_private.id
  route_table_id = aws_route_table.demo03_private.id
}