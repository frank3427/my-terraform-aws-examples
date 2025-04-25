# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo44_inst1 {
  instance = aws_instance.demo44_inst1.id
  domain   = "vpc"
  tags     = { Name = "demo44-inst1" }
}

# ------ Create an EC2 instance
resource aws_instance demo44_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  instance_type          = var.inst1_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo44.id
  subnet_id              = aws_subnet.demo44_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo44.id ] 
  tags                   = { Name = "demo44-inst1" }
  user_data_base64       = base64encode(file(local.script)) 
  private_ip             = var.inst1_private_ip   # optional  
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo44-inst1-boot" }
  }
}

locals {
  username = startswith(var.linux_os_version, "ubuntu") ? "ubuntu" : "ec2-user"
  scripts  = {
    "al2": var.cloud_init_script_al,
    "al2023": var.cloud_init_script_al,
    "ubuntu22": var.cloud_init_script_ubuntu,
    "sles15": var.cloud_init_script_sles,
    "rhel9": var.cloud_init_script_rhel,
  }
  script = local.scripts[var.linux_os_version]
}

# ------ Customize the default security group for the EC2 instance
resource aws_default_security_group demo44 {
  vpc_id      = aws_vpc.demo44.id
  tags        = { Name = "demo44-sg1" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
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
