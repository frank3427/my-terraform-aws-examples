# ------ Create a VPC 
resource aws_vpc demo43 {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo43-vpc" }
}

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo43 {
  vpc_id = aws_vpc.demo43.id
  tags   = { Name = "demo43-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo43 {
  default_route_table_id = aws_vpc.demo43.default_route_table_id
  tags                   = { Name = "demo43-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo43.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo43 {
  default_network_acl_id = aws_vpc.demo43.default_network_acl_id
  tags                   = { Name = "demo43-acl1" }
  subnet_ids             = [ aws_subnet.demo43_public1.id ]

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

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# ------ Create a second Network ACL for the HTTP subnet
resource aws_network_acl demo43_acl2 {
  vpc_id     = aws_vpc.demo43.id
  tags       = { Name = "demo43-acl2" }
  subnet_ids = [ aws_subnet.demo43_public2.id ]

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

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 80
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

# ------ Create a public subnet for SSH (use the default route table and default network ACL)
resource aws_subnet demo43_public1 {
  vpc_id                  = aws_vpc.demo43.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet1
  map_public_ip_on_launch = true
  tags                    = { Name = "demo43-public1-ssh" }
}

# ------ Create a public subnet for HTTP (use the default route table and specific network ACL)
resource aws_subnet demo43_public2 {
  vpc_id                  = aws_vpc.demo43.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet2
  map_public_ip_on_launch = true
  tags                    = { Name = "demo43-public2-http" }
}

# ------ Associate new network ACL with HTTP subnet
resource aws_network_acl_association demo43_public2 {
  network_acl_id = aws_network_acl.demo43_acl2.id
  subnet_id      = aws_subnet.demo43_public2.id
}

# ------ Customize the default security group for the primary ENI of EC2 instance (SSH)
resource aws_default_security_group demo43_sg1 {
  vpc_id      = aws_vpc.demo43.id
  tags        = { Name = "demo43-sg1" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses"
    from_port   = 22
    to_port     = 22
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
}

# ------ Create a new security group for the secondary ENI of EC2 instance (HTTP)
resource aws_security_group demo43_sg2 {
  vpc_id      = aws_vpc.demo43.id
  name        = "demo43-sg2"
  tags        = { Name = "demo43-sg2" }

  # ingress rule: allow SSH
  ingress {
    description = "allow HTTP access from authorized public IP addresses"
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
}
