# # ------ Create an EC2 instances for web servers
# resource aws_instance demo18_websrv {
#   # wait for NAT gateway to be ready (needed by cloud-init script)
#   depends_on = [
#     aws_nat_gateway.demo18
#   ]
#   # ignore change in cloud-init file after provisioning
#   lifecycle {
#     ignore_changes = [
#       user_data_base64
#     ]
#   }
#   count                  = 3
#   availability_zone      = "${var.aws_region}${var.websrv_az[count.index % 2]}"
#   instance_type          = var.websrv_inst_type
#   ami                    = data.aws_ami.al2_arm64.id
#   key_name               = aws_key_pair.demo18_websrv.id
#   subnet_id              = aws_subnet.demo18_private_websrv[count.index % 2].id
#   vpc_security_group_ids = [ aws_security_group.demo18_sg_websrv.id ]
#   tags                   = { Name = "demo18-websrv${count.index + 1}" }
#   user_data_base64       = base64encode(replace(file(var.websrv_cloud_init_script),"<HOSTNAME>","websrv${count.index + 1}"))        
# }

# -------- Create a Launch template
resource aws_launch_template demo18 {
  name                   = "demo18"
  image_id               = data.aws_ami.al2_arm64.id
  instance_type          = var.websrv_inst_type
  key_name               = aws_key_pair.demo18_websrv.id
  user_data              = filebase64(var.websrv_cloud_init_script) 
  network_interfaces {
    # subnet_id       = aws_subnet.demo18_private_websrv[0].id
    security_groups = [ aws_security_group.demo18_sg_websrv.id ]
  }
  # network_interfaces {
  #   subnet_id = aws_subnet.demo18_private_websrv[1].id
  # }
}

# -------- Create an auto scaling group
resource aws_autoscaling_group demo18 {
  # wait for NAT gateway to be ready (needed by cloud-init script)
  depends_on = [
    aws_nat_gateway.demo18
  ]
  name                = "demo18-asg"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  target_group_arns   = [ aws_lb_target_group.demo18_tg1.arn ]
  vpc_zone_identifier = [ for subnet in aws_subnet.demo18_private_websrv: subnet.id ]

  launch_template {
    id      = aws_launch_template.demo18.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "demo18-from-asg"
    propagate_at_launch = true
  }
  instance_refresh {
    strategy = "Rolling"
  }
}

# ------ Create a security group
resource aws_security_group demo18_sg_websrv {
  name        = "demo18-sg-websrv"
  description = "Description for demo18-sg-websrv"
  vpc_id      = aws_vpc.demo18.id
  tags        = { Name = "demo18-sg-websrv" }

  # Cycle error in Terraform
  # # ingress rule: allow HTTP
  # ingress {
  #   description = "allow HTTP access from load balancer"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   security_groups = [ aws_security_group.demo18_sg_alb.id ]
  # }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTP access from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_vpc ]
  }

  # ingress rule: allow SSH from bastion host
  ingress {
    description     = "allow SSH access from bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [ aws_security_group.demo18_sg_bastion.id ]
  }

  # # ingress rule: allow SSH
  # ingress {
  #   description = "allow SSH access from public subnet"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
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
