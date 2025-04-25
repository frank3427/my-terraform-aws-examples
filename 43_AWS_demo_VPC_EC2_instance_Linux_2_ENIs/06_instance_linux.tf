# ------ Create an EC2 instance
resource aws_instance demo43_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  instance_type          = var.inst1_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo43.id
  subnet_id              = aws_subnet.demo43_public1.id
  vpc_security_group_ids = [ aws_default_security_group.demo43_sg1.id ] 
  tags                   = { Name = "demo43-inst1" }
  user_data_base64       = base64encode(file(local.script)) 
  private_ip             = var.inst1_private_ip   # optional  
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo43-inst1-boot" }
  }
}

# ------ Create an Elastic IP address
# ------ to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo43_inst1 {
  domain   = "vpc"
  tags     = { Name = "demo43-inst1" }
}

# ------ Associate the Elastic IP with the primary network interface
resource aws_eip_association demo43_inst1 {
  network_interface_id = aws_instance.demo43_inst1.primary_network_interface_id
  allocation_id        = aws_eip.demo43_inst1.id
}

# ====== Second ENI 

# ------ Create a second network interface using second security group
resource aws_network_interface demo43_inst1_eni2 {
  subnet_id       = aws_subnet.demo43_public2.id
  security_groups = [ aws_security_group.demo43_sg2.id ]
  tags            = { Name = "demo43-inst1-eni2" }
}

# ------ Attach second network interface to the EC2 instance
resource aws_network_interface_attachment demo43_inst1_eni2 {
  instance_id          = aws_instance.demo43_inst1.id
  network_interface_id = aws_network_interface.demo43_inst1_eni2.id
  device_index         = 1
}

# ------ Create an Elastic IP address for the second network interface
resource aws_eip demo43_inst1_eni2 {
  domain            = "vpc"
  tags              = { Name = "demo43-inst1-eni2" }
}

# ------ Associate the Elastic IP with the second network interface
resource aws_eip_association demo43_inst1_eni2 {
  network_interface_id = aws_network_interface.demo43_inst1_eni2.id
  allocation_id        = aws_eip.demo43_inst1_eni2.id
}