# ------ optional: Create Elastic IP addresses
# ------           to have public IP addresses for EC2 instances persistent across stop/start
resource aws_eip demo20 {
  count    = var.nb_instances_linux
  instance = aws_instance.demo20[count.index].id
  vpc      = true
  tags     = { Name = "demo20-linux${count.index+1}" }
}

# ------ Create EC2 instances
resource aws_instance demo20 {
  count    = var.nb_instances_linux
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst_type
  ami                    = data.aws_ami.al2_x86_64.id
  key_name               = aws_key_pair.demo20.id
  subnet_id              = aws_subnet.demo20_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo20.id ] 
  tags                   = { Name = "demo20-linux${count.index+1}" }
  user_data_base64       = base64encode(file(var.cloud_init_script_al2)) 
  iam_instance_profile   = aws_iam_instance_profile.demo20_ssm.id
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { Name = "demo20-linux${count.index+1}-boot" }
  }
}

# ------ SSH config file
resource local_file sshconfig {
  content = templatefile("templates/sshcfg.template", {
    username             = "ec2-user",
    instances            = aws_instance.demo20,
    ssh_private_key_file = var.private_sshkey_path
  })
  filename = "sshcfg"
  file_permission = "0644"
}

# ------ Display the complete ssh command needed to connect to the instance
output Instances {
  value = <<EOF


---- You can SSH directly to the Linux instances by typing the following ssh commands:
${join("\n",[for instance in aws_instance.demo20: "ssh -F sshcfg ${instance.tags_all.Name}"])}

EOF
}