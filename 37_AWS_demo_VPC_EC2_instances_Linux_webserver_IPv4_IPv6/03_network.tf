# ------ Create a VPC 
resource aws_vpc demo37 {
  cidr_block                       = var.cidr_vpc
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  tags                             = { Name = "demo37-vpc" }
}

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo37 {
  vpc_id = aws_vpc.demo37.id
  tags   = { Name = "demo37-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo37 {
  default_route_table_id = aws_vpc.demo37.default_route_table_id
  tags                   = { Name = "demo37-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo37.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.demo37.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo37 {
  default_network_acl_id = aws_vpc.demo37.default_network_acl_id
  tags                   = { Name = "demo37-acl" }
  subnet_ids             = [ aws_subnet.demo37_public1.id, aws_subnet.demo37_public2.id ]

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
    for_each = var.authorized_ips_v6
    content {
      protocol        = "tcp"
      rule_no         = 150 + 10 * index(var.authorized_ips_v6, ingress.value)
      action          = "allow"
      ipv6_cidr_block = ingress.value
      from_port       = 22
      to_port         = 22
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

  dynamic ingress {
    for_each = var.authorized_ips_v6
    content {
      protocol        = "tcp"
      rule_no         = 250 + 10 * index(var.authorized_ips_v6, ingress.value)
      action          = "allow"
      ipv6_cidr_block = ingress.value
      from_port       = 80
      to_port         = 80
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

  # allow all IPv6 traffic from the VPC
  ingress {
    protocol        = "all"
    rule_no         = 400
    action          = "allow"
    ipv6_cidr_block = aws_vpc.demo37.ipv6_cidr_block
    from_port       = 0
    to_port         = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol        = -1
    rule_no         = 200
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }
}

# ------ Create public subnets (use the default route table and default network ACL)
resource aws_subnet demo37_public1 {
  vpc_id                          = aws_vpc.demo37.id
  availability_zone               = "${var.aws_region}${var.az1}"
  cidr_block                      = var.cidr_subnet1
  map_public_ip_on_launch         = true
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.demo37.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation = true
  tags                            = { Name = "demo37-public1" }
}

resource aws_subnet demo37_public2 {
  vpc_id                          = aws_vpc.demo37.id
  availability_zone               = "${var.aws_region}${var.az2}"
  cidr_block                      = var.cidr_subnet2
  map_public_ip_on_launch         = true
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.demo37.ipv6_cidr_block, 8, 2)
  assign_ipv6_address_on_creation = true
  tags                            = { Name = "demo37-public2" }
}

# ------ Customize the security group for the EC2 instances
resource aws_default_security_group demo37 {
  vpc_id      = aws_vpc.demo37.id
  tags        = { Name = "demo37-sg1" }

  # -- IP v4

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP v4 addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
  }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTP access from authorized public IP v4 addresses"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
  }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  # -- IP v6

  # ingress rule: allow SSH
  ingress {
    description      = "allow SSH access from authorized public IP v6 addresses"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = var.authorized_ips_v6
  }

  # ingress rule: allow HTTP
  ingress {
    description      = "allow HTTP access from authorized public IP v6 addresses"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = var.authorized_ips_v6
  }

  # # ingress rule: allow ping6
  # ingress {
  #   description      = "allow ICMPv6 access from the VPC (allow ping6 between instances)"
  #   from_port        = 0
  #   to_port          = 0
  #   protocol         = "icmpv6"
  #   ipv6_cidr_blocks = [ aws_vpc.demo37.ipv6_cidr_block ]
  # }

  # ingress rule: allow ping6
  ingress {
    description      = "allow all IPv6 traffic from the VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    ipv6_cidr_blocks = [ aws_vpc.demo37.ipv6_cidr_block ]
  }

  # egress rule: allow all traffic
  egress {
    description      = "allow all traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"    # all protocols
    ipv6_cidr_blocks = [ "::/0" ]
  }
}
