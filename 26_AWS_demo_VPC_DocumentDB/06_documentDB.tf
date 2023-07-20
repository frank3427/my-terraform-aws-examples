# ------ Generate a random password for the documentDB cluster
resource random_string demo26-docdb-passwd {
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
  docdb_pwd = random_string.demo26-docdb-passwd.result
}

# ------ Create a new security group for the documentDB cluster
resource aws_security_group demo26_docdb {
  name        = "demo26-docdb-sg"
  vpc_id      = aws_vpc.demo26.id
  tags        = { Name = "demo26-docdb-sg" }

  # ingress rule: allow connection 
  ingress {
    description = "allow access from VPC"
    from_port   = var.docdb_port
    to_port     = var.docdb_port
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

# ------ Create a new subnet group (at least 2 AZs)
resource aws_db_subnet_group demo26 {
  name       = "demo26"
  subnet_ids = [ aws_subnet.demo26_public1.id, aws_subnet.demo26_public2.id ]

  tags = {
    Name = "demo26_DB_subnet_group"
  }
}

# ------ Create a DocumentDB regional (not elastic) cluster (empty)
resource aws_docdb_cluster demo26 {
  cluster_identifier           = var.docdb_identifier
  engine                       = "docdb"
  port                         = var.docdb_port
  master_username              = var.docdb_user
  master_password              = local.docdb_pwd
  db_subnet_group_name         = aws_db_subnet_group.demo26.name
  vpc_security_group_ids       = [ aws_security_group.demo26_docdb.id ]
  backup_retention_period      = var.docdb_backup_retention
  preferred_backup_window      = var.docdb_backup_window
  preferred_maintenance_window = var.docdb_maintenance_window
  skip_final_snapshot          = true
  apply_immediately            = var.docdb_apply_immediately 
}

# ------ Add DocumentDB instances (at least 1) to DocumentDB cluster
resource aws_docdb_cluster_instance demo26 {
  count                        = var.docdb_nb_of_instances
  identifier                   = "${var.docdb_identifier}-${count.index + 1}"
  cluster_identifier           = aws_docdb_cluster.demo26.id
  instance_class               = var.docdb_instance_type
  apply_immediately            = var.docdb_apply_immediately 
  #preferred_maintenance_window = var.docdb_maintenance_window
}

#aws_docdb_cluster_instance.demo26[1]: Destruction complete after 7m37s
#aws_docdb_cluster_instance.demo26[0]: Creation complete after 3m45s [id=demo26-docdb-cluster-1]