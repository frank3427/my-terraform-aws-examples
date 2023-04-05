# ------ Create a VPC 
resource aws_vpc demo06b_2 {
  cidr_block           = var.cidr_vpc2
  enable_dns_hostnames = true
  tags                 = { Name = "demo06b-vpc2" }
}

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo06b_2 {
  vpc_id = aws_vpc.demo06b_2.id
  tags   = { Name = "demo06b-igw2" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo06b_2 {
  default_route_table_id = aws_vpc.demo06b_2.default_route_table_id
  tags                   = { Name = "demo06b-rt2" }

  route {
    cidr_block = var.cidr_public3
    gateway_id = aws_ec2_transit_gateway.demo06b.id
  }

  route {
    cidr_block = var.cidr_public1
    gateway_id = aws_ec2_transit_gateway.demo06b.id
  }
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo06b_2.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo06b_2 {
  default_network_acl_id = aws_vpc.demo06b_2.default_network_acl_id
  tags                   = { Name = "demo06b-acl2" }
  subnet_ids             = [ aws_subnet.demo06b_public2.id ]

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

  ingress {
    protocol   = -1 # all
    rule_no    = 301
    action     = "allow"
    cidr_block = var.cidr_vpc1
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = -1 # all
    rule_no    = 303
    action     = "allow"
    cidr_block = var.cidr_vpc3
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

# ------ Create a subnet (use the default route table and default network ACL)
resource aws_subnet demo06b_public2 {
  vpc_id                  = aws_vpc.demo06b_2.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_public2
  map_public_ip_on_launch = true
  tags                    = { Name = "demo06b-public2" }
}

# ------ Create a security group for the EC2 instance
resource aws_security_group demo06b_sg2 {
  name        = "demo06b-sg2"
  description = "Description for demo06b-sg2"
  vpc_id      = aws_vpc.demo06b_2.id
  tags        = { Name = "demo06b-sg2" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
  }

  # ingress rule: allow traffic from other VPCs
  ingress {
    description = "allow traffic from other VPCs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ var.cidr_public1, var.cidr_public2, var.cidr_public3 ]
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

# ------ Transit gateway attachment to VPC
resource aws_ec2_transit_gateway_vpc_attachment demo06b_2 {
  subnet_ids         = [ aws_subnet.demo06b_public2.id ]
  transit_gateway_id = aws_ec2_transit_gateway.demo06b.id
  vpc_id             = aws_vpc.demo06b_2.id
}