# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo37_inst1 {
  instance = aws_instance.demo37_inst1.id
  domain   = "vpc"
  tags     = { Name = "demo37-inst1" }
}

resource aws_eip demo37_inst2 {
  instance = aws_instance.demo37_inst2.id
  domain   = "vpc"
  tags     = { Name = "demo37-inst2" }
}

# ------ Create an EC2 instance
resource aws_instance demo37_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  instance_type          = var.inst1_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo37.id
  subnet_id              = aws_subnet.demo37_public1.id
  vpc_security_group_ids = [ aws_default_security_group.demo37.id ] 
  tags                   = { Name = "demo37-inst1" }
  user_data_base64       = base64encode(file(local.script)) 
  private_ip             = var.inst1_private_ip   # optional 
  # ipv6_address_count     = 1  # automatic IPv6 address
  ipv6_addresses         = [ cidrhost(aws_subnet.demo37_public1.ipv6_cidr_block, 101) ]   # OR manual IPv6 address
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo37-inst1-boot" }
  }
}

resource aws_instance demo37_inst2 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  instance_type          = var.inst2_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo37.id
  subnet_id              = aws_subnet.demo37_public2.id
  vpc_security_group_ids = [ aws_default_security_group.demo37.id ] 
  tags                   = { Name = "demo37-inst2" }
  user_data_base64       = base64encode(file(local.script)) 
  private_ip             = var.inst2_private_ip   # optional  
  ipv6_address_count     = 1  # automatic IPv6 address
  # ipv6_addresses         = [ cidrhost(aws_subnet.demo37_public1.ipv6_cidr_block, 102) ]   # OR manual IPv6 address
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo37-inst2-boot" }
  }
}

# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
  script     = var.cloud_init_script_al
  inst1_ipv6 = aws_instance.demo37_inst1.ipv6_addresses[0]
  inst2_ipv6 = aws_instance.demo37_inst2.ipv6_addresses[0]
}

output Instances {
  value = <<EOF


---- You can SSH directly to the Linux instances by typing the following ssh command
instance #1: ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo37_inst1.public_ip}
instance #2: ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo37_inst2.public_ip}

---- Once connected to instance #1, you can test access to web servers using IPv6
to instance #1: curl -6 'http://[${local.inst1_ipv6}]:80/'
to instance #2: curl -6 'http://[${local.inst2_ipv6}]:80/'

---- Once connected to instance #1, you can ping instance #2 using IPv6
to instance #1: ping6 ${local.inst1_ipv6}
to instance #2: ping6 ${local.inst2_ipv6}

---- You can access Web Servers from local machine using IP v4 addresses
instance #1: http://${aws_eip.demo37_inst1.public_ip}
instance #2: http://${aws_eip.demo37_inst2.public_ip}

---- You can access Web Servers from local machine using IP v6 addresses
instance #1: http://[${local.inst1_ipv6}]
instance #2: http://[${local.inst2_ipv6}]


EOF
}