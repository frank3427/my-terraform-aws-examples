# ------ Create a VPC 
resource "aws_vpc" "demo45a" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo45a-vpc" }
}

# ========== Public subnet for everything

# ------ Create an internet gateway in the new VPC
resource "aws_internet_gateway" "demo45a-ig" {
  vpc_id = aws_vpc.demo45a.id
  tags   = { Name = "demo45a-igw" }
}

# ------ Create a public subnet
resource "aws_subnet" "demo45a_public" {
  vpc_id                  = aws_vpc.demo45a.id
  availability_zone       = "${var.aws_region}${var.az_subnet}"
  cidr_block              = var.cidr_subnet_public
  map_public_ip_on_launch = true
  tags                    = { Name = "demo45a-public" }
}

# ------ Add a name and route rule to the default route table
resource "aws_default_route_table" "demo45a" {
  default_route_table_id = aws_vpc.demo45a.default_route_table_id
  tags                   = { Name = "demo45a-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo45a-ig.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource "aws_default_network_acl" "demo45a" {
  default_network_acl_id = aws_vpc.demo45a.default_network_acl_id
  tags                   = { Name = "demo45a-acl" }
  subnet_ids             = [aws_subnet.demo45a_public.id]

  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # dynamic ingress {
  #   for_each = var.authorized_ips
  #   content {
  #     protocol   = "tcp"
  #     rule_no    = 100 + 10 * index(var.authorized_ips, ingress.value)
  #     action     = "allow"
  #     cidr_block = ingress.value
  #     from_port  = 22
  #     to_port    = 22
  #   }
  # }

  # # this is needed for yum
  # ingress {
  #   protocol   = "tcp"
  #   rule_no    = 300
  #   action     = "allow"
  #   cidr_block = "0.0.0.0/0"
  #   from_port  = 1024
  #   to_port    = 65535
  # }

  # # allow access from private subnets (needed for traffic thru NAT gateway)
  # ingress {
  #   protocol   = -1
  #   rule_no    = 400
  #   action     = "allow"
  #   cidr_block = var.cidr_subnet_private_cpt_nodes
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

# ------ Create a security group for everything

resource "aws_security_group" "demo45a" {
  name        = "demo45a-sg"
  description = "Security group for demo45a"
  vpc_id      = aws_vpc.demo45a.id

  tags = {
    Name = "demo45a-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "demo45a_ingress_ssh_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo45a.id
  description       = "SSH from authorized IPs"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo45a-sgr-ingress-ssh-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo45a_ingress_port0_1" {
  security_group_id = aws_security_group.demo45a.id
  description       = "self"
  ip_protocol       = "-1"
  tags              = { Name = "demo45a-sgr-ingress-port0-1" }
}

resource "aws_vpc_security_group_egress_rule" "demo45a_egress_all_2" {
  security_group_id = aws_security_group.demo45a.id
  description       = ""
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo45a-sgr-egress-all-2" }
}

resource "aws_vpc_security_group_egress_rule" "demo45a_egress_port0_3" {
  security_group_id = aws_security_group.demo45a.id
  description       = "self"
  ip_protocol       = "-1"
  tags              = { Name = "demo45a-sgr-egress-port0-3" }
}
