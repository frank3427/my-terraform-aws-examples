# ------ Create an NLB (Network Load Balancer) in public subnets
resource "aws_lb" "demo04c_nlb" {
  name               = "demo04c-nlb"
  internal           = false # public facing
  load_balancer_type = "network"
  subnets            = aws_subnet.demo04c_public_nlb[*].id

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
}

# ------ Create a target group for NLB with ALB as target
resource "aws_lb_target_group" "demo04c_nlb_tg" {
  name        = "demo04c-nlb-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.demo04c.id
  target_type = "alb" # ALB as target

  health_check {
    enabled             = true
    timeout             = 5
    interval            = 10
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ------ Attach ALB to NLB target group
resource "aws_lb_target_group_attachment" "demo04c_nlb_tg_alb" {
  target_group_arn = aws_lb_target_group.demo04c_nlb_tg.arn
  target_id        = aws_lb.demo04c_alb.arn
  port             = 80
}

# ------ Create a listener for the NLB
resource "aws_lb_listener" "demo04c_nlb_listener80" {
  load_balancer_arn = aws_lb.demo04c_nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo04c_nlb_tg.arn
  }
}
