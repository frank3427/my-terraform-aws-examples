# ------ Create a VPC 
resource aws_vpc demo13b {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo13b-vpc" }
}

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo13b {
  vpc_id = aws_vpc.demo13b.id
  tags   = { Name = "demo13b-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo13b {
  default_route_table_id = aws_vpc.demo13b.default_route_table_id
  tags                   = { Name = "demo13b-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo13b.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo13b {
  default_network_acl_id = aws_vpc.demo13b.default_network_acl_id
  tags                   = { Name = "demo13b-acl" }
  subnet_ids             = [ aws_subnet.demo13b_db_client.id, aws_subnet.demo13b_rds[0].id, aws_subnet.demo13b_rds[1].id, aws_subnet.demo13b_rds[2].id ]

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

# ------ Create a public subnet for db client (use the default route table and default network ACL)
resource aws_subnet demo13b_db_client {
  vpc_id                  = aws_vpc.demo13b.id
  availability_zone       = "${var.aws_region}${var.db_client_az}"
  cidr_block              = var.cidr_client_subnet
  map_public_ip_on_launch = true
  tags                    = { Name = "demo13b-db-client" }
}

# ------ Create a subnet (use the default route table and default network ACL)
resource aws_subnet demo13b_rds {
  count                   = 3
  vpc_id                  = aws_vpc.demo13b.id
  availability_zone       = "${var.aws_region}${var.aurora_subnets_azs[count.index]}"
  cidr_block              = var.cidr_rds_subnets[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo13b-rds-subnet${count.index + 1}" }
}