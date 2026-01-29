# ------ Create a security group for the ALB
resource "aws_security_group" "demo04c_sg_alb" {
  name        = "demo04c-sg-alb"
  description = "sg for the Application Load Balancer"
  vpc_id      = aws_vpc.demo04c.id
  tags        = { Name = "demo04c-sg-alb" }

  ingress {
    description = "allow HTTP from VPC and authorized IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # concat([var.cidr_vpc], var.authorized_ips)
  }
}

# ------ Create separate egress rule for ALB to websrv
resource "aws_security_group_rule" "demo04c_sg_alb_egress_websrv" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.demo04c_sg_websrv.id
  security_group_id        = aws_security_group.demo04c_sg_alb.id
  description              = "allow HTTP traffic to web servers"
}

# ------ Create an ALB (Application Load Balancer) in private subnets
resource "aws_lb" "demo04c_alb" {
  name               = "demo04c-alb"
  internal           = true # private ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo04c_sg_alb.id]
  subnets            = aws_subnet.demo04c_private_alb[*].id

  enable_deletion_protection = false
}

# ------ Create a target group for ALB
resource "aws_lb_target_group" "demo04c_alb_tg" {
  name     = "demo04c-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo04c.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
}

# ------ Attach webserver instances to ALB target group
resource "aws_lb_target_group_attachment" "demo04c_alb_tg_websrv" {
  count            = 2
  target_group_arn = aws_lb_target_group.demo04c_alb_tg.arn
  target_id        = aws_instance.demo04c_websrv[count.index].id
  port             = 80
}

# ------ Create a listener for the ALB
resource "aws_lb_listener" "demo04c_alb_listener80" {
  load_balancer_arn = aws_lb.demo04c_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo04c_alb_tg.arn
  }
}
