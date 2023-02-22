# ------ create an ALB (Apllication Load Balancer)
resource aws_lb demo04_alb {
  name               = "demo04-alb"
  internal           = false        # public facing
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.demo04_sg_alb.id ]
  subnets            = [ for subnet in aws_subnet.demo04_public_lb: subnet.id ]

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

# ------ Create a first target group (empty)
resource aws_lb_target_group demo04_tg1 {
  name     = "demo04-tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo04.id
}

# ------ Attach the first 2 webservers EC2 instances to the target group #1
resource aws_lb_target_group_attachment demo04_tg1_websrv {
  count            = 2
  target_group_arn = aws_lb_target_group.demo04_tg1.arn
  target_id        = aws_instance.demo04_websrv[count.index].id
  port             = 80
}

# ------ Create a listener for the ALB
resource aws_lb_listener demo04_listener80 {
  load_balancer_arn = aws_lb.demo04_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo04_tg1.arn
  }
}

# ------ Create a security group for the ALB
resource aws_security_group demo04_sg_alb {
  name        = "demo04-sg-alb"
  description = "sg for the Load Balancer"
  vpc_id      = aws_vpc.demo04.id
  tags        = { Name = "demo04-sg-alb" }

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
    security_groups = [ aws_security_group.demo04_sg_websrv.id ]
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

# ====== Path based routing

# ------ Create a second target group (empty) for path-based routing
resource aws_lb_target_group demo04_tg2 {
  name     = "demo04-tg2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo04.id
}

# ------ Attach the 3rd webserver EC2 instance to the target group #2
resource aws_lb_target_group_attachment demo04_tg2_websrv {
  target_group_arn = aws_lb_target_group.demo04_tg2.arn
  target_id        = aws_instance.demo04_websrv[2].id
  port             = 80
}

# ------ Add a listener rule for path based routing
resource aws_lb_listener_rule demo04_rule1 {
  listener_arn = aws_lb_listener.demo04_listener80.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo04_tg2.arn
  }

  condition {
    path_pattern {
      values = ["/mypath/*"]
    }
  }

  # condition {
  #   host_header {
  #     values = ["example.com"]
  #   }
  # }
}
