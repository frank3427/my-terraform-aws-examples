resource aws_vpc_endpoint_service demo15b_pvd {
  provider                   = aws.acct1
  acceptance_required        = false
  network_load_balancer_arns = [ aws_lb.demo15b_pvd_nlb.arn ]
  tags                       = { Name = "demo15b-pvd-endp-svc-for-nlb" }
  allowed_principals         = [ local.acct2_role_arn ] 
}

data aws_caller_identity acct2_current {
  provider = aws.acct2
}

data aws_iam_role acct2 {
  provider = aws.acct2
  name     = local.acct2_role
}

locals {
  acct2_role     = split("/",data.aws_caller_identity.acct2_current.arn)[1]
  acct2_role_arn = data.aws_iam_role.acct2.arn
}
