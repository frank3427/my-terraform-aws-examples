# ------ Generate a random password for the database
resource random_string demo13d-db-passwd {
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


# ------ Create an Aurora PostgreSQL cluster
resource aws_db_subnet_group demo13d {
  name       = "demo13d"
  subnet_ids = [ aws_subnet.demo13d_db_client.id, aws_subnet.demo13d_rds[0].id, aws_subnet.demo13d_rds[1].id, aws_subnet.demo13d_rds[2].id ]

  tags = {
    Name = "demo13d-DB-subnet-group"
  }
}

# ------ Create an Aurora PostgreSQL cluster (serverless v2)
resource aws_rds_cluster demo13d {
  cluster_identifier           = var.aurora_postgresql_cluster_identifier
  engine                       = "aurora-postgresql"
  engine_version               = var.aurora_postgresql_engine_version
  availability_zones           = [ "${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c" ]
  database_name                = var.aurora_postgresql_db_name
  master_username              = var.aurora_postgresql_username
  master_password              = random_string.demo13d-db-passwd.result
  backup_retention_period      = 5
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "mon:13:30-mon:14:00"
  performance_insights_enabled = true
  db_subnet_group_name         = aws_db_subnet_group.demo13d.name
  vpc_security_group_ids       = [ aws_security_group.demo13d_rds.id ]
  skip_final_snapshot          = true
  # monitoring_interval  = 60   # enhanced monitoring (0 to disable)
  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_postgresql_serverless_v2_min_acu
    max_capacity = var.aurora_postgresql_serverless_v2_max_acu
  }
}

# ------ Create a DB instance (writer instance)
resource aws_rds_cluster_instance demo13d_inst1 {
  cluster_identifier   = aws_rds_cluster.demo13d.id
  identifier           = "${var.aurora_postgresql_cluster_identifier}-instance-1"
  instance_class       = "db.serverless"
  engine               = "aurora-postgresql"
  engine_version       = var.aurora_postgresql_engine_version
  db_subnet_group_name = aws_db_subnet_group.demo13d.name
  # monitoring_interval  = 60   # enhanced monitoring (0 to disable)
  tags                 = { Name = "demo13d-rds-instance-1" }
}

# ------ Create a DB instance (reader instance)
resource aws_rds_cluster_instance demo13d_inst2 {
  cluster_identifier   = aws_rds_cluster.demo13d.id
  identifier           = "${var.aurora_postgresql_cluster_identifier}-instance-2"
  instance_class       = "db.serverless"
  engine               = "aurora-postgresql"
  engine_version       = var.aurora_postgresql_engine_version
  db_subnet_group_name = aws_db_subnet_group.demo13d.name
  # monitoring_interval  = 60   # enhanced monitoring (0 to disable)
  tags                 = { Name = "demo13d-rds-instance-2" }
}

# ------ Create a new security group for the RDS instance
resource aws_security_group demo13d_rds {
  name        = "demo13d-rds-sg"
  vpc_id      = aws_vpc.demo13d.id
  tags        = { Name = "demo13d-rds-sg" }

  # ingress rule: allow SSH
  ingress {
    description = "allow PostgreSQL access from VPC"
    from_port   = 5432
    to_port     = 5432
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
#   value = aws_rds_cluster.demo13d.endpoint
# }