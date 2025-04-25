# ------ create a random key used as secret in customer header to prevent 
#        access to ALB directly from Global Accelerator (without CloudFront)
resource random_string demo41_secret {
  # must contains at least 2 upper case letters, 2 lower case letters, 2 numbers and 2 special characters
  length      = 20
  upper       = true
  min_upper   = 2
  lower       = true
  min_lower   = 2
  numeric     = true
  min_numeric = 2
  special     = true
  min_special = 2
  override_special = "#-_"   # use only special characters in this list
}

locals {
  demo41_secret = random_string.demo41_secret.result
}

# ------ create an ALB (Application Load Balancer) in private subnet
resource aws_lb demo41_alb_private {
  name               = "demo41-alb-private"
  internal           = true        # private
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.demo41_sg_alb.id ]
  subnets            = [ for subnet in aws_subnet.demo41_private_alb: subnet.id ]

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
resource aws_lb_target_group demo41_tg1 {
  name     = "demo41-tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo41.id
  # preserve_client_ip = true
}

# ------ Attach the webservers EC2 instances to the target group
resource aws_lb_target_group_attachment demo41_tg1_websrv {
  count            = var.websrv_nb_instances
  target_group_arn = aws_lb_target_group.demo41_tg1.arn
  target_id        = aws_instance.demo41_websrv[count.index].id
  port             = 80
}

# ------ Create a listener for the ALB
resource aws_lb_listener demo41_alb_private_80 {
  load_balancer_arn = aws_lb.demo41_alb_private.arn
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
resource aws_lb_listener_rule demo41_alb_private_80_header {
  listener_arn = aws_lb_listener.demo41_alb_private_80.arn
  priority     = 1
  tags         = { Name = "demo41-fwd-tg" }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo41_tg1.arn
  }

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"
      values           = [ local.demo41_secret ]
    }
  }
}

# ------ Create a security group for the ALB
# data aws_ec2_managed_prefix_list cloudfront {
#   name = "com.amazonaws.global.cloudfront.origin-facing"
# }

# data aws_ec2_managed_prefix_list globalaccelerator {
#   name = "com.amazonaws.global.globalaccelerator.prefix_list"
# }

resource aws_security_group demo41_sg_alb {
  name        = "demo41-sg-alb"
  description = "sg for the Load Balancer"
  vpc_id      = aws_vpc.demo41.id
  tags        = { Name = "demo41-sg-alb" }

#   ingress {
#     description     = "Allow HTTP from Global Accelerator"
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     cidr_blocks     = []
#     # cidr_blocks     = formatlist("%s/32", aws_globalaccelerator_accelerator.demo41.ip_sets[0].ip_addresses)
# #    prefix_list_ids = [data.aws_ec2_managed_prefix_list.globalaccelerator.id]
#   }

  ingress {
    description     = "Allow HTTP from VPC"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ] # var.cidr_vpc ]
  }

  # # egress rule: allow only HTTP traffic to web servers
  # egress {
  #   description     = "allow only HTTP traffic to web servers"
  #   from_port       = 80
  #   to_port         = 80
  #   protocol        = "tcp"   
  #   security_groups = [ aws_security_group.demo41_sg_websrv.id ]
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