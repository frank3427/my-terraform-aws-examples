# ------ Create a VPC 
resource aws_vpc demo35 {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  tags                 = { Name = "demo35-vpc" }
}

# ------ Create an internet gateway in the new VPC
resource aws_internet_gateway demo35 {
  vpc_id = aws_vpc.demo35.id
  tags   = { Name = "demo35-igw" }
}

# ------ Add a name and route rule to the default route table
resource aws_default_route_table demo35 {
  default_route_table_id = aws_vpc.demo35.default_route_table_id
  tags                   = { Name = "demo35-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo35.id
  }
}

# # ------ Add a name to the default network ACL and modify ingress rules
# resource aws_default_network_acl demo35 {
#   default_network_acl_id = aws_vpc.demo35.default_network_acl_id
#   tags                   = { Name = "demo35-acl" }
#   subnet_ids             = [ for subnet in aws_subnet.demo35_public: subnet.id ]

#   dynamic ingress {
#     for_each = var.authorized_ips
#     content {
#       protocol   = "tcp"
#       rule_no    = 100 + 10 * index(var.authorized_ips, ingress.value)
#       action     = "allow"
#       cidr_block = ingress.value
#       from_port  = 22
#       to_port    = 22
#     }
#   }

#   # this is needed for yum
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1024
#     to_port    = 65535
#   }

#   egress {
#     protocol   = -1
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }
# }

# ------ Create 3 public subnets (use the default route table and default network ACL)
resource aws_subnet demo35_public {
  count                   = 3
  vpc_id                  = aws_vpc.demo35.id
  availability_zone       = "${var.aws_region}${var.az_subnets[count.index]}"
  cidr_block              = var.cidr_subnets[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "demo35-public-${var.az_subnets[count.index]}}" }
}

# ------ Customize the security group for the EC2 instance
resource aws_default_security_group demo35 {
  vpc_id      = aws_vpc.demo35.id
  tags        = { Name = "demo35-sg1" }

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
