# ------ Create standard network interfaces (device_index 0) for EC2 instances
resource "aws_network_interface" "demo28_primary" {
  count           = var.nb_instances
  subnet_id       = aws_subnet.demo28_public.id
  private_ips     = [var.inst_private_ip[count.index]]
  security_groups = [aws_default_security_group.demo28.id]
  tags            = { Name = "demo28-nic0-primary-${count.index + 1}" }
}

# ------ Create EFA network interfaces (device_index 1) for EC2 instances
resource "aws_network_interface" "demo28_efa" {
  count           = var.nb_instances
  interface_type  = "efa"
  subnet_id       = aws_subnet.demo28_private_efa.id
  private_ips     = [var.inst_private_ip_efa[count.index]]
  security_groups = [aws_security_group.demo28_efa.id]
  tags            = { Name = "demo28-nic1-efa-${count.index + 1}" }
}

# ------ Create a placement group for EC2 instances (type CLUSTER)
resource "aws_placement_group" "demo28" {
  name     = "demo28-cluster"
  strategy = "cluster"
}

# ------ Create EC2 instances with both NICs attached at launch
resource "aws_instance" "demo28_inst" {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  count             = var.nb_instances
  placement_group   = aws_placement_group.demo28.id
  availability_zone = "${var.aws_region}${var.az}"
  instance_type     = var.inst_type
  ami               = local.ami
  key_name          = aws_key_pair.demo28.id
  tags              = { Name = "demo28-inst${count.index + 1}" }
  user_data_base64  = base64encode(templatefile(local.script, {
    ssh_private_key  = tls_private_key.ssh_demo28.private_key_pem
    hostfile_content = join("\n", [for ip in var.inst_private_ip_efa : "${ip} slots=4"])
  }))

  # Primary network interface (standard)
  network_interface {
    network_interface_id = aws_network_interface.demo28_primary[count.index].id
    device_index         = 0
  }

  # EFA network interface - attached at launch (required for EFA)
  network_interface {
    network_interface_id = aws_network_interface.demo28_efa[count.index].id
    device_index         = 1
  }

  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo28-inst${count.index + 1}-boot" }
  }
}

# ------ Create Elastic IP addresses for EC2 instances
resource "aws_eip" "demo28_inst" {
  count                     = var.nb_instances
  domain                    = "vpc"
  network_interface         = aws_network_interface.demo28_primary[count.index].id
  associate_with_private_ip = var.inst_private_ip[count.index]
  tags                      = { Name = "demo28-inst${count.index + 1}" }
  depends_on                = [aws_internet_gateway.demo28]
}

# ------ Locals
locals {
  username   = (var.linux == "al") ? "ec2-user" : "ubuntu"
  ami_arm64  = (var.linux == "al") ? data.aws_ami.al_arm64.id : data.aws_ami.ubuntu_2204_arm64.id
  ami_x86_64 = (var.linux == "al") ? data.aws_ami.al_x86_64.id : data.aws_ami.ubuntu_2204_x86_64.id
  ami        = (var.arch == "arm64") ? local.ami_arm64 : local.ami_x86_64
  script     = (var.linux == "al") ? var.cloud_init_script_al : var.cloud_init_script_ubuntu
}

# ------ Create a SSH config file
resource "local_file" "sshconfig" {
  content = templatefile("templates/sshcfg.tpl", {
    eips                 = aws_eip.demo28_inst,
    username             = local.username,
    ssh_private_key_file = var.private_sshkey_path
  })
  filename        = "sshcfg"
  file_permission = "0644"
}

# ------ Display instructions to connect to compute instances
output "CONNECTIONS" {
  value = templatefile("templates/outputs.tpl", {
    eips = aws_eip.demo28_inst
  })
}
