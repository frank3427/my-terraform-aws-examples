# ------ Create a VPC 
resource "aws_vpc" "demo28" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo28-vpc" }
}

# ------ Create an internet gateway in the new VPC
resource "aws_internet_gateway" "demo28" {
  vpc_id = aws_vpc.demo28.id
  tags   = { Name = "demo28-igw" }
}

# ------ Add a name and route rule to the default route table
resource "aws_default_route_table" "demo28" {
  default_route_table_id = aws_vpc.demo28.default_route_table_id
  tags                   = { Name = "demo28-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo28.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource "aws_default_network_acl" "demo28" {
  default_network_acl_id = aws_vpc.demo28.default_network_acl_id
  tags                   = { Name = "demo28-acl" }
  subnet_ids             = [aws_subnet.demo28_public.id]

  dynamic "ingress" {
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

# ------ Create a public subnet (use the default route table and default network ACL)
resource "aws_subnet" "demo28_public" {
  vpc_id                  = aws_vpc.demo28.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet1
  map_public_ip_on_launch = true
  tags                    = { Name = "demo28-public" }
}

# ------ Create a private subnet for EFA (use the default route table and default network ACL)
resource "aws_subnet" "demo28_private_efa" {
  vpc_id                  = aws_vpc.demo28.id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidr_subnet2_efa
  map_public_ip_on_launch = false
  tags                    = { Name = "demo28-private-EFA" }
}

# ------ Network ACL for the private EFA subnet (allow all traffic for MPI/EFA)
resource "aws_network_acl" "demo28_efa" {
  vpc_id     = aws_vpc.demo28.id
  subnet_ids = [aws_subnet.demo28_private_efa.id]
  tags       = { Name = "demo28-acl-efa" }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
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

# ------ Customize the security group for the EC2 instances
resource "aws_default_security_group" "demo28" {
  vpc_id = aws_vpc.demo28.id
  tags   = { Name = "demo28-sg1" }

}

# ---- New security group for EFA
#      For EFA: Security group from allow all inbound/outbound to itself
#     https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa-start.html
resource "aws_security_group" "demo28_efa" {
  vpc_id = aws_vpc.demo28.id
  tags   = { Name = "demo28-sg2-efa" }

}


resource "aws_vpc_security_group_ingress_rule" "demo28_ingress_ssh_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_default_security_group.demo28.id
  description       = "allow SSH access from authorized public IP addresses"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo28-sgr-ingress-ssh-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo28_ingress_internal" {
  security_group_id            = aws_default_security_group.demo28.id
  description                  = "allow all traffic between instances in this security group"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_default_security_group.demo28.id
  tags                         = { Name = "demo28-sgr-ingress-internal" }
}

resource "aws_vpc_security_group_egress_rule" "demo28_egress_all_1" {
  security_group_id = aws_default_security_group.demo28.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo28-sgr-egress-all-1" }
}

resource "aws_vpc_security_group_ingress_rule" "demo28_efa_ingress_all_0" {
  security_group_id            = aws_security_group.demo28_efa.id
  description                  = "allow all ingress traffic from this security group"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.demo28_efa.id
  tags                         = { Name = "demo28_efa-sgr-ingress-all-0" }
}

resource "aws_vpc_security_group_egress_rule" "demo28_efa_egress_all_1" {
  security_group_id = aws_security_group.demo28_efa.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo28_efa-sgr-egress-all-1" }
}
