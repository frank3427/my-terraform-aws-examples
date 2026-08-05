# ------ create an ALB (Application Load Balancer) in public subnet
resource "aws_lb" "demo41_alb_public" {
  name               = "demo41-alb-public"
  internal           = false # public
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo41_sg_alb.id]
  subnets            = [for subnet in aws_subnet.demo41_public : subnet.id]

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
resource "aws_lb_target_group" "demo41_tg2" {
  name     = "demo41-tg2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo41.id
  # preserve_client_ip = true
}

# ------ Attach the webservers EC2 instances to the target group
resource "aws_lb_target_group_attachment" "demo41_tg2_websrv" {
  count            = var.websrv_nb_instances
  target_group_arn = aws_lb_target_group.demo41_tg2.arn
  target_id        = aws_instance.demo41_websrv[count.index].id
  port             = 80
}

# ------ Create a listener for the ALB
resource "aws_lb_listener" "demo41_alb_public_80" {
  load_balancer_arn = aws_lb.demo41_alb_public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Invalid request (missing custom header)"
      status_code  = "403"
    }
  }
}

# ------ Create a listener rule
resource "aws_lb_listener_rule" "demo41_alb_public_80_header" {
  listener_arn = aws_lb_listener.demo41_alb_public_80.arn
  priority     = 1
  tags         = { Name = "demo41-fwd-tg" }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo41_tg2.arn
  }

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"
      values           = [local.demo41_secret]
    }
  }
}

resource "aws_security_group" "demo41_sg_alb_public" {
  name        = "demo41-sg-alb-public"
  description = "sg for the Load Balancer"
  vpc_id      = aws_vpc.demo41.id
  tags        = { Name = "demo41-sg-alb-public" }

}


resource "aws_vpc_security_group_ingress_rule" "demo41_sg_alb_public_ingress_http_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo41_sg_alb_public.id
  description       = "Allow HTTP from Authorized IP addresses"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo41_sg_alb_public-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_egress_rule" "demo41_sg_alb_public_egress_all_1" {
  security_group_id = aws_security_group.demo41_sg_alb_public.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo41_sg_alb_public-sgr-egress-all-1" }
}
