resource aws_network_interface demo19_vip {
  subnet_id       = aws_subnet.demo19_public.id
  private_ips     = [ var.websrv_private_ip_vip ]
  security_groups = [ aws_security_group.demo19_sg_vip.id ]

  attachment {
    instance     = aws_instance.demo19_websrv[var.websrv_vip_owner - 1].id
    device_index = 1
  }
}

resource aws_eip demo19_vip {
  network_interface = aws_network_interface.demo19_vip.id
  vpc               = true
  tags              = { Name = "demo19-bastion" }
}

# ------ Create a security group
resource aws_security_group demo19_sg_vip {
  name        = "demo19-sg-vip"
  description = "Description for demo19-sg-vip"
  vpc_id      = aws_vpc.demo19.id
  tags        = { Name = "demo19-sg-vip" }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTP access from authorized IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
  }
}