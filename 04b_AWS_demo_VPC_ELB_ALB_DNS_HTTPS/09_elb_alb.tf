# ------ create an ALB (Application Load Balancer)
resource aws_lb demo04b_alb {
  name               = "demo04b-alb"
  internal           = false        # public facing
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.demo04b_sg_alb.id ]
  subnets            = [ for subnet in aws_subnet.demo04b_public_lb: subnet.id ]

  enable_deletion_protection = false

#   access_logs {
#     bucket  = aws_s3_bucket.lb_logs.bucket
#     prefix  = "test-lb"
#     enabled = true
#   }

#   tags = {
#     Environment = "production"
#   }
}

# ------ Create a target group (empty)
resource aws_lb_target_group demo04b_tg1 {
  name     = "demo04b-tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo04b.id
}

# ------ Attach the 2 webservers EC2 instances to the target group
resource aws_lb_target_group_attachment demo04b_websrv {
  count            = 2
  target_group_arn = aws_lb_target_group.demo04b_tg1.arn
  target_id        = aws_instance.demo04b_websrv[count.index].id
  port             = 80
}

# ------ Create a HTTP listener for the ALB
resource aws_lb_listener demo04b_listener80 {
  load_balancer_arn = aws_lb.demo04b_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo04b_tg1.arn
  }
}

# # ------ Create a HTTPS listener for the ALB
# resource aws_lb_listener demo04b_listener443 {
#   load_balancer_arn = aws_lb.demo04b_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.demo04b_tg1.arn
#   }
# }

# ------ Create a security group for the ALB
resource aws_security_group demo04b_sg_alb {
  name        = "demo04b-sg-alb"
  description = "sg for the Load Balancer"
  vpc_id      = aws_vpc.demo04b.id
  tags        = { Name = "demo04b-sg-alb" }

  # # ingress rule: allow HTTP
  # ingress {
  #   description = "allow HTTP access from authorized_ips"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = var.authorized_ips
  # }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTPS access from authorized_ips"
    from_port   = 443
    to_port     = 443
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
