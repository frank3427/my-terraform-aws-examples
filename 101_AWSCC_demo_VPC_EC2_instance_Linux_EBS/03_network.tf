# ------ Create a VPC 
resource awscc_ec2_vpc demo101 {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = [{ key = "Name", value = "demo101-vpc" }]
}

# ------ Create an internet gateway 
#        and attach it to the new VPC (cannot use awscc)
resource awscc_ec2_internet_gateway demo101 {
  tags   = [{ key = "Name", value = "demo101-igw" }]
}

# missing in awscc
resource aws_internet_gateway_attachment demo101 {
  internet_gateway_id = awscc_ec2_internet_gateway.demo101.id
  vpc_id              = awscc_ec2_vpc.demo101.id
}

# ------ Create new route table for new subnet 
#        (cannot modify default route table with awscc)
#        (cannot add route rules to route table with awscc)
resource aws_route_table demo101 {
  vpc_id = awscc_ec2_vpc.demo101.id
  tags   = { Name = "demo101-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = awscc_ec2_internet_gateway.demo101.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo101 {
  default_network_acl_id = awscc_ec2_vpc.demo101.default_network_acl
  tags                   = { Name = "demo101-acl" }
  subnet_ids             = [ awscc_ec2_subnet.demo101_public.id ]

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
resource awscc_ec2_subnet demo101_public {
  vpc_id                  = awscc_ec2_vpc.demo101.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet1
  map_public_ip_on_launch = true
  tags                    = [{ key = "Name", value = "demo101-public" }]
}

# ------ Associate new route table with subnet
resource awscc_ec2_subnet_route_table_association demo101_public {
  route_table_id = aws_route_table.demo101.id
  subnet_id      = awscc_ec2_subnet.demo101_public.id
}

# ------ Customize the security group for the EC2 instance
# missing in awscc
resource aws_default_security_group demo101 {
  vpc_id      = awscc_ec2_vpc.demo101.id
  tags        = { Name = "demo101-sg1" }

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
