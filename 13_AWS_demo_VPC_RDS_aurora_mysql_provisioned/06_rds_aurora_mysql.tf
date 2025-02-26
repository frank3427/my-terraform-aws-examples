# ------ Generate a random password for the database
resource random_string demo13-db-passwd {
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


# ------ Create an Aurora MySQL cluster
resource aws_db_subnet_group demo13 {
  name       = "demo13"
  subnet_ids = [ aws_subnet.demo13_db_client.id, aws_subnet.demo13_rds[0].id, aws_subnet.demo13_rds[1].id, aws_subnet.demo13_rds[2].id ]

  tags = {
    Name = "demo13-DB-subnet-group"
  }
}

# ------ Create an Aurora MySQL cluster
resource aws_rds_cluster demo13 {
  cluster_identifier           = var.aurora_mysql_cluster_identifier
  engine                       = "aurora-mysql"
  engine_version               = var.aurora_mysql_engine_version
  availability_zones           = [ "${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c" ]
  database_name                = var.aurora_mysql_db_name
  master_username              = var.aurora_mysql_username
  master_password              = random_string.demo13-db-passwd.result
  backup_retention_period      = 5
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "mon:13:30-mon:14:00"
  db_subnet_group_name         = aws_db_subnet_group.demo13.name
  vpc_security_group_ids       = [ aws_security_group.demo13_rds.id ]
  skip_final_snapshot          = true
}

# ------ Create 3 RDS instances in the Aurora MySQL cluster (1 writer and 2 readers)
resource aws_rds_cluster_instance demo13 {
  count                  = 3
  identifier             = "${var.aurora_mysql_db_identifier}${count.index+1}"
  cluster_identifier     = aws_rds_cluster.demo13.id
  engine                  = "aurora-mysql"
  instance_class         = var.aurora_mysql_instance_class
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.demo13.name
  tags                   = { Name = "demo13-rds-aurora-inst${count.index+1}" }
}

# ------ Create a new security group for the RDS instance
resource aws_security_group demo13_rds {
  name        = "demo13-rds-sg"
  vpc_id      = aws_vpc.demo13.id
  tags        = { Name = "demo13-rds-sg" }

  # ingress rule: allow SSH
  ingress {
    description = "allow MYSQL access from authorized public IP addresses"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_vpc ]
  }

  # # ingress rule: allow all traffic inside VPC
  # ingress {
  #   description = "allow all traffic from VPC"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"    # all protocols
  #   cidr_blocks = [ var.cidr_vpc ]
  # }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

# output rds {
#   value = aws_rds_cluster.demo13.endpoint
# }