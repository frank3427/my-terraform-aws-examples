# ------ Create a VPC 
resource aws_vpc demo05 {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo05-vpc" }
}

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo05 {
  vpc_id = aws_vpc.demo05.id
  tags   = { Name = "demo05-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo05 {
  default_route_table_id = aws_vpc.demo05.default_route_table_id
  tags                   = { Name = "demo05-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo05.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo05 {
  default_network_acl_id = aws_vpc.demo05.default_network_acl_id
  tags                   = { Name = "demo05-acl" }
  subnet_ids             = [ aws_subnet.demo05_public.id ]

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
resource aws_subnet demo05_public {
  vpc_id                  = aws_vpc.demo05.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet1
  map_public_ip_on_launch = true
  tags                    = { Name = "demo05-public" }
}

# ------ Create and use a VPC gateway endpoint for S3 to keep traffic between instance and S3 internal (Internet not used)
resource aws_vpc_endpoint demo05_s3_gateway {
  vpc_id            = aws_vpc.demo05.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  tags              = { Name = "demo05-s3-endpt" }
}

resource aws_vpc_endpoint_route_table_association demo05_s3 {
  route_table_id  = aws_default_route_table.demo05.id
  vpc_endpoint_id = aws_vpc_endpoint.demo05_s3_gateway.id
}

# ------ Create a security group for the EC2 instance
resource aws_security_group demo05_sg1 {
  name        = "demo05-sg1"
  description = "Description for demo05-sg1"
  vpc_id      = aws_vpc.demo05.id
  tags        = { Name = "demo05-sg1" }

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
