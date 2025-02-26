# ------ Create a VPC 
resource aws_vpc demo38 {
  cidr_block                       = var.cidr_vpc
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  tags                             = { Name = "demo38-vpc" }
}

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo38 {
  vpc_id = aws_vpc.demo38.id
  tags   = { Name = "demo38-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo38 {
  default_route_table_id = aws_vpc.demo38.default_route_table_id
  tags                   = { Name = "demo38-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo38.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.demo38.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo38 {
  default_network_acl_id = aws_vpc.demo38.default_network_acl_id
  tags                   = { Name = "demo38-acl" }
  subnet_ids             = [ aws_subnet.demo38_public1.id, aws_subnet.demo38_public2.id ]

  dynamic ingress {
    for_each = var.authorized_ips_v6
    content {
      protocol        = "tcp"
      rule_no         = 100 + 10 * index(var.authorized_ips_v6, ingress.value)
      action          = "allow"
      ipv6_cidr_block = ingress.value
      from_port       = 22
      to_port         = 22
    }
  }
  
  dynamic ingress {
    for_each = var.authorized_ips_v6
    content {
      protocol        = "tcp"
      rule_no         = 200 + 10 * index(var.authorized_ips_v6, ingress.value)
      action          = "allow"
      ipv6_cidr_block = ingress.value
      from_port       = 80
      to_port         = 80
    }
  }

  # this is needed for yum
  ingress {
    protocol        = "tcp"
    rule_no         = 300
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 1024
    to_port         = 65535
  }

  # allow all IPv6 traffic from the VPC
  ingress {
    protocol        = "all"
    rule_no         = 400
    action          = "allow"
    ipv6_cidr_block = aws_vpc.demo38.ipv6_cidr_block
    from_port       = 0
    to_port         = 0
  }

  egress {
    protocol        = -1
    rule_no         = 100
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }
}

# ------ Create public subnets using only IPv6 (use the default route table and default network ACL)
resource aws_subnet demo38_public1 {
  vpc_id                                         = aws_vpc.demo38.id
  availability_zone                              = "${var.aws_region}${var.az1}"
  ipv6_native                                    = true
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.demo38.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation                = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  tags                                           = { Name = "demo38-public1" }
}

resource aws_subnet demo38_public2 {
  vpc_id                                         = aws_vpc.demo38.id
  availability_zone                              = "${var.aws_region}${var.az2}"
  ipv6_native                                    = true
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.demo38.ipv6_cidr_block, 8, 2)
  assign_ipv6_address_on_creation                = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  tags                                           = { Name = "demo38-public2" }
}

# ------ Customize the security group for the EC2 instances
resource aws_default_security_group demo38 {
  vpc_id      = aws_vpc.demo38.id
  tags        = { Name = "demo38-sg1" }

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
  #   ipv6_cidr_blocks = [ aws_vpc.demo38.ipv6_cidr_block ]
  # }

  # ingress rule: allow IPv6
  ingress {
    description      = "allow all IPv6 traffic from the VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    ipv6_cidr_blocks = [ aws_vpc.demo38.ipv6_cidr_block ]
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
