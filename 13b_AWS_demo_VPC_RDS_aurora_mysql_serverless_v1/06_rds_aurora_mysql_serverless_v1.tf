# ------ Generate a random password for the database
resource random_string demo13b-db-passwd {
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
resource aws_db_subnet_group demo13b {
  name       = "demo13b"
  subnet_ids = [ aws_subnet.demo13b_rds[0].id, aws_subnet.demo13b_rds[1].id, aws_subnet.demo13b_rds[2].id ]

  tags = {
    Name = "demo13b-DB-subnet-group"
  }
}

# ------ Create an Aurora MySQL cluster (serverless v2)
resource aws_rds_cluster demo13b {
  cluster_identifier           = var.aurora_mysql_cluster_identifier
  engine                       = "aurora-mysql"
  engine_mode                  = "serverless"
  engine_version               = var.aurora_mysql_engine_version
  availability_zones           = [ "${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c" ]
  database_name                = var.aurora_mysql_db_name
  master_username              = var.aurora_mysql_username
  master_password              = random_string.demo13b-db-passwd.result
  backup_retention_period      = 5
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "mon:13:30-mon:14:00"
  db_subnet_group_name         = aws_db_subnet_group.demo13b.name
  vpc_security_group_ids       = [ aws_security_group.demo13b_rds.id ]
  skip_final_snapshot          = true
  scaling_configuration {
    auto_pause               = true
    max_capacity             = 256
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
}
# ------ Create a new security group for the RDS instance
resource aws_security_group demo13b_rds {
  name        = "demo13b-rds-sg"
  vpc_id      = aws_vpc.demo13b.id
  tags        = { Name = "demo13b-rds-sg" }

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
#   value = aws_rds_cluster.demo13b.endpoint
# }