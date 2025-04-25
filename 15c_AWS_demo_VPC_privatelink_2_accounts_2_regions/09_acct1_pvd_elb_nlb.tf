# ------ create an NLB (Network Load Balancer)
resource aws_lb demo15c_pvd_nlb {
  provider           = aws.acct1
  name               = "demo15c-pvd-nlb"
  internal           = false        # public facing
  load_balancer_type = "network"
  subnets            = aws_subnet.demo15c_acct1_pvd_public[*].id

  enable_deletion_protection = false

#   # -- optionally, uses Elastic IP addresses instead of ephemeral IP addresses for public NLB
#   subnet_mapping {
#     subnet_id     = aws_subnet.example1.id
#     allocation_id = aws_eip.example1.id
#   }

#   subnet_mapping {
#     subnet_id     = aws_subnet.example2.id
#     allocation_id = aws_eip.example2.id
#   }

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
resource aws_lb_target_group demo15c_pvd_tg1 {
  provider = aws.acct1
  name     = "demo15c-pvd-tg1"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.demo15c_acct1_pvd.id

  health_check {
    enabled             = true
    timeout             = 5
    interval            = 10
    protocol            = "TCP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ------ Attach the 2 webservers EC2 instances to the target group
resource aws_lb_target_group_attachment demo15c_pvd_websrv {
  provider         = aws.acct1
  count            = 2
  target_group_arn = aws_lb_target_group.demo15c_pvd_tg1.arn
  target_id        = aws_instance.demo15c_acct1_pvd_websrv[count.index].id
  port             = 80
}

# ------ Create a listener for the NLB
resource aws_lb_listener demo15c_pvd_listener80 {
  provider          = aws.acct1
  load_balancer_arn = aws_lb.demo15c_pvd_nlb.arn
  port              = "80"
  protocol          = "TCP" # must be one of 'TLS, TCP, TCP_UDP, UDP'

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo15c_pvd_tg1.arn
  }
}