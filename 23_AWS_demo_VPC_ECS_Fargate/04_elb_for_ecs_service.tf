resource aws_lb demo23_alb {
  name               = "demo23-alb"
  internal           = false        # public facing
  load_balancer_type = "application"
  security_groups    = [ aws_default_security_group.demo23.id ]
  subnets            = [ for subnet in aws_subnet.demo23_public: subnet.id ]
  enable_deletion_protection = false
}

resource aws_lb_target_group demo23_tg1 {
  name     = "demo23-tg1"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.demo23.id
}

resource aws_lb_listener demo23_listener80 {
  load_balancer_arn = aws_lb.demo23_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo23_tg1.arn
  }
}