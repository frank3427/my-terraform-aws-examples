# ------ Create a VPC 
resource aws_vpc demo17 {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo17-vpc" }
}

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo17 {
  vpc_id = aws_vpc.demo17.id
  tags   = { Name = "demo17-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo17 {
  default_route_table_id = aws_vpc.demo17.default_route_table_id
  tags                   = { Name = "demo17-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo17.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo17 {
  default_network_acl_id = aws_vpc.demo17.default_network_acl_id
  tags                   = { Name = "demo17-acl" }
  subnet_ids             = [ aws_subnet.demo17_public.id ]

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

# ------ Create a subnet (use the default route table and default network ACL)
resource aws_subnet demo17_public {
  vpc_id                  = aws_vpc.demo17.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet1
  map_public_ip_on_launch = true
  tags                    = { Name = "demo17-public" }
}

# ------ Create VPC endpoint for CloudWatch
resource aws_vpc_endpoint demo17_cloudwatch {
  vpc_id              = aws_vpc.demo17.id
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.demo17_public.id]
  security_group_ids  = [aws_security_group.demo17_vpce.id]
  tags                = { Name = "demo17-cloudwatch-vpce" }
}

# ------ Security group for VPC endpoint
resource aws_security_group demo17_vpce {
  name_prefix = "demo17-vpce-"
  vpc_id      = aws_vpc.demo17.id
  tags        = { Name = "demo17-vpce-sg" }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_vpc]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------ Customize the security group for the EC2 instance
resource aws_default_security_group demo17 {
  vpc_id      = aws_vpc.demo17.id
  tags        = { Name = "demo17-sg1" }

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
