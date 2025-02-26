## see https://repost.aws/knowledge-center/ec2-systems-manager-vpc-endpoints

# ------ Create a VPC 
resource aws_vpc demo20b {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo20b-vpc" }
}

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo20b {
  vpc_id = aws_vpc.demo20b.id
  tags   = { Name = "demo20b-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo20b {
  default_route_table_id = aws_vpc.demo20b.default_route_table_id
  tags                   = { Name = "demo20b-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo20b.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo20b {
  default_network_acl_id = aws_vpc.demo20b.default_network_acl_id
  tags                   = { Name = "demo20b-public-acl" }
  subnet_ids             = [ aws_subnet.demo20b_public.id ]

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

  # ingress {
  #   protocol   = -1
  #   rule_no    = 100
  #   action     = "allow"
  #   cidr_block = "0.0.0.0/0"
  #   from_port  = 0
  #   to_port    = 0
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

# ------ Create a subnet (use the default route table and default network ACL)
resource aws_subnet demo20b_public {
  vpc_id                  = aws_vpc.demo20b.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet1
  map_public_ip_on_launch = true
  tags                    = { Name = "demo20b-public" }
}

# ------ Customize the security group for the EC2 instance
resource aws_default_security_group demo20b {
  vpc_id      = aws_vpc.demo20b.id
  tags        = { Name = "demo20b-sg1" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses and VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(var.authorized_ips, [ var.cidr_vpc ])
  }

  # ingress rule: allow HTTPS for Systems Manager
  ingress {
    description = "allow HTTPS access from VPC (required by Systems Manager)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_vpc ]
  }

  # ingress {
  #   description = "allow all"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = -1
  #   cidr_blocks = [ "0.0.0.0/0" ]
  # }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

# ========== Private subnets for web servers

# ------ Create an elastic IP address for the NAT gateway
resource aws_eip demo20b_natgw {
  domain   = "vpc"
  tags     = { Name = "demo20b-natgw" }
}

# ------ Create a NAT gateway
resource aws_nat_gateway demo20b {
  connectivity_type = "public"
  allocation_id     = aws_eip.demo20b_natgw.id
  subnet_id         = aws_subnet.demo20b_public.id
  tags              = { Name = "demo20b-natgw" }
}

# ------ Create a new route table
resource aws_route_table demo20b_private {
  vpc_id = aws_vpc.demo20b.id
  tags   = { Name = "demo20b-private-rt" }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo20b.id
  }
}

# ------ Create a new network ACL for private subnet
resource aws_network_acl demo20b_private {
  vpc_id     = aws_vpc.demo20b.id
  tags       = { Name = "demo20b-private-acl" }
  subnet_ids = [ aws_subnet.demo20b_private.id ]

  # allow all traffic from vpc
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 22
    to_port    = 22
  }

  # needed
  dynamic ingress {
    for_each = var.authorized_ips
    content {
      protocol   = "tcp"
      rule_no    = 200 + 10 * index(var.authorized_ips, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 22
      to_port    = 22
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

  # this is needed for Systems Manager
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 443
    to_port    = 443
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

# ------ Create 1 private subnet
resource aws_subnet demo20b_private {
  vpc_id                  = aws_vpc.demo20b.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnets_private
  map_public_ip_on_launch = false
  tags                    = { Name = "demo20b-private" }
}

# ------ Associate the route table with subnet
resource aws_route_table_association demo20b_private {
  subnet_id      = aws_subnet.demo20b_private.id
  route_table_id = aws_route_table.demo20b_private.id
}

# ------ Create endpoints for System Manager
locals {
  ssm_endp = [ "ssm", "ec2messages", "ssmmessages"]
}

resource aws_vpc_endpoint demo20b_ssm {
  count               = length(local.ssm_endp)  
  vpc_id              = aws_vpc.demo20b.id
  service_name        = "com.amazonaws.${var.aws_region}.${local.ssm_endp[count.index]}" 
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  tags                = { Name = "demo20b-${local.ssm_endp[count.index]}" }
  subnet_ids          = [ aws_subnet.demo20b_private.id ]
  security_group_ids  = [ aws_default_security_group.demo20b.id ]
}
