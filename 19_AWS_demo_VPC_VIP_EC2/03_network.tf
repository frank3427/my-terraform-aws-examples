# ------ Create a VPC 
resource aws_vpc demo19 {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo19-vpc" }
}

# ========== Public subnets 

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo19-ig {
  vpc_id = aws_vpc.demo19.id
  tags   = { Name = "demo19-igw" }
}

# ------ Create a subnet for bastion
resource aws_subnet demo19_public {
  vpc_id                  = aws_vpc.demo19.id
  availability_zone      = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet_public
  map_public_ip_on_launch = true
  tags                    = { Name = "demo19-public-bastion" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo19 {
  default_route_table_id = aws_vpc.demo19.default_route_table_id
  tags   = { Name = "demo19-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo19-ig.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo19 {
  default_network_acl_id = aws_vpc.demo19.default_network_acl_id
  tags                   = { Name = "demo19-acl" }
  subnet_ids             = [ aws_subnet.demo19_public.id ]

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
# resource aws_route_table demo19_public {
#   vpc_id = aws_vpc.demo19.id
#   tags   = { Name = "demo19-public-rt" }
  
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.demo19-ig.id
#   }
# }

# # ------ Associate the route table with subnets
# resource aws_route_table_association demo19_public_bastion {
#   subnet_id      = aws_subnet.demo19_public_bastion.id
#   route_table_id = aws_route_table.demo19_public.id
# }

# resource aws_route_table_association demo19_public_lb {
#   count          = 2
#   subnet_id      = aws_subnet.demo19_public_lb[count.index].id
#   route_table_id = aws_route_table.demo19_public.id
# }
