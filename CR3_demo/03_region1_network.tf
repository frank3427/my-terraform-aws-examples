# ------ Create a VPC 
resource aws_vpc cr3_r1 {
  provider             = aws.r1
  cidr_block           = var.cidr_vpc_r1
  enable_dns_hostnames = true
  tags                 = { Name = "cr3-r1-vpc" }
}

# ====== Objects for public subnets (1 for Bastion, 3 for ALB)

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway cr3_r1 {
  provider = aws.r1
  vpc_id   = aws_vpc.cr3_r1.id
  tags     = { Name = "cr3-r1-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table cr3_r1 {
  provider               = aws.r1
  default_route_table_id = aws_vpc.cr3_r1.default_route_table_id
  tags                   = { Name = "cr3-r1-public-rt" }

  route {
    cidr_block = var.cidr_public_r2
    gateway_id = aws_vpc_peering_connection.cr3_r1.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cr3_r1.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl cr3_r1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      subnet_ids
    ]
  }
  provider               = aws.r1
  default_network_acl_id = aws_vpc.cr3_r1.default_network_acl_id
  tags                   = { Name = "cr3-r1-bastion-alb-acl" }
  #subnet_ids             = [ aws_subnet.cr3_r1_bastion.id ] cr3_r1_alb

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

  dynamic ingress {
    for_each = var.authorized_ips
    content {
      protocol   = "tcp"
      rule_no    = 200 + 10 * index(var.authorized_ips, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 80
      to_port    = 80
    }
  }

  dynamic ingress {
    for_each = var.authorized_ips
    content {
      protocol   = "tcp"
      rule_no    = 300 + 10 * index(var.authorized_ips, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 443
      to_port    = 443
    }
  }

  # this is needed for yum
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # TODO: REMOVE AND OPTIMIZE
  ingress {
    protocol   = -1
    rule_no    = 500
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

# ------ Create a public subnet for the Bastion Host (use the default route table and default network ACL)
resource aws_subnet cr3_r1_bastion {
  provider                = aws.r1
  vpc_id                  = aws_vpc.cr3_r1.id
  availability_zone       = "${var.aws_region1}${var.az_bastion}"
  cidr_block              = var.cidr_bastion_r1
  map_public_ip_on_launch = true
  tags                    = { Name = "cr3-r1-bastion" }
}

# ------ Create 3 public subnets for the ALB (use the default route table and default network ACL)
resource aws_subnet cr3_r1_alb {
  count                   = 3
  provider                = aws.r1
  vpc_id                  = aws_vpc.cr3_r1.id
  availability_zone       = "${var.aws_region1}${local.all_az[count.index]}"
  cidr_block              = var.cidrs_alb_r1[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "cr3-r1-alb-${local.all_az[count.index]}" }
}

# ====== Objects for private subnets (Web Servers)

# ------ Create an elastic IP address for the NAT gateway
resource aws_eip cr3_natgw_r1 {
  provider = aws.r1
  domain   = "vpc"
  tags     = { Name = "cr3-r1-natgw" }
}

# ------ Create a NAT gateway
resource aws_nat_gateway cr3_r1 {
  provider          = aws.r1
  connectivity_type = "public"
  allocation_id     = aws_eip.cr3_natgw_r1.id
  subnet_id         = aws_subnet.cr3_r1_bastion.id
  tags              = { Name = "cr3-r1-natgw" }
}

# ------ Create a new route table
resource aws_route_table cr3_private_r1 {
  provider = aws.r1
  vpc_id   = aws_vpc.cr3_r1.id
  tags     = { Name = "cr3-r1-private-rt" }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cr3_r1.id
  }
}

# ------ Create a new network ACL
resource aws_network_acl cr3_r1_websrv {
  provider   = aws.r1
  vpc_id     = aws_vpc.cr3_r1.id
  tags       = { Name = "cr3-r1-websrv-acl" }
  subnet_ids = [ for subnet in aws_subnet.cr3_private_r1: subnet.id ]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_bastion_r1
    from_port  = 22
    to_port    = 22
  }

  dynamic ingress {
    for_each = var.cidrs_alb_r1
    content {
      protocol   = "tcp"
      rule_no    = 200 + 10 * index(var.cidrs_alb_r1, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 80
      to_port    = 80
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

  # accept all traffic from peered VPC
  ingress {
    protocol   = -1
    rule_no    = 400
    action     = "allow"
    cidr_block = var.cidr_vpc_r2
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

# ------ Create 3 private subnets (1 per AZ)
locals {
  all_az = ["a","b","c"]
}

resource aws_subnet cr3_private_r1 {
  count                   = 3
  provider                = aws.r1
  vpc_id                  = aws_vpc.cr3_r1.id
  availability_zone       = "${var.aws_region1}${local.all_az[count.index]}"
  cidr_block              = var.cidrs_websrv_r1[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "cr3-r1-private-${local.all_az[count.index]}" }
}

# ------ Associate the route table with subnets
resource aws_route_table_association demo04_public_bastion {
  count          = 3
  provider       = aws.r1
  subnet_id      = aws_subnet.cr3_private_r1[count.index].id
  route_table_id = aws_route_table.cr3_private_r1.id
}

# ======== Peering connection to other VPC: REQUESTER
resource aws_vpc_peering_connection cr3_r1 {
  provider      = aws.r1
  peer_vpc_id   = aws_vpc.cr3_r2.id
  peer_region   = var.aws_region2
  vpc_id        = aws_vpc.cr3_r1.id
  tags          = { Name = "cr3-peering" }
}