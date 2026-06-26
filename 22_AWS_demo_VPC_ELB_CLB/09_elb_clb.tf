# ------ create a CLB (Classic Load Balancer)
resource "aws_elb" "demo22_clb" {
  name                        = "demo22-clb"
  security_groups             = [aws_security_group.demo22_sg_clb.id]
  subnets                     = [for subnet in aws_subnet.demo22_public_lb : subnet.id]
  tags                        = { Name = "demo22-clb" }
  instances                   = [for inst in aws_instance.demo22_websrv : inst.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
}

# ------ Create a security group for the clb
resource "aws_security_group" "demo22_sg_clb" {
  name        = "demo22-sg-clb"
  description = "sg for the Load Balancer"
  vpc_id      = aws_vpc.demo22.id
  tags        = { Name = "demo22-sg-clb" }

  # # egress rule: allow all traffic
  # egress {
  #   description = "allow all traffic"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"    # all protocols
  #   cidr_blocks = [ "0.0.0.0/0" ]
  # }
}


resource "aws_vpc_security_group_ingress_rule" "demo22_sg_clb_ingress_http_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo22_sg_clb.id
  description       = "allow HTTP access from authorized_ips"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo22_sg_clb-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_egress_rule" "demo22_sg_clb_egress_http_1" {
  security_group_id            = aws_security_group.demo22_sg_clb.id
  description                  = "allow only HTTP traffic to web servers"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.demo22_sg_websrv.id
  tags                         = { Name = "demo22_sg_clb-sgr-egress-http-1" }
}
