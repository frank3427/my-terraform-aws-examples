# ------ Generate a random password for the database
resource random_string demo10-db-passwd {
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

resource aws_db_subnet_group demo10 {
  name       = "demo10"
  subnet_ids = [ aws_subnet.demo10_public.id, aws_subnet.demo10_public2.id ]

  tags = {
    Name = "demo10_DB_subnet_group"
  }
}

# ------ Create a new security group for the RDS instance
resource aws_security_group demo10_rds {
  name        = "demo10-rds-sg"
  vpc_id      = aws_vpc.demo10.id
  tags        = { Name = "demo10-rds-sg" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
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

# resource aws_db_instance demo10_oracle {
#   availability_zone      = "${var.aws_region}${var.az}"
#   allocated_storage      = var.oracle_max_size_in_gbs
#   max_allocated_storage  = var.oracle_max_size_in_gbs
#   character_set_name     = var.oracle_charset
#   db_name                = var.oracle_sid
#   engine                 = var.oracle_edition
#   engine_version         = var.oracle_version
#   instance_class         = var.oracle_instance_class
#   username               = "admin"
#   password               = random_string.demo10-db-passwd.result
#   port                   = "1521"
#   #parameter_group_name = "default.mysql5.7"
#   #family               = var.oracle_family
#   #major_engine_version = "19"           # DB option group
#   skip_final_snapshot    = true
#   db_subnet_group_name   = aws_db_subnet_group.demo10.name
#   multi_az               = false
#   vpc_security_group_ids = [ aws_security_group.demo10_rds.id ]
#   tags                   = { Name = "demo10-rds" }
#   identifier             = var.oracle_identifier
# }

# Create the RDS instance
resource "aws_db_instance" "demo10_oracle" {
  identifier        = "myoracle-db"
  engine                      = "custom-oracle-ee"
  engine_version              = "19.0.0.0.ru-2021-01.rur-2021-01.r1"
  license_model               = "bring-your-own-license"
  instance_class              = "db.m5.large"  # or another supported instance type
  custom_iam_instance_profile = "AWSRDSCustomInstanceProfileForRdsCustomInstance"

  allocated_storage = 20
  storage_type      = "gp2"
  
  db_name           = "ORCL"  # SID for Oracle
  username          = "admin"
  password               = random_string.demo10-db-passwd.result
  
  vpc_security_group_ids = [ aws_security_group.demo10_rds.id ]
  db_subnet_group_name   = aws_db_subnet_group.demo10.name
  
  publicly_accessible    = false
  skip_final_snapshot    = true  # Set to false for production

  tags                   = { Name = "demo10-rds" }
}