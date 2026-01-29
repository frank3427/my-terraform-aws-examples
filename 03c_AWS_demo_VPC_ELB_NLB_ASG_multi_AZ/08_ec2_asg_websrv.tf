# ------ Create launch template for web servers
resource aws_launch_template demo03c_websrv {
  name_prefix   = "demo03c-websrv-"
  image_id      = data.aws_ami.al2023_arm64.id
  instance_type = var.websrv_inst_type
  
  vpc_security_group_ids = [aws_security_group.demo03c_sg_websrv.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.demo03c_ssm.name
  }
  
  user_data = base64encode(replace(file(var.websrv_cloud_init_script), "<HOSTNAME>", "websrv"))
  
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted   = true
      volume_type = "gp3"
    }
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "demo03c-websrv"
    }
  }
}

# ------ Create auto-scaling group
resource aws_autoscaling_group demo03c_websrv {
  name                = "demo03c-websrv-asg"
  vpc_zone_identifier = [for subnet in aws_subnet.demo03c_private : subnet.id]
  target_group_arns   = [aws_lb_target_group.demo03c_tg1.arn]
  health_check_type   = "ELB"
  
  min_size         = var.nb_az
  max_size         = var.nb_az * 2
  desired_capacity = var.nb_az
  
  launch_template {
    id      = aws_launch_template.demo03c_websrv.id
    version = "$Latest"
  }
  
  depends_on = [aws_nat_gateway.demo03c]
}

# ------ Create a security group
resource aws_security_group demo03c_sg_websrv {
  name        = "demo03c-sg-websrv"
  description = "Description for demo03c-sg-websrv"
  vpc_id      = aws_vpc.demo03c.id
  tags        = { Name = "demo03c-sg-websrv" }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTP access from authorized public IP addresses (thru NLB)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips 
  }

  # ingress rule: allow HTTP for LB health checks
  ingress {
    description = "allow HTTP access from VPC public subnet (needed for health checks)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_subnet_public
  }
  
  # ingress rule: allow HTTPS for Session Manager
  ingress {
    description = "allow HTTPS access from VPC (required by Session Manager)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_vpc]
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