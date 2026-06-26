# ------ create an ALB (Apllication Load Balancer)
resource "aws_lb" "demo18_alb" {
  name               = "demo18-alb"
  internal           = false # public facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo18_sg_alb.id]
  subnets            = [for subnet in aws_subnet.demo18_public_lb : subnet.id]

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
resource "aws_lb_target_group" "demo18_tg1" {
  name     = "demo18-tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo18.id
}

# ------ Create a listener for the ALB
resource "aws_lb_listener" "demo18_listener80" {
  load_balancer_arn = aws_lb.demo18_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo18_tg1.arn
  }
}

# ------ Create a security group for the ALB
resource "aws_security_group" "demo18_sg_alb" {
  name        = "demo18-sg-alb"
  description = "sg for the Load Balancer"
  vpc_id      = aws_vpc.demo18.id
  tags        = { Name = "demo18-sg-alb" }

  # # egress rule: allow all traffic
  # egress {
  #   description = "allow all traffic"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"    # all protocols
  #   cidr_blocks = [ "0.0.0.0/0" ]
  # }
}


resource "aws_vpc_security_group_ingress_rule" "demo18_sg_alb_ingress_http_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo18_sg_alb.id
  description       = "allow HTTP access from authorized_ips"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo18_sg_alb-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_egress_rule" "demo18_sg_alb_egress_http_1" {
  security_group_id            = aws_security_group.demo18_sg_alb.id
  description                  = "allow only HTTP traffic to web servers"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.demo18_sg_websrv.id
  tags                         = { Name = "demo18_sg_alb-sgr-egress-http-1" }
}
