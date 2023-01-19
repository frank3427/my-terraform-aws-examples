# ------ Generate a random password for the database
resource random_string demo12-db-passwd {
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

resource aws_db_subnet_group demo12 {
  name       = "demo12"
  subnet_ids = [ aws_subnet.demo12_public.id, aws_subnet.demo12_public2.id ]

  tags = {
    Name = "demo12_DB_subnet_group"
  }
}

# aws_db_instance.demo12_postgresql: Creation complete after 3m24s [id=demo12-rds-postgresql]
resource aws_db_instance demo12_postgresql {
  availability_zone      = "${var.aws_region}${var.az}"
  allocated_storage      = var.postgresql_size_in_gbs
  max_allocated_storage  = var.postgresql_max_size_in_gbs
  db_name                = var.postgresql_db_name
  engine                 = "postgres"
  engine_version         = var.postgresql_version
  instance_class         = var.postgresql_instance_class
  username               = "adm"
  password               = random_string.demo12-db-passwd.result
  db_subnet_group_name   = aws_db_subnet_group.demo12.name
  vpc_security_group_ids = [ aws_security_group.demo12_rds.id ]
  tags                   = { Name = "demo12-rds" }
  identifier             = var.postgresql_identifier
  storage_type           = var.postgresql_storage_type
  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true
}

# ------ Create a new security group for the RDS instance
resource aws_security_group demo12_rds {
  name        = "demo12-rds-sg"
  vpc_id      = aws_vpc.demo12.id
  tags        = { Name = "demo12-rds-sg" }

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