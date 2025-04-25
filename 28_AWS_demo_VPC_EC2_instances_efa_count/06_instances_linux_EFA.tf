# ------ Create the default network interfaces 
resource aws_network_interface demo28_eth0 {
  count           = var.nb_instances
  subnet_id       = aws_subnet.demo28_public.id
  private_ips     = [ var.inst_private_ip[count.index] ]
  tags            = { Name = "demo28-nic0-${count.index + 1}" }  
}

# ------ Create EFA network interfaces to be attached to supported EC2 instances (1 nic per instance)
resource aws_network_interface demo28_efa {
  count           = var.nb_instances
  interface_type  = "efa"
  subnet_id       = aws_subnet.demo28_private_efa.id
  private_ips     = [ var.inst_private_ip_efa[count.index] ]  
  security_groups = [ aws_security_group.demo28_efa.id ]
  tags            = { Name = "demo28-nic1-efa-${count.index + 1}" }  
}

# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo28_inst {
  count    = var.nb_instances
  network_interface = aws_network_interface.demo28_eth0[count.index].id
  domain   = "vpc"
  tags     = { Name = "demo28-inst${count.index + 1}" }
}

# ------ Create a placement group for EC2 instances (type CLUSTER)
resource aws_placement_group demo28 {
  name     = "demo28-cluster"
  strategy = "cluster"
}

# ------ Create an EC2 instance
resource aws_instance demo28_inst {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  count                  = var.nb_instances
  placement_group        = aws_placement_group.demo28.id
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo28.id
  tags                   = { Name = "demo28-inst${count.index + 1}" }
  user_data_base64       = base64encode(file(local.script)) 
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.demo28_eth0[count.index].id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.demo28_efa[count.index].id
  } 
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo28-inst${count.index + 1}-boot" }
  }
}

# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = (var.linux == "al") ? "ec2-user" : "ubuntu"
  ami_arm64  = (var.linux == "al") ? data.aws_ami.al_arm64.id  : data.aws_ami.ubuntu_2204_arm64.id
  ami_x86_64 = (var.linux == "al") ? data.aws_ami.al_x86_64.id : data.aws_ami.ubuntu_2204_x86_64.id
  ami        = (var.arch == "arm64") ? local.ami_arm64 : local.ami_x86_64
  script     = (var.linux == "al") ? var.cloud_init_script_al : var.cloud_init_script_ubuntu
}

# output SSH_connections {
#   value = [
#     for eip in aws_eip.demo28_inst.*:
#       "ssh -i ${var.private_sshkey_path} ${local.username}@${eip.public_ip}"
#   ]
# }


# ------ Create a SSH config file
resource local_file sshconfig {
  content = templatefile("templates/sshcfg.tpl", {
    eips                  = aws_eip.demo28_inst,
    username              = local.username,
    ssh_private_key_file  = var.private_sshkey_path
  })
  filename = "sshcfg"
  file_permission = "0644"
}

# ------ Display instructions to connect to compute instances
output CONNECTIONS {
 value = templatefile("templates/outputs.tpl", {
    eips                  = aws_eip.demo28_inst
 })
}