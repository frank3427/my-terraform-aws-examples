# ------ Create a VPC 
resource aws_vpc demo23 {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo23-vpc" }
}

# ========== Resources for public subnets

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo23 {
  vpc_id = aws_vpc.demo23.id
  tags   = { Name = "demo23-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo23 {
  default_route_table_id = aws_vpc.demo23.default_route_table_id
  tags                   = { Name = "demo23-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo23.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo23 {
  default_network_acl_id = aws_vpc.demo23.default_network_acl_id
  tags                   = { Name = "demo23-acl" }
  subnet_ids             = [ for subnet in aws_subnet.demo23_public: subnet.id ]

  dynamic ingress {
    for_each = var.authorized_ips
    content {
      protocol   = "tcp"
      rule_no    = 100 + 10 * index(var.authorized_ips, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 80
      to_port    = 80
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

# ------ Create 3 public subnets (1 per AZ) (use the default route table and default network ACL)
locals {
  azs = ["a","b","c"]
}

resource aws_subnet demo23_public {
  count                   = 3
  vpc_id                  = aws_vpc.demo23.id
  availability_zone       = "${var.aws_region}${local.azs[count.index]}"
  cidr_block              = var.cidr_subnets_public[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo23-public-az-${local.azs[count.index]}" }
}

# ------ Customize the default security group
resource aws_default_security_group demo23 {
  vpc_id      = aws_vpc.demo23.id
  tags        = { Name = "demo23-sg1" }

  # # ingress rule: allow HTTP
  # ingress {
  #   description = "allow HTTP access from authorized public IP addresses"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = var.authorized_ips
  # }

  ingress {
    description = "allow HTTP access from authorized public IP addresses"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

# ========== Resources for private subnets

# ------ Create an elastic IP address for the NAT gateway
resource aws_eip demo23_natgw {
  domain   = "vpc"
  tags     = { Name = "demo23-natgw" }
}

# ------ Create a NAT gateway
resource aws_nat_gateway demo23 {
  connectivity_type = "public"
  allocation_id     = aws_eip.demo23_natgw.id
  subnet_id         = aws_subnet.demo23_public[0].id
  tags              = { Name = "demo23-natgw" }
}

# ------ Create a new route table
resource aws_route_table demo23_private {
  vpc_id = aws_vpc.demo23.id
  tags   = { Name = "demo23-private-rt" }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo23.id
    # nat_gateway_id = aws_nat_gateway.demo23.id
  }
}

# ------ Create a new network ACL for private subnets
resource aws_network_acl demo23_private {
  vpc_id     = aws_vpc.demo23.id
  tags       = { Name = "demo23-private-acl" }
  subnet_ids = [ for subnet in aws_subnet.demo23_private: subnet.id ]

  # allow all traffic from vpc
  ingress {
    protocol   = -1
    rule_no    = 50
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 0
    to_port    = 0
  }

  dynamic ingress {
    for_each = var.authorized_ips
    content {
      protocol   = "tcp"
      rule_no    = 100 + 10 * index(var.authorized_ips, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 80
      to_port    = 80
    }
  }

  # # this is needed for yum
  # ingress {
  #   protocol   = "tcp"
  #   rule_no    = 300
  #   action     = "allow"
  #   cidr_block = "0.0.0.0/0"
  #   from_port  = 1024
  #   to_port    = 65535
  # }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# ------ Create 3 private subnets (1 per AZ)
resource aws_subnet demo23_private {
  count                   = 3
  vpc_id                  = aws_vpc.demo23.id
  availability_zone       = "${var.aws_region}${local.azs[count.index]}"
  cidr_block              = var.cidr_subnets_private[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo23-public2-az-${local.azs[count.index]}" }
}

# ------ Associate the route table with subnets
resource aws_route_table_association demo23_private {
  count          = 3
  subnet_id      = aws_subnet.demo23_private[count.index].id
  route_table_id = aws_route_table.demo23_private.id
}

# ------ Create a security group
resource aws_security_group demo23_sg2 {
  name        = "demo23-sg2"
  description = "Description for demo23-sg2"
  vpc_id      = aws_vpc.demo23.id
  tags        = { Name = "demo23-sg2" }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTP access from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_vpc ]
  }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}



