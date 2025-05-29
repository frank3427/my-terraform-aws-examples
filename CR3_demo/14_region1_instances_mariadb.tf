# ------ Create a security group for the MariaDB EC2 instances
resource "aws_security_group" "cr3_sg_r1_mariadb" {
  provider    = aws.r1
  name        = "cr3-r1-mariadb-sg"
  description = "Security group for MariaDB instances in region 1"
  vpc_id      = aws_vpc.cr3_r1.id
  tags        = { Name = "cr3-r1-mariadb-sg" }

  # ingress rule: allow MariaDB traffic from web servers
  ingress {
    description     = "allow MariaDB traffic from webserver SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.cr3_sg_r1_websrv.id]
  }

  # ingress rule: allow SSH and MariaDB traffic from Bastion
  ingress {
    description = "allow SSH access from Bastion public subnet in VPC" # Corrected description
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_bastion_r1] # Using bastion subnet CIDR as data.aws_instance.bastion.private_ip is not defined
  }
  ingress {
    description = "allow MariaDB access from Bastion public subnet in VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.cidr_bastion_r1] # Using bastion subnet CIDR as data.aws_instance.bastion.private_ip is not defined
  }

  # ingress rule: allow MariaDB traffic from other MariaDB server (replication)
  ingress {
    description     = "allow MariaDB traffic from other MariaDB server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    self            = true # Allows traffic from instances within the same security group
  }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------ Create EC2 instances for MariaDB servers
resource "aws_instance" "cr3_r1_mariadb" {
  provider      = aws.r1
  count         = 2
  instance_type = var.inst_type_db
  ami           = data.aws_ami.al2_arm64_r1.id
  key_name      = aws_key_pair.cr3_r1_kp[1].id
  # Ensure instances are in different AZs for HA
  availability_zone      = "${var.aws_region1}${local.all_az[count.index]}"
  subnet_id              = aws_subnet.cr3_private_r1[count.index].id
  # Define private IPs if necessary, e.g., using a variable like var.priv_ip_db[count.index]
  # private_ip             = var.priv_ip_db[count.index] 
  vpc_security_group_ids = [aws_security_group.cr3_sg_r1_mariadb.id]
  tags                   = { Name = "cr3-r1-mariadb${count.index + 1}" }
  
  user_data_base64 = base64encode(templatefile("${path.module}/cloud_init/cloud_init_mariadb_TEMPLATE.sh", {
    db_nb = count.index + 1
  }))

  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { Name = "cr3-r1-mariadb${count.index + 1}-boot" }
    # delete_on_termination is true by default for root volumes
  }

  ebs_block_device {
    device_name = var.db_ebs_device_name
    volume_size = var.db_ebs_volume_size
    volume_type = "gp3" # Assuming gp3 is still desired, not making it a variable per task.
    encrypted   = true
    tags        = { Name = "cr3-r1-mariadb${count.index + 1}-data" }
    delete_on_termination = true # Ensures the volume is deleted when the instance is terminated
  }
}
