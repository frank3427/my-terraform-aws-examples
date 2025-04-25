locals {
  nb_vpcs = length(var.cidrs_vpc)
}

# ------ Create 3 VPCs 
resource aws_vpc demo06b {
  depends_on           = [ aws_ec2_transit_gateway.demo06b ]
  count                = local.nb_vpcs
  cidr_block           = var.cidrs_vpc[count.index]
  enable_dns_hostnames = true
  tags                 = { Name = "demo06b-vpc${count.index+1}" }
}

# ====== Private subnets for TGW attachments

# ------ 1 Transit gateway (attached to all VPCs)
resource aws_ec2_transit_gateway demo06b {
  tags        = { Name = "demo06b-tgw" }
  description = "demo06b-tgw"
}

output tgwid {
  value = aws_ec2_transit_gateway.demo06b.id
}

# ------ Add a name and route rule to the default route table for each VPC
resource aws_default_route_table demo06b {
  lifecycle { ignore_changes = [ route ] }    # needed as additional routes are added automatically by TGW attachements
  count                  = local.nb_vpcs
  default_route_table_id = aws_vpc.demo06b[count.index].default_route_table_id
  tags                   = { Name = "demo06b-vpc${count.index+1}-rt-default" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_ec2_transit_gateway.demo06b.id
  }
}

# ------ Add a name to the default network ACL and modify ingress rules
resource aws_default_network_acl demo06b {
  lifecycle { ignore_changes = [ subnet_ids ] } 

  count                  = local.nb_vpcs
  default_network_acl_id = aws_vpc.demo06b[count.index].default_network_acl_id
  tags                   = { Name = "demo06b-vpc${count.index+1}-acl-default" }

  ingress {
    protocol   = -1 # all
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

# ------ Create a private subnet dedicated to TGW attachment (1 needed for each AZ we want to use)
#        (use the default route table and default network ACL)
resource aws_subnet demo06b_tgw {
  count                   = local.nb_vpcs
  vpc_id                  = aws_vpc.demo06b[count.index].id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidrs_subnet_tgw[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "demo06b-vpc${count.index+1}-tgw" }
}

# ------ Transit gateway attachments to VPC
resource aws_ec2_transit_gateway_vpc_attachment demo06b {
  count              = local.nb_vpcs
  subnet_ids         = [ aws_subnet.demo06b_tgw[count.index].id ]
  transit_gateway_id = aws_ec2_transit_gateway.demo06b.id
  vpc_id             = aws_vpc.demo06b[count.index].id
  tags               = { Name = "demo06b-vpc${count.index+1}-tgw-attachment" }
}

# ====== Public subnets for EC2 instancs

# ------ Create an internet gateway in each VPC
resource aws_internet_gateway demo06b {
  count  = local.nb_vpcs
  vpc_id = aws_vpc.demo06b[count.index].id
  tags   = { Name = "demo06b-vpc${count.index+1}-igw" }
}

# ------ Create a new route table for EC2 subnet in each VPC
resource aws_route_table demo06b_ec2 {
  lifecycle { ignore_changes = [ route ] }    # needed as additional routes are added automatically by TGW attachements
  count  = local.nb_vpcs
  vpc_id = aws_vpc.demo06b[count.index].id
  tags   = { Name = "demo06b-vpc${count.index+1}-rt-ec2" }

  dynamic route {
    for_each = setsubtract(var.cidrs_vpc, [var.cidrs_vpc[count.index]])
    content {
      cidr_block = route.value
      gateway_id = aws_ec2_transit_gateway.demo06b.id
    }
  }
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo06b[count.index].id
  }
}

# ------ Create a new network ACL for EC2 subnet in each VPC
resource aws_network_acl demo06b_ec2 {
  count      = local.nb_vpcs
  vpc_id     = aws_vpc.demo06b[count.index].id
  tags       = { Name = "demo06b-vpc${count.index+1}-nacl-ec2" }
  subnet_ids = [ aws_subnet.demo06b_ec2[count.index].id ]

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
  
  dynamic ingress {
    for_each = var.cidrs_vpc
    content {
      protocol   = "all"
      rule_no    = 300 + 10 * index(var.cidrs_vpc, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 0
      to_port    = 0
    }
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


# ------ Create a public subnet for EC2 instances in each VPC 
resource aws_subnet demo06b_ec2 {
  count                   = local.nb_vpcs
  vpc_id                  = aws_vpc.demo06b[count.index].id
  availability_zone       = "${var.aws_region}${var.az}"
  cidr_block              = var.cidrs_subnet_ec2[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo06b-vpc${count.index+1}-ec2" }
}

# ------ Associate the route table to the EC2 subnet in each VPC
resource aws_route_table_association demlo06b_ec2 {
  count          = local.nb_vpcs
  subnet_id      = aws_subnet.demo06b_ec2[count.index].id
  route_table_id = aws_route_table.demo06b_ec2[count.index].id
}

# ------ Create a security group for the EC2 instance in each VPC
resource aws_security_group demo06b_sg_ec2 {
  count       = local.nb_vpcs
  name        = "demo06b-vpc${count.index+1}-sg-ec2"
  description = "secgrp for EC2 instance in VPC ${count.index+1}-sg-ec2"
  vpc_id      = aws_vpc.demo06b[count.index].id
  tags        = { Name = "demo06b-vpc${count.index+1}-sg-ec2" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses"
    cidr_blocks = var.authorized_ips
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }

  # ingress rule: allow traffic from all VPCs
  ingress {
    description = "allow all traffic from the VPCs"
    cidr_blocks = var.cidrs_vpc
    protocol   = "all"
    from_port  = 0
    to_port    = 0
  }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    cidr_blocks = [ "0.0.0.0/0" ]
    protocol    = "all"
    from_port   = 0
    to_port     = 0
  }
}
