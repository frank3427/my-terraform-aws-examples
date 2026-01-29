# ------ Create a VPC 
resource "aws_vpc" "demo41-test" {
  region               = var.test_region
  cidr_block           = var.test_cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo41-test-vpc" }
}


# ========== 2 Public subnets for bastion host and public ALB

# ------ Create an internet gateway in the new VPC
resource "aws_internet_gateway" "demo41-test-ig" {
  region = var.test_region
  vpc_id = aws_vpc.demo41-test.id
  tags   = { Name = "demo41-test-igw" }
}

# ------ Create 1 public subnets
resource "aws_subnet" "demo41-test-public" {
  count                   = 1
  region                  = var.test_region
  vpc_id                  = aws_vpc.demo41-test.id
  availability_zone       = "${var.test_region}${var.az[count.index]}"
  cidr_block              = var.test_cidr_subnet_public[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo41-test-public-${var.az[count.index]}" }
}

# ------ Add a name and route rule to the default route table
resource "aws_default_route_table" "demo41-test" {
  region                 = var.test_region
  default_route_table_id = aws_vpc.demo41-test.default_route_table_id
  tags                   = { Name = "demo41-test-public-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo41-test-ig.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource "aws_default_network_acl" "demo41-test" {
  region                 = var.test_region
  default_network_acl_id = aws_vpc.demo41-test.default_network_acl_id
  tags                   = { Name = "demo41-test-acl" }
  subnet_ids             = [for subnet in aws_subnet.demo41-test-public : subnet.id]

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
    rule_no    = 300
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
