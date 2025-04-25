resource aws_db_subnet_group demo12b {
  name       = "demo12b"
  subnet_ids = [ aws_subnet.demo12b_public.id, aws_subnet.demo12b_public2.id ]

  tags = {
    Name = "demo12b_DB_subnet_group"
  }
}

# aws_db_instance.demo12b_postgresql: Creation complete after 3m24s [id=demo12b-rds-postgresql]
resource aws_db_instance demo12b_postgresql {
  availability_zone           = "${var.aws_region}${var.az}"
  allocated_storage           = var.postgresql_size_in_gbs
  max_allocated_storage       = var.postgresql_max_size_in_gbs
  db_name                     = var.postgresql_db_name
  engine                      = "postgres"
  engine_version              = var.postgresql_version
  instance_class              = var.postgresql_instance_class
  username                    = "adm"
  manage_master_user_password = true  # use default KMS key for secret
  db_subnet_group_name        = aws_db_subnet_group.demo12b.name
  vpc_security_group_ids      = [ aws_security_group.demo12b_rds.id ]
  tags                        = { Name = "demo12b-rds" }
  identifier                  = var.postgresql_identifier
  storage_type                = var.postgresql_storage_type
  multi_az                    = false
  publicly_accessible         = false
  skip_final_snapshot         = true
  monitoring_interval         = 0    # Enhanced monitoring disabled
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  backup_retention_period               = 7
  backup_window                         = "15:00-16:00" # UTC, daily
  delete_automated_backups              = true
}

# ------ Create a new security group for the RDS instance
resource aws_security_group demo12b_rds {
  name        = "demo12b-rds-sg"
  vpc_id      = aws_vpc.demo12b.id
  tags        = { Name = "demo12b-rds-sg" }

  # ingress rule: allow connection to PostgreSQL
  ingress {
    description = "allow PostgreSQL access from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_vpc ]
  }

  # ingress rule: allow all traffic inside VPC
  ingress {
    description = "allow all traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ var.cidr_vpc ]
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

# ------ Retrieve RDS username and password from Secrets Manager
locals {
  ec2_username   = "ec2-user"
  rds_username   = aws_db_instance.demo12b_postgresql.username
  secret_mgr_arn = aws_db_instance.demo12b_postgresql.master_user_secret[0].secret_arn
  secret_string  = nonsensitive(data.aws_secretsmanager_secret_version.demo12b.secret_string)
  rds_password   = jsondecode(local.secret_string).password
}

data aws_secretsmanager_secret demo12b {
  arn = local.secret_mgr_arn
}

data aws_secretsmanager_secret_version demo12b {
  secret_id = data.aws_secretsmanager_secret.demo12b.id
}
