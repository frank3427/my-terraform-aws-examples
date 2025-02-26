# ------ Generate a random password for the database if password not managed in Secrets Manager
resource random_string demo36-db-passwd {
  # must contains at least 2 upper case letters, 2 lower case letters, 2 numbers and 2 special characters
  length      = 12
  upper       = true
  min_upper   = 2
  lower       = true
  min_lower   = 2
  numeric     = true
  min_numeric = 2
  special     = true
  min_special = 2
  override_special = "#-_"   # use only special characters in this list
}

locals {
  username   = "awsuser"
  password   = random_string.demo36-db-passwd.result
}

# ------ Create a subnet group for the RedShift cluster
resource aws_redshift_subnet_group demo36 {
  name       = "demo36-redshift-vpc"
  subnet_ids = [ aws_subnet.demo36_private.id ]
}

# ------ Create a Security group
resource aws_security_group demo36-redshift {
  name        = "demo36-redshift"
  description = "Security group for RedShift cluster"
  vpc_id      = aws_vpc.demo36.id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_subnet_public ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------ Create a RedShift cluster in provisioned mode with single node
# Example: Creation complete after 3m38s
resource aws_redshift_cluster demo36 {
  cluster_identifier = "demo36-redshift-cluster"
  database_name      = "d36db1"
  master_username    = local.username
  master_password    = local.password
  node_type          = "dc2.large"
  cluster_type       = "single-node"
  
  vpc_security_group_ids    = [ aws_security_group.demo36-redshift.id ]
  cluster_subnet_group_name = aws_redshift_subnet_group.demo36.id
  availability_zone         = "${var.aws_region}${var.az}"
  enhanced_vpc_routing      = true
}