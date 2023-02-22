# ------ create an ALB (Apllication Load Balancer)
resource aws_lb demo18_alb {
  name               = "demo18-alb"
  internal           = false        # public facing
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.demo18_sg_alb.id ]
  subnets            = [ for subnet in aws_subnet.demo18_public_lb: subnet.id ]

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
resource aws_lb_target_group demo18_tg1 {
  name     = "demo18-tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo18.id
}

# ------ Create a listener for the ALB
resource aws_lb_listener demo18_listener80 {
  load_balancer_arn = aws_lb.demo18_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo18_tg1.arn
  }
}

# ------ Create a security group for the ALB
resource aws_security_group demo18_sg_alb {
  name        = "demo18-sg-alb"
  description = "sg for the Load Balancer"
  vpc_id      = aws_vpc.demo18.id
  tags        = { Name = "demo18-sg-alb" }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTP access from authorized_ips"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
  }

  # egress rule: allow only HTTP traffic to web servers
  egress {
    description     = "allow only HTTP traffic to web servers"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"   
    security_groups = [ aws_security_group.demo18_sg_websrv.id ]
  }

  # # egress rule: allow all traffic
  # egress {
  #   description = "allow all traffic"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"    # all protocols
  #   cidr_blocks = [ "0.0.0.0/0" ]
  # }
}