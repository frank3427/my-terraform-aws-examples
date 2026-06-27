# ------ create an ALB (Application Load Balancer)
resource "aws_lb" "cr3_r1_alb" {
  provider           = aws.r1
  name               = "cr3-r1-alb"
  internal           = false # public facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cr3_r1_sg_alb.id]
  subnets            = [for subnet in aws_subnet.cr3_r1_alb : subnet.id]

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
resource "aws_lb_target_group" "cr3_r1_tg1" {
  provider = aws.r1
  name     = "cr3-r1-tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cr3_r1.id
}

# ------ Attach the 3 webservers EC2 instances to the target group
resource "aws_lb_target_group_attachment" "cr3_r1_websrv" {
  provider         = aws.r1
  count            = 3
  target_group_arn = aws_lb_target_group.cr3_r1_tg1.arn
  target_id        = aws_instance.cr3_r1_websrv[count.index].id
  port             = 80
}

# ------ Create a HTTP listener for the ALB (redirect to HTTPS)
resource "aws_lb_listener" "cr3_r1_listener80" {
  provider          = aws.r1
  load_balancer_arn = aws_lb.cr3_r1_alb.arn
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
resource "aws_lb_listener" "cr3_r1_listener443" {
  depends_on        = [aws_acm_certificate_validation.cr3]
  provider          = aws.r1
  load_balancer_arn = aws_lb.cr3_r1_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cr3_alb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cr3_r1_tg1.arn
  }
}

# ------ Create a security group for the ALB
resource "aws_security_group" "cr3_r1_sg_alb" {
  provider    = aws.r1
  name        = "cr3_r1-sg-alb"
  description = "sg for the Load Balancer"
  vpc_id      = aws_vpc.cr3_r1.id
  tags        = { Name = "cr3_r1-sg-alb" }

}


resource "aws_vpc_security_group_ingress_rule" "cr3_r1_sg_alb_ingress_http_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.cr3_r1_sg_alb.id
  description       = "allow HTTP access from authorized_ips"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "cr3_r1_sg_alb-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_ingress_rule" "cr3_r1_sg_alb_ingress_https_1" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.cr3_r1_sg_alb.id
  description       = "allow HTTPS access from authorized_ips"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "cr3_r1_sg_alb-sgr-ingress-https-1" }
}

resource "aws_vpc_security_group_egress_rule" "cr3_r1_sg_alb_egress_all_2" {
  security_group_id = aws_security_group.cr3_r1_sg_alb.id
  description       = "allow all traffic"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "cr3_r1_sg_alb-sgr-egress-all-2" }
}
