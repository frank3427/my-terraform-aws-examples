# ------ Generate a random password for the database
resource random_string demo11b-db-passwd {
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

resource aws_db_subnet_group demo11b {
  name       = "demo11b"
  subnet_ids = [ aws_subnet.demo11b_public.id, aws_subnet.demo11b_public2.id ]

  tags = {
    Name = "demo11b_DB_subnet_group"
  }
}

resource aws_db_parameter_group demo11b {
  name        = "demo11b-rds-pg"
  family      = "mysql${var.mysql_version}"
  description = "forcing in-transit encryption with require_secure_transport=1"

  parameter {
    name  = "require_secure_transport"
    value = "1"
  }
}

# multi-AZ=true: aws_db_instance.demo11b_mysql: Creation complete after 9m55s [id=demo11b-rds-mysql]
resource aws_db_instance demo11b_mysql {
  #availability_zone      = "${var.aws_region}${var.az}"    # not valid for multi-AZ
  parameter_group_name   = aws_db_parameter_group.demo11b.name
  allocated_storage      = var.mysql_size_in_gbs
  storage_type           = var.mysql_storage_type
  max_allocated_storage  = var.mysql_max_size_in_gbs
  db_name                = var.mysql_db_name
  engine                 = "mysql"
  engine_version         = var.mysql_version
  instance_class         = var.mysql_instance_class
  username               = "admin"
  password               = random_string.demo11b-db-passwd.result
  #port                   = "3306"
  db_subnet_group_name   = aws_db_subnet_group.demo11b.name
  vpc_security_group_ids = [ aws_security_group.demo11b_rds.id ]
  tags                   = { Name = "demo11b-rds" }
  identifier             = var.mysql_identifier
  multi_az               = var.mysql_multi_az
  publicly_accessible    = false
  skip_final_snapshot    = true
  backup_retention_period= var.mysql_backups_retention_days
}

# ------ Create a new security group for the RDS instance
resource aws_security_group demo11b_rds {
  name        = "demo11b-rds-sg"
  vpc_id      = aws_vpc.demo11b.id
  tags        = { Name = "demo11b-rds-sg" }

  # ingress rule: allow connection to MySQL
  ingress {
    description = "allow MySQL access from VPC"
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