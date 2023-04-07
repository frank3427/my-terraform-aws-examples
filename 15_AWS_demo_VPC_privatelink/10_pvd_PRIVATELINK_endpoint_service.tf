resource aws_vpc_endpoint_service demo15_pvd {
  acceptance_required        = false
  network_load_balancer_arns = [ aws_lb.demo15_pvd_nlb.arn ]
  tags                       = { Name = "demo15-pvd-endp-svc-for-nlb" }
}