# ------ create an ALB (Application Load Balancer)
resource "aws_lb" "demo04b_alb" {
  name               = "demo04b-alb"
  internal           = false # public facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo04b_sg_alb.id]
  subnets            = [for subnet in aws_subnet.demo04b_public_lb : subnet.id]

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
resource "aws_lb_target_group" "demo04b_tg1" {
  name     = "demo04b-tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo04b.id
}

# ------ Attach the 2 webservers EC2 instances to the target group
resource "aws_lb_target_group_attachment" "demo04b_websrv" {
  count            = 2
  target_group_arn = aws_lb_target_group.demo04b_tg1.arn
  target_id        = aws_instance.demo04b_websrv[count.index].id
  port             = 80
}

# ------ Create a HTTP listener for the ALB (redirect to HTTPS)
resource "aws_lb_listener" "demo04b_listener80" {
  load_balancer_arn = aws_lb.demo04b_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ------ Create a HTTPS listener for the ALB
resource "aws_lb_listener" "demo04b_listener443" {
  load_balancer_arn = aws_lb.demo04b_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.demo04b.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo04b_tg1.arn
  }
}

# ------ Add a second certificate for ALB listener
resource "aws_lb_listener_certificate" "demo04b2" {
  listener_arn    = aws_lb_listener.demo04b_listener443.arn
  certificate_arn = aws_acm_certificate.demo04b2.arn
}

# ------ Create a security group for the ALB
resource "aws_security_group" "demo04b_sg_alb" {
  name        = "demo04b-sg-alb"
  description = "sg for the Load Balancer"
  vpc_id      = aws_vpc.demo04b.id
  tags        = { Name = "demo04b-sg-alb" }

}


resource "aws_vpc_security_group_ingress_rule" "demo04b_sg_alb_ingress_http_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo04b_sg_alb.id
  description       = "allow HTTP access from authorized_ips"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo04b_sg_alb-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo04b_sg_alb_ingress_https_1" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo04b_sg_alb.id
  description       = "allow HTTPS access from authorized_ips"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo04b_sg_alb-sgr-ingress-https-1" }
}

resource "aws_vpc_security_group_egress_rule" "demo04b_sg_alb_egress_all_2" {
  security_group_id = aws_security_group.demo04b_sg_alb.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo04b_sg_alb-sgr-egress-all-2" }
}
