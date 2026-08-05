# ------ Generate a random password for the database
resource "random_string" "demo10-db-passwd" {
  # must contains at least 2 upper case letters, 2 lower case letters, 2 numbers and 2 special characters
  length           = 12
  upper            = true
  min_upper        = 2
  lower            = true
  min_lower        = 2
  numeric          = true
  min_numeric      = 2
  special          = true
  min_special      = 2
  override_special = "#-_" # use only special characters in this list
}

resource "aws_db_subnet_group" "demo10" {
  name       = "demo10"
  subnet_ids = [aws_subnet.demo10_public.id, aws_subnet.demo10_public2.id]

  tags = {
    Name = "demo10_DB_subnet_group"
  }
}

# ------ Create a new security group for the RDS instance
resource "aws_security_group" "demo10_rds" {
  name   = "demo10-rds-sg"
  vpc_id = aws_vpc.demo10.id
  tags   = { Name = "demo10-rds-sg" }

}

# ------ Create the RDS Oracle instance
resource "aws_db_instance" "demo10_oracle" {
  availability_zone      = "${var.aws_region}${var.az}"
  allocated_storage      = var.oracle_size_in_gbs
  max_allocated_storage  = var.oracle_max_size_in_gbs
  character_set_name     = var.oracle_charset
  db_name                = var.oracle_sid
  engine                 = var.oracle_edition
  engine_version         = var.oracle_version
  instance_class         = var.oracle_instance_class
  license_model          = var.oracle_license_model
  username               = "admin"
  password               = random_string.demo10-db-passwd.result
  port                   = 1521
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.demo10.name
  multi_az               = false
  vpc_security_group_ids = [aws_security_group.demo10_rds.id]
  tags                   = { Name = "demo10-rds" }
  identifier             = var.oracle_identifier
}


resource "aws_vpc_security_group_ingress_rule" "demo10_rds_ingress_ssh_0" {
  security_group_id = aws_security_group.demo10_rds.id
  description       = "allow SSH access from authorized public IP addresses"
  from_port         = 1521
  to_port           = 1521
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo10_rds-sgr-ingress-ssh-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo10_rds_ingress_all_1" {
  security_group_id = aws_security_group.demo10_rds.id
  description       = "allow all traffic from VPC"
  ip_protocol       = "-1"
  cidr_ipv4         = var.cidr_vpc
  tags              = { Name = "demo10_rds-sgr-ingress-all-1" }
}

resource "aws_vpc_security_group_egress_rule" "demo10_rds_egress_all_2" {
  security_group_id = aws_security_group.demo10_rds.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo10_rds-sgr-egress-all-2" }
}
